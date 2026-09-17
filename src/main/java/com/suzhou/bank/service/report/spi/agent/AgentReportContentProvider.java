package com.suzhou.bank.service.report.spi.agent;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.agent.core.SqlDataSetBuilder;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.model.req.AgentRuleExecuteReq;
import com.suzhou.bank.agent.model.vo.AgentRuleExecuteVO;
import com.suzhou.bank.agent.service.IAgentRuleService;
import com.suzhou.bank.agent.service.IknowledgeBaseConfigService;
import com.suzhou.bank.agent.util.QLExpressUtil;
import com.suzhou.bank.entity.report.AppGuarantorInfo;
import com.suzhou.bank.entity.report.AppReportContentBlock;
import com.suzhou.bank.mapper.report.AppGuarantorInfoMapper;
import com.suzhou.bank.service.report.ai.CollectingSseEmitter;
import com.suzhou.bank.service.report.ai.LargeModelGatewayClient;
import com.suzhou.bank.service.report.model.ReportConstants;
import com.suzhou.bank.service.report.spi.ContentPayload;
import com.suzhou.bank.service.report.spi.ReportContentProvider;
import com.suzhou.bank.service.report.spi.ReportGenerateContext;
import com.suzhou.bank.service.report.spi.RuleHit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 报告内容提供者 · 智能体实现（**正式链路**）
 *
 * <p>按模板给的两把钥匙取真实内容：</p>
 * <ul>
 *   <li><b>ANALYSIS（知识库）</b> —— {@code agentCode} 是「知识配置管理」里的知识库编号；
 *       调 {@code KnowledgeBaseConfigService#getPromptContent}，由它按该条配置渲染 prompt 并
 *       调本地大模型，返回分析文案。</li>
 *   <li><b>RULE（智策引擎）</b> —— {@code agentCode} 是经验规则编号；
 *       先 {@code IAgentRuleService#executeRule} 判定：<b>命中</b>才按
 *       {@code disposalAdvice / thresholdConfig / riskRemark / ...} 走「补充分析」那条链路出文案，
 *       同时把<b>校验结论</b>（{@code 命中}）放进 {@link ContentPayload#getCheckResult()}；
 *       <b>未命中返回 null</b>（块内容为空 → 模板 {@code emptyStrategy=HIDE} → 正文整块不渲染，
 *       也不生成 AI 风险行）。</li>
 * </ul>
 *
 * <p>⚠️ 由此得到一条重要语义：<b>AI 风险列表里的每一条都是"命中的规则"</b>，
 * 未命中的规则在正文和风险列表里都不出现 —— 这正是用户要的
 * 「命中了才展示这个内容块，未命中就不会有这个内容块」。</p>
 *
 * <p><b>入参</b>：来自模板的 {@code agentParams}（逗号分隔），只有三种组合：
 * {@code reportNo,entName} / {@code reportNo,entName,guarantorName}。
 * 后者的 {@code guarantorName} 从 {@code app_guarantor_info} 按
 * {@code reportNo + subjectType='担保人' + guarantorType='法人'} 取，**多个担保人时逐个轮循**，
 * 结果按段落拼接。</p>
 *
 * <p><b>启用条件</b>：{@code report.mock-content.enabled = false}。
 * 与 {@code MockReportContentProvider} 互斥（那个在 {@code = true} 时生效，且 {@code matchIfMissing=true}），
 * 一个时刻容器里只会有本类或它其中之一，不会出现两个 {@link ReportContentProvider} 候选。</p>
 *
 * <p><b>容错</b>：本类<b>绝不向外抛异常</b> —— 单块取数失败只记日志 + 返回 null，
 * 由生成器的分块隔离机制把原因收进 {@code fail_reason} 软备注，报告仍走 888 终态。</p>
 *
 * @author cyj666666
 * @since 1.4.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(name = "report.mock-content.enabled", havingValue = "false")
public class AgentReportContentProvider implements ReportContentProvider {

    /** 风险要点「总结块」的 agentCode —— 其内容由 doProcess 二阶段回填，本类不处理 */
    public static final String AGENT_RULE_SUMMARY = "RULE_SUMMARY";

    /** 风险要点「条目块」的 agentCode 前缀（后接对应 RULE 块的 blockCode）——同样由 doProcess 回填 */
    public static final String AGENT_RULE_ENTRY_PREFIX = "RULE_ENTRY#";

    /** 智策引擎「补充分析」用的 moduleCode（与 AgentPromptController#getRule 一致） */
    private static final String MODULE_STRATEGY_ENGINE = "IntelligentStrategyEngine";

    private static final String SUBJECT_GUARANTOR = "担保人";
    private static final String GUARANTOR_TYPE_LEGAL = "法人";

    private static final String PARAM_REPORT_NO = "reportNo";
    private static final String PARAM_ENT_NAME = "entName";
    private static final String PARAM_GUARANTOR_NAME = "guarantorName";

    /** 报告头块名 → 固定文案（说明块恒为空串，配合 emptyStrategy=HIDE 不渲染） */
    private static final String HEAD_MAIN_TITLE = "报告主标题";
    private static final String HEAD_SUB_TITLE = "报告副标题";
    private static final String HEAD_SUB_TITLE_TEXT = "日常贷后检查报告";

    /**
     * 智策引擎校验结论：命中
     *
     * <p>未命中与「校验失败」（表达式没算成）在 {@link #ruleContent} 里就返回 null 了，
     * 不会走到落库；所以风险表 {@code checkResult} 列的值恒为本常量。
     * 定义成常量而不是散落的字面量，是为了将来若要落"未命中"记录时只改一处。</p>
     */
    private static final String CHECK_RESULT_HIT = "命中";

    /**
     * 报告正文调大模型时的输出上限（{@code max_tokens}）
     *
     * <p>🔴 <b>必须显式给，不能吃默认值</b>：本平台接的是 reasoning 模型
     * （返回体里带 {@code reasoning_content}），<b>思考 token 与正文 token 共用这一个额度</b>。
     * 报告单块的输入动辄上万 token（如「特定贷款的检查情况」要把整份检查明细喂进去），
     * 默认 10000 会被思考吃满 —— 表现不是报错，而是<b>正文为空串</b>。</p>
     *
     * <p>2026-09-18 实测：该块 {@code prompt_tokens=10214}、
     * {@code completion_tokens=10000}（正好顶满）、{@code answer=""}。</p>
     */
    private static final int REPORT_LLM_MAX_TOKENS = 32000;

    private final IknowledgeBaseConfigService knowledgeBaseConfigService;

    private final IAgentRuleService agentRuleService;

    private final AppGuarantorInfoMapper guarantorInfoMapper;

    /** 表格溯源：按表名 + 条件查业务表 → 拼 md 表格（见该类注释） */
    private final TraceTableBuilder traceTableBuilder;

    private final LargeModelGatewayClient largeModelGatewayClient;

    @Override
    public ContentPayload provide(ReportGenerateContext context) {
        if (context == null || context.getBlock() == null) {
            return null;
        }
        AppReportContentBlock block = context.getBlock();
        String blockCode = block.getBlockCode();

        // ① 报告级内容块（catalogCode 为空，如报告头）：不调智能体，给固定文案
        if (!StringUtils.hasText(block.getCatalogCode())) {
            return headContent(context, block, blockCode);
        }

        // ② 风险要点相关块：内容依赖「本报告已生成的全部 RULE 块」，由 doProcess 二阶段回填。
        //    这里必须返回 null（不能自己调 agent），否则会拿不到素材、生成错误的总结。
        String agentCode = block.getAgentCode();
        if (AGENT_RULE_SUMMARY.equals(agentCode)
                || (agentCode != null && agentCode.startsWith(AGENT_RULE_ENTRY_PREFIX))) {
            return null;
        }

        // ③ 溯源（两类）/ 外部灌入：**不走知识库/智策引擎链路**
        String analysisType = block.getAnalysisType();

        // ③-1 表格溯源：agentCode = 表英文名（app_*），agentParams = 查询条件（可带 `列=值` 过滤令牌）。
        //      🔴 严格按条件查，**不做担保人轮询**。
        //      若放它去走知识库链路（拿表名当 moduleCode 查知识配置）→ 查不到 →
        //      每次报告都往 fail_reason 里写"调用失败"。
        if (ReportConstants.ANALYSIS_TRACE_TABLE.equals(analysisType)) {
            long traceStart = System.currentTimeMillis();
            try {
                Map<String, String> values = new HashMap<>();
                values.put(PARAM_REPORT_NO, context.getReportNo());
                values.put(PARAM_ENT_NAME, context.getCustomerName());
                String md = traceTableBuilder.buildMd(agentCode, block.getAgentParams(), values);
                if (!StringUtils.hasText(md)) {
                    log.info("【报告内容加工】表格溯源无内容 reportNo={} block={}({}) 表={} 入参={} 耗时={}ms",
                            context.getReportNo(), blockCode, block.getBlockName(), agentCode,
                            block.getAgentParams(), System.currentTimeMillis() - traceStart);
                    return null;
                }
                log.info("【报告内容加工】表格溯源完成 reportNo={} block={}({}) 表={} 字数={} 耗时={}ms",
                        context.getReportNo(), blockCode, block.getBlockName(), agentCode,
                        md.length(), System.currentTimeMillis() - traceStart);
                return new ContentPayload(md);
            } catch (Throwable e) {
                // 与其它块一致：绝不外抛，失败只记日志 → 块内容为空 → 模板 HIDE 兜底
                log.error("【报告内容加工】表格溯源失败(跳过该块) reportNo={} block={}({}) 表={}",
                        context.getReportNo(), blockCode, block.getBlockName(), agentCode, e);
                return null;
            }
        }

        // ③-2 链接溯源 / 外部灌入：内容**不由本服务产出**
        //      · TRACE_LINK —— content 是"链接开头"（配置表未接入），本版留空；
        //      · EXTERNAL   —— 后续由别的接口直接落 content。
        if (ReportConstants.ANALYSIS_TRACE_LINK.equals(analysisType)
                || ReportConstants.ANALYSIS_EXTERNAL.equals(analysisType)) {
            log.info("【报告内容加工】非本服务产出(跳过该块) reportNo={} block={}({}) analysisType={} agentCode={}",
                    context.getReportNo(), blockCode, block.getBlockName(), analysisType, agentCode);
            return null;
        }

        // ④ 只处理 TEXT / TABLE 类分析块；TITLE / SOURCE_LINK 不调智能体
        String fillType = block.getFillType();
        boolean analysable = ReportConstants.FILL_TEXT.equalsIgnoreCase(fillType)
                || ReportConstants.FILL_TABLE.equalsIgnoreCase(fillType);
        if (!analysable || !StringUtils.hasText(block.getAnalysisType()) || !StringUtils.hasText(agentCode)) {
            return null;
        }
        // ⑤ 其余（知识库 ANALYSIS）走下面这条链路：「知识配置管理」该条详情页预览的大模型分析结果

        List<String> params = parseAgentParams(block.getAgentParams());
        boolean needGuarantor = params.contains(PARAM_GUARANTOR_NAME);

        long start = System.currentTimeMillis();
        try {
            ContentPayload payload;
            if (ReportConstants.ANALYSIS_RULE.equalsIgnoreCase(block.getAnalysisType())) {
                // 智策引擎：命中才有内容，且必须把「校验结果」一并带回去
                // （它要落到 app_report_ai_risk.check_result，与补充分析同一行关联展示）
                payload = needGuarantor
                        ? provideRuleForEachGuarantor(context, block, start)
                        : ruleContent(context, block, null, start);
            } else {
                // 知识库：只有分析文案，没有校验结果
                String text = needGuarantor
                        ? provideForEachGuarantor(context, block, start)
                        : analysisContent(context, block, null, start);
                payload = StringUtils.hasText(text) ? new ContentPayload(text) : null;
            }
            if (payload == null || !StringUtils.hasText(payload.getContent())) {
                // 未命中 / 无数据：内容为空。RULE 类块的模板 emptyStrategy=HIDE，
                // 所以「没命中的规则」在正文里整块不渲染，也不会生成 AI 风险行。
                log.info("【报告内容加工】无内容 reportNo={} block={}({}) agentCode={} 入参={} 耗时={}ms",
                        context.getReportNo(), blockCode, block.getBlockName(), agentCode,
                        block.getAgentParams(), System.currentTimeMillis() - start);
                return null;
            }
            return payload;
        } catch (Throwable e) {
            // 🔴 兜底：任何异常都不外抛，否则会中断整份报告的分块隔离语义
            log.error("【报告内容加工】失败(跳过该块) reportNo={} block={}({}) agentCode={} 入参={}",
                    context.getReportNo(), blockCode, block.getBlockName(), agentCode,
                    block.getAgentParams(), e);
            return null;
        }
    }

    /* ==================== 报告头（固定文案） ==================== */

    private ContentPayload headContent(ReportGenerateContext context, AppReportContentBlock block, String blockCode) {
        String name = block.getBlockName();
        if (HEAD_MAIN_TITLE.equals(name)) {
            // 主标题 = entName（借款人名称）；取不到时回落客户编号，保证报告头不为空
            String title = StringUtils.hasText(context.getCustomerName())
                    ? context.getCustomerName()
                    : context.getCustomerId();
            return StringUtils.hasText(title) ? new ContentPayload(title) : null;
        }
        if (HEAD_SUB_TITLE.equals(name)) {
            return new ContentPayload(HEAD_SUB_TITLE_TEXT);
        }
        // 报告说明等：本版固定为空串 → 交由 emptyStrategy=HIDE 整块不渲染
        log.debug("【报告内容加工】报告级块按空内容处理 block={} name={}", blockCode, name);
        return null;
    }

    /* ==================== ANALYSIS（知识库） ==================== */

    /**
     * 调「知识配置管理」该条知识库，取它详情页预览的那份大模型分析结果。
     *
     * @param guarantorName 担保人口径时传入；借款人口径传 null
     */
    private String analysisContent(ReportGenerateContext context, AppReportContentBlock block,
                                   String guarantorName, long start) {
        JSONObject params = baseParams(context, guarantorName);
        params.put("moduleCode", block.getAgentCode());
        // 🔴 三个必传项，都是「默认值陷阱」，不传拿不到分析结果：
        //    withModelSummary 默认 false → 只返回渲染好的 prompt，根本不调大模型
        //    stream           必须 true  → 见下方说明（流式才保险）
        //    max_tokens       见 REPORT_LLM_MAX_TOKENS（reasoning 模型思考与正文共用额度）
        params.put("withModelSummary", true);
        params.put("stream", true);
        params.put("max_tokens", REPORT_LLM_MAX_TOKENS);

        CollectingSseEmitter emitter = new CollectingSseEmitter();
        Object res = knowledgeBaseConfigService.getPromptContent(params.toJSONString(), emitter);
        String text = pickLlmText(emitter, res);
        logCallDone("知识库", context, block, guarantorName, text, start);
        return text;
    }

    /* ==================== RULE（智策引擎） ==================== */

    /**
     * 调智策引擎：先规则判定，命中后再取「补充分析」的大模型文案，
     * 并把**校验结果**（命中判定 + 事实表达式 + 校验溯源明细）一并带回。
     *
     * <p>判定与取数口径与 {@code AgentPromptController#getRule} 完全一致
     * （同一 JVM 直接调 service，不走 HTTP）。</p>
     *
     * <p>🔴 <b>「校验失败」必须与「未命中」分开认</b>：表达式算不成时
     * {@code resultStatus} 是 null，若直接按未命中处理，就把"这次校验根本没成立"
     * 伪装成了业务结论（智策引擎前端 @ 2026-09-16 已专门修过这个问题）。</p>
     *
     * @param guarantorName 担保人口径时传入；借款人口径传 null
     * @return 命中 → {@code content}=补充分析文案、{@code checkResult}=校验结果 JSON；
     * 未命中 / 校验失败 → null（该块内容为空）
     */
    private ContentPayload ruleContent(ReportGenerateContext context, AppReportContentBlock block,
                                       String guarantorName, long start) {
        String ruleCode = block.getAgentCode();
        AgentRuleEntity rule = agentRuleService.getRule(ruleCode);
        if (rule == null) {
            log.warn("【报告内容加工】规则不存在 agentCode={} reportNo={}", ruleCode, context.getReportNo());
            return null;
        }

        JSONObject params = baseParams(context, guarantorName);
        // 🔴 正式执行必须打严格取数标记：参数没传全时宁可取不到数，
        //    也不能让取数层拿配置里预置的样例值（如"苏州XX精密机械制造有限公司"）兜底顶上。
        params.put(SqlDataSetBuilder.STRICT_FETCH_KEY, true);

        AgentRuleExecuteReq req = new AgentRuleExecuteReq();
        req.setRuleCode(ruleCode);
        req.setName(rule.getRuleName());
        req.setId(rule.getId());
        req.setRuleStatus(rule.getRuleStatus());
        req.setParsedExpression(rule.getParsedExpression());
        req.setPromptKey(rule.getPromptKey());
        if (StringUtils.hasText(rule.getFactAnalysis())) {
            req.setFactAnalysis(rule.getFactAnalysis());
        }
        req.setRequestParams(params);

        AgentRuleExecuteVO vo = agentRuleService.executeRule(req);
        if (vo == null || vo.getResultStatus() == null) {
            // 表达式没算成 → 校验失败（不是"未命中"），单列一类日志便于排查数据问题
            log.warn("【报告内容加工】规则校验失败(表达式未执行) ruleCode={} reportNo={} guarantor={} 耗时={}ms",
                    ruleCode, context.getReportNo(), guarantorName, System.currentTimeMillis() - start);
            return null;
        }
        if (!QLExpressUtil.getResultAsBool(vo.getResultStatus())) {
            // 未命中 → 该块无内容 → 前端按 emptyStrategy 隐藏，这不是错误
            log.info("【报告内容加工】规则未命中 ruleCode={} reportNo={} guarantor={} 耗时={}ms",
                    ruleCode, context.getReportNo(), guarantorName, System.currentTimeMillis() - start);
            return null;
        }

        // 命中：按 getRule 的同一口径拼「补充分析」素材
        JSONObject getParams = new JSONObject();
        getParams.put("content", rule.getDisposalAdvice());
        getParams.put("input", rule.getThresholdConfig());
        getParams.put("data", vo.getMatchedMetrics());
        getParams.put("risk", rule.getRiskRemark());
        getParams.put("result", vo.getResultStatus());
        getParams.put("rule_name", rule.getRuleName());
        if (StringUtils.hasText(vo.getFactExpression())) {
            getParams.put("factExpression", vo.getFactExpression());
        }
        getParams.put("moduleCode", MODULE_STRATEGY_ENGINE);
        params.forEach(getParams::put);
        getParams.put("withModelSummary", true);
        getParams.put("stream", true);
        getParams.put("max_tokens", REPORT_LLM_MAX_TOKENS);

        CollectingSseEmitter emitter = new CollectingSseEmitter();
        Object res = knowledgeBaseConfigService.getPromptContent(getParams.toJSONString(), emitter);
        String text = pickLlmText(emitter, res);
        logCallDone("智策引擎", context, block, guarantorName, text, start);
        // 校验结论随内容一起回去，落 app_report_ai_risk.check_result
        return new ContentPayload(text, CHECK_RESULT_HIT);
    }

    /**
     * 取模型输出：<b>流式收集结果优先</b>，兜底才回落到 {@link #extractAnswer}
     *
     * <h3>🔴 为什么报告链路一律走「流式 + 服务端拼接」</h3>
     * <p>本平台接的是 reasoning 模型，<b>思考 token 与正文 token 共用同一个
     * {@code max_tokens} 额度</b>。非流式时若思考把额度吃满，返回的
     * {@code answer} 是空串 —— 而且<b>不报错</b>：{@code code=200}、
     * {@code completion_tokens} 顶满，调用方只能靠"正文为空"猜出问题。</p>
     *
     * <p>流式的价值在于<b>边生成边吐</b>：已经产出的正文帧不会因为总量被截断而整段丢失。
     * 这条路径与「知识配置管理 → 预览」完全一致（预览同样是
     * {@code stream=true} + {@code returnFlag=true}，用户实测可正常出分析文案），
     * 所以报告正文与预览不会有口径差异（{@code returnFlag=true} 时
     * {@code consumeStream} 吐的是 {@code {code:200, answer:...}} 结构化帧）。</p>
     *
     * @param emitter 本次调用用的收集器，正常帧的 {@code answer}/{@code content} 会被逐帧拼进来
     * @param res     {@code getPromptContent} 的返回值。走流式时它是 emitter 本身
     *                （{@code shouldReturnLlmResult} 判定非 null 即返回），并无正文可取 ——
     *                正文一律从 emitter 里拿。保留入参是为了兼容"万一走了非流式分支"的兜底。
     */
    private String pickLlmText(CollectingSseEmitter emitter, Object res) {
        String streamed = emitter.getText();
        if (StringUtils.hasText(streamed)) {
            // 流式拿到的就是模型正文，不存在"误取 prompt"的可能，无需 looksLikePrompt 过滤
            return trimToNull(streamed);
        }
        String notices = emitter.getNotices();
        if (StringUtils.hasText(notices)) {
            // 一个正文帧都没有时，把错误帧留痕 —— 否则排查时只看到"内容为空"
            log.warn("【报告内容加工】流式未收到正文帧，非正常帧内容={}", trimToNull(notices));
        }
        return extractAnswer(res);
    }

    /* ==================== 担保人口径：多担保人轮循 ==================== */

    /**
     * 知识库口径：标注了 {@code guarantorName} 的块要按**企业担保人**逐个轮循调用，
     * 结果按段落拼接。一个担保人都取不到时返回 null（该块为空）。
     */
    private String provideForEachGuarantor(ReportGenerateContext context, AppReportContentBlock block, long start) {
        List<String> guarantors = listEnterpriseGuarantors(context.getReportNo());
        if (CollectionUtils.isEmpty(guarantors)) {
            log.info("【报告内容加工】无企业担保人(跳过该块) reportNo={} block={}",
                    context.getReportNo(), block.getBlockCode());
            return null;
        }
        StringBuilder sb = new StringBuilder();
        for (String guarantor : guarantors) {
            String piece = analysisContent(context, block, guarantor, start);
            if (!StringUtils.hasText(piece)) {
                continue;
            }
            appendGuarantorPiece(sb, guarantors.size(), guarantor, piece);
        }
        return sb.length() == 0 ? null : sb.toString();
    }

    /**
     * 智策引擎口径：对每个企业担保人各跑一次「规则判定 + 补充分析」，
     * 文案按段落拼接。
     *
     * <p>校验结论只记"这次判定命中"这一件事（{@code 命中}），与担保人无关，
     * 所以多个担保人轮循时**不展开成数组** —— 一行一条结论即可。</p>
     *
     * <p>一个担保人都没命中 / 没有企业担保人 → 返回 null → 该块为空 → 整块隐藏。</p>
     */
    private ContentPayload provideRuleForEachGuarantor(ReportGenerateContext context, AppReportContentBlock block,
                                                       long start) {
        List<String> guarantors = listEnterpriseGuarantors(context.getReportNo());
        if (CollectionUtils.isEmpty(guarantors)) {
            log.info("【报告内容加工】无企业担保人(跳过该块) reportNo={} block={}",
                    context.getReportNo(), block.getBlockCode());
            return null;
        }
        StringBuilder sb = new StringBuilder();
        for (String guarantor : guarantors) {
            ContentPayload piece = ruleContent(context, block, guarantor, start);
            if (piece == null) {
                continue;
            }
            appendGuarantorPiece(sb, guarantors.size(), guarantor, piece.getContent());
        }
        return sb.length() == 0 ? null : new ContentPayload(sb.toString(), CHECK_RESULT_HIT);
    }

    /**
     * 多担保人时在每段前加一行小标题，否则几段文案粘在一起分不清是谁的。
     *
     * @param total 担保人总数；只有 &gt;1 时才加标题
     */
    private static void appendGuarantorPiece(StringBuilder sb, int total, String guarantor, String piece) {
        if (sb.length() > 0) {
            sb.append('\n');
        }
        if (total > 1) {
            sb.append("<p><strong>担保人：").append(escapeHtml(guarantor)).append("</strong></p>\n");
        }
        sb.append(piece);
    }

    /** 企业担保人名单：reportNo + subjectType=担保人 + guarantorType=法人，去重保序 */
    private List<String> listEnterpriseGuarantors(String reportNo) {
        List<AppGuarantorInfo> rows = guarantorInfoMapper.selectList(Wrappers.<AppGuarantorInfo>lambdaQuery()
                .eq(AppGuarantorInfo::getReportNo, reportNo)
                .eq(AppGuarantorInfo::getSubjectType, SUBJECT_GUARANTOR)
                .eq(AppGuarantorInfo::getGuarantorType, GUARANTOR_TYPE_LEGAL));
        List<String> names = new ArrayList<>();
        if (rows == null) {
            return names;
        }
        for (AppGuarantorInfo row : rows) {
            String name = row.getGuarantorName();
            if (StringUtils.hasText(name) && !names.contains(name)) {
                names.add(name.trim());
            }
        }
        return names;
    }

    /* ==================== 风险要点总结（阶段2回调） ==================== */

    /** 总结用的系统提示词（可直接改这里，不必动代码结构） */
    private static final String RULE_SUMMARY_SYSTEM_PROMPT =
            "你是银行贷后检查报告的风险汇总助手。用户会给你一组已经判定命中的风险要点"
                    + "（每条含规则名称、所在章节、风险文案）。请把它们**高度精炼**成一段中文总结：\n"
                    + "① 先用 1~2 句话给出总体判断（整体风险程度、主要涉及哪几个方面、最突出的问题）；\n"
                    + "② 再按重要程度列出**最多 5 条**要点，每条用「规则名称：一句话结论」的形式；\n"
                    + "③ 🔴 **全文控制在 300 字以内（最多不超过 400 字）**，"
                    + "**严禁把命中的每条规则逐条罗列** —— 必须合并同类项、只保留最关键的几条；\n"
                    + "④ 素材里可能给出几十条，那是原始明细，你的任务是**归纳**而不是**复述**；\n"
                    + "⑤ 不要臆造材料里没有的信息。\n"
                    + "直接输出 HTML 片段（用 <p> 和 <ol><li> 标签），不要输出 markdown 代码块。";

    /** 总结素材里「每条风险文案」的截断长度（素材太长会让模型倾向忠实罗列而不是归纳） */
    private static final int SUMMARY_MATERIAL_PER_HIT_CHARS = 120;

    /**
     * 风险要点总结：把本报告命中的全部 RULE 块内容交给大模型归纳成一段。
     *
     * <p>素材为空（本次一条规则都没命中）时返回 null，该块按 emptyStrategy 处理。</p>
     */
    @Override
    public ContentPayload provideRuleSummary(ReportGenerateContext context, List<RuleHit> ruleHits) {
        if (CollectionUtils.isEmpty(ruleHits)) {
            log.info("【报告内容加工】风险要点总结：本次无命中的规则，跳过 reportNo={}", context.getReportNo());
            return null;
        }
        StringBuilder material = new StringBuilder();
        material.append("【报告编号】").append(context.getReportNo()).append('\n');
        if (StringUtils.hasText(context.getCustomerName())) {
            material.append("【企业名称】").append(context.getCustomerName()).append('\n');
        }
        material.append("【命中风险要点共 ").append(ruleHits.size()).append(" 条】\n");
        int n = 0;
        for (RuleHit hit : ruleHits) {
            n++;
            material.append(n).append(". 【所在章节】").append(nullToDash(hit.getCatalogName()))
                    .append(" 【规则名称】").append(nullToDash(hit.getBlockName())).append('\n')
                    .append("   风险文案：")
                    .append(abbreviate(stripHtml(hit.getContent()), SUMMARY_MATERIAL_PER_HIT_CHARS))
                    .append('\n');
        }
        material.append("\n（以上为原始明细，请按要求归纳，不要逐条复述。）\n");

        long start = System.currentTimeMillis();
        try {
            // 用报告模块自己的大模型配置（report.ai-analysis.lm-code），与全文分析/预警建议一致
            LargeModelGatewayClient.LlmResult res =
                    largeModelGatewayClient.chat(RULE_SUMMARY_SYSTEM_PROMPT, material.toString());
            String text = res == null ? null : trimToNull(res.getContent());
            log.info("【报告内容加工】风险要点总结完成 reportNo={} 素材条数={} 模型={} 字数={} 耗时={}ms",
                    context.getReportNo(), ruleHits.size(), res == null ? "-" : res.getModelName(),
                    text == null ? 0 : text.length(), System.currentTimeMillis() - start);
            return text == null ? null : new ContentPayload(text);
        } catch (Throwable e) {
            // 🔴 与单块取数同一口径：总结失败只记日志，不中断整份报告
            log.error("【报告内容加工】风险要点总结失败 reportNo={} 素材条数={}",
                    context.getReportNo(), ruleHits.size(), e);
            return null;
        }
    }

    private static String nullToDash(String text) {
        return StringUtils.hasText(text) ? text : "-";
    }

    /** 截断到 max 字符（超出加省略号）—— 用于压短总结素材，让模型"归纳"而不是"复述" */
    private static String abbreviate(String text, int max) {
        if (text == null) {
            return "";
        }
        return text.length() <= max ? text : text.substring(0, max) + "…";
    }

    /** 送进模型前去掉 HTML 标签，避免把标签本身当内容喂进去 */
    private static String stripHtml(String html) {
        if (!StringUtils.hasText(html)) {
            return "";
        }
        return html.replaceAll("<[^>]*>", " ").replaceAll("\\s+", " ").trim();
    }

    /* ==================== 公共小工具 ==================== */

    /** 基础入参：reportNo 恒有；entName 取报告客户名；guanrantorName 仅担保人口径传 */
    private JSONObject baseParams(ReportGenerateContext context, String guarantorName) {
        JSONObject params = new JSONObject();
        params.put(PARAM_REPORT_NO, context.getReportNo());
        if (StringUtils.hasText(context.getCustomerName())) {
            params.put(PARAM_ENT_NAME, context.getCustomerName());
        }
        if (StringUtils.hasText(guarantorName)) {
            params.put(PARAM_GUARANTOR_NAME, guarantorName);
        }
        return params;
    }

    /** agentParams 解析：逗号分隔的参数名 → 集合（空/非法值时回落为只带 reportNo） */
    private List<String> parseAgentParams(String agentParams) {
        List<String> params = new ArrayList<>();
        if (StringUtils.hasText(agentParams)) {
            for (String item : agentParams.split(",")) {
                String name = item == null ? "" : item.trim();
                if (StringUtils.hasText(name)) {
                    params.add(name);
                }
            }
        }
        if (!params.contains(PARAM_REPORT_NO)) {
            params.add(PARAM_REPORT_NO);
        }
        return params;
    }

    /**
     * 从 {@code getPromptContent} 的返回值里取**模型输出**。
     *
     * <p>🔴 别拿错字段：走本地大模型（{@code invokeLocalLlm}）时 {@code knowledgeQuery=true}，
     * {@code OpenAiChatUtil.doNonStream} 里写的是
     * {@code answer = 模型输出}、{@code content = prompt 本身}。</p>
     *
     * <p>另一种返回值是「只渲染 prompt、没调模型」的 promptObject（含 {@code isExist} 键）。
     * 那种不能当内容用，否则正文里会出现一大段提示词 —— 这里用 {@code isExist} 把它挡掉。</p>
     */
    private String extractAnswer(Object res) {
        if (res == null) {
            return null;
        }
        if (res instanceof JSONObject) {
            JSONObject jo = (JSONObject) res;
            if (jo.containsKey("isExist")) {
                // promptObject：只渲染了提示词，没出分析结果
                log.warn("【报告内容加工】未取到大模型分析结果（仅返回 prompt），isExist={}",
                        jo.getBooleanValue("isExist"));
                return null;
            }
            String text = jo.getString("answer");
            if (!StringUtils.hasText(text)) {
                // 🔴 绝不回退到 content！content 在这个路径下就是 prompt 本身（见上面注释）。
                //    2026-09-18 实测事故：知识配置 tddkjcqk（prompttype=basic、output 直接引用数据源）
                //    返回的 answer 为空，旧代码回退取 content ⇒ 报告正文里出现
                //    「一坨原始 JSON + 整份提示词模板」，用户看到就是"出来个什么玩意儿"。
                String fallback = jo.getString("content");
                log.warn("【报告内容加工】只拿到 prompt、没有模型输出（不采用 content，避免正文出现提示词）"
                                + " content字数={}", fallback == null ? 0 : fallback.length());
                return null;
            }
            if (looksLikePrompt(text)) {
                log.warn("【报告内容加工】取到的文本含提示词特征，判为无效（不落正文）字数={}", text.length());
                return null;
            }
            return trimToNull(text);
        }
        if (res instanceof String) {
            String s = trimToNull((String) res);
            return looksLikePrompt(s) ? null : s;
        }
        return null;
    }

    /** 提示词特征词：命中 2 个以上即认定「取到的是 prompt 而不是模型输出」 */
    private static final String[] PROMPT_MARKERS = {
            "你是一名", "你是银行", "你的任务", "严禁", "最终输出", "输入数据", "不得输出", "分析规则",
    };

    /**
     * 启发式判断「这段文本是提示词，不是分析结果」
     *
     * <p>兜底用：正常取到 {@code answer} 时不应命中；万一某个知识配置把 prompt 拼进了 answer，
     * 靠这个把它挡在正文之外（宁可空着，也不能让报告里出现一大段提示词）。</p>
     * <p>用"命中 ≥2 个特征词"而不是"含 1 个"，避免正常业务文案被误伤。</p>
     */
    private static boolean looksLikePrompt(String text) {
        if (!StringUtils.hasText(text)) {
            return false;
        }
        if (text.contains("{{") && text.contains("}}")) {
            // 未替换的模板占位符 —— 一定是模板/prompt，不可能是模型输出
            return true;
        }
        int hits = 0;
        for (String marker : PROMPT_MARKERS) {
            if (text.contains(marker) && ++hits >= 2) {
                return true;
            }
        }
        return false;
    }

    /** 单次调用收尾日志（成功路径） */
    private void logCallDone(String source, ReportGenerateContext context, AppReportContentBlock block,
                             String guarantorName, String text, long start) {
        log.info("【报告内容加工】{}调用完成 reportNo={} block={}({}) agentCode={} 担保人={} 字数={} 耗时={}ms",
                source, context.getReportNo(), block.getBlockCode(), block.getBlockName(),
                block.getAgentCode(), StringUtils.hasText(guarantorName) ? guarantorName : "-",
                text == null ? 0 : text.length(), System.currentTimeMillis() - start);
    }

    private static String trimToNull(String text) {
        if (text == null) {
            return null;
        }
        String trimmed = text.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private static String escapeHtml(String text) {
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
