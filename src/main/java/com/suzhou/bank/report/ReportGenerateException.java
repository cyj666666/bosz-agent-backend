package com.suzhou.bank.report;

/**
 * 报告生成业务异常
 * <p>用于表达可预期的业务失败（参数缺失、模板未配置、编号重复等），
 * 由上层统一捕获后记录日志、置失败状态，不向调用方抛出。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
public class ReportGenerateException extends RuntimeException {

    public ReportGenerateException(String message) {
        super(message);
    }

    public ReportGenerateException(String message, Throwable cause) {
        super(message, cause);
    }
}
