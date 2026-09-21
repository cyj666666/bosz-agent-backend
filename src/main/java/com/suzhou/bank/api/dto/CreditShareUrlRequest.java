package com.suzhou.bank.api.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import java.io.Serializable;

/**
 * 信贷页面分享链接请求体（报告「链接溯源」内容块点击时，换取一次性跳转链接）
 *
 * <p>🔴 {@code appCode} 由后端固定为 {@code AIMP-PLMA}，**不在本请求体内**。</p>
 * <p>字段来源：{@code shareCode} 取自「链接溯源」内容块的 {@code agentCode}（值由信贷侧 shareCode 配置表提供）；
 * {@code userId} = **报告发起人**（`report.user_no`）；{@code pageParams} 一般**不由调用方传**
 * （由后端按 shareCode 实时装配，见 `LinkTraceParamBuilder`）。</p>
 * <p>⚠️ 信贷侧规则：换回的链接**仅限使用一次、默认超时 1h** ⇒ 每次点击实时换取、结果不可缓存。</p>
 *
 * <p>🔴 本文件在行内 / 外网 **同包同路径、逐字同源**（2026-09-21 链接溯源行内外同步）。修改时请两边一起改。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
public class CreditShareUrlRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 分享编码（注册在信贷侧；报告侧取自「链接溯源」内容块的 agentCode） */
    @NotBlank(message = "shareCode 不能为空")
    private String shareCode;

    /**
     * 用户账号 —— 🔴 **报告发起人** `report.user_no`（上游/信贷发起报告时写入），
     * 由前端从详情接口的 `userNo` 字段取，**不是**当前登录态账号。
     * 取不到必须报错，**不要退回登录态**（否则链接归属会挂到错的人头上）。
     */
    @NotBlank(message = "userId 不能为空")
    private String userId;

    /** 报告编号（后端据此**实时**装配 pageParams） */
    @NotBlank(message = "reportNo 不能为空")
    private String reportNo;

    /** 内容块编号（`1050` 征信靠它读块上的主体令牌，区分借款人 / 企业担保人 / 个人担保人） */
    private String blockCode;

    /** 当前担保人名（可选；多个担保人时用于定位具体人，由前端按分段带上） */
    private String guarantorName;

    /**
     * 页面参数（**可选**）。
     *
     * <p>🔴 2026-09-21 口径（方案 B）：默认**由后端按 shareCode 实时装配**
     * （见 `LinkTraceParamBuilder`）；只有联调/手工覆盖时才由调用方直接传本字段
     * —— 传了就用传入值，不再装配。</p>
     */
    private String pageParams;
}
