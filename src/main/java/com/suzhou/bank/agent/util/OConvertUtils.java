package com.suzhou.bank.agent.util;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Map;

/**
 * 轻量类型/空值判断工具
 *
 * <p>替代源工程的 {@code org.jeecg.common.util.oConvertUtils}。
 * 本模块只用到其中的空值判断方法，因此只平移这部分，
 * 不引入 JeecgBoot 工具类的其他能力（那些多为 Online 表单/权限相关，与本模块无关）。</p>
 */
public class OConvertUtils {

    public static boolean isEmpty(Object object) {
        if (object == null) {
            return true;
        }
        if (object instanceof String) {
            return ((String) object).trim().length() == 0;
        }
        if (object instanceof Object[]) {
            return ((Object[]) object).length == 0;
        }
        if (object instanceof Collection) {
            return ((Collection<?>) object).isEmpty();
        }
        if (object instanceof Map) {
            return ((Map<?, ?>) object).isEmpty();
        }
        return false;
    }

    public static boolean isNotEmpty(Object object) {
        return !isEmpty(object);
    }

    public static boolean isEmpty(String str) {
        return str == null || str.trim().length() == 0;
    }

    public static boolean isNotEmpty(String str) {
        return !isEmpty(str);
    }

    /**
     * 判断是否是数字
     */
    public static boolean isNumber(Object object) {
        if (object == null) {
            return false;
        }
        try {
            new BigDecimal(String.valueOf(object));
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }
}
