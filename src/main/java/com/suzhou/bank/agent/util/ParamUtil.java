package com.suzhou.bank.agent.util;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;
import org.apache.commons.lang3.tuple.Pair;
import lombok.extern.slf4j.Slf4j;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import com.suzhou.bank.agent.util.OConvertUtils;import com.suzhou.bank.agent.entity.ExtIntfParamManageEntity;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.InetAddress;
import java.nio.charset.StandardCharsets;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
public class ParamUtil {

    static AtomicInteger atomicInteger = new AtomicInteger(0);

    // ==================== 雪花算法相关 ====================
    /**
     * 开始时间戳 (2024-01-01 00:00:00)
     */
    private static final long START_TIMESTAMP = 1704067200000L;

    /**
     * 机器ID所占的位数
     */
    private static final long WORKER_ID_BITS = 5L;

    /**
     * 数据中心ID所占的位数
     */
    private static final long DATACENTER_ID_BITS = 5L;

    /**
     * 序列号所占的位数
     */
    private static final long SEQUENCE_BITS = 12L;

    /**
     * 机器ID的最大值
     */
    private static final long MAX_WORKER_ID = ~(-1L << WORKER_ID_BITS);

    /**
     * 数据中心ID的最大值
     */
    private static final long MAX_DATACENTER_ID = ~(-1L << DATACENTER_ID_BITS);

    /**
     * 序列号的最大值
     */
    private static final long MAX_SEQUENCE = ~(-1L << SEQUENCE_BITS);

    /**
     * 机器ID向左移的位数
     */
    private static final long WORKER_ID_SHIFT = SEQUENCE_BITS;

    /**
     * 数据中心ID向左移的位数
     */
    private static final long DATACENTER_ID_SHIFT = SEQUENCE_BITS + WORKER_ID_BITS;

    /**
     * 时间戳向左移的位数
     */
    private static final long TIMESTAMP_SHIFT = DATACENTER_ID_SHIFT + DATACENTER_ID_BITS;

    /**
     * 机器ID
     * <p>
     * 多实例负载部署时，必须保证每台机器的机器ID唯一，否则同一毫秒内生成的ID会重复。
     * 优先通过 JVM 参数指定：-Dworker.id=1、-Ddatacenter.id=1；
     * 未显式指定时，根据主机名(hash)自动生成一个稳定且分布均匀的workerId兜底，
     * 避免多实例使用相同默认值导致ID冲突。
     */
    private static final long WORKER_ID = initWorkerId();

    /**
     * 数据中心ID
     */
    private static final long DATACENTER_ID = initDatacenterId();

    /**
     * 解析机器ID。
     * 优先级：JVM参数 -Dworker.id > 环境变量 WORKER_ID > 主机名hash兜底。
     */
    private static long initWorkerId() {
        String value = System.getProperty("worker.id");
        if (StringUtils.isBlank(value)) {
            value = System.getenv("WORKER_ID");
        }
        if (StringUtils.isNotBlank(value)) {
            long id = parseId(value, MAX_WORKER_ID, "worker.id");
            if (id >= 0) {
                return id;
            }
        }
        // 未配置时，根据主机名hash生成一个稳定的workerId，避免多实例默认值相同
        String host = getHostName();
        long id = Math.floorMod(host.hashCode(), MAX_WORKER_ID + 1);
        log.warn("未配置worker.id，根据主机名[{}]自动生成workerId={}", host, id);
        return id;
    }

    /**
     * 解析数据中心ID。
     * 优先级：JVM参数 -Ddatacenter.id > 环境变量 DATACENTER_ID > 默认值0。
     */
    private static long initDatacenterId() {
        String value = System.getProperty("datacenter.id");
        if (StringUtils.isBlank(value)) {
            value = System.getenv("DATACENTER_ID");
        }
        if (StringUtils.isNotBlank(value)) {
            long id = parseId(value, MAX_DATACENTER_ID, "datacenter.id");
            if (id >= 0) {
                return id;
            }
        }
        return 0L;
    }

    /**
     * 解析ID值，校验范围并给出告警。
     */
    private static long parseId(String value, long max, String name) {
        try {
            long id = Long.parseLong(value.trim());
            if (id < 0 || id > max) {
                log.error("配置项[{}]的值[{}]超出合法范围[0, {}]，将忽略并使用兜底策略", name, value, max);
                return -1;
            }
            return id;
        } catch (NumberFormatException e) {
            log.error("配置项[{}]的值[{}]不是合法数字，将忽略并使用兜底策略", name, value);
            return -1;
        }
    }

    /**
     * 获取主机名，作为兜底生成workerId的依据。
     */
    private static String getHostName() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            return "unknown-host";
        }
    }

    /**
     * 序列号
     */
    private static long sequence = 0L;

    /**
     * 上次生成ID的时间戳
     */
    private static long lastTimestamp = -1L;

    /**
     * 雪花锁
     */
    private static final Object LOCK = new Object();

    /**
     * 生成雪花ID
     *
     * @return 雪花ID字符串
     */
    private static String generateSnowflakeId() {
        synchronized (LOCK) {
            long currentTimestamp = System.currentTimeMillis();

            // 如果当前时间小于上次生成ID的时间，说明系统时钟回退
            if (currentTimestamp < lastTimestamp) {
                throw new RuntimeException(String.format("系统时钟回退！拒绝生成ID，上次时间戳：%d，当前时间戳：%d", lastTimestamp, currentTimestamp));
            }

            // 如果是同一时间戳，则序列号加1
            if (currentTimestamp == lastTimestamp) {
                sequence = (sequence + 1) & MAX_SEQUENCE;
                // 序列号溢出，等待下一毫秒
                if (sequence == 0L) {
                    while (currentTimestamp <= lastTimestamp) {
                        currentTimestamp = System.currentTimeMillis();
                    }
                }
            } else {
                // 不同时间戳，序列号重置为0
                sequence = 0L;
            }

            lastTimestamp = currentTimestamp;

            // 生成ID
            long id = ((currentTimestamp - START_TIMESTAMP) << TIMESTAMP_SHIFT)
                      | (DATACENTER_ID << DATACENTER_ID_SHIFT)
                      | (WORKER_ID << WORKER_ID_SHIFT)
                      | sequence;

            return String.valueOf(id);
        }
    }

    private static final String PATTERN_STRING = "\\{[a-zA-Z_$][a-zA-Z0-9_$]*}";
    private static final Pattern TEMPLATE_PATTERN = Pattern.compile("\\{\\{.*?\\|\\|.*?}}");
    private static final Pattern TAG_A_PATTERN = Pattern.compile("##A##[\\s\\S]*?##A##\n?");
    private static final Pattern TILDE_PATTERN = Pattern.compile("~[\\s\\S]*?~\n?");
    private static final Pattern PERCENT_PATTERN = Pattern.compile("<%.*?%>");
    private static final Pattern BASE64_PROMPT_PATTERN = Pattern.compile("\\{\\{.*?\\|#\\|.*?}}");

    // 标点符号映射表，对应Python中的punctuation_map
    private static final Map<String, String> PUNCTUATION_MAP = new HashMap<>();

    static {
        // 初始化标点符号映射
        PUNCTUATION_MAP.put("，", ",");  // 逗号
        PUNCTUATION_MAP.put("。", ".");  // 句号
        PUNCTUATION_MAP.put("、", ",");  // 顿号
        PUNCTUATION_MAP.put("；", ";");  // 分号
        PUNCTUATION_MAP.put("：", ":");  // 冒号
        PUNCTUATION_MAP.put("？", "?");  // 问号
        PUNCTUATION_MAP.put("！", "!");  // 感叹号
        PUNCTUATION_MAP.put("…", "..."); // 省略号
        PUNCTUATION_MAP.put("\n", "\n"); // 换行符
    }

    public static String getSerialNo() {
        DateFormat yyyyMMddHHmmss = new SimpleDateFormat("yyyyMMddHHmmss");
        Calendar instance = Calendar.getInstance();
        String serialNoPre = yyyyMMddHHmmss.format(instance.getTime());
        return serialNoPre + atomicInteger.incrementAndGet();
    }

    public static String getSessionNo(String prefix) {
        prefix = prefix == null ? "" : prefix;
        StringBuffer rtnBuilder = new StringBuffer(prefix);
        try {
            rtnBuilder.append(generateSnowflakeId());
        } catch (Exception e) {
            log.error("创建sessionNo异常", e);
            rtnBuilder.append(UUID.randomUUID().toString().replace("-", ""));
        }

        return rtnBuilder.toString();
    }

    public static List<String> getParamNoList(String prompt) {
        List<String> paramNoList = new ArrayList<>();
        String patternString = "\\{\\{.*?}}";
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(prompt);
        while (matcher.find()) {
            String group = matcher.group().replace("{{", "").replace("}}", "");
            String[] array = group.split("\\|\\|");
            if (array.length == 2) {
                paramNoList.add(array[1]);
            } else {
                // 兼容base64内容占位符 {{文件base64内容|#|key}}
                array = group.split("\\|#\\|");
                if (array.length == 2) {
                    paramNoList.add(array[1]);
                }
            }
        }
        return paramNoList;
    }

    public static List<String> getRuleList(String prompt) {
        List<String> ruleList = new ArrayList<>();
        String patternString = "\\[\\[.*?]]";
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(prompt);
        while (matcher.find()) {
            String[] array = matcher.group().replace("[[", "").replace("]]", "").split("\\|\\|");
            if (array.length == 2) {
                ruleList.add(array[1] +"@@" + array[0]);
            }
        }
        return ruleList;
    }

    public static Pair<String, List<String>> getParamInfoList(String content) {
        List<String> paramNoList = new ArrayList<>();
        StringBuffer builder = new StringBuffer();
        String patternString = "\\{\\{.*?}}";
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(content);
        while (matcher.find()) {
            builder.append(matcher.group());
            String[] array = matcher.group().replace("{{", "").replace("}}", "").split("\\|\\|");
            if (array.length == 2) {
                paramNoList.add(array[1]);
            }
        }
        return Pair.of(builder.toString(), paramNoList);
    }

    public static String decodeBase64Prompt(String prompt, Map<String, Object> groupMap) {
        Matcher matcher = BASE64_PROMPT_PATTERN.matcher(prompt);
        StringBuffer sb = new StringBuffer();
        while (matcher.find()) {
            String group = matcher.group();
            String[] parts = group.replace("{{", "").replace("}}", "").split("\\|#\\|");
            if (parts.length == 2) {
                String key = parts[1];
                Object value = groupMap.get(key);
                if (value != null && StringUtils.isNotEmpty(value.toString())) {
                    try {
                        byte[] decodedBytes = Base64.getDecoder().decode(value.toString());
                        matcher.appendReplacement(sb, Matcher.quoteReplacement(new String(decodedBytes, StandardCharsets.UTF_8)));
                    } catch (Exception e) {
                        log.warn("base64解码失败，key={}，返回原值", key);
                        matcher.appendReplacement(sb, Matcher.quoteReplacement(value.toString()));
                    }
                }
            }
        }
        matcher.appendTail(sb);
        return sb.toString();
    }
    public static String insteadPrompt(String prompt, Map<String, Object> paramResultMap) {
        if (StringUtils.isEmpty(prompt)) {
            return prompt;
        }

        Matcher matcher = TEMPLATE_PATTERN.matcher(prompt);
        StringBuffer buffer = new StringBuffer();

        while (matcher.find()) {
            String[] parts = matcher.group().replace("{{", "").replace("}}", "").replace("$", "\\$").split("\\|\\|");
            if (parts.length == 2) {
                Object value = paramResultMap.get(parts[1]);
                if (value != null && StringUtils.isNotEmpty(value.toString())) {
                    String replacement = (value instanceof JSONObject || value instanceof JSONArray) ? JSONObject.toJSONString(value, SerializerFeature.WriteMapNullValue) : value.toString();
                    matcher.appendReplacement(buffer, Matcher.quoteReplacement(replacement));
                }
            }
        }
        matcher.appendTail(buffer);
        return insteadPromptIfNull(buffer.toString());
    }

    public static String insteadPromptIfNull(String prompt) {
        if (StringUtils.isEmpty(prompt)) {
            return prompt;
        }
        String processed = processTagPattern(prompt, TAG_A_PATTERN, "##A##");
        processed = processTagPattern(processed, TILDE_PATTERN, "~");
        processed = removeUnresolvedTemplates(processed);
        return processPercentPattern(processed);
    }

    private static String processTagPattern(String input, Pattern pattern, String tag) {
        Matcher matcher = pattern.matcher(input);
        StringBuffer buffer = new StringBuffer();
        while (matcher.find()) {
            String match = matcher.group();
            if ((match.contains("{{") && match.contains("}}")) || (match.contains("[#") && match.contains("#]"))) {
                matcher.appendReplacement(buffer, "");
            } else {
                // 使用 Matcher.quoteReplacement 方法对替换字符串进行转义
                matcher.appendReplacement(buffer, Matcher.quoteReplacement(match.replace(tag, "")));
            }
        }
        matcher.appendTail(buffer);
        return buffer.toString();
    }

    private static String removeUnresolvedTemplates(String input) {
        Matcher matcher = TEMPLATE_PATTERN.matcher(input);
        return matcher.replaceAll("");
    }

    private static String processPercentPattern(String input) {
        Matcher matcher = PERCENT_PATTERN.matcher(input);
        StringBuffer buffer = new StringBuffer();
        while (matcher.find()) {
            try {
                String numStr = matcher.group().replace("<%", "").replace("%>", "");
                BigDecimal decimal = new BigDecimal(numStr).multiply(new BigDecimal(100)).setScale(2, RoundingMode.HALF_DOWN);
                matcher.appendReplacement(buffer, decimal + "%");
            } catch (Exception e) {
                matcher.appendReplacement(buffer, "");
            }
        }
        matcher.appendTail(buffer);
        return buffer.toString();
    }

    public static String insteadScript(String script, Map<String, Object> dataMap) {
        String result = script;

        // 查找所有 {{key}} 格式的占位符
        java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\{\\{(.*?)}}");
        java.util.regex.Matcher matcher = pattern.matcher(script);

        while (matcher.find()) {
            String placeholder = matcher.group(0);  // {{key}}
            String key = matcher.group(1);          // key

            Object value = dataMap.get(key);
            String replacement;

            if (value == null) {
                replacement = "null";
            } else if (value instanceof Number) {
                replacement = value.toString();
            } else if (value instanceof Boolean) {
                replacement = value.toString();
            } else {
                // 字符串类型需要加引号并转义
                String strValue = value.toString()
                        .replace("\\", "\\\\")  // 转义反斜杠
                        .replace("\"", "\\\"")  // 转义双引号
                        .replace("\'", "\\\'")  // 转义单引号
                        .replace("\n", "\\n")   // 转义换行符
                        .replace("\r", "\\r")   // 转义回车符
                        .replace("\t", "\\t");  // 转义制表符

                replacement = "\"" + strValue + "\"";
            }

            result = result.replace(placeholder, replacement);
        }

        return result;
    }

    public static String getTraceId(String content) {
        Pattern pattern = Pattern.compile("数据详情追踪ID:\\[\\s*(\\w+)\\s*]");
        Matcher matcher = pattern.matcher(content);
        String traceId = "";
        if (matcher.find()) {
            traceId = matcher.group(1);
        }
        return traceId;
    }

    public static String replacePromptParam(String prompt, JSONObject params) {
        if (StringUtils.isNotEmpty(prompt) && params != null && !params.isEmpty()) {
            Matcher matcher = Pattern.compile("\\[#.*?#]").matcher(prompt);
            while (matcher.find()) {
                String paramName = matcher.group().substring(2, matcher.group().length() - 2).trim();
                Object paramValue = params.get(paramName);
                if ((paramValue == null || StringUtils.isEmpty(paramValue.toString())) && paramName.contains(".")) {
                    paramValue = getNestedValue(params, paramName);
                }
                if (paramValue != null && StringUtils.isNotEmpty(paramValue.toString())) {
                    prompt = prompt.replace(matcher.group(), paramValue.toString());
                } else {
                    prompt = prompt.replace(matcher.group(), "");
                }
            }
        }
        return prompt;
    }

    public static JSONObject sortJSONObject(JSONObject jsonObject) {
        TreeMap<String, Object> treeMap = new TreeMap<>();
        for (String key : jsonObject.keySet()) {
            treeMap.put(key, jsonObject.get(key));
        }
        return new JSONObject(treeMap);
    }

    public static List<String> getDiff(String main, String diff) {
        if (OConvertUtils.isEmpty(diff)) {
            return null;
        }
        if (OConvertUtils.isEmpty(main)) {
            return Arrays.asList(diff.split(","));
        }

        String[] mainArr = main.split(",");
        String[] diffArr = diff.split(",");
        Map<String, Integer> map = new HashMap<>();
        for (String string : mainArr) {
            map.put(string, 1);
        }
        List<String> res = new ArrayList<String>();
        for (String key : diffArr) {
            if (OConvertUtils.isNotEmpty(key) && !map.containsKey(key)) {
                res.add(key);
            }
        }
        return res;
    }

    public static boolean isNumericInt(String str) {
        Pattern pattern = Pattern.compile("[0-9]*\\.?[0-9]+");
        return pattern.matcher(str).matches();
    }

    public static boolean isNumericDouble(Object str) {
        Pattern pattern = Pattern.compile("(-*\\d+\\.\\d+)");// 判断小数
        return pattern.matcher(String.valueOf(str)).matches();
    }

    public static Object formatDecimal(Object value) {
        // 将 double 类型的值转换为 BigDecimal 对象
        BigDecimal bd = new BigDecimal(String.valueOf(value));
        // 获取小数部分的位数
        String strValue = bd.toPlainString();
        int dotIndex = strValue.indexOf('.');
        if (dotIndex != -1) {
            int decimalPlaces = strValue.length() - dotIndex - 1;
            // 如果小数位数大于 4，则保留 4 位小数
            if (decimalPlaces > 4) {
                value = bd.setScale(4, RoundingMode.HALF_UP);
            }
        }
        // 将处理后的 BigDecimal 对象转换回 double 类型并返回
        return value;
    }

    public static List<List<String>> getPromptParam(String prompt) {
        Pattern pattern = Pattern.compile(PATTERN_STRING);
        Matcher matcher = pattern.matcher(prompt);
        List<List<String>> listList = new ArrayList<>();
        while (matcher.find()) {
            String substring = prompt.substring(matcher.start(), matcher.end());
            List<String> stringList = Collections.singletonList(substring.replace("{", "").replace("}", "").replace(" ", ""));
            if (!listList.contains(stringList)) {
                listList.add(stringList);
            }
        }
        return listList;
    }

    public static List<String> getPromptParamList(String prompt) {
        Pattern pattern = Pattern.compile(PATTERN_STRING);
        Matcher matcher = pattern.matcher(prompt);
        List<String> listList = new ArrayList<>();
        while (matcher.find()) {
            String substring = prompt.substring(matcher.start(), matcher.end());
            String replace = substring.replace("{", "").replace("}", "").replace(" ", "");
            if (!listList.contains(replace)) {
                listList.add(replace);
            }
        }
        return listList;
    }

    public static String getPromptSample(String prompt, String param) {
        if (StringUtils.isEmpty(prompt) || StringUtils.isEmpty(param)) {
            return prompt;
        }
        JSONObject paramResultObj = JSONObject.parseObject(param);
        Pattern pattern = Pattern.compile(PATTERN_STRING);
        Matcher matcher = pattern.matcher(prompt);
        StringBuffer stringBuffer = new StringBuffer();
        while (matcher.find()) {
            String substring = prompt.substring(matcher.start(), matcher.end());
            String str = matcher.group().replace("{", "").replace("}", "");
            Object value = paramResultObj.get(str);
            if (Objects.nonNull(value) && StringUtils.isNotEmpty(String.valueOf(value)) && !String.valueOf(value).equalsIgnoreCase("[]")) {
                matcher.appendReplacement(stringBuffer, matcher.group().replace(substring, String.valueOf(value.toString())));
            }
        }
        matcher.appendTail(stringBuffer);
        return stringBuffer.toString();
    }

    public static String sortJsonStr(String jsonStr) {
        JSONObject jsonObject = JSONObject.parseObject(jsonStr);
        TreeMap<String, Object> sortedMap = new TreeMap<>();
        for (String key : jsonObject.keySet()) {
            sortedMap.put(key, jsonObject.get(key));
        }
        return new JSONObject(sortedMap).toString();
    }

    public static String getFileExtension(String originalFilename) {
        if (StringUtils.isNotEmpty(originalFilename) && originalFilename.contains(".")) {
            return originalFilename.substring(originalFilename.lastIndexOf(".") + 1);
        }
        return "";
    }

    /**
     * 按点号分隔的路径从JSON中获取嵌套值
     * 如 "params.name" → json.getJSONObject("params").get("name")
     * 路径中遇到JSONArray时取第一个元素继续导航
     */
    public static Object getNestedValue(JSONObject json, String path) {
        if (StringUtils.isEmpty(path) || !path.contains(".")) {
            return Objects.isNull(json) ? null : json.get(path);
        }
        String[] keys = path.split("\\.");
        Object current = json;
        for (String key : keys) {
            if (Objects.isNull(current)) {
                return null;
            }
            if (current instanceof JSONObject) {
                current = ((JSONObject) current).get(key);
            } else if (current instanceof JSONArray) {
                JSONArray arr = (JSONArray) current;
                current = arr.isEmpty() ? null : arr.get(0);
                if (current instanceof JSONObject) {
                    current = ((JSONObject) current).get(key);
                } else {
                    return null;
                }
            } else {
                return null;
            }
        }
        return current;
    }

    public static Object getValue(ExtIntfParamManageEntity paramManageEntity, String paramType, Object paramValue) {
        try {
            if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                return paramValue;
            }
            Object value = paramValue;
            if ("2".equals(paramType)) {
                value = Integer.valueOf(String.valueOf(paramValue));
            } else if ("3".equals(paramType)) {
                value = Boolean.valueOf(String.valueOf(paramValue));
            } else if ("4".equals(paramType)) {
                if (paramValue instanceof HashMap<?,?>) {
                    value = JSONObject.parseObject(JSONObject.toJSONString(paramValue));
                }else {
                    value = JSONObject.parseObject(String.valueOf(paramValue));
                }
            } else if ("5".equals(paramType)) {
                if (paramValue instanceof List<?>) {
                    value = JSONObject.parseArray(JSONObject.toJSONString(paramValue));
                }else {
                    value = JSONObject.parseArray(String.valueOf(paramValue));
                }
            }
            return value;
        } catch (Exception e) {
            log.error("参数[{}]-值[{}]的类型转换异常，异常信息：{}", paramManageEntity.toString(), paramValue, ExceptionUtils.getStackTrace(e));
            return paramValue;
        }
    }

    public static Object getValueByType(String paramType, Object paramValue) {
        try {
            if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                return paramValue;
            }
            Object value = paramValue;
            if ("number".equals(paramType)) {
                value = Integer.valueOf(String.valueOf(paramValue));
            } else if ("boolean".equals(paramType)) {
                value = Boolean.valueOf(String.valueOf(paramValue));
            } else if ("object".equals(paramType)) {
                if (paramValue instanceof HashMap<?,?>) {
                    value = JSONObject.parseObject(JSONObject.toJSONString(paramValue));
                }else {
                    value = JSONObject.parseObject(String.valueOf(paramValue));
                }
            } else if ("array".equals(paramType)) {
                if (paramValue instanceof List<?>) {
                    value = JSONObject.parseArray(JSONObject.toJSONString(paramValue));
                }else {
                    value = JSONObject.parseArray(String.valueOf(paramValue));
                }
            }
            return value;
        } catch (Exception e) {
            log.error("参数[{}]-值[{}]的类型转换异常，异常信息：{}", paramType, paramValue, ExceptionUtils.getStackTrace(e));
            return paramValue;
        }
    }

    public static Object getToolValueByType(String paramType, Object paramValue) {
        try {
            if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                return paramValue;
            }
            Object value = paramValue;
            if ("number".equals(paramType) || "int".equals(paramType) || "integer".equals(paramType)) {
                value = Integer.valueOf(String.valueOf(paramValue));
            } else if ("boolean".equals(paramType) || "bool".equals(paramType)) {
                value = Boolean.valueOf(String.valueOf(paramValue));
            } else if ("object".equals(paramType)) {
                if (paramValue instanceof HashMap<?,?>) {
                    value = JSONObject.parseObject(JSONObject.toJSONString(paramValue));
                }else {
                    value = JSONObject.parseObject(String.valueOf(paramValue));
                }
            } else if ("array".equals(paramType)) {
                if (paramValue instanceof List<?>) {
                    value = JSONObject.parseArray(JSONObject.toJSONString(paramValue));
                }else {
                    value = JSONObject.parseArray(String.valueOf(paramValue));
                }
            } else if ("string".equals(paramType)) {
                value = String.valueOf(paramValue);
            } else if ("array[object]".equals(paramType)) {
                value = JSONObject.parseArray(JSONObject.toJSONString(paramValue));
            } else if ("array[string]".equals(paramType)) {
                value = JSONObject.parseArray(String.valueOf(paramValue));
            } else if ("array[number]".equals(paramType) || "array[int]".equals(paramType) || "array[integer]".equals(paramType)) {
                value = JSONObject.parseArray(String.valueOf(paramValue));
            }
            return value;
        } catch (Exception e) {
            log.error("参数[{}]-值[{}]的类型转换异常，异常信息：{}", paramType, paramValue, ExceptionUtils.getStackTrace(e));
            return paramValue;
        }
    }

    public static String getFullNumberStr(int i) {
        return String.format("0%04d", i);
    }

    public static String sumNumericWithSuffix(List<String> values) {
        if (values == null || values.isEmpty()) {
            return "0";
        }
        // 正则表达式用于匹配数字部分
        Pattern numberPattern = Pattern.compile("\\d+(\\.\\d+)?");
        BigDecimal sum = BigDecimal.ZERO;
        for (String value : values) {
            Matcher numberMatcher = numberPattern.matcher(value);
            if (numberMatcher.find()) {
                BigDecimal number = new BigDecimal(numberMatcher.group());
                sum = sum.add(number);
            }
        }
        return sum.toPlainString();
    }

    public static boolean getBoolValue(Map<String, Object> jsonBody, String key, boolean defaultValue) {
        Object value = jsonBody.get(key);
        if (value == null) {
            return defaultValue;
        }

        if (value instanceof Boolean) {
            return (Boolean) value;
        }

        if (value instanceof String) {
            String strValue = ((String) value).toUpperCase();
            if ("TRUE".equals(strValue)) {
                return true;
            } else if ("FALSE".equals(strValue)) {
                return false;
            }
        }
        return defaultValue;
    }

    public static String toMarkdown(Object variable) {
        if (variable == null) {
            return "";
        }

        if (variable instanceof String) {
            return (String) variable;
        }

        if (variable instanceof List) {
            List<?> list = (List<?>) variable;
            if (list.isEmpty()) {
                return "";
            }

            // 检查是否为字符串列表
            boolean allStrings = list.stream().allMatch(item -> item instanceof String);
            if (allStrings) {
                StringBuffer sb = new StringBuffer();
                for (Object item : list) {
                    sb.append("- ").append(item).append("\n");
                }
                return sb.toString();
            }

            // 检查是否为Map列表
            boolean allMaps = list.stream().allMatch(item -> item instanceof Map);
            if (allMaps && !list.isEmpty()) {
                List<Map<String, Object>> mapList = (List<Map<String, Object>>) list;
                Map<String, Object> firstItem = mapList.get(0);
                Set<String> headers = firstItem.keySet();

                StringBuffer table = new StringBuffer();
                table.append("| ").append(String.join(" | ", headers)).append(" |\n");
                table.append("| ").append(String.join(" | ",
                        Collections.nCopies(headers.size(), "---"))).append(" |\n");

                for (Map<String, Object> item : mapList) {
                    List<String> row = new ArrayList<>();
                    for (String header : headers) {
                        row.add(item.getOrDefault(header, "").toString());
                    }
                    table.append("| ").append(String.join(" | ", row)).append(" |\n");
                }
                return table.toString();
            }
        }

        if (variable instanceof Map) {
            Map<?, ?> map = (Map<?, ?>) variable;
            StringBuffer markdown = new StringBuffer();
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                markdown.append("## ").append(entry.getKey()).append("\n\n")
                        .append(toMarkdown(entry.getValue())).append("\n\n");
            }
            return markdown.toString().trim();
        }

        return variable.toString();
    }

    public static boolean validateTranslateConfig(JSONObject translateConfig) {
        // 如果translate_config为null，返回true
        if (translateConfig == null) {
            return true;
        }

        // 验证language字段
        Object languageObj = translateConfig.get("language");
        if (languageObj != null) {
            String language = languageObj.toString();
            // 检查language是否在允许的范围内
            if (!language.equals("zh") && !language.equals("en")) {
                return false;
            }
        } else {
            // language字段不存在，返回false
            return false;
        }

        // 验证delimiter字段，默认值为["\n"]
        Object delimiterObj = translateConfig.get("delimiter");

        if (delimiterObj != null) {
            // 检查delimiter是否为List类型
            if (!(delimiterObj instanceof List)) {
                return false;
            }

            @SuppressWarnings("unchecked")
            List<Object> delimiterList = (List<Object>) delimiterObj;

            // 验证每个分隔符是否有效
            for (Object delimiter : delimiterList) {
                if (!(delimiter instanceof String)) {
                    return false;
                }
                // 源工程此处用 Java 17 的 instanceof 模式匹配，降级为 Java 8 写法
                String delimiterStr = (String) delimiter;

                // 检查分隔符是否在标点符号映射的键或值中
                if (!PUNCTUATION_MAP.containsKey(delimiterStr) && !PUNCTUATION_MAP.containsValue(delimiterStr)) {
                    return false;
                }
            }
        } else {
            // delimiter字段不存在，返回false
            return false;
        }

        // 所有验证通过，返回true
        return true;
    }

    // 生成一个随机数，范围是50.00-100.00，保留2位小数
    public static double getRandomScore() {
        // 生成5000到10000之间的随机整数，然后除以100.0得到50.00到100.00之间的数
        int randomInt = (int) (new java.security.SecureRandom().nextDouble() * 5001 + 5000);
        return randomInt / 100.0;
    }

    // 去除字符串前后空白字符，包含空格、制表符、换行符、回车符等
    public static String trimBlank(String field) {
        if (field == null) {
            return null;
        }
        // 使用正则表达式去除所有Unicode空白字符
        // 包括：空格、制表符(\t)、换行符(\n)、回车符(\r)、全角空格(\u3000)等
        return field.replaceAll("^\\s+|\\s+$", "");
    }
}