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
     * 业务入口：占位替换后直接执行字面量表达式，不再传入上下文数据
     */
    public static Object execute(String expression, Map<String, Object> contextMap) {
        String mapTemp = "";
        try {
            // 1、将所有{id|备注}占位替换为合法QL字面量（null/数字/'字符串'）
            mapTemp = replaceExpressionIds(expression, contextMap);
            // 2、替换完成后表达式已全是字面量，不需要传入上下文数据，传空即可
            IExpressContext<String, Object> context = new DefaultContext<>();
            return execute(mapTemp, context);
        } catch (QLCompileException e) {
            // 单独捕获：表达式语法错误（当前你遇到的编译报错）
            log.error("QL表达式语法编译失败，原始表达式：\n{}", expression);
            log.error("转换后表达式：{}", mapTemp);
            log.error("编译异常堆栈", e);
            return null;
        } catch (Exception e) {
            // 捕获占位替换、反射、运行空指针等Java层异常
            log.error("QL表达式转换/执行未知异常，原始表达式：\n{}", expression);
            log.error("转换后表达式：{}", mapTemp);
            log.error("异常堆栈", e);
            return null;
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
