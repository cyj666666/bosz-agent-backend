package com.suzhou.bank.agent.util;

import com.ql.util.express.DefaultContext;
import com.ql.util.express.ExpressRunner;
import com.ql.util.express.IExpressContext;
import com.ql.util.express.exception.QLCompileException;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * QL表达式工具类
 */
@Slf4j
public class QLExpressUtil {

    private static volatile ExpressRunner runner;

    private QLExpressUtil() {
    }

    private static ExpressRunner getRunner() throws Exception {
        if (runner == null) {
            synchronized (QLExpressUtil.class) {
                if (runner == null) {
                    runner = new ExpressRunner(true, false);
                    registerMathFunctions(runner);
                }
            }
        }
        return runner;
    }

    /**
     * 批量注册Math常用静态数学函数 + 内置isEmpty判空函数
     */
    private static void registerMathFunctions(ExpressRunner runner) throws Exception {
        String[][] mathFuncList = {
                {"abs", "abs", "double"},
                {"max", "max", "double", "double"},
                {"min", "min", "double", "double"},
                {"round", "round", "double"},
                {"ceil", "ceil", "double"},
                {"floor", "floor", "double"},
                {"pow", "pow", "double", "double"},
                {"sqrt", "sqrt", "double"},
                {"log", "log", "double"},
                {"log10", "log10", "double"},
                {"exp", "exp", "double"},
                {"sin", "sin", "double"},
                {"cos", "cos", "double"},
                {"tan", "tan", "double"}
        };

        for (String[] row : mathFuncList) {
            String funcName = row[0];
            String javaMethod = row[1];
            String[] paramTypes = new String[row.length - 2];
            System.arraycopy(row, 2, paramTypes, 0, paramTypes.length);

            // 大小写变体全注册（2026-09-16 新增）
            // QLExpress 的函数名**大小写敏感**，而大模型生成表达式时大小写风格不定：
            // 实测 ABS(9.8000)>10 ——「在Runner的操作符定义和自定义函数中都没有找到ABS的定义」，
            // 因为此前只注册了小写 abs。这里按「原样 / 全大写 / 首字母大写」三种常见形态都注册，
            // 使 abs、ABS、Abs 都可用，避免模型大小写风格差异导致整个表达式执行失败。
            for (String alias : caseVariants(funcName)) {
                if (!runner.getOperatorFactory().isExistOperator(alias)) {
                    runner.addFunctionOfClassMethod(
                            alias,
                            Math.class.getName(),
                            javaMethod,
                            paramTypes,
                            null
                    );
                }
            }
        }
        runner.addMacro("PI", String.valueOf(Math.PI));
        runner.addMacro("pi", String.valueOf(Math.PI));
        // E 只注册大写：小写 e 有与科学计数法（如 1e5）混淆的风险，故不做变体
        runner.addMacro("E", String.valueOf(Math.E));

        // 内置注册isEmpty，方法名、类名、参数类型完全匹配（同样按大小写变体注册）
        for (String alias : caseVariants("isEmpty")) {
            if (!runner.getOperatorFactory().isExistOperator(alias)) {
                runner.addFunctionOfClassMethod(
                        alias,
                        QLExpressUtil.class.getName(),
                        "isEmpty",
                        new String[]{"java.lang.Object"},
                        null
                );
            }
        }
    }

    /**
     * 生成函数名的常见大小写变体：原样、全大写、首字母大写（保序去重）
     *
     * <p>用于把同一个函数按多种大小写风格注册进 QLExpress（其函数名大小写敏感），
     * 兜住大模型输出的大小写差异。</p>
     */
    private static List<String> caseVariants(String name) {
        List<String> candidates = new ArrayList<>();
        candidates.add(name);
        candidates.add(name.toUpperCase(Locale.ROOT));
        candidates.add(Character.toUpperCase(name.charAt(0)) + name.substring(1));

        List<String> distinct = new ArrayList<>();
        for (String candidate : candidates) {
            if (!distinct.contains(candidate)) {
                distinct.add(candidate);
            }
        }
        return distinct;
    }

    /**
     * QL内置判空函数：null、空白字符串都判定为空
     */
    public static boolean isEmpty(Object obj) {
        if (obj == null) {
            return true;
        }
        if (obj instanceof String) {
            return StringUtils.isBlank((String) obj);
        }
        return false;
    }

    /**
     * 表达式执行失败（**严格版**用它替代"返回 null"）
     *
     * <p>为什么需要这个类型：{@link #execute} 在任何异常时都 `return null`，
     * 调用方拿到 null **无法区分**「表达式算出来是假」和「表达式根本没算成」——
     * 界面上前者显示"未命中"、后者被吞掉后也显示"未命中"，等于把"数据没取到/表达式有错"掩盖成业务结论。
     *
     * <p>实测案例（2026-09-16）：企业名填不存在的值 → 指标全部取不到 → 表达式被替换成
     * `(''>''-'')`（字符串做减法）→ QLBizException → 返回 null → 界面显示"未命中"，
     * 但真实情况是**这次校验根本没成立**。
     */
    public static class ExprExecuteException extends RuntimeException {

        /** 占位符替换**之后**的表达式（排查时最有用的一条信息） */
        private final String renderedExpression;

        public ExprExecuteException(String renderedExpression, Throwable cause) {
            super(cause == null ? "表达式执行失败" : String.valueOf(cause.getMessage()), cause);
            this.renderedExpression = renderedExpression;
        }

        public String getRenderedExpression() {
            return renderedExpression;
        }

        /** 是否属于"表达式语法就编译不过"（与运行期异常分开，日志分级不同） */
        public boolean isCompileError() {
            return getCause() instanceof QLCompileException;
        }
    }

    /**
     * 业务入口：占位替换后直接执行字面量表达式，不再传入上下文数据
     *
     * <p>⚠️ **异常一律吞掉并返回 null**（沿用源工程行为，`buildCalculationProcess` 依赖它）。
     * 需要区分"算成 false"和"没算成"的调用方，请改用 {@link #executeStrict}。
     */
    public static Object execute(String expression, Map<String, Object> contextMap) {
        try {
            return executeStrict(expression, contextMap);
        } catch (ExprExecuteException e) {
            if (e.isCompileError()) {
                // 单独分类：表达式语法错误
                log.error("QL表达式语法编译失败，原始表达式：\n{}", expression);
                log.error("转换后表达式：{}", e.getRenderedExpression());
                log.error("编译异常堆栈", e.getCause());
            } else {
                // 占位替换、反射、运行空指针等
                log.error("QL表达式转换/执行未知异常，原始表达式：\n{}", expression);
                log.error("转换后表达式：{}", e.getRenderedExpression());
                log.error("异常堆栈", e.getCause());
            }
            return null;
        }
    }

    /**
     * 严格执行：**不吞异常**，失败时抛 {@link ExprExecuteException}（异常里带替换后的表达式）。
     *
     * <p>给「规则校验」这类需要把失败**明确告诉用户**的场景用：失败 ≠ 未命中。
     */
    public static Object executeStrict(String expression, Map<String, Object> contextMap) {
        // 与 execute 保持同样的顺序：替换失败时 renderedExpression 仍为原表达式（原先 mapTemp 初值是 ""）
        String mapTemp = "";
        try {
            // 0、表达式归一化（2026-09-16 新增）
            //    规则表达式由大模型生成，模型会带出各种"非标准但常见"的写法：全角标点、
            //    数学符号 ≥≤≠、大写的 AND/OR/NOT、单个等号、行尾注释…… 任何一个都会让
            //    **整个表达式**编译不过。详见 normalizeExpression 的说明。
            String normalized = normalizeExpression(expression);
            // 1、将所有{id|备注}占位替换为合法QL字面量（null/数字/'字符串'）
            mapTemp = replaceExpressionIds(normalized, contextMap);
            // 2、替换完成后表达式已全是字面量，不需要传入上下文数据，传空即可
            IExpressContext<String, Object> context = new DefaultContext<>();
            return execute(mapTemp, context);
        } catch (Exception e) {
            throw new ExprExecuteException(mapTemp, e);
        }
    }

    /**
     * 全角标点 → 半角标点 规范化（**字符级**，1 个字符换 1 个）
     *
     * <p><b>为什么需要</b>：规则表达式由大模型生成（见
     * {@code AgentRuleServiceImpl#parseRule}，取 {@code final_answer} 的「最终结果」字段）。
     * 提示词里虽已声明"只允许半角符号"，但模型仍会带出中文全角标点；而下游**没有任何兜底**，
     * 表达式一路流到 QLExpress 编译环节。</p>
     *
     * <p>实测（2026-09-16）：表达式
     * {@code （'是'=='是' && '是'=='是'） || （20.0000>=50 && '是'=='是'）}
     * 因首字符为**全角左括号**而编译失败，抛
     * {@code QLCompileException: 程序错误，不满足语法规范，没有匹配到合适的语法,最大匹配至[0:6]}。
     * 此前该异常被 {@link #execute} 吞成 null、界面显示"未命中"，换成 {@link #executeStrict}
     * 后才暴露出 ERROR。</p>
     *
     * <p>只映射**标点 / 符号字符**，不触碰任何字母、数字、中文内容，因此不会改变表达式语义。
     * 语义级归一（注释、逻辑关键字、等号）见 {@link #normalizeExpression}。</p>
     *
     * @param expression 原始表达式（可为 null / 空白）
     * @return 规范化后的表达式；入参为空时原样返回
     */
    public static String normalizePunctuation(String expression) {
        if (StringUtils.isBlank(expression)) {
            return expression;
        }
        return expression
                // 数学符号（U+2265 / U+2264 / U+2260）：模型表达"大于等于"时爱用，QLExpress 不认；
                // 注意是 1 个字符换成 2 个，只能用 CharSequence 重载
                .replace("≥", ">=").replace("≤", "<=").replace("≠", "!=")
                // 括号类
                .replace('（', '(').replace('）', ')')
                .replace('［', '[').replace('］', ']')
                .replace('｛', '{').replace('｝', '}')
                // 比较 / 赋值
                .replace('＜', '<').replace('＞', '>').replace('＝', '=')
                // 逻辑
                .replace('＆', '&').replace('｜', '|').replace('！', '!')
                // 算术
                .replace('＋', '+').replace('－', '-')
                .replace('＊', '*').replace('／', '/')
                // 分隔符
                .replace('，', ',').replace('；', ';').replace('：', ':')
                // 引号（在表达式里只作字符串分隔符使用，故一并归一）
                .replace('‘', '\'').replace('’', '\'').replace('＇', '\'')
                .replace('“', '"').replace('”', '"').replace('＂', '"')
                // 空格（全角空格 / 不间断空格）
                .replace('　', ' ').replace('\u00A0', ' ');
    }

    /** 表达式里的占位符形态：{编号|名称}（见 AgentRuleServiceImpl#normalizeMetricRefs） */
    private static final Pattern PLACEHOLDER = Pattern.compile("\\{[^}]*\\}");

    /**
     * 表达式归一化（**对外总入口**）：把大模型可能输出的"非标准但常见"写法收敛成 QLExpress 能接受的形态
     *
     * <p>与 {@link #normalizePunctuation} 的分工：本方法做**语义级**归一，
     * 并内部调用它做**字符级**全角→半角归一。</p>
     *
     * <h3>每一步都来自 2026-09-16 的实测（探针结果）</h3>
     * <table border="1">
     *   <tr><th>模型可能输出</th><th>QLExpress 原生表现</th><th>本方法处理</th></tr>
     *   <tr><td>{@code 1≥0} / {@code 1≤0} / {@code 1≠2}</td><td>编译失败</td><td>转 {@code >=} / {@code <=} / {@code !=}</td></tr>
     *   <tr><td>{@code 1>0 AND 2>1}（大写）</td><td>编译失败（<b>只有小写 {@code and} 可用</b>）</td><td>统一转小写</td></tr>
     *   <tr><td>{@code not (1>2)}</td><td>"没有找到 not 的定义"</td><td>转 {@code !}</td></tr>
     *   <tr><td>{@code 12.5=12.5}（单等号）</td><td>运行期异常</td><td>转 {@code ==}</td></tr>
     *   <tr><td>{@code 1>0 // 说明} 或 {@code # 说明}</td><td>编译失败</td><td>剥除行注释</td></tr>
     * </table>
     *
     * <p><b>为什么按 {@code {}} 分段</b>：占位符里是指标名称（可能含中文标点，甚至恰好叫 "OR"），
     * 只在占位符<b>之外</b>归一、占位符原样保留，可彻底避免误改指标名。</p>
     *
     * @param expression 原始表达式（可为 null / 空白）
     * @return 归一后的表达式；入参为空时原样返回
     */
    public static String normalizeExpression(String expression) {
        if (StringUtils.isBlank(expression)) {
            return expression;
        }
        StringBuilder result = new StringBuilder();
        Matcher matcher = PLACEHOLDER.matcher(expression);
        int cursor = 0;
        while (matcher.find()) {
            result.append(normalizeSegment(expression.substring(cursor, matcher.start())));
            result.append(matcher.group());
            cursor = matcher.end();
        }
        result.append(normalizeSegment(expression.substring(cursor)));
        return result.toString();
    }

    /**
     * 归一化占位符**之外**的一段文本（{@link #normalizeExpression} 的子步骤）
     */
    private static String normalizeSegment(String segment) {
        if (StringUtils.isEmpty(segment)) {
            return segment;
        }
        String result = segment;

        // 1、剥除行注释：模型爱在表达式后补一句解释（如 "// 单位：万元"）。
        //    ⚠️ 只匹配**连续两个**斜杠，单斜杠除法不受影响；表达式里 # 无合法用途。
        result = result.replaceAll("//[^\\r\\n]*", " ");
        result = result.replaceAll("#[^\\r\\n]*", " ");

        // 2、字符级归一：全角标点 → 半角（含 ≥≤≠ → >=/<=/!=）
        result = normalizePunctuation(result);

        // 3、逻辑关键字统一成 QLExpress 认识的形态。
        //    两侧排除「字母 / 数字 / 下划线 / 引号 / 花括号 / 竖线」，避免误伤：
        //    · 字符串字面量里的单词（如 'AND'）
        //    · 标识符的一部分（如 BAND、ORACLE）
        //    注意 NOT 没有对应关键字，只能转 !
        result = result.replaceAll("(?i)(?<![0-9A-Za-z_'\"|{}])AND(?![0-9A-Za-z_'\"|{}])", "and");
        result = result.replaceAll("(?i)(?<![0-9A-Za-z_'\"|{}])OR(?![0-9A-Za-z_'\"|{}])", "or");
        result = result.replaceAll("(?i)(?<![0-9A-Za-z_'\"|{}])NOT(?![0-9A-Za-z_'\"|{}])", "!");

        // 4、单等号 → 双等号（QLExpress 用 == 做相等比较，单个 = 会在运行期抛异常）。
        //    负向环视排掉 ==、>=、<=、!= 中的等号。
        result = result.replaceAll("(?<![<>=!])=(?!=)", "==");

        return result;
    }

    /**
     * 底层重载方法，提供IExpressContext入参
     */
    private static Object execute(String expr, IExpressContext<String, Object> context) throws Exception {
        ExpressRunner runner = getRunner();
        // 参数：表达式、上下文、错误输出列表、快速执行、打印日志
        return runner.execute(expr, context, null, true, false);
    }

    /**
     * 修复版占位替换：null/空白字符串统一替换为QL关键字null（不带引号）
     */
    public static String replaceExpressionIds(String parsedExpression, Map<String, Object> indexValueMap) {
        if (parsedExpression == null || parsedExpression.isEmpty()) {
            return parsedExpression;
        }

        Pattern pattern = Pattern.compile("\\{(\\d+)(?:\\|[^}]*)?\\}");
        Matcher matcher = pattern.matcher(parsedExpression);
        StringBuffer sb = new StringBuffer();

        while (matcher.find()) {
            String id = matcher.group(1);
            Object value = indexValueMap==null||indexValueMap.isEmpty()?null:indexValueMap.get(id);

            String replacement;
            String rawStr = String.valueOf(value);
            if (value instanceof String) {
                // 去前后空白（上游/模型可能给 " 12.5 "），并兼容千分位数字（"1,000.00" → "1000.00"）：
                // 否则会被当成普通字符串包上引号，进而变成 '1,000.00' > 500 这种"字符串与数字比较"的报错。
                // 注意只在"去掉逗号后确实是数字"时才清洗，避免误伤正常文本。
                String strVal = ((String) value).trim();
                if (!isNumeric(strVal)) {
                    String stripped = strVal.replace(",", "");
                    if (isNumeric(stripped)) {
                        strVal = stripped;
                    }
                }
                if (isNumeric(strVal)) {
                    // 纯数字（含负数）：负数加括号，避免与前后运算符粘连
                    replacement = strVal.startsWith("-")
                            ? Matcher.quoteReplacement("(" + strVal + ")")
                            : Matcher.quoteReplacement(strVal);
                } else {
                    // 普通文本包裹单引号
                    replacement = "'" + Matcher.quoteReplacement(strVal) + "'";
                }
            } else if (value instanceof Number) {
                // 数值类型（Long/Double/Integer/BigDecimal）
                replacement = rawStr.startsWith("-")
                        ? Matcher.quoteReplacement("(" + rawStr + ")")
                        : Matcher.quoteReplacement(rawStr);
            } else if (value == null) {
                // 未取到值：替换成 QL 的 null 字面量（保持既有行为，由调用方用 missingValueCount 暴露缺失）
                replacement = "null";
            } else {
                // 其它类型（数组 / 对象 / 布尔等）：包成字符串，避免拼出非法表达式
                // （原实现一律当数值直接拼接，遇到 JSONArray 会拼出 ["a","b"] 这种东西导致编译失败）
                replacement = "'" + Matcher.quoteReplacement(rawStr) + "'";
            }

            matcher.appendReplacement(sb, replacement);
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    /** 是否是不带千分位、可被 QL 当成数字字面量的字符串 */
    private static boolean isNumeric(String s) {
        return s != null && s.matches("-?\\d+(\\.\\d+)?");
    }

    public static boolean getResultAsBool(Object exprResult) {
        if (exprResult == null) {
            return false;
        }
        if (exprResult instanceof Boolean) {
            return (Boolean) exprResult;
        }
        if (exprResult instanceof Number) {
            return ((Number) exprResult).doubleValue() != 0;
        }
        if (exprResult instanceof String) {
            String val = ((String) exprResult).trim();
            return "true".equalsIgnoreCase(val) || "1".equals(val);
        }
        return false;
    }
    public static String buildCalculationProcess(String originalExpression, Map<String, Object> indexValueMap) {
        if (StringUtils.isBlank(originalExpression)) {
            return "";
        }

        String processText = originalExpression;
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\[\\[\\{.*?\\}\\]\\]");
        java.util.regex.Matcher matcher = pattern.matcher(processText);
        StringBuffer sb = new StringBuffer();

        while (matcher.find()) {
            String fullBlock = matcher.group();
            // 修改点：substring(2, fullBlock.length() - 2)，保留内层{}
            String innerExpression = fullBlock.substring(2, fullBlock.length() - 2);
            String executableExpr = replaceExpressionIds(innerExpression, indexValueMap);

            Object evalResult;
            try {
                IExpressContext<String, Object> context = new DefaultContext<>();
                evalResult = execute(executableExpr, context);
            } catch (Exception e) {
                log.warn("子条件执行失败: {}, error: {}", executableExpr, e.getMessage());
                evalResult = null;
            }

            String replaceVal;
            if (evalResult == null) {
                replaceVal = "";
            } else if (evalResult instanceof Object[]) {
                Object[] arr = (Object[]) evalResult;
                StringBuffer arrSb = new StringBuffer();
                for (int i = 0; i < arr.length; i++) {
                    if (i > 0) {
                        arrSb.append(",");
                    }
                    arrSb.append(arr[i]);
                }
                replaceVal = arrSb.toString();
            } else {
                replaceVal = String.valueOf(evalResult);
            }
            matcher.appendReplacement(sb, java.util.regex.Matcher.quoteReplacement(replaceVal));
        }
        matcher.appendTail(sb);

        return sb.toString();
    }

    // 测试main方法
    public static void main(String[] args) {
        // 标准无坑短路表达式，规避三目优先级编译报错
        String originExpr = "{2085641008898412545|应收账款前五大是否为关联方}=='是'";

        // 两个指标全部为空
        Map<String, Object> indexValueMap = new HashMap<>();
        indexValueMap.put("202606301614561908", 695.56);
        indexValueMap.put("2085641008898412545", "是");

        Object result = QLExpressUtil.execute(originExpr, indexValueMap);
        System.out.println("QL执行结果：" + result);
        // 预期输出 false，不会抛出编译/空指针异常
    }
}
