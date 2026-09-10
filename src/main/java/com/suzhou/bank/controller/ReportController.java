package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.report.ReportGenerateException;
import com.suzhou.bank.report.model.ReportDetailVO;
import com.suzhou.bank.report.model.ReportGenerateResult;
import com.suzhou.bank.report.service.ReportGenerateService;
import com.suzhou.bank.service.report.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 贷后管理报告接口
 * <p>提供报告生成、查询和删除功能。
 * 报告基于 Know-Kit 分析结果和原始指标数据生成 H5 交互式页面，
 * 生成时拍摄数据快照（dataSnapshot），保证历史报告内容不可变。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/report")
@RequiredArgsConstructor
public class ReportController {
    private final ReportService service;

    /** 模板驱动的新报告生成服务（与既有 ReportService 完全独立） */
    private final ReportGenerateService generateService;

    /**
     * 一键生成报告：采集最新数据 → Know-Kit 分析 → 生成 HTML 报告
     * <p>将数据采集、智能分析和报告生成串联为单次请求。</p>
     *
     * @param customerId 客户ID
     * @return 生成的报告记录
     */
    @PostMapping("/create")
    public Result<Report> create(@RequestParam Long customerId) {
        return Result.ok(service.create(customerId));
    }

    /**
     * 生成贷后管理报告（基于已有分析结果）
     * <p>根据客户信息和 Know-Kit 分析结果生成报告，
     * 报告内容包含数据快照和 H5 交互式 HTML。</p>
     *
     * @param customerId    客户ID
     * @param knowKitTaskId Know-Kit 分析任务ID
     * @return 生成的报告记录
     */
    @PostMapping("/generate")
    public Result<Report> generate(@RequestParam Long customerId, @RequestParam Long knowKitTaskId) { return Result.ok(service.generate(customerId, knowKitTaskId)); }

    /**
     * 报告列表分页查询
     *
     * @param page       页码
     * @param size       每页条数
     * @param customerId 按客户ID筛选，可选
     * @return 报告分页数据
     */
    @GetMapping("/page")
    public Result<Page<Report>> page(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) Long customerId) { return Result.ok(service.page(page, size, customerId)); }

    /**
     * 查询报告详情
     *
     * @param id 报告ID
     * @return 报告信息（含数据快照JSON）
     */
    @GetMapping("/{id}")
    public Result<Report> getById(@PathVariable Long id) { return Result.ok(service.getById(id)); }

    /**
     * 获取报告的 H5 HTML 内容
     *
     * @param id 报告ID
     * @return 报告 HTML 字符串
     */
    @GetMapping("/{id}/html")
    public Result<String> getHtml(@PathVariable Long id) { return Result.ok(service.getReportHtml(id)); }

    /**
     * 删除报告
     *
     * @param id 报告ID
     * @return 操作结果
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) { service.delete(id); return Result.ok(); }

    /**
     * 获取报告结构化数据（客户+分域指标+规则命中）
     * <p>供前端渲染三栏式交互报告页使用。</p>
     *
     * @param customerId 客户ID
     * @return 报告结构化数据
     */
    @GetMapping("/data/{customerId}")
    public Result<Map<String, Object>> getReportData(@PathVariable Long customerId) {
        return Result.ok(service.getReportData(customerId));
    }

    /* ==================================================================================
     * 以下为"模板驱动的报告实例生成"接口（新增，独立命名空间 /api/report/instance/**）
     * 生成逻辑只处理模板表 + 实例表：模板层（目录 + 内容块）→ 实例层（内容实例 + AI 风险）。
     * 报告记录（app_report_info）由上游预生成，本接口不负责发起报告。
     * 与上面既有的报告生成逻辑互不影响。
     * ================================================================================== */

    /**
     * 生成报告实例（含状态流转，定时任务调用本接口）
     * <p>报告记录须已存在：置 000-进行中 → 按模板加工内容实例与 AI 风险明细
     * → 置 888-已完成；加工抛异常则置 999-失败，且实例数据整体回滚。</p>
     * <p>本方法只是 HTTP 入口，定时任务也可直接调用 {@code ReportGenerateService.generate(reportNo)}。</p>
     *
     * @param reportNo 报告编号（对应 app_report_info.reportNo）
     * @return 生成结果（内容块/实例/空内容/风险各项统计）
     */
    @PostMapping("/instance/generate")
    public Result<ReportGenerateResult> generateInstance(@RequestParam String reportNo) {
        try {
            return Result.ok(generateService.generate(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 纯加工报告实例（不改状态，便于联调与失败重跑）
     * <p>只执行"模板表 → 实例表"的落地，报告状态由调用方自行维护。
     * 可重复执行：会先清理该报告下已有实例，不会触发唯一键冲突。</p>
     *
     * @param reportNo 报告编号
     * @return 加工结果
     */
    @PostMapping("/instance/process")
    public Result<ReportGenerateResult> processInstance(@RequestParam String reportNo) {
        try {
            return Result.ok(generateService.process(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 查询模板化报告详情（三栏式渲染数据源）
     * <p>返回报告头内容块、目录树（含各目录内容块与空数据策略）、AI 风险列表与风险统计，
     * 前端按 block.emptyStrategy 决定整块隐藏或显示占位。</p>
     *
     * @param reportNo 报告编号
     * @return 报告详情
     */
    @GetMapping("/instance/{reportNo}")
    public Result<ReportDetailVO> getInstanceDetail(@PathVariable String reportNo) {
        try {
            return Result.ok(generateService.detail(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }
}
