package com.suzhou.bank.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.ReportService;
import com.suzhou.bank.service.report.model.ReportBlockContentRequest;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import com.suzhou.bank.service.report.model.ReportRiskStatusRequest;
import com.suzhou.bank.service.report.model.ReportVersionVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

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
     * 查询某日检流水号（checkTaskNo）下的所有版本（版本下拉框数据源）
     * <p>最新版本在前，返回每个版本的 reportNo / version / status / updatedAt。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 版本列表
     */
    @GetMapping("/instance/versions")
    public Result<List<ReportVersionVO>> instanceVersions(@RequestParam String checkTaskNo) {
        return Result.ok(reportService.versions(checkTaskNo));
    }

    /**
     * 查询某日检流水号（checkTaskNo）下最新版本的报告详情
     * <p>供报告列表进入详情页时一步到位（用 checkTaskNo 而非 reportNo 入参）。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 最新版本报告详情
     */
    @GetMapping("/instance/latest")
    public Result<ReportDetailVO> getLatestDetail(@RequestParam String checkTaskNo) {
        try {
            return Result.ok(reportService.latest(checkTaskNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 更新报告：在某日检流水号下新建一份报告（新版本）
     * <p>复制最新已完成版本字段 + 随机报告编号 + 版本号自增 1，状态置 000-进行中，
     * 后端异步触发生成；生成完成后该版本变为 888。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 新建的进行中版本（reportNo / version / status）
     */
    @PostMapping("/instance/renew")
    public Result<ReportVersionVO> renewInstance(@RequestParam String checkTaskNo) {
        try {
            return Result.ok(reportService.renew(checkTaskNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 更新 AI 风险处置状态（采纳 / 无效 / 待处理）
     * <p>行身份为 (reportNo, blockCode)。只改 app_report_ai_risk.status，不动正文。</p>
     *
     * @param request 请求体（reportNo / blockCode / status）
     * @return 空响应体
     */
    @PostMapping("/instance/risk/status")
    public Result<Void> updateRiskStatus(@RequestBody ReportRiskStatusRequest request) {
        try {
            reportService.updateRiskStatus(request.getReportNo(), request.getBlockCode(), request.getStatus());
            return Result.ok();
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 修改规则类正文内容
     * <p>同事务更新内容实例的 content 与对应 AI 风险的 riskDesc，并把风险状态置为已采纳。</p>
     *
     * @param request 请求体（reportNo / blockCode / content）
     * @return 空响应体
     */
    @PostMapping("/instance/block/content")
    public Result<Void> updateBlockContent(@RequestBody ReportBlockContentRequest request) {
        try {
            reportService.updateBlockContent(request.getReportNo(), request.getBlockCode(), request.getContent());
            return Result.ok();
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
            return Result.ok(reportService.detail(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }
}
