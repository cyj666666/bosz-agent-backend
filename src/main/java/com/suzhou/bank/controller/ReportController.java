package com.suzhou.bank.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.ReportService;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 贷后管理报告接口（模板驱动的报告实例生成）
 * <p>生成逻辑只处理模板表 + 实例表：模板层（目录 + 内容块）→ 实例层（内容实例 + AI 风险）。
 * 报告记录（report 表）由上游预生成，本接口不负责发起报告。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/report")
@RequiredArgsConstructor
public class ReportController {

    /** 报告服务（模板驱动的报告实例生成） */
    private final ReportService reportService;

    /**
     * 生成报告实例（含状态流转，定时任务调用本接口）
     * <p>报告记录须已存在：置 000-进行中 → 按模板加工内容实例与 AI 风险明细 → 置 888-已完成。
     * 生成过程不会抛异常：任何技术类/业务类异常都会被捕获、记日志、置 999-失败并落 failReason，
     * 结果通过 {@code success=false + failReason} 返回给调用方。</p>
     * <p>本方法只是 HTTP 入口，定时任务也可直接调用 {@code ReportService.generate(reportNo)}。</p>
     *
     * @param reportNo 报告编号（对应 report.report_no）
     * @return 生成结果（success 标志 + failReason + 各项统计）
     */
    @PostMapping("/instance/generate")
    public Result<ReportGenerateResult> generateInstance(@RequestParam String reportNo) {
        try {
            return Result.ok(reportService.generate(reportNo));
        } catch (Throwable e) {
            // 兜底：生成服务已保证不抛异常，此分支仅防御极端情况
            return Result.fail(e.getMessage() == null ? "报告生成异常" : e.getMessage());
        }
    }

    /**
     * 纯加工报告实例（不改状态，便于联调）
     * <p>只执行"模板表 → 实例表"的落地，报告状态由调用方自行维护。
     * 不做重跑清理：同一 reportNo 重复加工会触发实例表唯一键冲突。
     * 同样不抛异常：失败通过 success=false + failReason 返回。</p>
     *
     * @param reportNo 报告编号
     * @return 加工结果
     */
    @PostMapping("/instance/process")
    public Result<ReportGenerateResult> processInstance(@RequestParam String reportNo) {
        try {
            return Result.ok(reportService.process(reportNo));
        } catch (Throwable e) {
            return Result.fail(e.getMessage() == null ? "报告加工异常" : e.getMessage());
        }
    }

    /**
     * 报告记录分页查询（报告列表页）
     * <p>查 report，返回的 reportNo 即详情接口的入参。</p>
     *
     * @param page       页码
     * @param size       每页条数
     * @param customerId 按客户编号筛选，可选
     * @return 报告记录分页数据
     */
    @GetMapping("/instance/page")
    public Result<Page<Report>> instancePage(@RequestParam(defaultValue = "1") int page,
                                             @RequestParam(defaultValue = "10") int size,
                                             @RequestParam(required = false) String customerId) {
        return Result.ok(reportService.page(page, size, customerId));
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
            return Result.ok(reportService.detail(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }
}
