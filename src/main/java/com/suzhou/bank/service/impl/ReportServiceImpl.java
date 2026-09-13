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
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import com.suzhou.bank.service.report.model.ReportRiskEditLogVO;
import com.suzhou.bank.service.report.model.ReportRiskItem;
import com.suzhou.bank.service.report.model.ReportVersionVO;
import com.suzhou.bank.service.report.model.ReportWarningAdviceItem;
import com.suzhou.bank.service.report.model.ReportWarningAdviceVO;
import com.suzhou.bank.service.report.spi.ContentPayload;
import com.suzhou.bank.service.report.spi.ReportContentProvider;
import com.suzhou.bank.service.report.spi.ReportGenerateContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import javax.annotation.Resource;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.Collectors;

import static com.suzhou.bank.service.report.model.ReportConstants.*;

/**
 * 报告服务实现（模板驱动的报告实例生成）
 * <p>只负责"模板表 + 实例表"的逻辑，不负责报告记录的发起（{@code report}
 * 由上游预生成，初始状态 111-待开始）。</p>
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

    /** 同一 reportNo 的触发互斥锁：避免两次点击并发通过「是否已有 RUNNING」的校验 */
    private static final ConcurrentHashMap<String, Object> ANALYSIS_LOCKS = new ConcurrentHashMap<>();

    @Override
    public ReportGenerateResult generate(String reportNo) {
        long start = System.currentTimeMillis();
        ReportGenerateResult result = new ReportGenerateResult();
        result.setReportNo(reportNo);
        result.setSuccess(false);

        if (!StringUtils.hasText(reportNo)) {
            return failResult(result, start, "报告编号（reportNo）不能为空");
        }

        try {
            Report reportInfo = loadReportInfo(reportNo);
            result.setCustomerId(reportInfo.getCustomerId());
            result.setCustomerName(reportInfo.getCustomerName());
            result.setReportTitle(reportInfo.getReportTitle());

            // 已完成的报告不做重复加工
            if (REPORT_STATUS_DONE.equals(reportInfo.getStatus())) {
                return failResult(result, start, "报告已完成（888），无需重复生成：" + reportNo);
            }

            // 置 000-进行中
            markStatus(reportNo, REPORT_STATUS_RUNNING);
            ReportGenerateResult processed = process(reportNo);
            // 加工失败（process 已捕获异常，success=false）：置 999 + 落失败原因
            if (!processed.isSuccess()) {
                markStatus(reportNo, REPORT_STATUS_FAILED);
                markFailReason(reportNo, processed.getFailReason());
                processed.setReportStatus(REPORT_STATUS_FAILED);
                return processed;
            }
            // 置 888-已完成，并清空历史失败原因
            markStatus(reportNo, REPORT_STATUS_DONE);
            markFailReason(reportNo, null);
            processed.setReportStatus(REPORT_STATUS_DONE);
            processed.setSuccess(true);
            log.info("报告生成成功 reportNo={} 内容实例={} AI风险={} 耗时={}ms",
                    reportNo, processed.getContentTotal(), processed.getRiskTotal(), processed.getCostMs());
            return processed;
        } catch (Throwable e) {
            // 任何异常（技术类/业务类）都不向外抛：记录日志、置 999 失败、落失败原因
            log.error("报告生成失败，已置为 999 reportNo={}", reportNo, e);
            String reason = buildFailReason(e);
            markStatus(reportNo, REPORT_STATUS_FAILED);
            markFailReason(reportNo, reason);
            result.setReportStatus(REPORT_STATUS_FAILED);
            return failResult(result, start, reason);
        }
    }

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

    /** 加工内核：模板 → 实例的落地；失败时抛异常，由 process 统一捕获 */
    private ReportGenerateResult doProcess(String reportNo) {
        long start = System.currentTimeMillis();

        // ===== 1. 报告记录（上游预生成，此处只读抬头信息） =====
        Report reportInfo = loadReportInfo(reportNo);
        String customerId = reportInfo.getCustomerId();
        String customerName = StringUtils.hasText(reportInfo.getCustomerName())
                ? reportInfo.getCustomerName() : "客户" + customerId;
        String reportTitle = StringUtils.hasText(reportInfo.getReportTitle())
                ? reportInfo.getReportTitle() : customerName + "贷后管理定期检查报告";

        // ===== 2. 载入模板（生成依据） =====
        Map<String, AppReportCatalog> catalogMap = loadEnabledCatalogs().stream()
                .collect(Collectors.toMap(AppReportCatalog::getCatalogCode, c -> c, (a, b) -> a, LinkedHashMap::new));
        List<AppReportContentBlock> blocks = loadEnabledBlocks();
        if (blocks.isEmpty()) {
            throw new ReportGenerateException("报告模板未配置内容块，请先维护 app_report_content_block");
        }
        validateTemplate(blocks, catalogMap);

        // ===== 3. 逐块实例化（模板驱动） =====
        Set<String> agentCodes = new HashSet<>();
        List<AppReportContentInstance> instances = new ArrayList<>(blocks.size());
        List<AppReportAiRisk> risks = new ArrayList<>();
        int emptyCount = 0;
        int hiddenCount = 0;

        for (AppReportContentBlock block : blocks) {
            try {
                AppReportContentInstance instance = buildInstance(
                        reportNo, customerId, customerName, reportTitle, block, catalogMap);
                instances.add(instance);

                if (!StringUtils.hasText(instance.getContent())) {
                    emptyCount++;
                    if (EMPTY_HIDE.equalsIgnoreCase(block.getEmptyStrategy())) {
                        hiddenCount++;
                    }
                }
                // 经验规则类内容块 → 一对一生成 AI 风险明细
                if (isRuleBlock(block)) {
                    risks.add(buildRisk(instance, block, agentCodes));
                }
            } catch (Exception e) {
                // 单环节异常：记录日志后转成带定位信息的业务异常，交由上层统一置失败
                log.error("报告加工失败，内容块={} reportNo={}", block.getBlockCode(), reportNo, e);
                throw new ReportGenerateException("内容块加工失败（" + block.getBlockCode() + "）：" + e.getMessage(), e);
            }
        }

        // ===== 4. 落库 =====
        for (AppReportContentInstance instance : instances) {
            instanceMapper.insert(instance);
        }
        for (AppReportAiRisk risk : risks) {
            riskMapper.insert(risk);
        }

        log.info("报告实例加工完成 reportNo={} 内容块={} 实例={} 空内容={} 隐藏={} AI风险={} 耗时={}ms",
                reportNo, blocks.size(), instances.size(), emptyCount, hiddenCount, risks.size(),
                System.currentTimeMillis() - start);

        ReportGenerateResult result = new ReportGenerateResult();
        result.setReportNo(reportNo);
        result.setCustomerId(customerId);
        result.setCustomerName(customerName);
        result.setReportTitle(reportTitle);
        result.setBlockTotal(blocks.size());
        result.setContentTotal(instances.size());
        result.setContentEmpty(emptyCount);
        result.setContentHidden(hiddenCount);
        result.setRiskTotal(risks.size());
        result.setSuccess(true);
        result.setCostMs(System.currentTimeMillis() - start);
        return result;
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
    public Page<Report> page(int page, int size, String customerId) {
        Page<Report> pager = new Page<>(page, size);
        return reportMapper.selectPage(pager, Wrappers.<Report>lambdaQuery()
                .eq(StringUtils.hasText(customerId), Report::getCustomerId, customerId)
                .orderByDesc(Report::getUpdatedAt));
    }

    @Override
    public List<ReportVersionVO> versions(String checkTaskNo) {
        if (!StringUtils.hasText(checkTaskNo)) {
            return new ArrayList<>();
        }
        // 返回：进行中（000，"新报告生成中"）+ 已完成（888 且已赋予版本号）+ 失败（999，供前端提示生成失败）；
        // 失败记录由前端过滤、不进入版本下拉。
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

        // 4) 异步触发生成（不阻塞接口返回；生成失败由 generate 内部置 999 并落 failReason）
        final String newReportNo = report.getReportNo();
        CompletableFuture.runAsync(() -> generate(newReportNo));

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
            Long running = warningBatchMapper.selectCount(
                    Wrappers.<AppReportWarningAdviceBatch>lambdaQuery()
                            .eq(AppReportWarningAdviceBatch::getReportNo, reportNo)
                            .eq(AppReportWarningAdviceBatch::getStatus, ANALYSIS_STATUS_RUNNING));
            if (running != null && running > 0) {
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
                batchId, reportNo, analysis.getId(), operatorName);
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
     * 实例化一个内容块：取加工产物 → 标题兜底 → 建锚点与跳转 → 快照模板结构性字段
     */
    private AppReportContentInstance buildInstance(String reportNo, String customerId, String customerName,
                                                   String reportTitle,
                                                   AppReportContentBlock block,
                                                   Map<String, AppReportCatalog> catalogMap) {
        AppReportCatalog catalog = StringUtils.hasText(block.getCatalogCode())
                ? catalogMap.get(block.getCatalogCode()) : null;
        String catalogName = catalog == null ? null : catalog.getCatalogName();

        // ① 前置加工产物（由数据加工链路提供，本服务不取数）
        ReportGenerateContext context = new ReportGenerateContext();
        context.setReportNo(reportNo);
        context.setCustomerId(customerId);
        context.setCustomerName(customerName);
        context.setCatalogName(catalogName);
        context.setBlock(block);
        ContentPayload payload = contentProvider.provide(context);

        String content = payload == null ? null : payload.getContent();
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
        return instance;
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
     * 生成 AI 风险明细（1:1）
     * <p>riskDesc 取正文内容同一份文案：正文 content 为准、列表为副本。</p>
     */
    private AppReportAiRisk buildRisk(AppReportContentInstance instance, AppReportContentBlock block, Set<String> agentCodes) {
        if (!agentCodes.add(block.getAgentCode())) {
            throw new ReportGenerateException("智能体编码在报告内重复，要求报告内唯一：" + block.getAgentCode());
        }
        AppReportAiRisk risk = new AppReportAiRisk();
        risk.setReportNo(instance.getReportNo());
        risk.setCustomerId(instance.getCustomerId());
        risk.setCustomerName(instance.getCustomerName());
        risk.setBlockCode(block.getBlockCode());
        risk.setAgentCode(block.getAgentCode());
        risk.setRuleName(block.getBlockName());
        risk.setRiskDesc(instance.getContent());
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

    /** 模板配置错误一律 fail-fast，避免生成残缺报告 */
    private void validateTemplate(List<AppReportContentBlock> blocks, Map<String, AppReportCatalog> catalogMap) {
        Set<String> ruleAgentCodes = new HashSet<>();
        for (AppReportContentBlock block : blocks) {
            if (!StringUtils.hasText(block.getFillType())) {
                throw new ReportGenerateException("内容块缺少填充类型（fillType）：" + block.getBlockCode());
            }
            boolean reportLevel = !StringUtils.hasText(block.getCatalogCode());
            if (!reportLevel && !catalogMap.containsKey(block.getCatalogCode())) {
                throw new ReportGenerateException("内容块所属目录不存在或已停用：block="
                        + block.getBlockCode() + "，catalog=" + block.getCatalogCode());
            }
            if (StringUtils.hasText(block.getAnalysisType()) && !FILL_TEXT.equalsIgnoreCase(block.getFillType())) {
                throw new ReportGenerateException("分析文本类型仅文本类内容块可配置：block=" + block.getBlockCode());
            }
            if (!StringUtils.hasText(block.getBlockName())) {
                throw new ReportGenerateException("内容块缺少名称（blockName）：" + block.getBlockCode());
            }
            if (!isRuleBlock(block)) {
                continue;
            }
            if (!StringUtils.hasText(block.getAgentCode())) {
                throw new ReportGenerateException("经验规则类内容块缺少智能体编码（agentCode）：" + block.getBlockCode());
            }
            if (!ruleAgentCodes.add(block.getAgentCode())) {
                throw new ReportGenerateException("智能体编码在模板内重复，要求报告内唯一：" + block.getAgentCode());
            }
        }
    }

    private boolean isRuleBlock(AppReportContentBlock block) {
        return FILL_TEXT.equalsIgnoreCase(block.getFillType())
                && ANALYSIS_RULE.equalsIgnoreCase(block.getAnalysisType());
    }

    /* ==================== 状态流转与渲染装配 ==================== */

    private void markStatus(String reportNo, String status) {
        reportMapper.update(null, Wrappers.<Report>lambdaUpdate()
                .eq(Report::getReportNo, reportNo)
                .set(Report::getStatus, status)
                .set(Report::getUpdatedAt, new Date()));
    }

    /** 写入/清空失败原因（成功时传 null 清空历史失败原因） */
    private void markFailReason(String reportNo, String failReason) {
        reportMapper.update(null, Wrappers.<Report>lambdaUpdate()
                .eq(Report::getReportNo, reportNo)
                .set(Report::getFailReason, failReason)
                .set(Report::getUpdatedAt, new Date()));
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
