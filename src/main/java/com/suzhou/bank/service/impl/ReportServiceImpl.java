package com.suzhou.bank.service.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.entity.report.AppReportAiAnalysis;
import com.suzhou.bank.entity.report.AppReportAiRisk;
import com.suzhou.bank.entity.report.AppReportCatalog;
import com.suzhou.bank.entity.report.AppReportContentBlock;
import com.suzhou.bank.entity.report.AppReportContentInstance;
import com.suzhou.bank.entity.report.AppReportRiskEditLog;
import com.suzhou.bank.entity.report.AppReportWarningAdvice;
import com.suzhou.bank.entity.report.AppReportWarningAdviceBatch;
import com.suzhou.bank.mapper.ReportMapper;
import com.suzhou.bank.mapper.report.AppReportAiAnalysisMapper;
import com.suzhou.bank.mapper.report.AppReportAiRiskMapper;
import com.suzhou.bank.mapper.report.AppReportCatalogMapper;
import com.suzhou.bank.mapper.report.AppReportContentBlockMapper;
import com.suzhou.bank.mapper.report.AppReportContentInstanceMapper;
import com.suzhou.bank.mapper.report.AppReportRiskEditLogMapper;
import com.suzhou.bank.mapper.report.AppReportWarningAdviceBatchMapper;
import com.suzhou.bank.mapper.report.AppReportWarningAdviceMapper;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.ReportService;
import com.suzhou.bank.service.report.ai.ReportAiAnalysisTask;
import com.suzhou.bank.service.report.ai.ReportWarningAdviceTask;
import com.suzhou.bank.service.report.model.ReportAiAnalysisVO;
import com.suzhou.bank.service.report.model.ReportBlockVO;
import com.suzhou.bank.service.report.model.ReportCatalogNode;
import com.suzhou.bank.service.report.model.ReportCreateRequest;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import com.suzhou.bank.service.report.model.ReportPageQuery;
import com.suzhou.bank.service.report.model.ReportRiskEditLogVO;
import com.suzhou.bank.service.report.model.ReportRiskItem;
import com.suzhou.bank.service.report.model.ReportVersionVO;
import com.suzhou.bank.service.report.model.ReportWarningAdviceItem;
import com.suzhou.bank.service.report.model.ReportWarningAdviceVO;
import com.suzhou.bank.service.report.spi.ContentPayload;
import com.suzhou.bank.service.report.spi.ReportContentProvider;
import com.suzhou.bank.service.report.spi.ReportGenerateContext;
import com.suzhou.bank.service.report.spi.RuleHit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

import static com.suzhou.bank.service.report.model.ReportConstants.*;

/**
 * 报告服务实现（模板驱动的报告实例生成）
 *
 * <p><b>本工程的发起口径（与行内不同）</b>：行内是「发起落 111 → 生成池
 * {@code ReportGenerateJob} 定时轮询捞取 → CAS 认领 111→000 → 加工 → 888」，
 * 外网没有生成池、也不对接 SSF/ESB，因此改为<b>列表点「发起」后异步直接触发加工</b>
 * （{@link #createReport} 内提交到 {@code reportGenerateExecutor}），
 * 「更新报告」（{@link #renew}）同理。报告记录仍由本服务负责落表，初始状态 111。</p>
 *
 * <p><b>状态流转</b>：111-待开始 → 000-进行中 → 888-已完成（同时写入 version）/ 999-失败。</p>
 *
 * <p><b>并发与事务约定</b>：本服务<b>不声明事务</b>，也不做"重跑清理"。
 * 互斥由上游统一加分布式锁保证；每次生成的报告编号唯一，
 * 因此重复加工会被实例表的唯一键拦住，不会产生数据错乱。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {

    /**
     * 风险要点「总结块」的 agentCode（与 {@code AgentReportContentProvider#AGENT_RULE_SUMMARY} 同值）。
     * <p>本类的两阶段调度用它识别「延后到阶段 2 回填」的块。</p>
     */
    private static final String AGENT_RULE_SUMMARY = "RULE_SUMMARY";

    /**
     * 风险要点「收尾结论块」的 agentCode（与 {@code AgentReportContentProvider#AGENT_RULE_SUMMARY_TAIL} 同值）
     *
     * <p>2026-09-18 用户口径：风险要点 = 开篇总述 → 4~5 条要点 → 收尾结论。开头与收尾是**两个块**，
     * 中间夹着条目块；两段由同一次大模型调用产出（在 {@code summarizeRuleRisks} 里一起拿回来），
     * 由本类的阶段 2 分别落到对应块上。</p>
     */
    private static final String AGENT_RULE_SUMMARY_TAIL = "RULE_SUMMARY_TAIL";

    /**
     * 风险要点「条目块」的 agentCode 前缀（与 {@code AgentReportContentProvider#AGENT_RULE_ENTRY_PREFIX} 同值）。
     * <p>前缀之后存的是「它对应的那个 RULE 块的 blockCode」——条目块的内容就是复用那条规则的正文档内容。</p>
     */
    private static final String AGENT_RULE_ENTRY_PREFIX = "RULE_ENTRY#";

    private final ReportMapper reportMapper;
    private final AppReportCatalogMapper catalogMapper;
    private final AppReportContentBlockMapper blockMapper;
    private final AppReportContentInstanceMapper instanceMapper;
    private final AppReportAiRiskMapper riskMapper;
    private final AppReportRiskEditLogMapper editLogMapper;
    private final AppReportAiAnalysisMapper aiAnalysisMapper;
    private final AppReportWarningAdviceBatchMapper warningBatchMapper;
    private final AppReportWarningAdviceMapper warningAdviceMapper;
    private final ReportContentProvider contentProvider;
    private final ReportAiAnalysisTask aiAnalysisTask;
    private final ReportWarningAdviceTask warningAdviceTask;

    /**
     * 全文分析专用线程池。
     * <p>用 {@code @Resource} 按名字注入：Spring Boot 自带一个 {@code applicationTaskExecutor}，
     * 按类型注入会有两个候选，必须指定 bean 名。</p>
     */
    @Resource(name = "reportAiAnalysisExecutor")
    private ThreadPoolTaskExecutor aiAnalysisExecutor;

    /**
     * 报告实例加工专用线程池：列表点「发起」（或详情页「更新报告」）后异步触发加工用。
     * <p>同 {@code reportAiAnalysisExecutor}，用 {@code @Resource} 按名字注入 ——
     * Spring Boot 自带一个 {@code applicationTaskExecutor}，按类型注入会有两个候选，必须指定 bean 名。</p>
     */
    @Resource(name = "reportGenerateExecutor")
    private ThreadPoolTaskExecutor reportGenerateExecutor;

    /**
     * 内容块级并发池：一份报告内多个内容块并行调智能体用。
     * <p>与 {@code reportGenerateExecutor}（按报告维度的加工池）是两层，**不能合并** ——
     * 详见 {@code ReportGenerateConfig#reportBlockExecutor} 的说明。</p>
     */
    @Resource(name = "reportBlockExecutor")
    private ThreadPoolTaskExecutor reportBlockExecutor;

    /** 同一 reportNo 的触发互斥锁：避免两次点击并发通过「是否已有 RUNNING」的校验 */
    private static final ConcurrentHashMap<String, Object> ANALYSIS_LOCKS = new ConcurrentHashMap<>();

    /**
     * 生成报告实例（含状态流转）。<b>888 是唯一终态</b>（对齐行内口径）。
     *
     * <p><b>容错约定</b>：单个内容块加工异常<b>不会中断整份报告</b>，该块落空、原因汇总进
     * {@code fail_reason} 软备注，报告依然置 888。模板缺失/校验不通过/落库失败同理
     * （空壳 + 软备注 + 888）。<b>正常链路不再产生 999</b> —— 999 是预留状态，
     * 只在历史存量数据里可能见到。</p>
     *
     * <p><b>版本号</b>：置 888 时写入（{@link #markDone}），= 该流水号下最大版本号 + 1（首份 V1）。
     * 只有 888 且 version 非空才被 {@code versions()} / {@code latest()} 认作有效版本。</p>
     *
     * <p>本方法不向外抛异常：任何异常都收敛为 {@code success=false + failReason} 的返回结果。</p>
     */
    @Override
    public ReportGenerateResult generate(String reportNo) {
        long start = System.currentTimeMillis();
        ReportGenerateResult result = new ReportGenerateResult();
        result.setReportNo(reportNo);
        result.setSuccess(false);

        if (!StringUtils.hasText(reportNo)) {
            return failResult(result, start, "报告编号（reportNo）不能为空");
        }

        Report reportInfo;
        try {
            reportInfo = loadReportInfo(reportNo);
        } catch (Throwable e) {
            // 报告记录都读不到（编号不存在 / DB 不可用）：无从置 888，只记日志
            log.error("报告生成失败（报告记录不可读）reportNo={}", reportNo, e);
            return failResult(result, start, buildFailReason(e));
        }
        result.setCustomerId(reportInfo.getCustomerId());
        result.setCustomerName(reportInfo.getCustomerName());
        result.setReportTitle(reportInfo.getReportTitle());

        // 已完成的报告不做重复加工（要重跑请走详情页「更新报告」，会新建一个版本）
        if (REPORT_STATUS_DONE.equals(reportInfo.getStatus())) {
            return failResult(result, start, "报告已完成（888），无需重复生成：" + reportNo);
        }

        try {
            // 置 000-进行中
            markStatus(reportNo, REPORT_STATUS_RUNNING);
            ReportGenerateResult processed = process(reportNo);
            if (!processed.isSuccess()) {
                // 模板级/落库级致命错误（doProcess 已兜底不抛）：仍置 888 终态，失败原因落软备注
                processed.setVersion(markDone(reportInfo, processed.getFailReason()));
                processed.setReportStatus(REPORT_STATUS_DONE);
                return processed;
            }
            // 置 888 + 写入版本号，块级失败汇总进 fail_reason（无失败则清空历史失败原因）
            String softNote = buildBlockFailureNote(processed.getBlockFailures());
            processed.setVersion(markDone(reportInfo, softNote));
            processed.setReportStatus(REPORT_STATUS_DONE);
            processed.setSuccess(true);
            log.info("报告生成完成 reportNo={} version={} 内容实例={} AI风险={} 块失败={} 软备注={} 耗时={}ms",
                    reportNo, processed.getVersion(), processed.getContentTotal(), processed.getRiskTotal(),
                    processed.getBlockFailures().size(), softNote == null ? "无" : softNote, processed.getCostMs());
            return processed;
        } catch (Throwable e) {
            // 基础设施级异常（DB 不可用等）。
            // 行内此处「不置任何状态」，交给生成池的「000 超时兜底」重置回 111 重捞；
            // 但外网没有生成池 —— 若也放着不管，记录会永远卡在 000，所以这里就地兜底：
            // 尽力置 888 + 软备注（888 是唯一终态）。若连这一步都失败，说明 DB 真的挂了，只能记日志。
            log.error("报告生成异常，尝试兜底置 888 reportNo={}", reportNo, e);
            String reason = buildFailReason(e);
            try {
                result.setVersion(markDone(reportInfo, reason));
                result.setReportStatus(REPORT_STATUS_DONE);
            } catch (Throwable fatal) {
                log.error("兜底置 888 亦失败（DB 不可用）reportNo={}", reportNo, fatal);
            }
            return failResult(result, start, reason);
        }
    }

    /**
     * 纯加工：按模板生成内容实例与 AI 风险明细（含状态流转时调用见 {@link #generate}）。
     *
     * <p>不声明事务、不管理状态（调用方自行维护）。<b>支持重跑</b>：落库前先清该报告的旧实例与风险
     * （见 {@link #clearInstances}），因此同一 reportNo 重复加工不会撞实例表唯一键。</p>
     *
     * <p><b>不抛异常</b>：失败时记录日志并返回 {@code success=false + failReason}。</p>
     */
    @Override
    public ReportGenerateResult process(String reportNo) {
        long start = System.currentTimeMillis();
        ReportGenerateResult result = new ReportGenerateResult();
        result.setReportNo(reportNo);
        result.setSuccess(false);
        if (!StringUtils.hasText(reportNo)) {
            return failResult(result, start, "报告编号（reportNo）不能为空");
        }
        try {
            return doProcess(reportNo);
        } catch (Throwable e) {
            // 纯加工同样不抛异常：记录日志并返回失败结果
            log.error("报告实例加工失败 reportNo={}", reportNo, e);
            return failResult(result, start, buildFailReason(e));
        }
    }

    /**
     * 加工内核：模板 → 实例的落地。<b>分块隔离</b>，单块异常不中断整份报告（对齐行内口径）。
     *
     * <p>本方法只在「报告记录都不存在」时才抛异常；模板缺失/校验不通过/单块加工失败/落库失败
     * 一律收敛成 {@code success=false + failReason}（同时把原因逐条收进 {@code blockFailures}），
     * 由 {@link #generate} 统一置 888 + 软备注 —— <b>888 是唯一终态</b>。</p>
     */
    private ReportGenerateResult doProcess(String reportNo) {
        long start = System.currentTimeMillis();
        ReportGenerateResult result = new ReportGenerateResult();
        result.setReportNo(reportNo);
        result.setSuccess(false);
        List<String> blockFailures = result.getBlockFailures();

        // ===== 1. 报告记录（此处只读抬头信息） =====
        Report reportInfo = loadReportInfo(reportNo);
        String customerId = reportInfo.getCustomerId();
        String customerName = StringUtils.hasText(reportInfo.getCustomerName())
                ? reportInfo.getCustomerName() : "客户" + customerId;
        String reportTitle = StringUtils.hasText(reportInfo.getReportTitle())
                ? reportInfo.getReportTitle() : customerName + "贷后管理定期检查报告";
        result.setCustomerId(customerId);
        result.setCustomerName(customerName);
        result.setReportTitle(reportTitle);

        // ===== 2. 载入模板（生成依据） =====
        Map<String, AppReportCatalog> catalogMap = loadEnabledCatalogs().stream()
                .collect(Collectors.toMap(AppReportCatalog::getCatalogCode, c -> c, (a, b) -> a, LinkedHashMap::new));
        List<AppReportContentBlock> blocks = loadEnabledBlocks();
        if (blocks.isEmpty()) {
            // 模板级致命错误：无内容块可生成 → 空壳报告 + 软备注（仍走 888 终态，不中断也不抛）
            blockFailures.add("模板未配置内容块，请先维护 app_report_content_block");
            result.setBlockTotal(0);
            result.setFailReason("模板未配置内容块：app_report_content_block 无启用记录");
            result.setCostMs(System.currentTimeMillis() - start);
            return result;
        }
        try {
            validateTemplate(blocks, catalogMap);
        } catch (ReportGenerateException e) {
            // 模板校验不通过 → 空壳报告 + 软备注（仍走 888 终态）
            log.error("报告模板校验不通过 reportNo={}", reportNo, e);
            blockFailures.add("模板校验不通过：" + e.getMessage());
            result.setBlockTotal(blocks.size());
            result.setFailReason("模板校验不通过：" + e.getMessage());
            result.setCostMs(System.currentTimeMillis() - start);
            return result;
        }

        // ===== 3. 逐块实例化（**并发 + 分块隔离**：单块异常记软备注，继续下一块） =====
        //
        // 🔴 **为什么要两阶段**：模板里「一、（一）风险要点」的总结块排在所有 RULE 块**之前**
        //    （sortNo 20 vs 各章节 30+），而它的素材正是「本报告已生成的全部 RULE 块内容」。
        //    一阶段按顺序加工时素材还不存在，必须等普通块跑完再回填。
        //    · 阶段 1：普通块（TITLE / TEXT / TABLE）并发调智能体
        //    · 阶段 2：回填 RULE_SUMMARY（总结，1 次大模型调用）与 RULE_ENTRY#（条目，复用 RULE 内容，不调模型）
        //
        // 🔴 **为什么必须并发**：93 个取数块 × 单次数十秒 = 串行几十分钟，业务上不可接受。
        //    并发度由 report.agent.block-pool-size 控制（暂定 5）。
        Set<String> seenBlockCodes = new HashSet<>();
        List<String> failureSink = Collections.synchronizedList(new ArrayList<>());
        int size = blocks.size();
        AppReportContentInstance[] slots = new AppReportContentInstance[size];
        AppReportAiRisk[] riskSlots = new AppReportAiRisk[size];

        List<java.util.concurrent.Future<?>> futures = new ArrayList<>(size);
        for (int i = 0; i < size; i++) {
            final int idx = i;
            final AppReportContentBlock block = blocks.get(i);
            // 二阶段负责的块：这里先占位（内容留空），等阶段 2 回填
            if (isDeferredBlock(block)) {
                continue;
            }
            futures.add(reportBlockExecutor.submit(() -> {
                long blockStart = System.currentTimeMillis();
                try {
                    BlockOutcome outcome = buildInstance(
                            reportNo, customerId, customerName, reportTitle, block, catalogMap);
                    AppReportContentInstance instance = outcome.getInstance();
                    slots[idx] = instance;
                    // 🔴 AI 风险行 = **命中的**规则（2026-09-17 用户口径）：
                    //    「展示命中的规则，没有命中的就不用展示了」。
                    //    规则未命中 / 校验失败时 provider 会返回 null → 块内容为空。
                    //    所以「内容非空」就是"命中"的判定依据 —— 与下面 fillRiskSummaryBlocks
                    //    挑选总结素材（同样要求内容非空）用的是同一口径，不会出现
                    //    "风险列表有这条、风险要点总结里却没有"的错位。
                    if (isRuleBlock(block) && StringUtils.hasText(instance.getContent())) {
                        riskSlots[idx] = buildRisk(instance, block, outcome.getPayload(), seenBlockCodes);
                    }
                } catch (Throwable e) {
                    // 单块失败：记日志 + 软备注，继续下一块（绝不中断整份报告）
                    log.error("内容块加工失败(跳过该块) reportNo={} blockCode={}", reportNo, block.getBlockCode(), e);
                    String blockName = StringUtils.hasText(block.getBlockName())
                            ? block.getBlockName() : block.getBlockCode();
                    failureSink.add("[" + block.getBlockCode() + "/" + blockName + "] " + briefError(e));
                } finally {
                    log.debug("内容块加工结束 reportNo={} blockCode={} 耗时={}ms",
                            reportNo, block.getBlockCode(), System.currentTimeMillis() - blockStart);
                }
            }));
        }
        // 等全部块跑完（任何单块失败都已在任务内消化，不会抛到这里）
        for (java.util.concurrent.Future<?> future : futures) {
            try {
                future.get();
            } catch (Throwable e) {
                // 仅当任务被拒绝/池异常等情况才会走到；同样只记软备注
                log.error("内容块加工任务异常 reportNo={}", reportNo, e);
                failureSink.add("[任务提交] " + briefError(e));
            }
        }
        if (!failureSink.isEmpty()) {
            blockFailures.addAll(failureSink);
        }

        // ===== 3.5 阶段2：回填「风险要点」=====
        //   · 总结块：把本报告已生成的**全部 RULE 块内容**当素材，1 次大模型调用出总结
        //   · 条目块：直接复用对应 RULE 块的内容（本地截取，不再调模型）
        fillRiskSummaryBlocks(reportNo, customerId, customerName, blocks, catalogMap,
                slots, blockFailures);

        // 按模板顺序收敛结果（跳过被跳过/失败的块）
        List<AppReportContentInstance> instances = new ArrayList<>(size);
        List<AppReportAiRisk> risks = new ArrayList<>();
        int emptyCount = 0;
        int hiddenCount = 0;
        for (int i = 0; i < size; i++) {
            AppReportContentInstance instance = slots[i];
            if (instance == null) {
                continue;
            }
            instances.add(instance);
            if (!StringUtils.hasText(instance.getContent())) {
                emptyCount++;
                if (EMPTY_HIDE.equalsIgnoreCase(blocks.get(i).getEmptyStrategy())) {
                    hiddenCount++;
                }
            }
            if (riskSlots[i] != null) {
                risks.add(riskSlots[i]);
            }
        }

        // ===== 4. 落库：先清旧实例/风险（支持重跑，防唯一键冲突），再插新 =====
        clearInstances(reportNo);
        // 🔴 **逐行隔离落库**（2026-09-17 修正）：原来整批只套一个 try-catch，
        //    任何一行冲突都会直接跳到 catch、**丢掉其后所有行**，而报告照样置 888，
        //    表现为「报告完成了，但风险列表莫名少了几条」，极难排查。
        //    典型触发场景：风险表若仍残留 (reportNo, agentCode) 唯一索引，
        //    同一规则跨章节命中（如 feiyinrz 在「六、征信」与「十二、（二）担保人征信」
        //    各一个块）时，第二条起全部冲突。
        //    现在每行独立兜底：失败只进软备注，其余行照常入库 —— 与"块级失败不影响整体"一致。
        for (AppReportContentInstance instance : instances) {
            try {
                instanceMapper.insert(instance);
            } catch (Exception e) {
                log.error("内容实例落库失败 reportNo={} blockCode={}", reportNo, instance.getBlockCode(), e);
                blockFailures.add("[" + instance.getBlockCode() + "/" + instance.getBlockName()
                        + "] 内容实例落库失败：" + briefError(e));
            }
        }
        for (AppReportAiRisk risk : risks) {
            try {
                riskMapper.insert(risk);
            } catch (Exception e) {
                log.error("AI 风险明细落库失败 reportNo={} blockCode={} agentCode={}",
                        reportNo, risk.getBlockCode(), risk.getAgentCode(), e);
                blockFailures.add("[" + risk.getBlockCode() + "/" + risk.getRuleName()
                        + "] AI 风险明细落库失败：" + briefError(e));
            }
        }

        log.info("报告实例加工完成 reportNo={} 内容块={} 实例={} 空内容={} 隐藏={} AI风险={} 块失败={} 耗时={}ms",
                reportNo, blocks.size(), instances.size(), emptyCount, hiddenCount, risks.size(),
                blockFailures.size(), System.currentTimeMillis() - start);

        result.setBlockTotal(blocks.size());
        result.setContentTotal(instances.size());
        result.setContentEmpty(emptyCount);
        result.setContentHidden(hiddenCount);
        result.setRiskTotal(risks.size());
        result.setSuccess(true);
        result.setCostMs(System.currentTimeMillis() - start);
        return result;
    }

    /**
     * 是否「延后到阶段 2 回填」的块
     *
     * <p>两类：</p>
     * <ul>
     *   <li>{@code agentCode = RULE_SUMMARY} —— 风险要点总结块，素材是**全部 RULE 块内容**，
     *       而它排在这些 RULE 块之前（sortNo 20 vs 各章节 30+），阶段 1 跑它必然拿不到素材；</li>
     *   <li>{@code agentCode 以 RULE_ENTRY# 开头} —— 风险要点条目块，内容直接复用对应 RULE 块，
     *       同样要等阶段 1 结束。</li>
     *   <li>{@code agentCode = RULE_SUMMARY_TAIL} —— 风险要点「收尾结论块」（2026-09-18 新增），
     *       内容与开篇总述同一次模型调用产出，也要等阶段 2。</li>
     * </ul>
     * <p>阶段 1 遇到这两类**不建实例**（slots 留空），由
     * {@link #fillRiskSummaryBlocks} 统一补上。</p>
     */
    private boolean isDeferredBlock(AppReportContentBlock block) {
        String agentCode = block.getAgentCode();
        return AGENT_RULE_SUMMARY.equals(agentCode)
                || AGENT_RULE_SUMMARY_TAIL.equals(agentCode)
                || (agentCode != null && agentCode.startsWith(AGENT_RULE_ENTRY_PREFIX));
    }

    /**
     * 阶段 2：回填「风险要点」的两个角色块
     *
     * <ul>
     *   <li><b>总结块</b>（{@code agentCode=RULE_SUMMARY}）—— 收齐阶段 1 已生成的**全部 RULE 块内容**，
     *       回调 {@link ReportContentProvider#summarizeRuleRisks}，由加工方调大模型
     *       **归纳成一段 + 挑出最严重的最多 N 条**；</li>
     *   <li><b>条目块</b>（{@code agentCode=RULE_ENTRY#<目标RULE块code>}）—— 直接复用对应 RULE 块的
     *       正文内容（本地截取，**不再调模型**）；对应规则未命中（内容为空）时该块内容留空，
     *       由模板的 {@code emptyStrategy=HIDE} 让它整块不渲染 —— 「命中的才出现」就是这么实现的。</li>
     * </ul>
     *
     * <p>🔴 <b>本方法分两趟</b>（2026-09-18）：<b>先算总结</b>（它同时给出"只保留哪几条"的清单），
     * <b>再回填条目块</b> —— 有清单时只有清单里的条目出内容，其余留空。
     * 用户口径：报告里的「风险要点」不必如实罗列全部命中，挑最严重的几条即可
     * （此前 48 条全列，一片糊）。加工方未给清单（{@code null}）时回落为**不筛选**，即旧行为。</p>
     *
     * <p>本方法不抛异常：任何失败只记软备注。</p>
     *
     * @param slots 阶段 1 的实例槽位（按模板块顺序；本方法负责把延后块的空位填上）
     */
    private void fillRiskSummaryBlocks(String reportNo, String customerId, String customerName,
                                       List<AppReportContentBlock> blocks,
                                       Map<String, AppReportCatalog> catalogMap,
                                       AppReportContentInstance[] slots,
                                       List<String> blockFailures) {
        // 先按「RULE 块编号 → 实例内容」建索引，供总结素材与条目块复用
        Map<String, AppReportContentInstance> ruleInstanceOf = new LinkedHashMap<>();
        List<RuleHit> hits = new ArrayList<>();
        for (int i = 0; i < blocks.size(); i++) {
            AppReportContentBlock block = blocks.get(i);
            AppReportContentInstance instance = slots[i];
            if (instance == null || !isRuleBlock(block) || !StringUtils.hasText(instance.getContent())) {
                continue;
            }
            ruleInstanceOf.put(block.getBlockCode(), instance);
            AppReportCatalog catalog = StringUtils.hasText(block.getCatalogCode())
                    ? catalogMap.get(block.getCatalogCode()) : null;
            hits.add(new RuleHit(block.getBlockCode(), block.getBlockName(), instance.getContent(),
                    catalog == null ? null : catalog.getCatalogName()));
        }

        boolean anyDeferred = false;
        for (AppReportContentBlock block : blocks) {
            if (isDeferredBlock(block)) {
                anyDeferred = true;
                break;
            }
        }
        if (!anyDeferred) {
            return;
        }
        log.info("【报告内容加工】风险要点回填开始 reportNo={} 命中规则={} 条", reportNo, hits.size());

        // ① 先算「总结」—— 它同时决定风险要点**只保留哪几条** + 收尾结论（2026-09-18 用户口径：
        //    风险要点 = 开篇总述 → 4~5 条要点 → 收尾结论；开篇与收尾是**两个块**，中间夹着条目块）。
        //    必须先做：条目块要靠这份清单才知道自己该不该出内容。
        List<String> keepRuleCodes = null;
        ContentPayload tailPayload = null;
        for (int i = 0; i < blocks.size(); i++) {
            AppReportContentBlock block = blocks.get(i);
            if (slots[i] != null || !AGENT_RULE_SUMMARY.equals(block.getAgentCode())) {
                continue;
            }
            try {
                ReportGenerateContext ctx = new ReportGenerateContext();
                ctx.setReportNo(reportNo);
                ctx.setCustomerId(customerId);
                ctx.setCustomerName(customerName);
                ctx.setBlock(block);
                ContentPayload payload;
                ReportContentProvider.RuleSummaryResult result =
                        contentProvider.summarizeRuleRisks(ctx, hits);
                if (result != null) {
                    payload = result.getSummary();
                    keepRuleCodes = result.getKeepRuleBlockCodes();
                    tailPayload = result.getTail();
                } else {
                    // 加工方没实现新契约 → 回落老行为：只出总结、**不筛选**、无收尾
                    payload = contentProvider.provideRuleSummary(ctx, hits);
                }
                String content = payload == null ? null : payload.getContent();
                slots[i] = buildInstance(reportNo, customerId, customerName, null, block, catalogMap,
                        content).getInstance();
            } catch (Throwable e) {
                log.error("风险要点总结块加工失败(跳过该块) reportNo={} blockCode={}",
                        reportNo, block.getBlockCode(), e);
                String blockName = StringUtils.hasText(block.getBlockName())
                        ? block.getBlockName() : block.getBlockCode();
                blockFailures.add("[" + block.getBlockCode() + "/" + blockName + "] " + briefError(e));
            }
        }

        // ①' 回填「收尾结论块」—— 内容来自同一次模型调用（{@code #TAIL#} 之后那一段）。
        //    拿不到（模型没按契约输出 / 加工方是旧实现）就留空 ⇒ 模板 emptyStrategy=HIDE → 不渲染。
        for (int i = 0; i < blocks.size(); i++) {
            AppReportContentBlock block = blocks.get(i);
            if (slots[i] != null || !AGENT_RULE_SUMMARY_TAIL.equals(block.getAgentCode())) {
                continue;
            }
            try {
                String content = tailPayload == null ? null : tailPayload.getContent();
                slots[i] = buildInstance(reportNo, customerId, customerName, null, block, catalogMap,
                        content).getInstance();
            } catch (Throwable e) {
                log.error("风险要点收尾结论块加工失败(跳过该块) reportNo={} blockCode={}",
                        reportNo, block.getBlockCode(), e);
                String blockName = StringUtils.hasText(block.getBlockName())
                        ? block.getBlockName() : block.getBlockCode();
                blockFailures.add("[" + block.getBlockCode() + "/" + blockName + "]" + briefError(e));
            }
        }

        // ② 再回填「条目块」：有保留清单 ⇒ 只回填选中的那几条，其余**留空**
        //    （模板 emptyStrategy=HIDE → 整块不渲染 ⇒ 风险要点里只出现挑中的几条）
        boolean filter = keepRuleCodes != null && !keepRuleCodes.isEmpty();
        int kept = 0;
        int dropped = 0;
        for (int i = 0; i < blocks.size(); i++) {
            AppReportContentBlock block = blocks.get(i);
            String agentCode = block.getAgentCode();
            if (slots[i] != null || agentCode == null
                    || !agentCode.startsWith(AGENT_RULE_ENTRY_PREFIX)) {
                continue;
            }
            try {
                // 条目块：agentCode 里存的就是「对应 RULE 块的 blockCode」
                String targetBlockCode = agentCode.substring(AGENT_RULE_ENTRY_PREFIX.length());
                ContentPayload payload = null;
                if (!filter || keepRuleCodes.contains(targetBlockCode)) {
                    AppReportContentInstance ruleInstance = ruleInstanceOf.get(targetBlockCode);
                    if (ruleInstance != null) {
                        payload = new ContentPayload(ruleInstance.getContent());
                        kept++;
                    }
                } else {
                    dropped++;
                }
                String content = payload == null ? null : payload.getContent();
                slots[i] = buildInstance(reportNo, customerId, customerName, null, block, catalogMap,
                        content).getInstance();
            } catch (Throwable e) {
                log.error("风险要点条目块加工失败(跳过该块) reportNo={} blockCode={}",
                        reportNo, block.getBlockCode(), e);
                String blockName = StringUtils.hasText(block.getBlockName())
                        ? block.getBlockName() : block.getBlockCode();
                blockFailures.add("[" + block.getBlockCode() + "/" + blockName + "] " + briefError(e));
            }
        }
        log.info("【报告内容加工】风险要点回填结束 reportNo={} 命中={} 要点保留={} 要点过滤={}{}",
                reportNo, hits.size(), kept, dropped,
                filter ? "" : "（未筛选：加工方未给出保留清单）");
    }

    /** 清理某报告的内容实例与 AI 风险（重跑前调用，避免唯一键 (reportNo, blockCode) 冲突） */
    private void clearInstances(String reportNo) {
        instanceMapper.delete(Wrappers.<AppReportContentInstance>lambdaQuery()
                .eq(AppReportContentInstance::getReportNo, reportNo));
        riskMapper.delete(Wrappers.<AppReportAiRisk>lambdaQuery()
                .eq(AppReportAiRisk::getReportNo, reportNo));
    }

    /** 块级失败汇总 → fail_reason 软备注（无失败返回 null，表示清空历史失败原因） */
    private String buildBlockFailureNote(List<String> blockFailures) {
        if (blockFailures == null || blockFailures.isEmpty()) {
            return null;
        }
        String note = blockFailures.size() + " 个内容块生成失败：" + String.join("；", blockFailures);
        return note.length() > 1000 ? note.substring(0, 1000) : note;
    }

    /** 截断异常信息（块级软备注用，保留可读性且不撑爆 fail_reason 列） */
    private String briefError(Throwable e) {
        String msg = e.getMessage() == null || e.getMessage().trim().isEmpty()
                ? e.getClass().getSimpleName() : e.getMessage();
        msg = msg.trim().replace('\n', ' ').replace('\r', ' ');
        return msg.length() > 200 ? msg.substring(0, 200) : msg;
    }

    @Override
    public ReportDetailVO detail(String reportNo) {
        assertReportNoPresent(reportNo);
        Report reportInfo = loadReportInfo(reportNo);

        // 目录树来自模板层（目录不建实例表）
        Map<String, ReportCatalogNode> nodeMap = new LinkedHashMap<>();
        for (AppReportCatalog catalog : loadEnabledCatalogs()) {
            nodeMap.put(catalog.getCatalogCode(), toCatalogNode(catalog));
        }
        List<ReportCatalogNode> roots = new ArrayList<>();
        for (ReportCatalogNode node : nodeMap.values()) {
            ReportCatalogNode parent = StringUtils.hasText(node.getParentCode()) ? nodeMap.get(node.getParentCode()) : null;
            if (parent == null) {
                roots.add(node);
            } else {
                parent.getChildren().add(node);
            }
        }

        // 空数据策略属于渲染策略，取自模板；未配置时默认 PLACEHOLDER（保留结构、显示占位）
        Map<String, String> emptyStrategyMap = new HashMap<>();
        for (AppReportContentBlock block : loadEnabledBlocks()) {
            emptyStrategyMap.put(block.getBlockCode(),
                    StringUtils.hasText(block.getEmptyStrategy()) ? block.getEmptyStrategy() : EMPTY_PLACEHOLDER);
        }

        List<AppReportContentInstance> instances = instanceMapper.selectList(
                Wrappers.<AppReportContentInstance>lambdaQuery()
                        .eq(AppReportContentInstance::getReportNo, reportNo)
                        .orderByAsc(AppReportContentInstance::getSortNo)
                        .orderByAsc(AppReportContentInstance::getBlockCode));

        List<ReportBlockVO> headBlocks = new ArrayList<>();
        Map<String, String> catalogOfBlock = new HashMap<>();
        for (AppReportContentInstance instance : instances) {
            catalogOfBlock.put(instance.getBlockCode(), instance.getCatalogCode());
            ReportBlockVO vo = toBlockVO(instance, emptyStrategyMap.get(instance.getBlockCode()));
            ReportCatalogNode node = StringUtils.hasText(instance.getCatalogCode())
                    ? nodeMap.get(instance.getCatalogCode()) : null;
            if (node == null) {
                // 报告级内容块（如报告头），或目录已停用：一律渲染在正文顶部，避免内容丢失
                headBlocks.add(vo);
            } else {
                node.getBlocks().add(vo);
            }
        }
        roots.forEach(this::sortCatalogBlocks);

        // 各风险要点在该日检流水号下的修改记录条数（跨版本累计）：一次 group 查询得出，
        // 供前端决定是否显示「修改记录(N)」按钮，避免每行单独发一次请求
        Map<String, Integer> editCountOfBlock = new HashMap<>();
        if (StringUtils.hasText(reportInfo.getCheckTaskNo())) {
            List<AppReportRiskEditLog> editLogs = editLogMapper.selectList(
                    Wrappers.<AppReportRiskEditLog>lambdaQuery()
                            .select(AppReportRiskEditLog::getBlockCode)
                            .eq(AppReportRiskEditLog::getCheckTaskNo, reportInfo.getCheckTaskNo()));
            for (AppReportRiskEditLog editLog : editLogs) {
                editCountOfBlock.merge(editLog.getBlockCode(), 1, Integer::sum);
            }
        }

        List<AppReportAiRisk> riskRows = riskMapper.selectList(
                Wrappers.<AppReportAiRisk>lambdaQuery()
                        .eq(AppReportAiRisk::getReportNo, reportNo)
                        .orderByAsc(AppReportAiRisk::getSortNo)
                        .orderByAsc(AppReportAiRisk::getBlockCode));
        List<ReportRiskItem> risks = new ArrayList<>(riskRows.size());
        int pending = 0;
        int adopted = 0;
        int invalid = 0;
        for (AppReportAiRisk row : riskRows) {
            ReportRiskItem item = new ReportRiskItem();
            item.setBlockCode(row.getBlockCode());
            item.setAgentCode(row.getAgentCode());
            item.setRuleName(row.getRuleName());
            item.setRiskDesc(row.getRiskDesc());
            // 补充分析（riskDesc）的同伴：智策引擎校验结论（是否命中），前端「校验结果」列的数据源
            item.setCheckResult(row.getCheckResult());
            item.setStatus(row.getStatus());
            item.setJumpAnchorCode(row.getJumpAnchorCode());
            item.setSortNo(row.getSortNo());
            item.setCatalogCode(catalogOfBlock.get(row.getBlockCode()));
            item.setEditCount(editCountOfBlock.getOrDefault(row.getBlockCode(), 0));
            risks.add(item);

            if (RISK_ADOPTED.equalsIgnoreCase(row.getStatus())) {
                adopted++;
            } else if (RISK_INVALID.equalsIgnoreCase(row.getStatus())) {
                invalid++;
            } else {
                pending++;
            }
        }

        ReportDetailVO detail = new ReportDetailVO();
        detail.setReportNo(reportInfo.getReportNo());
        detail.setCustomerId(reportInfo.getCustomerId());
        detail.setCustomerName(reportInfo.getCustomerName());
        detail.setReportTitle(reportInfo.getReportTitle());
        detail.setCheckTaskNo(reportInfo.getCheckTaskNo());
        detail.setVersion(reportInfo.getVersion());
        detail.setStatus(reportInfo.getStatus());
        // 软备注：块级失败汇总（status 仍为 888），前端详情页顶部提示条的数据源
        detail.setFailReason(reportInfo.getFailReason());
        detail.setUpdatedAt(reportInfo.getUpdatedAt());
        detail.setHeadBlocks(headBlocks);
        detail.setCatalogs(roots);
        detail.setRisks(risks);
        detail.setRiskPending(pending);
        detail.setRiskAdopted(adopted);
        detail.setRiskInvalid(invalid);
        return detail;
    }

    @Override
    public Page<Report> page(ReportPageQuery query) {
        ReportPageQuery q = query == null ? new ReportPageQuery() : query;
        int pageNo = q.getPage() <= 0 ? 1 : q.getPage();
        int pageSize = q.getSize() <= 0 ? 10 : q.getSize();
        // ⚠️ 坑一：MyBatis-Plus 的 ge/le(condition, column, value) 里 value 是**无条件求值**的 ——
        //    把 dayStart(...)/dayEnd(...) 写在 value 位，condition 为 false 时照样会执行，
        //    入参为 null 就直接 NPE（2026-09-13 真实报错：dayStart 第 423 行）。
        //    故一律先算成局部变量（空值 → null），条件位只判 null。
        // ⚠️ 坑二：本工程连的是 openGauss（jdbc:opengauss://，PG 系）。时间条件必须传 Timestamp，
        //    传 String 时驱动按 varchar 下发，`timestamp >= varchar` 在 PG 上会直接报
        //    「operator does not exist: timestamp without time zone >= character varying」。
        Timestamp createdBegin = dayStart(q.getCreatedBegin());
        Timestamp createdEnd = dayEnd(q.getCreatedEnd());
        Timestamp updatedBegin = dayStart(q.getUpdatedBegin());
        Timestamp updatedEnd = dayEnd(q.getUpdatedEnd());
        // 文本列「包含」匹配；状态精确匹配；时间列按日期闭区间（含当天）
        return reportMapper.selectPage(new Page<>(pageNo, pageSize),
                Wrappers.<Report>lambdaQuery()
                        .like(StringUtils.hasText(q.getCheckTaskNo()), Report::getCheckTaskNo, q.getCheckTaskNo())
                        .like(StringUtils.hasText(q.getCustomerId()), Report::getCustomerId, q.getCustomerId())
                        .like(StringUtils.hasText(q.getCustomerName()), Report::getCustomerName, q.getCustomerName())
                        .like(StringUtils.hasText(q.getReportNo()), Report::getReportNo, q.getReportNo())
                        .like(StringUtils.hasText(q.getReportTitle()), Report::getReportTitle, q.getReportTitle())
                        .eq(StringUtils.hasText(q.getStatus()), Report::getStatus, q.getStatus())
                        .like(StringUtils.hasText(q.getUserNo()), Report::getUserNo, q.getUserNo())
                        .ge(createdBegin != null, Report::getCreatedAt, createdBegin)
                        .le(createdEnd != null, Report::getCreatedAt, createdEnd)
                        .ge(updatedBegin != null, Report::getUpdatedAt, updatedBegin)
                        .le(updatedEnd != null, Report::getUpdatedAt, updatedEnd)
                        .orderByDesc(Report::getUpdatedAt)
                        .orderByDesc(Report::getId));
    }

    @Override
    public Report createReport(ReportCreateRequest request, String operatorNo, String operatorName) {
        ReportCreateRequest req = request == null ? new ReportCreateRequest() : request;
        requireText(req.getCustomerId(), "客户编号");
        requireText(req.getCustomerName(), "客户名称");
        requireText(req.getCheckTaskNo(), "日检流水号");
        requireText(req.getReportTitle(), "报告标题");
        requireText(req.getReportType(), "报告类型");

        // 同一日检流水号下不允许「在途」重复发起 —— 对齐行内口径：只挡 111-待开始 / 000-进行中。
        // 已完成（888）的记录<b>不挡</b>：用户可以对着同一流水号再发起一次，按流水号自然堆出
        // V1、V2…（版本号由 nextVersionOf 递增）；详情页仍按 checkTaskNo 取版本号最大的那版。
        // 挡在途是为了避免同一流水号并发跑两份加工、版本号乱序。
        Long inFlight = reportMapper.selectCount(Wrappers.<Report>lambdaQuery()
                .eq(Report::getCheckTaskNo, req.getCheckTaskNo().trim())
                .in(Report::getStatus, REPORT_STATUS_WAITING, REPORT_STATUS_RUNNING));
        if (inFlight != null && inFlight > 0) {
            throw new ReportGenerateException("该日检流水号有报告正在生成中，请等它完成后再发起");
        }

        Report report = new Report();
        // 报告编号：填了就用填的（对齐行内「传入则直接使用、跳过取号」），留空才服务端取号
        if (StringUtils.hasText(req.getReportNo())) {
            String customNo = req.getReportNo().trim();
            Long dup = reportMapper.selectCount(Wrappers.<Report>lambdaQuery()
                    .eq(Report::getReportNo, customNo));
            if (dup != null && dup > 0) {
                // 行内也是直接用、撞库交给 DB 唯一键；这里提前查一次，避免用户拿到 500
                throw new ReportGenerateException("报告编号已存在，请更换：" + customNo);
            }
            report.setReportNo(customNo);
        } else {
            report.setReportNo(generateReportNo());
        }
        report.setCustomerId(req.getCustomerId().trim());
        report.setCustomerName(req.getCustomerName().trim());
        report.setCheckTaskNo(req.getCheckTaskNo().trim());
        report.setReportTitle(req.getReportTitle().trim());
        report.setReportType(req.getReportType().trim());
        report.setUserNo(StringUtils.hasText(operatorNo) ? operatorNo : null);
        report.setStatus(REPORT_STATUS_WAITING);
        // version 留空：生成完成（888）时再赋予；created_at / updated_at 交数据库默认值
        reportMapper.insert(report);
        log.info("发起报告：reportNo={} checkTaskNo={} 客户={} 发起人={}",
                report.getReportNo(), report.getCheckTaskNo(), report.getCustomerName(), operatorName);

        // 发起即触发加工 —— 外网工程没有行内那套「生成池轮询」（行内是落 111 后由
        // ReportGenerateJob 定时捞取、CAS 认领 111→000），因此这里主动把链路接上，
        // 否则报告会永远停在 111-待开始。
        // 🔴 必须异步：加工要逐块取数、后续接入大模型后是分钟级耗时，
        //    在 Web 请求线程里同步跑必然 HTTP 超时。
        // 提交失败也走 888 终态（对齐行内「888 是唯一终态」）：置 888 + 软备注说明原因，
        // 不留 111/000 脏态，用户仍能进详情、也能用「更新报告」重跑。
        final String newReportNo = report.getReportNo();
        try {
            reportGenerateExecutor.execute(() -> generate(newReportNo));
        } catch (Throwable e) {
            log.error("报告生成任务提交失败：reportNo={}", newReportNo, e);
            String reason = "生成任务提交失败：" + briefError(e);
            markDone(report, reason);
            report.setStatus(REPORT_STATUS_DONE);
            report.setFailReason(reason);
        }
        return report;
    }

    /**
     * 日期下界：只给到日期（yyyy-MM-dd）时补 00:00:00。
     *
     * <p><b>空值返回 null（表示不加该条件）；返回 Timestamp 而不是 String 是刻意的</b> ——
     * 见 {@link #dayTime(String, String)}。</p>
     */
    private static Timestamp dayStart(String day) {
        return dayTime(day, "00:00:00");
    }

    /** 日期上界：只给到日期时补 23:59:59，保证「含当天」；空值返回 null（表示不加该条件） */
    private static Timestamp dayEnd(String day) {
        return dayTime(day, "23:59:59");
    }

    /**
     * 把前端传来的日期/时间串转成 {@link Timestamp}。
     *
     * <p>三条约定：① 空值/空白串 → null（调用方按「不加该条件」处理）；
     * ② 只给日期（不含冒号）时补默认时分秒，给了时分秒则原样；③ ISO 的 {@code T} 分隔符合成空格。</p>
     *
     * <p><b>为什么必须是 Timestamp 而不是 String</b>：本工程连 openGauss（PG 系），
     * String 参数会被驱动按 varchar 下发，`timestamp_col &gt;= varchar` 在 PG 上不存在这个操作符，
     * 会直接抛 SQL 异常；给 Timestamp 才会按 timestamp 类型绑定参数。</p>
     *
     * <p><b>为什么格式不对不抛异常</b>：这是列表检索的筛选条件。工程里没有全局异常处理器，
     * 抛出去就是整个列表 500 打不开；格式不对时只忽略这一个条件并记 WARN，页面仍可用。</p>
     */
    private static Timestamp dayTime(String day, String fillTime) {
        if (!StringUtils.hasText(day)) {
            return null;
        }
        String value = day.trim().replace('T', ' ');
        if (value.indexOf(':') < 0) {
            value = value + " " + fillTime;
        }
        try {
            return Timestamp.valueOf(value);
        } catch (IllegalArgumentException e) {
            log.warn("报告列表检索：时间参数无法解析，已忽略该条件：{}", day);
            return null;
        }
    }

    /** 必填文本校验 */
    private static void requireText(String value, String label) {
        if (!StringUtils.hasText(value)) {
            throw new ReportGenerateException(label + "不能为空");
        }
    }

    @Override
    public List<ReportVersionVO> versions(String checkTaskNo) {
        if (!StringUtils.hasText(checkTaskNo)) {
            return new ArrayList<>();
        }
        // 返回：进行中（000，"新报告生成中"）+ 已完成（888 且已赋予版本号）+ 失败（999，仅历史存量）；
        // 失败记录由前端过滤、不进入版本下拉。
        // ⚠️ 999 分支只为兼容存量数据 —— 对齐行内口径后正常链路不再产生 999（失败也是 888 + 软备注），
        //    保留它是为了让升级前失败的老记录仍能在版本下拉里被看到（否则会「丢版本」）。
        // version 为整数列，倒序即"版本从新到旧"（进行中的新版本号最大，自然排最前），同版本号按 id 倒序。
        List<Report> list = reportMapper.selectList(Wrappers.<Report>lambdaQuery()
                .eq(Report::getCheckTaskNo, checkTaskNo)
                .and(w -> w
                        .eq(Report::getStatus, REPORT_STATUS_RUNNING)
                        .or(o -> o.eq(Report::getStatus, REPORT_STATUS_DONE).isNotNull(Report::getVersion))
                        .or(o -> o.eq(Report::getStatus, REPORT_STATUS_FAILED)))
                .orderByDesc(Report::getVersion)
                .orderByDesc(Report::getId));
        return list.stream().map(r -> {
            ReportVersionVO vo = new ReportVersionVO();
            vo.setReportNo(r.getReportNo());
            vo.setVersion(r.getVersion());
            vo.setStatus(r.getStatus());
            vo.setFailReason(r.getFailReason());
            vo.setUpdatedAt(r.getUpdatedAt());
            return vo;
        }).collect(Collectors.toList());
    }

    @Override
    public ReportDetailVO latest(String checkTaskNo) {
        if (!StringUtils.hasText(checkTaskNo)) {
            throw new ReportGenerateException("日检流水号（checkTaskNo）不能为空");
        }
        // 最新版本 = 已完成（888）且已赋予版本号 的版本中版本号最大的一条（按数字比较）
        Report latest = latestDoneReport(checkTaskNo);
        if (latest == null) {
            throw new ReportGenerateException("该日检流水号下不存在已完成（含版本号）的报告：" + checkTaskNo);
        }
        return detail(latest.getReportNo());
    }

    @Override
    public ReportVersionVO renew(String checkTaskNo) {
        if (!StringUtils.hasText(checkTaskNo)) {
            throw new ReportGenerateException("日检流水号（checkTaskNo）不能为空");
        }
        // 1) 防重复：该流水号下已有进行中的报告则拒绝
        Long runningCount = reportMapper.selectCount(Wrappers.<Report>lambdaQuery()
                .eq(Report::getCheckTaskNo, checkTaskNo)
                .eq(Report::getStatus, REPORT_STATUS_RUNNING));
        if (runningCount != null && runningCount > 0) {
            throw new ReportGenerateException("该日检流水号下已有报告正在生成中，请稍后再试");
        }
        // 2) 取最新已完成版本作模板（复制客户、标题、类型等字段），版本号按数字比较取最大
        Report template = latestDoneReport(checkTaskNo);
        if (template == null) {
            throw new ReportGenerateException("该日检流水号下暂无已完成版本，无法更新报告");
        }
        // 3) 新建报告记录：复制模板字段 + 随机编号 + 版本号自增 +1 + 状态置进行中
        Report report = new Report();
        report.setReportNo(generateReportNo());
        report.setCustomerId(template.getCustomerId());
        report.setCustomerName(template.getCustomerName());
        report.setReportTitle(template.getReportTitle());
        report.setReportType(template.getReportType());
        // 用户编号沿用上一版的操作人（user_no 后端只读不写，renew 新建的记录必须显式带上，否则为 NULL）
        report.setUserNo(template.getUserNo());
        report.setCheckTaskNo(checkTaskNo);
        report.setVersion(nextVersionOf(checkTaskNo));
        report.setStatus(REPORT_STATUS_RUNNING);
        report.setFailReason(null);
        reportMapper.insert(report);
        log.info("更新报告：新建版本 reportNo={} version={} checkTaskNo={}",
                report.getReportNo(), report.getVersion(), checkTaskNo);

        // 4) 异步触发生成（不阻塞接口返回）
        //    走与「发起报告」同一个专用池：原先是 CompletableFuture.runAsync（ForkJoinPool.commonPool），
        //    与 Web 请求/其它异步任务抢同一批线程，长耗时加工会拖垮无关任务。
        //    提交失败同样走 888 终态（对齐行内「888 是唯一终态」），置 888 + 软备注，不留 000 脏态。
        final String newReportNo = report.getReportNo();
        try {
            reportGenerateExecutor.execute(() -> generate(newReportNo));
        } catch (Throwable e) {
            log.error("更新报告：生成任务提交失败 reportNo={}", newReportNo, e);
            String reason = "生成任务提交失败：" + briefError(e);
            markDone(report, reason);
            report.setStatus(REPORT_STATUS_DONE);
            report.setFailReason(reason);
        }

        // 5) 返回新版本信息（前端据此提示"新报告生成中"）
        ReportVersionVO vo = new ReportVersionVO();
        vo.setReportNo(report.getReportNo());
        vo.setVersion(report.getVersion());
        vo.setStatus(report.getStatus());
        vo.setUpdatedAt(report.getUpdatedAt());
        return vo;
    }

    @Override
    public void updateRiskStatus(String reportNo, String blockCode, String status) {
        requireReportNoAndBlock(reportNo, blockCode);
        String normalized = normalizeRiskStatus(status);
        int updated = riskMapper.update(null, Wrappers.<AppReportAiRisk>lambdaUpdate()
                .eq(AppReportAiRisk::getReportNo, reportNo)
                .eq(AppReportAiRisk::getBlockCode, blockCode)
                .set(AppReportAiRisk::getStatus, normalized));
        if (updated == 0) {
            throw new ReportGenerateException("未找到对应的 AI 风险记录（reportNo=" + reportNo
                    + "，blockCode=" + blockCode + "）");
        }
        log.info("AI 风险状态更新：reportNo={} blockCode={} status={}", reportNo, blockCode, normalized);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateBlockContent(String reportNo, String blockCode, String content,
                                   String operatorNo, String operatorName) {
        requireReportNoAndBlock(reportNo, blockCode);
        String text = content == null ? "" : content.trim();
        if (text.isEmpty()) {
            throw new ReportGenerateException("正文内容不能为空");
        }
        // 0) 先取出该内容实例（旧文案用于归档对比；其余字段冗余进修改记录）
        AppReportContentInstance instance = instanceMapper.selectOne(
                Wrappers.<AppReportContentInstance>lambdaQuery()
                        .eq(AppReportContentInstance::getReportNo, reportNo)
                        .eq(AppReportContentInstance::getBlockCode, blockCode)
                        .last("LIMIT 1"));
        if (instance == null) {
            throw new ReportGenerateException("未找到对应的内容块实例（reportNo=" + reportNo
                    + "，blockCode=" + blockCode + "）");
        }
        String before = instance.getContent() == null ? "" : instance.getContent();
        boolean changed = !before.equals(text);

        // 1) 正文：更新内容实例的 content
        instanceMapper.update(null, Wrappers.<AppReportContentInstance>lambdaUpdate()
                .eq(AppReportContentInstance::getReportNo, reportNo)
                .eq(AppReportContentInstance::getBlockCode, blockCode)
                .set(AppReportContentInstance::getContent, text));
        // 2) 列表副本 + 处置状态：正文与 riskDesc 是同一份文案，必须同事务同步
        //    （只改正文不改 riskDesc，会导致列表文案与正文不一致、前端正文定位失配）
        riskMapper.update(null, Wrappers.<AppReportAiRisk>lambdaUpdate()
                .eq(AppReportAiRisk::getReportNo, reportNo)
                .eq(AppReportAiRisk::getBlockCode, blockCode)
                .set(AppReportAiRisk::getRiskDesc, text)
                .set(AppReportAiRisk::getStatus, RISK_ADOPTED));

        // 3) 修改记录归档（同事务）：仅当内容确实变化时写入，只记人工修改
        if (changed) {
            saveEditLog(instance, text, before, operatorNo, operatorName);
        }
        log.info("正文修改并同步风险文案：reportNo={} blockCode={} 长度={} 已归档={}",
                reportNo, blockCode, text.length(), changed);
    }

    /**
     * 写入一条风险要点修改记录
     * <p>归档维度是 checkTaskNo + blockCode（而非 reportNo），故这里要把 reportNo 反查成 checkTaskNo，
     * 这样同一日检流水号下各版本的修改历史才能累计、跨版本可追溯。</p>
     */
    private void saveEditLog(AppReportContentInstance instance, String after, String before,
                             String operatorNo, String operatorName) {
        Report report = reportMapper.selectOne(Wrappers.<Report>lambdaQuery()
                .eq(Report::getReportNo, instance.getReportNo())
                .last("LIMIT 1"));
        if (report == null || !StringUtils.hasText(report.getCheckTaskNo())) {
            // 拿不到日检流水号就无法归到正确维度上，宁可记日志也不写脏数据
            log.warn("跳过修改记录归档：reportNo={} 未找到日检流水号", instance.getReportNo());
            return;
        }
        AppReportRiskEditLog logRow = new AppReportRiskEditLog();
        logRow.setCheckTaskNo(report.getCheckTaskNo());
        logRow.setBlockCode(instance.getBlockCode());
        logRow.setReportNo(instance.getReportNo());
        logRow.setBlockName(instance.getBlockName());
        logRow.setCatalogCode(instance.getCatalogCode());
        logRow.setCustomerId(instance.getCustomerId());
        logRow.setCustomerName(instance.getCustomerName());
        logRow.setContentBefore(before);
        logRow.setContentAfter(after);
        logRow.setOperatorNo(StringUtils.hasText(operatorNo) ? operatorNo : null);
        logRow.setOperatorName(StringUtils.hasText(operatorName) ? operatorName : operatorNo);
        // inputtime 不在此赋值：交给列默认值 CURRENT_TIMESTAMP，与其它表 inputtime 的取值口径一致
        editLogMapper.insert(logRow);
    }

    @Override
    public List<ReportRiskEditLogVO> editHistory(String checkTaskNo, String blockCode) {
        if (!StringUtils.hasText(checkTaskNo) || !StringUtils.hasText(blockCode)) {
            return new ArrayList<>();
        }
        // 时间正序（最早在上）：首位是「原始版本」，其后按修改时间从早到晚，
        // 整条列表就是一条顺着往下读的时间轴（最新一条落在末尾）
        List<AppReportRiskEditLog> rows = editLogMapper.selectList(
                Wrappers.<AppReportRiskEditLog>lambdaQuery()
                        .eq(AppReportRiskEditLog::getCheckTaskNo, checkTaskNo)
                        .eq(AppReportRiskEditLog::getBlockCode, blockCode)
                        .orderByAsc(AppReportRiskEditLog::getInputtime)
                        .orderByAsc(AppReportRiskEditLog::getId));
        List<ReportRiskEditLogVO> list = new ArrayList<>(rows.size() + 1);

        // 置顶补一条「原始版本」：正文 content 是原地覆盖的，AI 生成的第一版只能由
        // 最早一条归档的 contentBefore 反推（已按 inputtime asc 排，故最早一条就是第一条）。
        // 它不在归档表里，是纯粹为了展示而造出来的条目：不参与「N 次修改」计数与序号编号。
        if (!rows.isEmpty()) {
            String origin = rows.get(0).getContentBefore();
            if (StringUtils.hasText(origin)) {
                ReportRiskEditLogVO first = new ReportRiskEditLogVO();
                first.setOriginal(Boolean.TRUE);
                first.setContentAfter(origin);
                list.add(first);
            }
        }

        for (AppReportRiskEditLog row : rows) {
            ReportRiskEditLogVO vo = new ReportRiskEditLogVO();
            vo.setOriginal(Boolean.FALSE);
            vo.setOperatorName(StringUtils.hasText(row.getOperatorName())
                    ? row.getOperatorName() : row.getOperatorNo());
            vo.setOperatorNo(row.getOperatorNo());
            vo.setInputtime(row.getInputtime());
            vo.setContentAfter(row.getContentAfter());
            vo.setContentBefore(row.getContentBefore());
            vo.setReportNo(row.getReportNo());
            list.add(vo);
        }
        return list;
    }

    /* =========================================================================
     * AI 全文分析（前端手动触发 / 后台独立线程池执行 / 前端按状态轮询）
     * ====================================================================== */

    @Override
    public ReportAiAnalysisVO startAiAnalysis(String reportNo, String operatorNo, String operatorName) {
        if (!StringUtils.hasText(reportNo)) {
            throw new ReportGenerateException("报告编号（reportNo）不能为空");
        }
        Report report = reportMapper.selectOne(Wrappers.<Report>lambdaQuery()
                .eq(Report::getReportNo, reportNo)
                .last("LIMIT 1"));
        if (report == null) {
            throw new ReportGenerateException("未找到报告记录（reportNo=" + reportNo + "）");
        }
        if (!StringUtils.hasText(report.getCheckTaskNo())) {
            throw new ReportGenerateException("该报告缺少日检流水号，无法进行全文分析");
        }

        // 互斥：同一 reportNo 同时只允许一次进行中的分析。
        // 按 reportNo 加锁，避免两次点击并发穿过「是否已有 RUNNING」的检查
        Object lock = ANALYSIS_LOCKS.computeIfAbsent(reportNo, k -> new Object());
        AppReportAiAnalysis record;
        synchronized (lock) {
            Long running = aiAnalysisMapper.selectCount(Wrappers.<AppReportAiAnalysis>lambdaQuery()
                    .eq(AppReportAiAnalysis::getReportNo, reportNo)
                    .eq(AppReportAiAnalysis::getStatus, ANALYSIS_STATUS_RUNNING));
            if (running != null && running > 0) {
                throw new ReportGenerateException("全文分析进行中，请稍后再试");
            }
            record = new AppReportAiAnalysis();
            record.setReportNo(reportNo);
            record.setCheckTaskNo(report.getCheckTaskNo());
            record.setCustomerId(report.getCustomerId());
            record.setCustomerName(report.getCustomerName());
            record.setStatus(ANALYSIS_STATUS_RUNNING);
            record.setOperatorNo(StringUtils.hasText(operatorNo) ? operatorNo : null);
            record.setOperatorName(StringUtils.hasText(operatorName) ? operatorName : operatorNo);
            // inputtime 交给列默认值 CURRENT_TIMESTAMP
            aiAnalysisMapper.insert(record);
        }

        final Long analysisId = record.getId();
        log.info("提交全文分析任务：id={} reportNo={} 触发人={}", analysisId, reportNo, operatorName);
        try {
            aiAnalysisExecutor.execute(() -> aiAnalysisTask.run(analysisId));
        } catch (Throwable e) {
            // 提交失败（如池已关闭）也要把状态收干净，不能让它永远停在 RUNNING
            log.error("全文分析任务提交失败：id={}", analysisId, e);
            AppReportAiAnalysis update = new AppReportAiAnalysis();
            update.setId(analysisId);
            update.setStatus(ANALYSIS_STATUS_FAILED);
            update.setFailReason("任务提交失败：" + e.getMessage());
            update.setGenerateTime(new Date());
            aiAnalysisMapper.updateById(update);
            throw new ReportGenerateException("全文分析任务提交失败，请重试");
        }
        return toAiAnalysisVO(record);
    }

    @Override
    public ReportAiAnalysisVO latestAiAnalysis(String checkTaskNo) {
        if (!StringUtils.hasText(checkTaskNo)) {
            return null;
        }
        Report latest = latestDoneReport(checkTaskNo);
        if (latest == null || !StringUtils.hasText(latest.getReportNo())) {
            return null;
        }
        AppReportAiAnalysis row = aiAnalysisMapper.selectOne(
                Wrappers.<AppReportAiAnalysis>lambdaQuery()
                        .eq(AppReportAiAnalysis::getReportNo, latest.getReportNo())
                        .orderByDesc(AppReportAiAnalysis::getId)
                        .last("LIMIT 1"));
        return row == null ? null : toAiAnalysisVO(row);
    }

    @Override
    public List<ReportAiAnalysisVO> aiAnalysisList(String reportNo) {
        if (!StringUtils.hasText(reportNo)) {
            return new ArrayList<>();
        }
        List<AppReportAiAnalysis> rows = aiAnalysisMapper.selectList(
                Wrappers.<AppReportAiAnalysis>lambdaQuery()
                        .eq(AppReportAiAnalysis::getReportNo, reportNo)
                        .orderByDesc(AppReportAiAnalysis::getId));
        List<ReportAiAnalysisVO> list = new ArrayList<>(rows.size());
        for (AppReportAiAnalysis row : rows) {
            list.add(toAiAnalysisVO(row));
        }
        return list;
    }

    @Override
    public ReportAiAnalysisVO aiAnalysisDetail(Long id) {
        if (id == null) {
            return null;
        }
        AppReportAiAnalysis row = aiAnalysisMapper.selectById(id);
        return row == null ? null : toAiAnalysisVO(row);
    }

    @Override
    public ReportAiAnalysisVO retryAiAnalysis(String reportNo, String operatorNo, String operatorName) {
        // 每次都新增一条记录、保留历史，语义与首次触发一致
        return startAiAnalysis(reportNo, operatorNo, operatorName);
    }

    // ==================== 预警建议 ====================

    @Override
    public ReportWarningAdviceVO startWarningAdvice(String reportNo, String operatorNo, String operatorName) {
        if (!StringUtils.hasText(reportNo)) {
            throw new ReportGenerateException("报告编号（reportNo）不能为空");
        }
        Report report = reportMapper.selectOne(Wrappers.<Report>lambdaQuery()
                .eq(Report::getReportNo, reportNo)
                .last("LIMIT 1"));
        if (report == null) {
            throw new ReportGenerateException("未找到报告记录（reportNo=" + reportNo + "）");
        }
        if (!StringUtils.hasText(report.getCheckTaskNo())) {
            throw new ReportGenerateException("该报告缺少日检流水号，无法生成预警建议");
        }

        // 「AI 全文分析结论」是可选素材，不是前置条件：有就附进素材并记下 analysisId（便于追溯
        // 本次定级参考了哪一版分析），没有就只用报告正文 + 风险要点清单，不阻断。
        // 预警建议的必要输入（报告正文、风险要点、预警管理办法）都不来自全文分析，
        // 若强行前置，全文分析一旦持续失败就会把预警建议一起拖死。
        AppReportAiAnalysis analysis = aiAnalysisMapper.selectOne(
                Wrappers.<AppReportAiAnalysis>lambdaQuery()
                        .eq(AppReportAiAnalysis::getReportNo, reportNo)
                        .eq(AppReportAiAnalysis::getStatus, ANALYSIS_STATUS_DONE)
                        .orderByDesc(AppReportAiAnalysis::getId)
                        .last("LIMIT 1"));

        // 互斥：同一 reportNo 同时只允许一个进行中的批次（与全文分析共用同一把按 reportNo 的锁）
        Object lock = ANALYSIS_LOCKS.computeIfAbsent(reportNo, k -> new Object());
        AppReportWarningAdviceBatch batch;
        synchronized (lock) {
            // 排队中（PENDING，链式预插）与进行中都要算「已有批次在跑」
            Long active = warningBatchMapper.selectCount(
                    Wrappers.<AppReportWarningAdviceBatch>lambdaQuery()
                            .eq(AppReportWarningAdviceBatch::getReportNo, reportNo)
                            .in(AppReportWarningAdviceBatch::getStatus,
                                    ANALYSIS_STATUS_PENDING, ANALYSIS_STATUS_RUNNING));
            if (active != null && active > 0) {
                throw new ReportGenerateException("预警建议生成中，请稍后再试");
            }
            batch = new AppReportWarningAdviceBatch();
            batch.setReportNo(reportNo);
            batch.setCheckTaskNo(report.getCheckTaskNo());
            // 有成功的全文分析才记 analysisId；没有则为空（本批次只基于报告正文定级）
            batch.setAnalysisId(analysis == null ? null : analysis.getId());
            batch.setCustomerId(report.getCustomerId());
            batch.setCustomerName(report.getCustomerName());
            batch.setStatus(ANALYSIS_STATUS_RUNNING);
            batch.setPromptCode(PROMPT_WARNING_ADVICE);
            batch.setOperatorNo(StringUtils.hasText(operatorNo) ? operatorNo : null);
            batch.setOperatorName(StringUtils.hasText(operatorName) ? operatorName : operatorNo);
            // inputtime 交给列默认值 CURRENT_TIMESTAMP
            warningBatchMapper.insert(batch);
        }

        final Long batchId = batch.getId();
        log.info("提交预警建议任务：batchId={} reportNo={} analysisId={} 触发人={}",
                batchId, reportNo, batch.getAnalysisId(), operatorName);
        try {
            aiAnalysisExecutor.execute(() -> warningAdviceTask.run(batchId));
        } catch (Throwable e) {
            // 提交失败（如池已关闭）也要把状态收干净，不能让它永远停在 RUNNING
            log.error("预警建议任务提交失败：batchId={}", batchId, e);
            AppReportWarningAdviceBatch update = new AppReportWarningAdviceBatch();
            update.setId(batchId);
            update.setStatus(ANALYSIS_STATUS_FAILED);
            update.setFailReason("任务提交失败：" + e.getMessage());
            update.setGenerateTime(new Date());
            warningBatchMapper.updateById(update);
            throw new ReportGenerateException("预警建议任务提交失败，请重试");
        }
        return toWarningAdviceVO(batch, new ArrayList<>());
    }

    // ==================== 一键串行：全文分析 → 预警建议 ====================

    @Override
    public ReportAiAnalysisVO startAiChain(String reportNo, String operatorNo, String operatorName) {
        if (!StringUtils.hasText(reportNo)) {
            throw new ReportGenerateException("报告编号（reportNo）不能为空");
        }
        Report report = reportMapper.selectOne(Wrappers.<Report>lambdaQuery()
                .eq(Report::getReportNo, reportNo)
                .last("LIMIT 1"));
        if (report == null) {
            throw new ReportGenerateException("未找到报告记录（reportNo=" + reportNo + "）");
        }
        if (!StringUtils.hasText(report.getCheckTaskNo())) {
            throw new ReportGenerateException("该报告缺少日检流水号，无法进行分析");
        }

        // 链级防重：全文分析或预警建议任一在跑，就不允许再起一条链。
        // 只靠各任务自己的互斥不够 —— 全文分析 DONE 后、预警建议还在 RUNNING 时，
        // 全文分析那把锁已经放开，再点一次会白跑一次全文分析，所以在这里统一挡掉。
        Object lock = ANALYSIS_LOCKS.computeIfAbsent(reportNo, k -> new Object());
        AppReportWarningAdviceBatch pending;
        synchronized (lock) {
            Long runningAnalysis = aiAnalysisMapper.selectCount(
                    Wrappers.<AppReportAiAnalysis>lambdaQuery()
                            .eq(AppReportAiAnalysis::getReportNo, reportNo)
                            .eq(AppReportAiAnalysis::getStatus, ANALYSIS_STATUS_RUNNING));
            if (runningAnalysis != null && runningAnalysis > 0) {
                throw new ReportGenerateException("分析进行中，请稍后再试");
            }
            Long activeAdvice = warningBatchMapper.selectCount(
                    Wrappers.<AppReportWarningAdviceBatch>lambdaQuery()
                            .eq(AppReportWarningAdviceBatch::getReportNo, reportNo)
                            .in(AppReportWarningAdviceBatch::getStatus,
                                    ANALYSIS_STATUS_PENDING, ANALYSIS_STATUS_RUNNING));
            if (activeAdvice != null && activeAdvice > 0) {
                throw new ReportGenerateException("分析进行中，请稍后再试");
            }

            // 预插「排队中」批次。这条记录一物两用：
            // ① 前端立刻能看到整条链在跑，不用等全文分析完成才知道；
            // ② 它的存在就是「本次全文分析属于链式触发」的标记，续接器据此决定是否接着跑预警建议。
            pending = new AppReportWarningAdviceBatch();
            pending.setReportNo(reportNo);
            pending.setCheckTaskNo(report.getCheckTaskNo());
            pending.setCustomerId(report.getCustomerId());
            pending.setCustomerName(report.getCustomerName());
            pending.setStatus(ANALYSIS_STATUS_PENDING);
            pending.setPromptCode(PROMPT_WARNING_ADVICE);
            pending.setOperatorNo(StringUtils.hasText(operatorNo) ? operatorNo : null);
            pending.setOperatorName(StringUtils.hasText(operatorName) ? operatorName : operatorNo);
            // inputtime 交给列默认值 CURRENT_TIMESTAMP
            warningBatchMapper.insert(pending);
            log.info("一键串行：已预插预警建议批次 batchId={} reportNo={}", pending.getId(), reportNo);
        }

        try {
            // 复用单任务入口，它自带「全文分析 RUNNING 互斥」与任务提交失败的收尾
            return startAiAnalysis(reportNo, operatorNo, operatorName);
        } catch (Throwable e) {
            // 全文分析没能启动 → 清掉预插批次，不留悬挂的排队记录
            log.error("一键串行：全文分析启动失败，回滚预插批次 batchId={}", pending.getId(), e);
            try {
                warningBatchMapper.deleteById(pending.getId());
            } catch (Throwable inner) {
                log.error("一键串行：回滚预插批次也失败了 batchId={}", pending.getId(), inner);
            }
            throw e;
        }
    }

    @Override
    public void launchChainedWarningAdvice(String reportNo, Long analysisId) {
        if (!StringUtils.hasText(reportNo)) {
            return;
        }
        Object lock = ANALYSIS_LOCKS.computeIfAbsent(reportNo, k -> new Object());
        final Long batchId;
        synchronized (lock) {
            AppReportWarningAdviceBatch pending = warningBatchMapper.selectOne(
                    Wrappers.<AppReportWarningAdviceBatch>lambdaQuery()
                            .eq(AppReportWarningAdviceBatch::getReportNo, reportNo)
                            .eq(AppReportWarningAdviceBatch::getStatus, ANALYSIS_STATUS_PENDING)
                            .orderByDesc(AppReportWarningAdviceBatch::getId)
                            .last("LIMIT 1"));
            if (pending == null) {
                // 单独触发的全文分析没有预插批次 —— 它不属于任何链，到此为止
                log.info("续接跳过：无排队中的预警建议批次（reportNo={}，本次为单独触发的全文分析）", reportNo);
                return;
            }
            AppReportWarningAdviceBatch update = new AppReportWarningAdviceBatch();
            update.setId(pending.getId());
            update.setStatus(ANALYSIS_STATUS_RUNNING);
            // 全文分析成功则为分析 id，失败时为空（软依赖，预警建议照样跑）
            update.setAnalysisId(analysisId);
            update.setPromptCode(PROMPT_WARNING_ADVICE);
            warningBatchMapper.updateById(update);
            batchId = pending.getId();
        }

        log.info("续接预警建议：batchId={} reportNo={} analysisId={}", batchId, reportNo, analysisId);
        try {
            aiAnalysisExecutor.execute(() -> warningAdviceTask.run(batchId));
        } catch (Throwable e) {
            // 提交失败也要把状态收干净，不能让它永远停在 RUNNING
            log.error("续接预警建议任务提交失败：batchId={}", batchId, e);
            AppReportWarningAdviceBatch update = new AppReportWarningAdviceBatch();
            update.setId(batchId);
            update.setStatus(ANALYSIS_STATUS_FAILED);
            update.setFailReason("任务提交失败：" + e.getMessage());
            update.setGenerateTime(new Date());
            warningBatchMapper.updateById(update);
        }
    }

    @Override
    public ReportWarningAdviceVO latestWarningAdvice(String reportNo) {
        if (!StringUtils.hasText(reportNo)) {
            return null;
        }
        AppReportWarningAdviceBatch batch = warningBatchMapper.selectOne(
                Wrappers.<AppReportWarningAdviceBatch>lambdaQuery()
                        .eq(AppReportWarningAdviceBatch::getReportNo, reportNo)
                        .orderByDesc(AppReportWarningAdviceBatch::getId)
                        .last("LIMIT 1"));
        if (batch == null) {
            return null;
        }
        List<AppReportWarningAdvice> rows = warningAdviceMapper.selectList(
                Wrappers.<AppReportWarningAdvice>lambdaQuery()
                        .eq(AppReportWarningAdvice::getBatchId, batch.getId())
                        .orderByAsc(AppReportWarningAdvice::getSeqNo)
                        .orderByAsc(AppReportWarningAdvice::getId));
        return toWarningAdviceVO(batch, rows);
    }

    @Override
    public void updateWarningAdviceStatus(Long adviceId, String status,
                                          String operatorNo, String operatorName) {
        if (adviceId == null) {
            throw new ReportGenerateException("预警建议ID不能为空");
        }
        String normalized = normalizeRiskStatus(status);
        int updated = warningAdviceMapper.update(null,
                Wrappers.<AppReportWarningAdvice>lambdaUpdate()
                        .eq(AppReportWarningAdvice::getId, adviceId)
                        .set(AppReportWarningAdvice::getStatus, normalized)
                        .set(AppReportWarningAdvice::getOperatorNo, operatorNo)
                        .set(AppReportWarningAdvice::getOperatorName,
                                StringUtils.hasText(operatorName) ? operatorName : operatorNo)
                        .set(AppReportWarningAdvice::getOperateTime, new Date()));
        if (updated == 0) {
            throw new ReportGenerateException("未找到对应的预警建议（id=" + adviceId + "）");
        }
        log.info("预警建议状态更新：id={} status={} 操作人={}", adviceId, normalized, operatorName);
    }

    /** 批次 + 明细 → VO（红橙黄条数现算，不在表里存，避免与实际明细不一致） */
    private ReportWarningAdviceVO toWarningAdviceVO(AppReportWarningAdviceBatch batch,
                                                    List<AppReportWarningAdvice> rows) {
        ReportWarningAdviceVO vo = new ReportWarningAdviceVO();
        vo.setId(batch.getId());
        vo.setReportNo(batch.getReportNo());
        vo.setCheckTaskNo(batch.getCheckTaskNo());
        vo.setAnalysisId(batch.getAnalysisId());
        vo.setStatus(batch.getStatus());
        vo.setCoreTip(batch.getCoreTip());
        vo.setPromptCode(batch.getPromptCode());
        vo.setModelName(batch.getModelName());
        vo.setOperatorNo(batch.getOperatorNo());
        vo.setOperatorName(StringUtils.hasText(batch.getOperatorName())
                ? batch.getOperatorName() : batch.getOperatorNo());
        vo.setCostMillis(batch.getCostMillis());
        vo.setFailReason(batch.getFailReason());
        vo.setGenerateTime(batch.getGenerateTime());
        vo.setInputtime(batch.getInputtime());

        List<ReportWarningAdviceItem> items = new ArrayList<>(rows.size());
        int red = 0;
        int orange = 0;
        int yellow = 0;
        for (AppReportWarningAdvice row : rows) {
            ReportWarningAdviceItem item = new ReportWarningAdviceItem();
            item.setId(row.getId());
            item.setBatchId(row.getBatchId());
            item.setSeqNo(row.getSeqNo());
            item.setWarningLevel(row.getWarningLevel());
            item.setSignalDesc(row.getSignalDesc());
            item.setTriggerCondition(row.getTriggerCondition());
            item.setSourceText(row.getSourceText());
            item.setRiskDesc(row.getRiskDesc());
            item.setChapter(row.getChapter());
            item.setStatus(row.getStatus());
            item.setOperatorNo(row.getOperatorNo());
            item.setOperatorName(StringUtils.hasText(row.getOperatorName())
                    ? row.getOperatorName() : row.getOperatorNo());
            item.setOperateTime(row.getOperateTime());
            items.add(item);

            if (WARNING_LEVEL_RED.equals(row.getWarningLevel())) {
                red++;
            } else if (WARNING_LEVEL_ORANGE.equals(row.getWarningLevel())) {
                orange++;
            } else if (WARNING_LEVEL_YELLOW.equals(row.getWarningLevel())) {
                yellow++;
            }
        }
        vo.setAdvices(items);
        vo.setRedCount(red);
        vo.setOrangeCount(orange);
        vo.setYellowCount(yellow);
        return vo;
    }

    /** 分析记录 → VO（不暴露素材快照与提示词快照，避免把大字段带到前端） */
    private ReportAiAnalysisVO toAiAnalysisVO(AppReportAiAnalysis row) {
        ReportAiAnalysisVO vo = new ReportAiAnalysisVO();
        vo.setId(row.getId());
        vo.setReportNo(row.getReportNo());
        vo.setCheckTaskNo(row.getCheckTaskNo());
        vo.setStatus(row.getStatus());
        vo.setAnalysisContent(row.getAnalysisContent());
        vo.setSummary(row.getSummary());
        vo.setRiskLevel(row.getRiskLevel());
        vo.setModelName(row.getModelName());
        vo.setOperatorNo(row.getOperatorNo());
        vo.setOperatorName(StringUtils.hasText(row.getOperatorName())
                ? row.getOperatorName() : row.getOperatorNo());
        vo.setCostMillis(row.getCostMillis());
        vo.setFailReason(row.getFailReason());
        vo.setGenerateTime(row.getGenerateTime());
        vo.setInputtime(row.getInputtime());
        return vo;
    }


    /** 参数校验：报告编号与内容块编号均必填（两者共同构成实例层的行身份） */
    private void requireReportNoAndBlock(String reportNo, String blockCode) {
        if (!StringUtils.hasText(reportNo)) {
            throw new ReportGenerateException("报告编号（reportNo）不能为空");
        }
        if (!StringUtils.hasText(blockCode)) {
            throw new ReportGenerateException("内容块编号（blockCode）不能为空");
        }
    }

    /** 归一化风险处置状态：仅接受 ADOPTED / INVALID，其它一律按 PENDING（待处理） */
    private String normalizeRiskStatus(String status) {
        if (RISK_ADOPTED.equalsIgnoreCase(status)) {
            return RISK_ADOPTED;
        }
        if (RISK_INVALID.equalsIgnoreCase(status)) {
            return RISK_INVALID;
        }
        return RISK_PENDING;
    }

    /** 生成随机报告编号：RPT + yyyyMMddHHmmss + 4 位随机数 */
    private String generateReportNo() {
        String ts = new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
        int rand = ThreadLocalRandom.current().nextInt(1000, 10000);
        return "RPT" + ts + rand;
    }

    /** 取该流水号下版本号最大的「已完成（888）且已赋版本号」报告，作为最新版本 / 更新报告的复制模板 */
    private Report latestDoneReport(String checkTaskNo) {
        return reportMapper.selectOne(Wrappers.<Report>lambdaQuery()
                .eq(Report::getCheckTaskNo, checkTaskNo)
                .eq(Report::getStatus, REPORT_STATUS_DONE)
                .isNotNull(Report::getVersion)
                .orderByDesc(Report::getVersion)
                .orderByDesc(Report::getId)
                .last("LIMIT 1"));
    }

    /**
     * 下一个版本号：取该流水号下所有已赋版本号记录的最大值 +1（含失败记录，避免失败后版本号被复用）
     */
    private Integer nextVersionOf(String checkTaskNo) {
        List<Report> all = reportMapper.selectList(Wrappers.<Report>lambdaQuery()
                .eq(Report::getCheckTaskNo, checkTaskNo)
                .isNotNull(Report::getVersion));
        int max = all.stream()
                .map(Report::getVersion)
                .filter(Objects::nonNull)
                .max(Integer::compareTo)
                .orElse(0);
        return max + 1;
    }

    /* ==================== 单块实例化 ==================== */

    /**
     * 单块加工产物：内容实例 + 加工方原始产物
     *
     * <p>为什么要一起带出来：智策引擎类内容块除了正文文案，还产出<b>校验结果</b>
     * （{@link ContentPayload#getCheckResult()}），它要落到 AI 风险表的 {@code checkResult} 列。
     * 而 {@code AppReportContentInstance} 是不落这个字段的（正文侧不需要），
     * 所以在装配期用本对象把两者一起传下去。</p>
     */
    private static final class BlockOutcome {

        private final AppReportContentInstance instance;

        private final ContentPayload payload;

        BlockOutcome(AppReportContentInstance instance, ContentPayload payload) {
            this.instance = instance;
            this.payload = payload;
        }

        AppReportContentInstance getInstance() {
            return instance;
        }

        ContentPayload getPayload() {
            return payload;
        }
    }

    /**
     * 实例化一个内容块：取加工产物 → 标题兜底 → 建锚点与跳转 → 快照模板结构性字段
     *
     * <p>正常路径：内容由 {@code contentProvider.provide()} 现取（阶段 1）。</p>
     */
    private BlockOutcome buildInstance(String reportNo, String customerId, String customerName,
                                       String reportTitle,
                                       AppReportContentBlock block,
                                       Map<String, AppReportCatalog> catalogMap) {
        return buildInstance(reportNo, customerId, customerName, reportTitle, block, catalogMap, null);
    }

    /**
     * 实例化一个内容块（可指定已加工好的内容）
     *
     * <p>阶段 2（风险要点回填）走这个重载：总结/条目块的内容在调用方就已经拿到了，
     * 不能再让 {@code contentProvider.provide()} 去取（它会返回 null，见
     * {@code AgentReportContentProvider} 对这两类块的显式跳过）。</p>
     *
     * @param presetContent 非 null 时直接用它当内容，跳过 provider 取数
     */
    private BlockOutcome buildInstance(String reportNo, String customerId, String customerName,
                                       String reportTitle,
                                       AppReportContentBlock block,
                                       Map<String, AppReportCatalog> catalogMap,
                                       String presetContent) {
        AppReportCatalog catalog = StringUtils.hasText(block.getCatalogCode())
                ? catalogMap.get(block.getCatalogCode()) : null;
        String catalogName = catalog == null ? null : catalog.getCatalogName();

        // ① 前置加工产物（由数据加工链路提供，本服务不取数）
        ContentPayload payload = null;
        String content = presetContent;
        if (content == null) {
            ReportGenerateContext context = new ReportGenerateContext();
            context.setReportNo(reportNo);
            context.setCustomerId(customerId);
            context.setCustomerName(customerName);
            context.setCatalogName(catalogName);
            context.setBlock(block);
            payload = contentProvider.provide(context);
            content = payload == null ? null : payload.getContent();
        }
        // ② 标题类内容块无加工产物时按模板兜底（报告头 / 章节标题）
        if (!StringUtils.hasText(content) && FILL_TITLE.equalsIgnoreCase(block.getFillType())) {
            content = fallbackTitle(block, catalogName, reportTitle, customerName);
        }

        AppReportContentInstance instance = new AppReportContentInstance();
        instance.setReportNo(reportNo);
        instance.setCustomerId(customerId);
        instance.setCustomerName(customerName);
        instance.setBlockCode(block.getBlockCode());
        instance.setCatalogCode(block.getCatalogCode());
        // 快照模板结构性字段：渲染无需 join 模板，模板改版也不污染历史报告
        instance.setFillType(block.getFillType());
        instance.setAnalysisType(block.getAnalysisType());
        instance.setAgentCode(block.getAgentCode());
        instance.setBlockName(block.getBlockName());
        instance.setTitleLevel(block.getTitleLevel());
        instance.setSortNo(block.getSortNo());
        instance.setContent(trimToNull(content));
        // ③ 本块位置锚点：其它块要跳过来时用它定位（默认取内容块编号）
        instance.setAnchorCode(block.getBlockCode());
        // ④ 块间跳转锚点（单向、仅用于块内位置跳转）：指向目标块的 anchorCode。
        //    跳转关系属报告结构、在模板层配置（block.jumpAnchorCode），此处直接快照到实例层。
        //    溯源类的外部跳转链接不在此处，随 content 写入。
        instance.setJumpAnchorCode(trimToNull(block.getJumpAnchorCode()));
        return new BlockOutcome(instance, payload);
    }

    /**
     * 标题兜底文案
     * <p>level=1（报告主标题）取报告标题承载报告头；章/节标题取所属目录名称。</p>
     */
    private String fallbackTitle(AppReportContentBlock block, String catalogName, String reportTitle, String customerName) {
        Integer level = block.getTitleLevel();
        if (level != null && level == TITLE_LEVEL_REPORT) {
            return reportTitle;
        }
        if (StringUtils.hasText(catalogName)) {
            return catalogName;
        }
        return reportTitle != null ? reportTitle : customerName;
    }

    /**
     * 生成 AI 风险明细（1:1）—— <b>只有命中的规则才会调到这里</b>
     *
     * <p>调用方（阶段 1）已确认 {@code instance.content} 非空，即该条经验规则**命中**。
     * 一条风险行同时装两个同源产物：</p>
     * <ul>
     *   <li>{@code riskDesc} —— 补充分析（大模型出的风险文案），与正文内容同一份：正文 content 为准、列表为副本；</li>
     *   <li>{@code checkResult} —— 智策引擎校验结论（是否命中），只读留痕。</li>
     * </ul>
     *
     * <p>⚠️ <b>不要在这里按 agentCode 判重</b>（2026-09-17 修正）：报告模板里同一个 agentCode
     * 会在不同章节<b>合法复用</b> —— 典型是征信类规则在「六、征信情况和潜在风险」按**借款人**口径、
     * 在「十二、（二）担保人征信信息」按**担保人**口径各出现一次，入参不同、结果不同。
     * 风险明细的行身份是 {@code (reportNo, blockCode)}（见 {@code uk_report_ai_risk_report_block}），
     * 而 blockCode 全局唯一，所以真正要防的是 blockCode 重复，不是 agentCode 重复。
     * 对应地，DB 上那条 {@code uk_report_ai_risk_report_agent} 唯一索引也已移除
     * （见 {@code sql/报告详情表设计/补丁_移除风险表agent唯一约束.sql}）。</p>
     *
     * @param payload        该块的加工产物（承载校验结果）；非 RULE 路径传 null
     * @param seenBlockCodes 本报告内已生成过风险的 blockCode 集合（跨块调用累积）
     */
    private AppReportAiRisk buildRisk(AppReportContentInstance instance, AppReportContentBlock block,
                                      ContentPayload payload, Set<String> seenBlockCodes) {
        if (!seenBlockCodes.add(block.getBlockCode())) {
            // blockCode 由模板唯一键保证全局唯一，理论上到不了这里；真到了说明模板数据脏，跳过即可
            log.warn("内容块编号在报告内重复，跳过该风险明细 reportNo={} blockCode={}",
                    instance.getReportNo(), block.getBlockCode());
            return null;
        }
        AppReportAiRisk risk = new AppReportAiRisk();
        risk.setReportNo(instance.getReportNo());
        risk.setCustomerId(instance.getCustomerId());
        risk.setCustomerName(instance.getCustomerName());
        risk.setBlockCode(block.getBlockCode());
        risk.setAgentCode(block.getAgentCode());
        risk.setRuleName(block.getBlockName());
        // 补充分析文案：与正文内容同一份（正文侧编辑正文时同事务同步本列）
        risk.setRiskDesc(instance.getContent());
        // 校验结论（智策引擎）：走到这里必然是命中的规则，所以取值就是「命中」。
        // 与上面的补充分析文案是同一次规则调用的两个产物，同行关联；只读留痕，
        // 不随正文编辑变化。
        risk.setCheckResult(payload == null ? null : trimToNull(payload.getCheckResult()));
        risk.setStatus(RISK_PENDING);
        // 单向：风险行 → 正文块位置锚点（同样属于块间位置跳转）
        risk.setJumpAnchorCode(instance.getAnchorCode());
        risk.setSortNo(block.getSortNo());
        return risk;
    }

    /* ==================== 模板载入与校验 ==================== */

    private List<AppReportCatalog> loadEnabledCatalogs() {
        return catalogMapper.selectList(Wrappers.<AppReportCatalog>lambdaQuery()
                .eq(AppReportCatalog::getIsEnabled, ENABLED)
                .orderByAsc(AppReportCatalog::getSortNo)
                .orderByAsc(AppReportCatalog::getCatalogCode));
    }

    private List<AppReportContentBlock> loadEnabledBlocks() {
        return blockMapper.selectList(Wrappers.<AppReportContentBlock>lambdaQuery()
                .eq(AppReportContentBlock::getIsEnabled, ENABLED)
                .orderByAsc(AppReportContentBlock::getSortNo)
                .orderByAsc(AppReportContentBlock::getBlockCode));
    }

    /**
     * 模板配置错误一律 fail-fast，避免生成残缺报告
     *
     * <p>⚠️ <b>校验的是 {@code blockCode} 唯一，不是 {@code agentCode} 唯一</b>（2026-09-17 修正）：</p>
     * <p>行身份是 {@code blockCode}（模板表有 {@code uk_report_block_code}、实例表与风险表都是
     * {@code (reportNo, blockCode)}）。而<b>同一个 agentCode 会在不同章节合法复用</b> ——
     * 典型如 {@code feiyinrz}（非银债务）在「六、征信」按<b>借款人</b>口径（入参 {@code reportNo,entName}）、
     * 在「十二、（二）担保人征信」按<b>担保人</b>口径（入参再加 {@code guarantorName}）各出现一次，
     * 入参不同、结果不同，两块都必须生成。同理知识库编号也存在跨章节复用。</p>
     * <p>旧版在这里按 agentCode 判重，会让这类报告在<b>校验阶段就被判失败</b>
     * （报「智能体编码在模板内重复，要求报告内唯一」，整份报告只出空壳），
     * 与 {@code buildRisk} 的口径自相矛盾。</p>
     */
    private void validateTemplate(List<AppReportContentBlock> blocks, Map<String, AppReportCatalog> catalogMap) {
        Set<String> blockCodes = new HashSet<>();
        for (AppReportContentBlock block : blocks) {
            if (!blockCodes.add(block.getBlockCode())) {
                // 模板表有 uk_report_block_code，DB 已兜底；这里给出可读的失败原因，便于定位脏数据
                throw new ReportGenerateException("内容块编号在模板内重复（要求全局唯一）：" + block.getBlockCode());
            }
            if (!StringUtils.hasText(block.getFillType())) {
                throw new ReportGenerateException("内容块缺少填充类型（fillType）：" + block.getBlockCode());
            }
            boolean reportLevel = !StringUtils.hasText(block.getCatalogCode());
            if (!reportLevel && !catalogMap.containsKey(block.getCatalogCode())) {
                throw new ReportGenerateException("内容块所属目录不存在或已停用：block="
                        + block.getBlockCode() + "，catalog=" + block.getCatalogCode());
            }
            // analysisType（RULE / ANALYSIS）的真实语义是「本块内容由智能体加工」，**TEXT 与 TABLE 都允许**：
            // TABLE 的 content 就是「表格成品片段」（见 {@code ReportConstants.FILL_TABLE}），
            // 同样由 agent 产出（如「我行结算账户与资产情况」「我行结算交易对手情况」这些知识库模板）。
            // 🔴 只有 TITLE / SOURCE_LINK 才禁止配 analysisType。
            // ⚠️ **这条不能反过来收紧**：{@code AgentReportContentProvider#provide} 是靠
            //     `analysable = TEXT || TABLE` + `analysisType 非空` 才决定去调 agent 的，
            //     给 TABLE 块清掉 analysisType 会让它直接 return null → 这些块**静默变空**（不报错）。
            String fillType = block.getFillType();
            if (StringUtils.hasText(block.getAnalysisType()) && !isAgentFillable(block)) {
                throw new ReportGenerateException("分析文本类型仅文本/表格类内容块可配置（TEXT/TABLE）：block="
                        + block.getBlockCode() + "，fillType=" + fillType);
            }
            if (!StringUtils.hasText(block.getBlockName())) {
                throw new ReportGenerateException("内容块缺少名称（blockName）：" + block.getBlockCode());
            }
            if (!isRuleBlock(block)) {
                continue;
            }
            // ⛔ 这里**不要**再校验 agentCode 在报告内唯一 —— 同一规则跨章节按不同入参复用是合法配置，
            //    详见方法注释；行身份是 blockCode，风险表那条 (reportNo, agentCode) 唯一索引也已移除。
            if (!StringUtils.hasText(block.getAgentCode())) {
                throw new ReportGenerateException("经验规则类内容块缺少智能体编码（agentCode）：" + block.getBlockCode());
            }
        }
    }

    /**
     * TEXT / TABLE 两类都可能由智能体加工（**与 {@code AgentReportContentProvider} 的 `analysable` 同口径**）
     *
     * <p>🔴 两处判据必须一致：provider 用 `TEXT || TABLE` 决定要不要调 agent，
     * 这边用同一口径决定「算不算规则块」。若这里收窄成只认 TEXT，
     * 将来出现 `fillType=TABLE + analysisType=RULE` 的块时就会
     * 「正文有内容、AI 风险列表却少一条」——provider 正常调了规则，而 {@link #isRuleBlock} 判 false。</p>
     */
    private boolean isAgentFillable(AppReportContentBlock block) {
        String fillType = block.getFillType();
        return FILL_TEXT.equalsIgnoreCase(fillType) || FILL_TABLE.equalsIgnoreCase(fillType);
    }

    private boolean isRuleBlock(AppReportContentBlock block) {
        return isAgentFillable(block) && ANALYSIS_RULE.equalsIgnoreCase(block.getAnalysisType());
    }

    /* ==================== 状态流转与渲染装配 ==================== */

    private void markStatus(String reportNo, String status) {
        reportMapper.update(null, Wrappers.<Report>lambdaUpdate()
                .eq(Report::getReportNo, reportNo)
                .set(Report::getStatus, status)
                .set(Report::getUpdatedAt, new Date()));
    }

    /**
     * 置 888-已完成并<b>写入版本号</b>，同时落/清失败备注（一次 update 落完，避免多次刷 updated_at）。
     *
     * <p><b>为什么 version 必须在这里写</b>：三处查询条件都是「888 <b>且 version 非空</b>」——</p>
     * <ul>
     *   <li>{@link #versions(String)}：详情页顶部版本下拉框</li>
     *   <li>{@link #latestDoneReport(String)}：列表点「查看」进详情（{@link #latest(String)}）
     *       与「更新报告」的复制模板（{@link #renew(String)}）</li>
     * </ul>
     * <p>发起时 version 刻意留空（落表即 111），若不在置 888 时补上，报告虽然已完成却永远
     * 找不到"已完成版本"，点「查看」会直接报「该日检流水号下不存在已完成（含版本号）的报告」。</p>
     *
     * <p><b>取号口径</b>：与 {@link #renew(String)} 一致，取该流水号下最大版本号 +1（首份为 V1）。
     * 这里不加分布式锁，沿用全服务「不声明事务、互斥交给上游」的既定口径；同流水号的并发由
     * 「发起时 checkTaskNo 不允许重复」+「renew 时该流水号已有进行中报告则拒绝」两道前置校验挡住。</p>
     *
     * @param reportInfo 报告记录（用其 reportNo 定位、checkTaskNo 取号）
     * @param failReason 失败/软备注；成功传 null 表示清空历史失败原因
     * @return 本次写入的版本号
     */
    private Integer markDone(Report reportInfo, String failReason) {
        Integer version = StringUtils.hasText(reportInfo.getCheckTaskNo())
                ? nextVersionOf(reportInfo.getCheckTaskNo())
                // 无流水号无法按流水号取号（也不参与版本下拉/最新版本查询），兜底给 V1
                : 1;
        reportMapper.update(null, Wrappers.<Report>lambdaUpdate()
                .eq(Report::getReportNo, reportInfo.getReportNo())
                .set(Report::getStatus, REPORT_STATUS_DONE)
                .set(Report::getVersion, version)
                .set(Report::getFailReason, failReason)
                .set(Report::getUpdatedAt, new Date()));
        return version;
    }

    /** 组装失败原因：技术类异常带异常类名与堆栈首因，业务类异常带业务描述 */
    private String buildFailReason(Throwable e) {
        String message = e.getMessage();
        if (message == null || message.trim().isEmpty()) {
            message = e.getClass().getSimpleName();
        }
        if (e instanceof ReportGenerateException) {
            return "业务异常：" + message;
        }
        StringBuilder sb = new StringBuilder("技术异常[").append(e.getClass().getSimpleName()).append("]：").append(message);
        Throwable cause = e.getCause();
        if (cause != null && cause.getMessage() != null) {
            sb.append("（根因：").append(cause.getMessage()).append("）");
        }
        String full = sb.toString();
        return full.length() > 1000 ? full.substring(0, 1000) : full;
    }

    /** 构造失败结果（不抛异常，success=false） */
    private ReportGenerateResult failResult(ReportGenerateResult result, long start, String reason) {
        result.setSuccess(false);
        result.setFailReason(reason);
        result.setCostMs(System.currentTimeMillis() - start);
        return result;
    }

    private Report loadReportInfo(String reportNo) {
        Report reportInfo = reportMapper.selectOne(
                Wrappers.<Report>lambdaQuery().eq(Report::getReportNo, reportNo));
        if (reportInfo == null) {
            throw new ReportGenerateException("报告记录不存在：" + reportNo);
        }
        return reportInfo;
    }

    private ReportCatalogNode toCatalogNode(AppReportCatalog catalog) {
        ReportCatalogNode node = new ReportCatalogNode();
        node.setCatalogCode(catalog.getCatalogCode());
        node.setCatalogName(catalog.getCatalogName());
        node.setCatalogLevel(catalog.getCatalogLevel());
        node.setParentCode(catalog.getParentCode());
        node.setSortNo(catalog.getSortNo());
        return node;
    }

    private ReportBlockVO toBlockVO(AppReportContentInstance instance, String emptyStrategy) {
        ReportBlockVO vo = new ReportBlockVO();
        vo.setBlockCode(instance.getBlockCode());
        vo.setCatalogCode(instance.getCatalogCode());
        vo.setFillType(instance.getFillType());
        vo.setAnalysisType(instance.getAnalysisType());
        vo.setAgentCode(instance.getAgentCode());
        vo.setBlockName(instance.getBlockName());
        vo.setTitleLevel(instance.getTitleLevel());
        vo.setSortNo(instance.getSortNo());
        vo.setEmptyStrategy(emptyStrategy);
        vo.setAnchorCode(instance.getAnchorCode());
        vo.setJumpAnchorCode(instance.getJumpAnchorCode());
        vo.setContent(instance.getContent());
        vo.setEmpty(!StringUtils.hasText(instance.getContent()));
        return vo;
    }

    private void sortCatalogBlocks(ReportCatalogNode node) {
        node.getBlocks().sort((a, b) -> {
            int sa = a.getSortNo() == null ? 0 : a.getSortNo();
            int sb = b.getSortNo() == null ? 0 : b.getSortNo();
            return sa != sb ? Integer.compare(sa, sb)
                    : String.valueOf(a.getBlockCode()).compareTo(String.valueOf(b.getBlockCode()));
        });
        node.getChildren().forEach(this::sortCatalogBlocks);
    }

    private String trimToNull(String text) {
        if (text == null) {
            return null;
        }
        String trimmed = text.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private void assertReportNoPresent(String reportNo) {
        if (!StringUtils.hasText(reportNo)) {
            throw new ReportGenerateException("报告编号（reportNo）不能为空");
        }
    }
}
