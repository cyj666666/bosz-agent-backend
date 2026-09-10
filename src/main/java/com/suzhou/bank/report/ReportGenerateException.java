package com.suzhou.bank.report;

/**
 * 报告生成业务异常
 * <p>用于表达可预期的业务失败（参数缺失、模板未配置、编号重复等），
 * 由接口层捕获后转换为统一响应体，不打印堆栈。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
public class ReportGenerateException extends RuntimeException {

    public ReportGenerateException(String message) {
        super(message);
    }
}
