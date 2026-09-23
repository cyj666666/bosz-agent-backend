package com.suzhou.bank.service.report.ai;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.entity.report.AppReportPrompt;
import com.suzhou.bank.mapper.report.AppReportPromptMapper;
import com.suzhou.bank.service.report.model.ReportConstants;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * 提示词取用服务
 *
 * <p>提示词<b>首选来自表 {@code app_report_prompt}</b>，按 {@code promptCode} 取用：</p>
 * <ol>
 *   <li>每次调用都重新查表 —— 与 {@code large_model_config} 相同的习惯，<b>改完立即生效、不用重启</b>；</li>
 *   <li>表里查不到该 promptCode、或 {@code isEnabled != 'Y'}、或 {@code systemPrompt} 为空
 *       → 回落到代码兜底（{@link ReportAiAnalysisPrompt} / {@link ReportWarningAdvicePrompt}）；</li>
 *   <li>读表抛异常（例如表还没建）→ 同样回落，只告警不阻断，保证功能可用。</li>
 * </ol>
 *
 * <p>用户提示词模板里的 {@code {material}} 会被替换成组装好的素材；若模板里漏了占位符，
 * 则把素材追加到末尾并告警 —— 避免"改了提示词却忘了占位符"导致模型完全看不到素材。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportPromptService {

    /** 素材占位符 */
    private static final String MATERIAL_PLACEHOLDER = "{material}";

    private final AppReportPromptMapper promptMapper;

    /**
     * 取提示词（表优先，兜底次之）
     *
     * @param promptCode 提示词编码，见 {@link ReportConstants#PROMPT_AI_FULL_ANALYSIS} /
     *                   {@link ReportConstants#PROMPT_WARNING_ADVICE}
     */
    public ResolvedPrompt resolve(String promptCode) {
        String system = null;
        String template = null;
        boolean fromTable = false;

        AppReportPrompt row = selectByCode(promptCode);
        if (row != null && isEnabled(row)) {
            system = row.getSystemPrompt();
            template = row.getUserPromptTemplate();
            fromTable = StringUtils.hasText(system);
            if (fromTable && !StringUtils.hasText(template)) {
                // 系统提示词配了、模板没配：模板走兜底，不影响使用
                template = fallbackTemplate(promptCode);
            }
        }

        if (!fromTable) {
            system = fallbackSystem(promptCode);
            template = fallbackTemplate(promptCode);
            log.info("提示词使用代码兜底：promptCode={}（app_report_prompt 未配置或未启用）", promptCode);
        }
        return new ResolvedPrompt(promptCode, system, template, fromTable);
    }

    /** 把素材填入用户提示词模板 */
    public String renderUserPrompt(ResolvedPrompt prompt, String material) {
        String body = material == null ? "" : material;
        String template = prompt == null ? null : prompt.getUserPromptTemplate();
        if (!StringUtils.hasText(template)) {
            return body;
        }
        if (template.contains(MATERIAL_PLACEHOLDER)) {
            return template.replace(MATERIAL_PLACEHOLDER, body);
        }
        // 模板里没有占位符：追加素材，避免模型完全看不到内容
        log.warn("提示词模板缺少 {material} 占位符，已把素材追加到末尾：promptCode={}", prompt.getPromptCode());
        return template + "\n\n" + body;
    }

    /* ==================== 配置页（通用提示词管理）读写，2026-09-23 新增 ==================== */

    /**
     * 列出全部提示词（供「系统管理 → 通用提示词管理」列表页）
     *
     * <p>读表异常（表没建 / 字段不符）⇒ 返回空列表并告警，<b>不抛异常</b>：
     * 与 {@link #resolve(String)} 同一套「表不可用也要让系统跑起来」的原则。</p>
     *
     * <p>排序按 {@code promptCode}，让列表顺序稳定、可预期（不依赖库的默认物理顺序）。</p>
     */
    public List<AppReportPrompt> listAll() {
        try {
            return promptMapper.selectList(Wrappers.<AppReportPrompt>lambdaQuery()
                    .orderByAsc(AppReportPrompt::getPromptCode));
        } catch (Exception e) {
            log.warn("读取提示词表失败，返回空列表：{}", e.getMessage());
            return Collections.emptyList();
        }
    }

    /**
     * 更新「系统提示词」（配置页唯一允许修改的字段）
     *
     * <p>🔴 <b>{@code updateTime} 必须显式写</b>：该列 DDL 是
     * {@code TIMESTAMP DEFAULT CURRENT_TIMESTAMP}，<b>没有</b> {@code ON UPDATE CURRENT_TIMESTAMP}，
     * 依赖数据库自动刷新会让「更新时间」永远等于创建时间（MySQL 与 PG 两边都是这个行为）。</p>
     *
     * <p>改完<b>立即生效、无需重启</b>：{@link #resolve(String)} 每次调用都重新查表。</p>
     *
     * @param id           主键
     * @param systemPrompt 新的系统提示词（允许为空串 —— 视为"清空"，取用时按 {@code hasText} 回落到代码兜底）
     * @return 是否命中并更新了一行
     */
    public boolean updateSystemPrompt(Long id, String systemPrompt) {
        Date now = new Date();
        int rows = promptMapper.update(null, Wrappers.<AppReportPrompt>lambdaUpdate()
                .set(AppReportPrompt::getSystemPrompt, systemPrompt)
                .set(AppReportPrompt::getUpdateTime, now)
                .eq(AppReportPrompt::getId, id));
        return rows > 0;
    }

    private AppReportPrompt selectByCode(String promptCode) {
        if (!StringUtils.hasText(promptCode)) {
            return null;
        }
        try {
            return promptMapper.selectOne(Wrappers.<AppReportPrompt>lambdaQuery()
                    .eq(AppReportPrompt::getPromptCode, promptCode)
                    .last("LIMIT 1"));
        } catch (Exception e) {
            // 表没建、字段不符等都不该让功能直接挂掉
            log.warn("读取提示词表失败，将使用代码兜底：promptCode={} 原因={}", promptCode, e.getMessage());
            return null;
        }
    }

    private static boolean isEnabled(AppReportPrompt row) {
        return !StringUtils.hasText(row.getIsEnabled()) || "Y".equalsIgnoreCase(row.getIsEnabled());
    }

    private static String fallbackSystem(String promptCode) {
        if (ReportConstants.PROMPT_WARNING_ADVICE.equals(promptCode)) {
            return ReportWarningAdvicePrompt.systemPrompt();
        }
        return ReportAiAnalysisPrompt.systemPrompt();
    }

    private static String fallbackTemplate(String promptCode) {
        if (ReportConstants.PROMPT_WARNING_ADVICE.equals(promptCode)) {
            return ReportWarningAdvicePrompt.userPromptTemplate();
        }
        return ReportAiAnalysisPrompt.userPromptTemplate();
    }

    /** 解析后的提示词 */
    @Data
    public static class ResolvedPrompt {

        /** 提示词编码 */
        private final String promptCode;

        /** 系统提示词 */
        private final String systemPrompt;

        /** 用户提示词模板（未替换素材） */
        private final String userPromptTemplate;

        /** true=来自表；false=来自代码兜底（写进快照便于排查） */
        private final boolean fromTable;
    }
}
