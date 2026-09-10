package com.suzhou.bank.report.service.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.suzhou.bank.entity.report.AppReportAiRisk;
import com.suzhou.bank.entity.report.AppReportCatalog;
import com.suzhou.bank.entity.report.AppReportContentBlock;
import com.suzhou.bank.entity.report.AppReportContentInstance;
import com.suzhou.bank.entity.report.AppReportInfo;
import com.suzhou.bank.mapper.report.AppReportAiRiskMapper;
import com.suzhou.bank.mapper.report.AppReportCatalogMapper;
import com.suzhou.bank.mapper.report.AppReportContentBlockMapper;
import com.suzhou.bank.mapper.report.AppReportContentInstanceMapper;
import com.suzhou.bank.mapper.report.AppReportInfoMapper;
import com.suzhou.bank.report.ReportGenerateException;
import com.suzhou.bank.report.model.ReportBlockVO;
import com.suzhou.bank.report.model.ReportCatalogNode;
import com.suzhou.bank.report.model.ReportDetailVO;
import com.suzhou.bank.report.model.ReportGenerateResult;
import com.suzhou.bank.report.model.ReportRiskItem;
import com.suzhou.bank.report.service.ReportGenerateService;
import com.suzhou.bank.report.spi.ContentPayload;
import com.suzhou.bank.report.spi.ReportContentProvider;
import com.suzhou.bank.report.spi.ReportGenerateContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import static com.suzhou.bank.report.model.ReportConstants.*;

/**
 * 模板驱动的报告实例生成服务实现
 * <p>只负责"模板表 + 实例表"的逻辑，不负责报告记录的发起（{@code app_report_info}
 * 由上游预生成，初始状态 111-待开始），与本工程既有报告逻辑完全独立。</p>
 * <p><b>并发与事务约定</b>：本服务<b>不声明事务</b>，也不做"重跑清理"。
 * 互斥由上游统一加分布式锁保证；每次生成的报告编号唯一，
 * 因此重复加工会被实例表的唯一键拦住，不会产生数据错乱。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportGenerateServiceImpl implements ReportGenerateService {

    private final AppReportInfoMapper reportInfoMapper;
    private final AppReportCatalogMapper catalogMapper;
    private final AppReportContentBlockMapper blockMapper;
    private final AppReportContentInstanceMapper instanceMapper;
    private final AppReportAiRiskMapper riskMapper;
    private final ReportContentProvider contentProvider;

    @Override
    public ReportGenerateResult generate(String reportNo) {
        assertReportNoPresent(reportNo);
        AppReportInfo reportInfo = loadReportInfo(reportNo);

        // 已完成的报告不做重复加工
        if (REPORT_STATUS_DONE.equals(reportInfo.getReportStatus())) {
            throw new ReportGenerateException("报告已完成（888），无需重复生成：" + reportNo);
        }

        // 置 000-进行中
        markStatus(reportNo, REPORT_STATUS_RUNNING);
        try {
            ReportGenerateResult result = process(reportNo);
            // 置 888-已完成
            markStatus(reportNo, REPORT_STATUS_DONE);
            result.setReportStatus(REPORT_STATUS_DONE);
            log.info("报告生成成功 reportNo={} 内容实例={} AI风险={} 耗时={}ms",
                    reportNo, result.getContentTotal(), result.getRiskTotal(), result.getCostMs());
            return result;
        } catch (Exception e) {
            // 置 999-失败
            markStatus(reportNo, REPORT_STATUS_FAILED);
            log.error("报告生成失败，已置为 999 reportNo={}", reportNo, e);
            if (e instanceof ReportGenerateException) {
                throw (ReportGenerateException) e;
            }
            throw new ReportGenerateException("报告生成失败：" + e.getMessage());
        }
    }

    @Override
    public ReportGenerateResult process(String reportNo) {
        assertReportNoPresent(reportNo);
        long start = System.currentTimeMillis();

        // ===== 1. 报告记录（上游预生成，此处只读抬头信息） =====
        AppReportInfo reportInfo = loadReportInfo(reportNo);
        String customerId = reportInfo.getCustomerId();
        String customerName = StringUtils.hasText(reportInfo.getCustomerName())
                ? reportInfo.getCustomerName() : "客户" + customerId;
        String reportTitle = StringUtils.hasText(reportInfo.getReportTitle())
                ? reportInfo.getReportTitle() : customerName + "贷后管理定期检查报告";
        String reportDate = reportInfo.getReportDate();

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
            AppReportContentInstance instance = buildInstance(
                    reportNo, customerId, customerName, reportDate, reportTitle, block, catalogMap);
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
        result.setCostMs(System.currentTimeMillis() - start);
        return result;
    }

    @Override
    public ReportDetailVO detail(String reportNo) {
        assertReportNoPresent(reportNo);
        AppReportInfo reportInfo = loadReportInfo(reportNo);

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

        // 空数据策略属于渲染策略，取自模板
        Map<String, String> emptyStrategyMap = new HashMap<>();
        for (AppReportContentBlock block : loadEnabledBlocks()) {
            emptyStrategyMap.put(block.getBlockCode(),
                    StringUtils.hasText(block.getEmptyStrategy()) ? block.getEmptyStrategy() : EMPTY_HIDE);
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
        detail.setReportDate(reportInfo.getReportDate());
        detail.setReportStatus(reportInfo.getReportStatus());
        detail.setGenerateTime(reportInfo.getGenerateTime());
        detail.setHeadBlocks(headBlocks);
        detail.setCatalogs(roots);
        detail.setRisks(risks);
        detail.setRiskPending(pending);
        detail.setRiskAdopted(adopted);
        detail.setRiskInvalid(invalid);
        return detail;
    }

    /* ==================== 单块实例化 ==================== */

    /**
     * 实例化一个内容块：取加工产物 → 标题兜底 → 建锚点与跳转 → 快照模板结构性字段
     */
    private AppReportContentInstance buildInstance(String reportNo, String customerId, String customerName,
                                                   String reportDate, String reportTitle,
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
        context.setReportDate(reportDate);
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
        instance.setRuleName(block.getRuleName());
        instance.setTitleLevel(block.getTitleLevel());
        instance.setSortNo(block.getSortNo());
        instance.setContent(trimToNull(content));
        // ③ 本块位置锚点：其它块要跳过来时用它定位（默认取内容块编号）
        instance.setAnchorCode(block.getBlockCode());
        // ④ 块间跳转锚点（单向、仅用于块内位置跳转）：指向目标块的 anchorCode，
        //    完全由前置加工产物提供，生成器不做任何推断。溯源类的外部跳转链接不在此处，随 content 写入。
        instance.setJumpAnchorCode(payload == null ? null : trimToNull(payload.getJumpAnchorCode()));
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
        risk.setRuleName(block.getRuleName());
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
        reportInfoMapper.update(null, Wrappers.<AppReportInfo>lambdaUpdate()
                .eq(AppReportInfo::getReportNo, reportNo)
                .set(AppReportInfo::getReportStatus, status));
    }

    private AppReportInfo loadReportInfo(String reportNo) {
        AppReportInfo reportInfo = reportInfoMapper.selectOne(
                Wrappers.<AppReportInfo>lambdaQuery().eq(AppReportInfo::getReportNo, reportNo));
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
        vo.setRuleName(instance.getRuleName());
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
