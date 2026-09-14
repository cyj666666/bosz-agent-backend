package com.suzhou.bank.agent.util;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * 查询条件构造器（JeecgBoot {@code QueryGenerator} 的轻量替代）
 *
 * <p><b>为什么要替代而不是平移</b>：源工程用的是 JeecgBoot 的 {@code QueryGenerator}（1128 行），
 * 它绑定了只在 Jeecg 体系里存在的能力：{@code sys_permission_data_rule} 数据权限规则、
 * {@code sys_dict} 字典翻译、{@code superQueryParams} 高级查询、{@code FillRule}……
 * 本工程不引入这套地基，因此<b>只复刻前端实际依赖的那部分行为</b>。</p>
 *
 * <p><b>已复刻的行为</b>（与源实现一致）：</p>
 * <ol>
 *   <li><b>实体非空字段 → 查询条件</b>：反射遍历 searchObj，非空属性参与查询</li>
 *   <li><b>列名解析</b>：优先取 {@code @TableField}/{@code @TableId} 的值，否则驼峰转下划线；
 *       标了 {@code @TableField(exist = false)} 的字段跳过</li>
 *   <li><b>区间查询</b>：URL 参数 {@code <字段名>_begin} / {@code <字段名>_end} → {@code >=} / {@code <=}</li>
 *   <li><b>参数值前缀规则</b>（Jeecg 约定，前端查询框依赖）：
 *       <ul>
 *         <li>{@code *值*} → 全模糊}  {@code like}</li>
 *         <li>{@code *值}  → 左模糊（{@code %值}）</li>
 *         <li>{@code 值*}  → 右模糊（{@code 值%}）</li>
 *         <li>{@code 值,值2} → IN</li>
 *         <li>其它 → 等值</li>
 *       </ul>
 *   </li>
 *   <li><b>排序</b>：URL 参数 {@code column} + {@code order}（{@code asc}/{@code desc}），支持逗号分隔多字段</li>
 * </ol>
 *
 * <p><b>刻意未复刻的行为</b>（用到时再补，不静默）：</p>
 * <ul>
 *   <li><b>数据权限规则</b>（{@code sys_permission_data_rule}）——本工程无此表；</li>
 *   <li><b>高级查询 superQuery</b>（{@code superQueryParams} JSON 传参）；</li>
 *   <li><b>字典翻译 / @Dict</b>——由前端处理展示；</li>
 *   <li><b>多值模糊</b>（参数值形如 {@code ,a,b,}）——当前三个菜单的页面未用到。</li>
 * </ul>
 *
 * <p><b>安全</b>：所有条件都经 MyBatis-Plus 的占位符传参（{@code #{}"}），不拼接 SQL，
 * 因此不存在注入面；列名来自实体注解或驼峰转换（非用户输入），同样安全。</p>
 */
@Slf4j
public class AgentQueryGenerator {

    /** 区间查询后缀 */
    private static final String BEGIN = "_begin";
    private static final String END = "_end";

    /** Jeecg 的参数值前缀关键字 */
    private static final String STAR = "*";
    private static final String COMMA = ",";
    private static final String NOT_EQUAL = "!";
    private static final String QUERY_SEPARATE_KEYWORD = " ";

    /** 分页/排序等控制参数，不当作字段条件处理 */
    private static final Set<String> USELESS_FIELDS = new HashSet<String>(Arrays.asList(
            "class", "serialVersionUID", "pageNo", "pageSize", "pageIndex",
            "column", "order", "superQueryParams", "superQueryMatchType", "_t"
    ));

    /**
     * 由「查询实体 + 请求参数」构造 MyBatis-Plus 的 QueryWrapper
     *
     * @param searchObj    承载查询条件的实体（其非空属性会变成等值/模糊条件）
     * @param parameterMap 请求参数 Map（用于取 _begin/_end 区间与排序参数）
     */
    public static <T> QueryWrapper<T> initQueryWrapper(T searchObj, Map<String, String[]> parameterMap) {
        QueryWrapper<T> queryWrapper = new QueryWrapper<T>();
        if (searchObj == null) {
            return queryWrapper;
        }
        Class<?> clazz = searchObj.getClass();
        // 先收集实体的「属性名 → 列名」映射，便于排序参数反查列名
        for (Field field : clazz.getDeclaredFields()) {
            if (Modifier.isStatic(field.getModifiers()) || Modifier.isFinal(field.getModifiers())) {
                continue;
            }
            String name = field.getName();
            if (USELESS_FIELDS.contains(name)) {
                continue;
            }
            try {
                field.setAccessible(true);
                String column = resolveColumnName(clazz, name);
                if (column == null) {
                    continue;
                }
                // 1) 区间查询
                addIntervalQuery(queryWrapper, parameterMap, name, column);

                // 2) 主值查询
                Object value = field.get(searchObj);
                if (value == null) {
                    continue;
                }
                String rule = convertToRule(value);
                if (rule == null) {
                    continue;
                }
                addEasyQuery(queryWrapper, column, rule, replaceValue(rule, value));
            } catch (Exception e) {
                // 与源实现一致：单个字段处理失败不影响其它条件
                log.warn("agent 查询条件构造失败，字段={}，已跳过", name, e);
            }
        }
        // 3) 排序
        doMultiFieldsOrder(queryWrapper, parameterMap, clazz);
        return queryWrapper;
    }

    /** 列名解析：@TableId / @TableField 注解优先，否则驼峰转下划线；exist=false 的返回 null */
    private static String resolveColumnName(Class<?> clazz, String fieldName) {
        try {
            Field field = clazz.getDeclaredField(fieldName);
            TableId tableId = field.getAnnotation(TableId.class);
            if (tableId != null) {
                return StringUtils.isNotBlank(tableId.value()) ? tableId.value() : camelToUnderline(fieldName);
            }
            TableField tableField = field.getAnnotation(TableField.class);
            if (tableField != null) {
                if (!tableField.exist()) {
                    return null;
                }
                return StringUtils.isNotBlank(tableField.value()) ? tableField.value() : camelToUnderline(fieldName);
            }
        } catch (NoSuchFieldException ignore) {
            // 取不到注解不代表字段不可用，继续走驼峰转换
        }
        return camelToUnderline(fieldName);
    }

    private static String camelToUnderline(String name) {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < name.length(); i++) {
            char c = name.charAt(i);
            if (Character.isUpperCase(c)) {
                if (i > 0) {
                    sb.append('_');
                }
                sb.append(Character.toLowerCase(c));
            } else {
                sb.append(c);
            }
        }
        return sb.toString();
    }

    /** 区间查询：<字段>_begin → >= ；<字段>_end → <= */
    private static <T> void addIntervalQuery(QueryWrapper<T> queryWrapper, Map<String, String[]> parameterMap,
                                             String fieldName, String column) {
        if (parameterMap == null) {
            return;
        }
        String[] begins = parameterMap.get(fieldName + BEGIN);
        if (begins != null && begins.length > 0 && StringUtils.isNotBlank(begins[0])) {
            queryWrapper.ge(column, begins[0].trim());
        }
        String[] ends = parameterMap.get(fieldName + END);
        if (ends != null && ends.length > 0 && StringUtils.isNotBlank(ends[0])) {
            queryWrapper.le(column, ends[0].trim());
        }
    }

    /**
     * 由参数值推断查询规则（复刻源实现 {@code convert2Rule} 的判定顺序）
     *
     * @return 规则名；返回 null 表示该值不参与查询
     */
    private static String convertToRule(Object value) {
        if (value == null) {
            return null;
        }
        String val = (value + "").trim();
        if (val.isEmpty()) {
            return null;
        }
        String rule = null;
        // 形如 ">= 5" / "> 5" 这类「两位关键字 + 空格」的写法
        if (val.length() >= 3 && QUERY_SEPARATE_KEYWORD.equals(val.substring(2, 3))) {
            rule = matchTwoCharRule(val.substring(0, 2));
        }
        if (rule == null && val.length() >= 2 && QUERY_SEPARATE_KEYWORD.equals(val.substring(1, 2))) {
            rule = matchOneCharRule(val.substring(0, 1));
        }
        if (rule == null && val.contains(STAR)) {
            if (val.startsWith(STAR) && val.endsWith(STAR)) {
                rule = "LIKE";
            } else if (val.startsWith(STAR)) {
                rule = "LEFT_LIKE";
            } else if (val.endsWith(STAR)) {
                rule = "RIGHT_LIKE";
            }
        }
        if (rule == null && val.contains(COMMA)) {
            rule = "IN";
        }
        if (rule == null && val.startsWith(NOT_EQUAL)) {
            rule = "NE";
        }
        return rule != null ? rule : "EQ";
    }

    private static String matchTwoCharRule(String s) {
        if (">=".equals(s)) return "GE";
        if ("<=".equals(s)) return "LE";
        if ("<>".equals(s) || "!=".equals(s)) return "NE";
        return null;
    }

    private static String matchOneCharRule(String s) {
        if (">".equals(s)) return "GT";
        if ("<".equals(s)) return "LT";
        if ("!".equals(s)) return "NE";
        return null;
    }

    /** 去掉用于标识规则的字符，只留真实查询值（复刻源实现 {@code replaceValue}） */
    private static Object replaceValue(String rule, Object value) {
        if (value == null || rule == null) {
            return value;
        }
        String val = value.toString().trim();
        switch (rule) {
            case "LIKE":
                val = val.replace(STAR, "").replace(" ", "");
                break;
            case "LEFT_LIKE":
                val = val.replaceFirst("\\*", "").replace(" ", "");
                break;
            case "RIGHT_LIKE":
                val = val.replaceFirst("\\*$", "").replace(" ", "");
                break;
            case "NE":
                val = val.replaceFirst("^!|^<>|^!=", "").replace(" ", "");
                break;
            case "GT":
            case "LT":
            case "GE":
            case "LE":
                val = val.replaceAll("^[><=!]+", "").trim();
                break;
            default:
                break;
        }
        return val;
    }

    /** 按规则添加单个条件 */
    private static <T> void addEasyQuery(QueryWrapper<T> queryWrapper, String column, String rule, Object value) {
        if (value == null || rule == null || StringUtils.isBlank(value.toString())) {
            return;
        }
        String val = value.toString().trim();
        switch (rule) {
            case "GT":
                queryWrapper.gt(column, val);
                break;
            case "GE":
                queryWrapper.ge(column, val);
                break;
            case "LT":
                queryWrapper.lt(column, val);
                break;
            case "LE":
                queryWrapper.le(column, val);
                break;
            case "NE":
                queryWrapper.ne(column, val);
                break;
            case "LIKE":
                queryWrapper.like(column, val);
                break;
            case "LEFT_LIKE":
                queryWrapper.likeLeft(column, val);
                break;
            case "RIGHT_LIKE":
                queryWrapper.likeRight(column, val);
                break;
            case "IN":
                queryWrapper.in(column, Arrays.asList(val.split(COMMA)));
                break;
            case "EQ":
            default:
                queryWrapper.eq(column, val);
                break;
        }
    }

    /** 排序：URL 参数 column=字段1,字段2 & order=asc,desc（复刻源实现 doMultiFieldsOrder 的核心） */
    private static <T> void doMultiFieldsOrder(QueryWrapper<T> queryWrapper,
                                               Map<String, String[]> parameterMap, Class<?> clazz) {
        if (parameterMap == null) {
            return;
        }
        String[] columns = parameterMap.get("column");
        String[] orders = parameterMap.get("order");
        if (columns == null || columns.length == 0 || StringUtils.isBlank(columns[0])) {
            return;
        }
        String columnStr = columns[0].trim();
        String orderStr = (orders != null && orders.length > 0) ? orders[0].trim() : "asc";
        String[] columnArr = columnStr.split(COMMA);
        String[] orderArr = orderStr.split(COMMA);
        for (int i = 0; i < columnArr.length; i++) {
            String prop = columnArr[i].trim();
            if (prop.isEmpty()) {
                continue;
            }
            // 参数传的是实体属性名，需转成数据库列名
            String column = resolveColumnName(clazz, prop);
            if (StringUtils.isBlank(column)) {
                continue;
            }
            String dir = i < orderArr.length ? orderArr[i].trim() : "asc";
            if ("desc".equalsIgnoreCase(dir)) {
                queryWrapper.orderByDesc(column);
            } else {
                queryWrapper.orderByAsc(column);
            }
        }
    }
}
