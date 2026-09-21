package com.suzhou.bank.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.Map;

/**
 * 链接溯源取数 Mapper（只读 · 注解 SQL，不依赖实体类）
 *
 * <p>为 {@code LinkTraceParamBuilder} 提供装配 pageParams 所需的字段：
 * 报告基础信息 / 模板块主体令牌 / 征信报告记录号 / 对公检查（批复）信息。</p>
 *
 * <p>🔴 **列名一律写小写** —— 这些表建表时列名未加双引号（如 `reportNo` / `zxReportNo`），
 * PG/openGauss 会把未加引号的标识符折成小写，物理列名即 {@code reportno} / {@code zxreportno}。
 * 写驼峰会因大小写不匹配报列不存在。</p>
 *
 * <p>🔴 本文件在行内 / 外网 **同包同路径、逐字同源**（2026-09-21 链接溯源行内外同步）。修改时请两边一起改。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface LinkTraceQueryMapper {

    /**
     * 报告基础信息（链接溯源参数的最主要来源）。
     *
     * @return { customer_id, customer_name, check_task_no }，报告不存在时为 null
     */
    @Select("SELECT customer_id, customer_name, check_task_no FROM report "
            + "WHERE report_no = #{reportNo} LIMIT 1")
    Map<String, Object> selectReportBase(@Param("reportNo") String reportNo);

    /**
     * 模板块的主体令牌（链接溯源块的 `agentParams`，如 `subjectType=担保人,guarantorType=法人`）。
     * <p>用于区分 1050 征信的三个主体（借款人 / 企业担保人 / 个人担保人）。</p>
     */
    @Select("SELECT agentparams FROM app_report_content_block WHERE blockcode = #{blockCode} LIMIT 1")
    String selectBlockAgentParams(@Param("blockCode") String blockCode);

    /** 企业征信记录号（快照表 `app_credit_report_info`，按 subjecttype 区分借款人/担保人） */
    @Select("SELECT zxreportno FROM app_credit_report_info WHERE reportno = #{reportNo} "
            + "AND subjecttype = #{subjectType} ORDER BY id DESC LIMIT 1")
    String selectCreditReportNo(@Param("reportNo") String reportNo,
                                @Param("subjectType") String subjectType);

    /** 企业征信记录号（限定担保人名 —— 多个企业担保人时用） */
    @Select("SELECT zxreportno FROM app_credit_report_info WHERE reportno = #{reportNo} "
            + "AND subjecttype = #{subjectType} AND guarantorname = #{guarantorName} "
            + "ORDER BY id DESC LIMIT 1")
    String selectCreditReportNoByName(@Param("reportNo") String reportNo,
                                      @Param("subjectType") String subjectType,
                                      @Param("guarantorName") String guarantorName);

    /** 个人担保人征信记录号（`app_guarantor_credit_info`） */
    @Select("SELECT zxreportno FROM app_guarantor_credit_info WHERE reportno = #{reportNo} "
            + "ORDER BY id DESC LIMIT 1")
    String selectGuarantorCreditReportNo(@Param("reportNo") String reportNo);

    /** 个人担保人征信记录号（限定担保人名） */
    @Select("SELECT zxreportno FROM app_guarantor_credit_info WHERE reportno = #{reportNo} "
            + "AND guarantorname = #{guarantorName} ORDER BY id DESC LIMIT 1")
    String selectGuarantorCreditReportNoByName(@Param("reportNo") String reportNo,
                                               @Param("guarantorName") String guarantorName);

    /**
     * 对公检查（批复）信息 —— 1010「批复链接（电子批复）」专用。
     *
     * @return { serialno, bapserialno, baserialno, electroapproveserialno, approveapplytype }
     */
    @Select("SELECT serialno, bapserialno, baserialno, electroapproveserialno, approveapplytype "
            + "FROM xd_corp_check_info WHERE reportno = #{reportNo} ORDER BY id DESC LIMIT 1")
    Map<String, Object> selectCorpCheckInfo(@Param("reportNo") String reportNo);
}
