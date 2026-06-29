package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.Report;
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
}
