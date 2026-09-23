package com.suzhou.bank.service.report.model;

import lombok.Data;

/**
 * 通用提示词管理 —— 编辑请求体
 *
 * <p><b>只开放「系统提示词」一个可改字段</b>（2026-09-23 测试反馈 #4 定的口径）：
 * 提示词编码是程序取用的键、名称/场景分类是分组展示用、用户提示词模板涉及 {@code {material}}
 * 占位约定 —— 都不该让界面随手改。备注也不开放，避免与需求描述的范围不一致。</p>
 *
 * <p>{@code isEnabled} / {@code userPromptTemplate} 等字段刻意<b>不出现在本请求体里</b>，
 * 即使前端多传也会被忽略（后端不读、不落库）。</p>
 *
 * @author 曹陆宇
 * @since 1.0.0
 */
@Data
public class ReportPromptUpdateRequest {

    /** 主键（app_report_prompt.id），定位要改哪一条 */
    private Long id;

    /** 系统提示词（角色设定 / 要求 / 输出格式），整段覆盖 */
    private String systemPrompt;
}
