package com.suzhou.bank.agent.util;

import com.ql.util.express.DefaultContext;
import com.ql.util.express.ExpressRunner;
import com.ql.util.express.IExpressContext;
import com.ql.util.express.exception.QLCompileException;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;

import java.util.HashMap;
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

            if (!runner.getOperatorFactory().isExistOperator(funcName)) {
                runner.addFunctionOfClassMethod(
                        funcName,
                        Math.class.getName(),
                        javaMethod,
                        paramTypes,
                        null
                );
            }
        }
        runner.addMacro("PI", String.valueOf(Math.PI));
        runner.addMacro("E", String.valueOf(Math.E));

        // 内置注册isEmpty，方法名、类名、参数类型完全匹配
        if (!runner.getOperatorFactory().isExistOperator("isEmpty")) {
            runner.addFunctionOfClassMethod(
                    "isEmpty",
                    QLExpressUtil.class.getName(),
                    "isEmpty",
                    new String[]{"java.lang.Object"},
                    null
            );
        }
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
            // 1、将所有{id|备注}占位替换为合法QL字面量（null/数字/'字符串'）
            mapTemp = replaceExpressionIds(expression, contextMap);
            // 2、替换完成后表达式已全是字面量，不需要传入上下文数据，传空即可
            IExpressContext<String, Object> context = new DefaultContext<>();
            return execute(mapTemp, context);
        } catch (Exception e) {
            throw new ExprExecuteException(mapTemp, e);
        }
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
                String strVal = (String) value;
                // 纯数字字符串
                if (strVal.matches("-?\\d+(\\.\\d+)?")) {
                    replacement = strVal.startsWith("-")
                            ? Matcher.quoteReplacement("(" + strVal + ")")
                            : Matcher.quoteReplacement(strVal);
                } else {
                    // 普通文本包裹单引号
                    replacement = "'" + Matcher.quoteReplacement(strVal) + "'";
                }
            } else {
                // 数值类型（Long/Double/Integer）
                replacement = rawStr.startsWith("-")
                        ? Matcher.quoteReplacement("(" + rawStr + ")")
                        : Matcher.quoteReplacement(rawStr);
            }

            matcher.appendReplacement(sb, replacement);
        }
        matcher.appendTail(sb);
        return sb.toString();
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
