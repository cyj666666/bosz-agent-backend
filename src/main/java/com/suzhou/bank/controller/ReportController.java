package com.suzhou.bank.controller;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.api.dto.CreditShareUrlRequest;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.entity.SysUser;
import com.suzhou.bank.mapper.SysUserMapper;
import com.suzhou.bank.service.report.ReportGenerateException;
import com.suzhou.bank.service.report.ReportService;
import com.suzhou.bank.service.report.mock.ReportShareUrlMockService;
import com.suzhou.bank.service.report.model.ReportAiAnalysisVO;
import com.suzhou.bank.service.report.model.ReportBlockContentRequest;
import com.suzhou.bank.service.report.model.ReportCreateRequest;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import com.suzhou.bank.service.report.model.ReportPageQuery;
import com.suzhou.bank.service.report.model.ReportRiskEditLogVO;
import com.suzhou.bank.service.report.model.ReportRiskStatusRequest;
import com.suzhou.bank.service.report.model.ReportVersionVO;
import com.suzhou.bank.service.report.model.ReportWarningAdviceStatusRequest;
import com.suzhou.bank.service.report.model.ReportWarningAdviceVO;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import javax.servlet.http.HttpServletRequest;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * 贷后管理报告接口（模板驱动的报告实例生成）
 *
 * <p>生成逻辑只处理模板表 + 实例表：模板层（目录 + 内容块）→ 实例层（内容实例 + AI 风险）。</p>
 *
 * <p><b>本工程的发起口径</b>：行内是「发起落 111 → 生成池定时轮询捞取 → 加工」，
 * 外网没有生成池、也不对接 SSF/ESB，因此 {@code POST /instance/create}（列表页「发起报告」）
 * 落表后会<b>立即异步触发加工</b>，报告状态自行流转 111 → 000 → <b>888（唯一终态）</b>，
 * 不需要再单独调用 {@code /instance/generate}。后者保留，供联调/运维手工重跑。</p>
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

    /** 用户表 Mapper：仅用于把操作账号解析成姓名，写进修改记录 */
    private final SysUserMapper sysUserMapper;

    /** 🔴 外网专用 MOCK：链接溯源「换一次性链接」的模拟实现（行内没有、也不该有 → 见类尾注释） */
    private final ReportShareUrlMockService reportShareUrlMockService;

    /** 🔴 外网专用：mock 开关（默认 false ⇒ 接口返回明确错误，而不是 404） */
    @Value("${credit.share.mock-enabled:false}")
    private boolean shareUrlMockEnabled;

    /** 🔴 外网专用：mock 链接的服务器基址（留空 ⇒ 按当前请求的 host:port 推导） */
    @Value("${credit.share.mock-base-url:}")
    private String shareUrlMockBaseUrl;

    /**
     * 生成报告实例（含状态流转，手工重跑 / 运维调用本接口）
     * <p>报告记录须已存在：置 000-进行中 → 按模板加工内容实例与 AI 风险明细 → 置 888-已完成
     * （同时写入 version）。<b>列表页「发起报告」已自动触发本流程</b>，本接口保留给联调/运维手工重跑。</p>
     * <p><b>888 是唯一终态</b>：生成过程不会抛异常，模板缺失/校验不通过/单块加工失败/落库失败都会被捕获，
     * 原因汇总进 {@code failReason} 软备注，报告仍置 888（部分内容块无内容），结果以
     * {@code success=false + failReason} 返回。</p>
     * <p>本方法只是 HTTP 入口，后台线程池直接调用的是 {@code ReportService.generate(reportNo)}。</p>
     *
     * @param reportNo 报告编号（对应 report.report_no）
     * @return 生成结果（success 标志 + failReason + 各项统计 + version）
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
     * <b>支持重跑</b>：落库前会先清掉该报告的旧实例与 AI 风险，同一 reportNo 重复加工不会撞唯一键。</p>
     * <p>同样不抛异常：失败通过 success=false + failReason 返回。</p>
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
     * 报告记录分页查询（报告列表页，支持全部列检索）
     *
     * <p>检索条件全部可选、全空即查全部：文本列按「包含」匹配，{@code status} 精确匹配，
     * {@code createdBegin/End} 与 {@code updatedBegin/End} 为日期闭区间（yyyy-MM-dd，含当天）。
     * 返回体带 {@code total}，供分页栏展示总条数。</p>
     *
     * @param query 检索条件 + 分页参数（页码/每页条数 + 各列条件）
     * @return 报告记录分页数据
     */
    @GetMapping("/instance/page")
    public Result<Page<Report>> instancePage(ReportPageQuery query) {
        return Result.ok(reportService.page(query));
    }

    /**
     * 发起报告（列表页「发起报告」弹框）
     *
     * <p>落一条 report 主表记录（status=111 待开始）后<b>立即异步触发加工</b>：
     * 按模板层（目录 + 内容块）配置加工出内容实例与 AI 风险明细，状态流转
     * 111 → 000 → <b>888（唯一终态，同时写入 version）</b>。内容块级失败不中断整份报告，
     * 原因汇总进 {@code failReason} 软备注、报告仍置 888，前端在详情页/列表 tooltip 可见。</p>
     *
     * <p><b>接口立即返回、不等待加工完成</b>（加工是长耗时过程，接大模型后为分钟级），
     * 因此返回值里的 status 通常还是 111；前端刷新列表看状态流转结果。
     * {@code reportNo} <b>选填</b> —— 填了就用填的，留空由服务端生成；
     * {@code userNo} 由服务端补全。<b>防重复</b>：同一日检流水号下只挡在途记录（111/000），
     * 已完成（888）的不挡 —— 可对着同一流水号再发起，自然堆出 V1、V2…</p>
     *
     * @param request {customerId, customerName, checkTaskNo, reportTitle, reportType, reportNo(选填)}
     * @return 新建的报告记录（加工异步进行）
     */
    @PostMapping("/instance/create")
    public Result<Report> createReport(@RequestBody ReportCreateRequest request,
                                       HttpServletRequest httpRequest) {
        try {
            return Result.ok(reportService.createReport(
                    request, currentUsername(httpRequest), currentRealName(httpRequest)));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
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
    public Result<Void> updateBlockContent(@RequestBody ReportBlockContentRequest request,
                                           HttpServletRequest httpRequest) {
        try {
            reportService.updateBlockContent(request.getReportNo(), request.getBlockCode(), request.getContent(),
                    currentUsername(httpRequest), currentRealName(httpRequest));
            return Result.ok();
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 查询某风险要点的修改记录（详情页「修改记录」弹窗数据源）
     * <p>归档维度为「同日检流水号 + 同风险要点」而非单个报告编号，
     * 因此同一日检流水号下各版本的修改历史会累计返回，跨版本可追溯；
     * <b>按修改时间正序（最早在上）</b>，首位是置顶的「原始版本」条目（original=true，不参与编号），
     * 前端按 1、2、3… 编号展示。</p>
     *
     * @param checkTaskNo 日检流水号
     * @param blockCode   风险要点编号（= 内容块编号）
     * @return 修改记录列表（无记录返回空列表）
     */
    @GetMapping("/instance/block/edit-history")
    public Result<List<ReportRiskEditLogVO>> blockEditHistory(@RequestParam String checkTaskNo,
                                                              @RequestParam String blockCode) {
        try {
            return Result.ok(reportService.editHistory(checkTaskNo, blockCode));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /* ===================== AI 全文分析（前端手动触发，后台异步执行） ===================== */

    /**
     * 取**某份报告**（reportNo）的最新一次全文分析
     * <p>前端打开「AI分析全文」面板、切换报告版本时调用。从未分析过返回 data=null，
     * 前端据此显示空态与「开始分析」按钮。</p>
     *
     * <p>🔴 入参由 checkTaskNo 改为 <b>reportNo</b>（2026-09-19），与
     * {@code /instance/warning-advice} 同口径 —— 全文分析按报告版本跑，按流水号取
     * 「最新已完成版本」会让历史版本页面显示新版本的分析结果。</p>
     *
     * @param reportNo 报告编号
     * @return 该报告最新一次分析（RUNNING/DONE/FAILED）；从未分析过为 null
     */
    @GetMapping("/instance/ai-analysis")
    public Result<ReportAiAnalysisVO> latestAiAnalysis(@RequestParam String reportNo) {
        try {
            return Result.ok(reportService.latestAiAnalysis(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 查某份报告的全部全文分析记录（保留多次，最新在上）
     *
     * @param reportNo 报告编号
     * @return 分析记录列表
     */
    @GetMapping("/instance/ai-analysis/list")
    public Result<List<ReportAiAnalysisVO>> aiAnalysisList(@RequestParam String reportNo) {
        try {
            return Result.ok(reportService.aiAnalysisList(reportNo));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 触发一次全文分析（异步）
     * <p><b>同一 reportNo 同时只允许一次进行中</b>：重复触发返回
     * {@code code!=200}，message 为「全文分析进行中，请稍后再试」。</p>
     *
     * @param body { reportNo }
     * @return 新建的分析记录（status=RUNNING）
     */
    @PostMapping("/instance/ai-analysis/generate")
    public Result<ReportAiAnalysisVO> startAiAnalysis(@RequestBody Map<String, String> body,
                                                     HttpServletRequest httpRequest) {
        String reportNo = body == null ? null : body.get("reportNo");
        try {
            return Result.ok(reportService.startAiAnalysis(
                    reportNo, currentUsername(httpRequest), currentRealName(httpRequest)));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 重新分析（失败重试 / 对同一报告再跑一次）
     * <p>语义等同触发：新增一条记录、保留历史，不覆盖旧结果。</p>
     *
     * @param body { reportNo }
     * @return 新建的分析记录（status=RUNNING）
     */
    @PostMapping("/instance/ai-analysis/retry")
    public Result<ReportAiAnalysisVO> retryAiAnalysis(@RequestBody Map<String, String> body,
                                                     HttpServletRequest httpRequest) {
        String reportNo = body == null ? null : body.get("reportNo");
        try {
            return Result.ok(reportService.retryAiAnalysis(
                    reportNo, currentUsername(httpRequest), currentRealName(httpRequest)));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 查单次全文分析详情
     *
     * @param id app_report_ai_analysis.id
     * @return 分析记录；不存在返回 data=null
     */
    @GetMapping("/instance/ai-analysis/{id}")
    public Result<ReportAiAnalysisVO> aiAnalysisDetail(@PathVariable Long id) {
        try {
            return Result.ok(reportService.aiAnalysisDetail(id));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 触发一次 AI 预警建议生成（后台异步执行）
     *
     * <p>该报告已有成功的全文分析时会把结论一并作为素材（更准），没有也能直接生成；
     * 同一报告同时只允许一个进行中的批次。</p>
     *
     * @param body {reportNo}
     * @return 新建批次（status=RUNNING，明细为空）
     */
    @PostMapping("/instance/warning-advice/generate")
    public Result<ReportWarningAdviceVO> startWarningAdvice(@RequestBody Map<String, String> body,
                                                           HttpServletRequest httpRequest) {
        String reportNo = body == null ? null : body.get("reportNo");
        try {
            return Result.ok(reportService.startWarningAdvice(
                    reportNo, currentUsername(httpRequest), currentRealName(httpRequest)));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 一键串行：全文分析 → 预警建议（前端「智能体分析」按钮的唯一入口）
     *
     * <p>先预插一条 {@code PENDING} 的预警建议批次（前端立刻能看到整条链在跑），
     * 再启动全文分析；全文分析结束（成功或失败）后由监听器自动续接预警建议。</p>
     *
     * <p><b>链级防重</b>：该报告存在进行中的全文分析、或排队中/进行中的预警建议批次时，
     * 直接返回「分析进行中，请稍后再试」。</p>
     *
     * @param body {reportNo}
     * @return 新建的全文分析记录（status=RUNNING）；预警建议批次已排队
     */
    @PostMapping("/instance/ai-chain/generate")
    public Result<ReportAiAnalysisVO> startAiChain(@RequestBody Map<String, String> body,
                                                   HttpServletRequest httpRequest) {
        String reportNo = body == null ? null : body.get("reportNo");
        try {
            return Result.ok(reportService.startAiChain(
                    reportNo, currentUsername(httpRequest), currentRealName(httpRequest)));
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 取某份报告最新一批预警建议（含明细与红橙黄统计）
     *
     * @param reportNo 报告编号
     * @return 最新批次；从未生成过返回 data=null
     */
    @GetMapping("/instance/warning-advice")
    public Result<ReportWarningAdviceVO> latestWarningAdvice(@RequestParam String reportNo) {
        return Result.ok(reportService.latestWarningAdvice(reportNo));
    }

    /**
     * 更新某条预警建议的处理状态（采纳 / 无效 / 恢复待处理）
     *
     * @param request {id, status}
     */
    @PostMapping("/instance/warning-advice/status")
    public Result<Void> updateWarningAdviceStatus(@RequestBody ReportWarningAdviceStatusRequest request,
                                                  HttpServletRequest httpRequest) {
        try {
            reportService.updateWarningAdviceStatus(
                    request.getId(), request.getStatus(),
                    currentUsername(httpRequest), currentRealName(httpRequest));
            return Result.ok();
        } catch (ReportGenerateException e) {
            return Result.fail(e.getMessage());
        }
    }

    /** 取当前登录账号（AuthInterceptor 已写入 request attribute） */
    private String currentUsername(HttpServletRequest request) {
        Object username = request == null ? null : request.getAttribute("username");
        return username == null ? null : String.valueOf(username);
    }

    /** 取当前登录用户姓名：优先 sys_user.real_name，取不到回落账号 */
    private String currentRealName(HttpServletRequest request) {
        Object userId = request == null ? null : request.getAttribute("userId");
        if (userId == null) {
            return null;
        }
        try {
            SysUser user = sysUserMapper.selectOne(Wrappers.<SysUser>lambdaQuery()
                    .eq(SysUser::getId, Long.valueOf(String.valueOf(userId)))
                    .last("LIMIT 1"));
            if (user != null && StringUtils.hasText(user.getRealName())) {
                return user.getRealName();
            }
        } catch (Exception e) {
            // 解析姓名失败不影响主流程，回落到账号
        }
        return currentUsername(request);
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

    /* ==========================================================================================
     * 🔴🔴 外网专用 MOCK —— 链接溯源「换一次性链接」（2026-09-21）
     * ------------------------------------------------------------------------------------------
     * ⛔ **行内不要这段**：行内已有同路径的**真实**接口（行内 `ReportController#shareUrl` +
     *    `CreditShareUrlService`，走信贷 SSF `AuthApi.getPageShareUrlN`）。
     *    往行内同步时**跳过本段** + 跳过 `service/report/mock/**`。
     *
     * 外网没有 SSF ⇒ 这个路径本来只会 **404**，前端点「🔗 溯源」只能看到失败 toast、没法联调。
     * 打开 `credit.share.mock-enabled=true` 之后：
     *   · `pageParams` 走**真实的** `LinkTraceParamBuilder`（真查库，11 个 shareCode 策略）；
     *   · 返回的 `url` 指向本工程 `/api/report/share-url/mock-page` —— 点开即「模拟信贷页面」，
     *     把收到的 shareCode / userId / reportNo / blockCode / guarantorName / pageParams 全部回显。
     * ========================================================================================== */

    /**
     * 链接溯源换链接（**外网 MOCK**）
     *
     * <p>返回值结构与行内一致：`{ url, relativeUrl }`（外网额外带 `mock: "true"`）。
     * 入参契约也与行内一致：`{ userId, shareCode, reportNo, blockCode?, guarantorName?, pageParams? }`。</p>
     *
     * @param body 同行内 `CreditShareUrlRequest`（此处**不加** `@Valid`，便于手工放空字段联调）
     */
    @PostMapping("/share-url")
    public Result<Map<String, String>> shareUrl(@RequestBody(required = false) CreditShareUrlRequest body) {
        if (!shareUrlMockEnabled) {
            return Result.fail("外网未接入信贷 SSF（getPageShareUrlN）：本接口在外网仅为 MOCK。"
                    + "如需前端联调，请把配置 credit.share.mock-enabled 置为 true");
        }
        try {
            CreditShareUrlRequest req = body == null ? new CreditShareUrlRequest() : body;
            String base = StringUtils.hasText(shareUrlMockBaseUrl)
                    ? shareUrlMockBaseUrl.trim().replaceAll("/+$", "")
                    : ServletUriComponentsBuilder.fromCurrentContextPath().build().toUriString();
            return Result.ok(reportShareUrlMockService.getPageShareUrl(base, req.getUserId(),
                    req.getShareCode(), req.getReportNo(), req.getBlockCode(),
                    req.getGuarantorName(), req.getPageParams()));
        } catch (RuntimeException e) {
            return Result.fail(e.getMessage());
        }
    }

    /**
     * 「模拟信贷页面」（**外网 MOCK**）：把上一步送过来的参数原样回显，便于肉眼核对。
     *
     * <p>⛔ 行内没有这个页面 —— 行内换出来的是**真的信贷系统地址**。</p>
     */
    @GetMapping(value = "/share-url/mock-page", produces = "text/html;charset=UTF-8")
    public String shareUrlMockPage(@RequestParam(required = false) Map<String, String> params) {
        return reportShareUrlMockService.mockPageHtml(params == null ? Collections.emptyMap() : params);
    }
}
