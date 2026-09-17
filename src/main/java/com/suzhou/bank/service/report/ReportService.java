package com.suzhou.bank.service.report;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.service.report.model.ReportAiAnalysisVO;
import com.suzhou.bank.service.report.model.ReportCreateRequest;
import com.suzhou.bank.service.report.model.ReportDetailVO;
import com.suzhou.bank.service.report.model.ReportGenerateResult;
import com.suzhou.bank.service.report.model.ReportPageQuery;
import com.suzhou.bank.service.report.model.ReportRiskEditLogVO;
import com.suzhou.bank.service.report.model.ReportVersionVO;
import com.suzhou.bank.service.report.model.ReportWarningAdviceVO;

import java.util.List;

/**
 * 报告服务（模板驱动的报告实例生成）
 *
 * <p><b>发起口径（外网工程）</b>：行内是「发起落 111 → 生成池定时轮询捞取 → 加工」，
 * 外网没有生成池、也不对接 SSF/ESB，因此 {@link #createReport} 落 111 后会
 * <b>立即异步触发加工</b>（{@link #generate}），{@link #renew} 同理。</p>
 *
 * <p><b>状态流转</b>：111-待开始 → 000-进行中 → <b>888-已完成（唯一终态，同时写入 version）</b>。
 * 999-失败为预留状态，正常链路不再产生（失败也走 888 + {@code fail_reason} 软备注）。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface ReportService {

    /**
     * 生成报告实例（含状态流转；发起/更新报告后由后台线程池调用）
     *
     * <p>流程：校验报告记录与状态 → 置 000-进行中 → 加工（{@link #process(String)}）
     * → 置 888-已完成并写入 version。</p>
     *
     * <p><b>888 是唯一终态</b>：单个内容块加工失败不中断整份报告，原因汇总进
     * {@code fail_reason} 软备注、报告仍置 888（模板缺失/校验不通过/落库失败同理）。
     * 本方法<b>不向外抛异常</b>，失败通过 {@code success=false + failReason} 返回。</p>
     *
     * <p>本方法不声明事务；互斥由上游统一加分布式锁保证。</p>
     *
     * @param reportNo 报告编号（对应 report.report_no）
     * @return 生成结果（各项统计 + 块级失败汇总 + 版本号）
     */
    ReportGenerateResult generate(String reportNo);

    /**
     * 纯加工：按模板生成内容实例与 AI 风险明细（自行管理状态时调用）
     * <p>以模板表为唯一驱动：读模板目录与内容块 → 逐块落实例（结构性字段快照、位置锚点）
     * → analysisType=RULE 的内容块一对一生成风险明细；单块异常只跳过该块并记入软备注。</p>
     * <p>不声明事务。<b>支持重跑</b>：落库前先清该报告的旧实例与风险，同一 reportNo 重复加工
     * 不会撞实例表唯一键。</p>
     * <p>不抛异常：失败时记录日志并返回 success=false + failReason。</p>
     *
     * @param reportNo 报告编号
     * @return 加工结果
     */
    ReportGenerateResult process(String reportNo);

    /**
     * 读取报告详情（三栏式渲染数据源）
     * <p>返回报告头内容块、目录树（含内容块与空数据策略）、AI 风险列表与风险统计。</p>
     *
     * @param reportNo 报告编号
     * @return 报告详情
     */
    ReportDetailVO detail(String reportNo);

    /**
     * 查询某日检流水号（checkTaskNo）下的版本列表（供版本下拉框）
     * <p>包含：进行中（000，即"新报告生成中"）与已完成（888 且已赋予版本号）的版本；
     * 按 id 倒序（最新插入的在前，故进行中的新版本排最前），返回每个版本的
     * reportNo / version / status / updatedAt。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 版本列表（空流水号返回空列表）
     */
    List<ReportVersionVO> versions(String checkTaskNo);

    /**
     * 查询某日检流水号（checkTaskNo）下最新版本的报告详情
     * <p>等价于「取该流水号下最新版本 reportNo → 查详情」，供列表进入详情页时一步到位。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 最新版本报告详情
     */
    ReportDetailVO latest(String checkTaskNo);

    /**
     * 更新报告：在指定日检流水号下新建一份报告（新版本）
     * <p>复制该流水号下最新已完成版本的字段，自动生成随机报告编号，版本号自增 1，
     * 状态置为 000-进行中，并异步触发报告生成（完成后置 888）。</p>
     * <p>若该流水号下已有进行中的报告，直接拒绝（避免重复生成）。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 新建的进行中版本（reportNo / version / status）
     */
    ReportVersionVO renew(String checkTaskNo);

    /**
     * 更新 AI 风险处置状态（采纳 / 无效 / 待处理）
     * <p>行身份为 (reportNo, blockCode)——一条 analysisType=RULE 的内容块 ↔ 一条风险。
     * 只更新 {@code app_report_ai_risk.status}；正文与 riskDesc 均不变
     * （"无效"表示该风险不参与报告，前端渲染时整块隐藏）。</p>
     *
     * @param reportNo  报告编号
     * @param blockCode 内容块编号
     * @param status    ADOPTED-已采纳 / INVALID-已无效 / PENDING-待处理（其它值按 PENDING 处理）
     */
    void updateRiskStatus(String reportNo, String blockCode, String status);

    /**
     * 修改规则类正文内容（同事务同步风险列表文案）
     * <p>更新 {@code app_report_content_instance.content}，并同步
     * {@code app_report_ai_risk.riskDesc}（两者为同一份文案，必须同步，
     * 否则列表文案与正文不一致、且前端正文定位会失配），
     * 同时把该风险状态置为 ADOPTED-已采纳。</p>
     * <p>本方法声明事务：正文与列表副本必须同时成功或同时失败。</p>
     *
     * @param reportNo     报告编号
     * @param blockCode    内容块编号
     * @param content      新的正文内容（HTML 片段，不允许为空）
     * @param operatorNo   操作人账号（写入修改记录）
     * @param operatorName 操作人姓名（写入修改记录；为空时回落账号）
     */
    void updateBlockContent(String reportNo, String blockCode, String content,
                            String operatorNo, String operatorName);

    /**
     * 查询某风险要点的修改记录（归档维度：同日检流水号 + 同风险要点）
     * <p><b>时间正序</b>返回（最早在上），首位是置顶的「原始版本」条目（{@code original=true}，
     * 由最早一条归档的 contentBefore 反推，不参与编号），其后按修改时间从早到晚，
     * 前端按 1、2、3… 编号展示为「N、{修改人} {修改时间} 修改为：{修改后文案}」，
     * 整条列表即一条顺着往下读的时间轴（最新一条在末尾）。</p>
     * <p>归档维度为 checkTaskNo + blockCode（而非 reportNo），故同一日检流水号下
     * 各版本的修改历史会累计展示，跨版本可追溯。</p>
     *
     * @param checkTaskNo 日检流水号
     * @param blockCode   风险要点编号（= 内容块编号）
     * @return 修改记录列表（无记录返回空列表）
     */
    List<ReportRiskEditLogVO> editHistory(String checkTaskNo, String blockCode);

    /**
     * 触发一次 AI 全文分析（前端手动触发，后台异步执行）
     * <p>先落一条 {@code RUNNING} 记录再交给独立线程池执行，
     * 因此接口立刻返回、前端凭 status 轮询。</p>
     * <p><b>并发约束</b>：同一 reportNo 同时只允许一条 RUNNING，
     * 重复触发抛 {@link ReportGenerateException}（消息固定为「全文分析进行中，请稍后再试」）。</p>
     *
     * @param reportNo     报告编号
     * @param operatorNo   触发人账号
     * @param operatorName 触发人姓名（为空回落账号）
     * @return 新建的分析记录（status=RUNNING）
     */
    ReportAiAnalysisVO startAiAnalysis(String reportNo, String operatorNo, String operatorName);

    /**
     * 取「某日检流水号下最新版本报告」的最新一次全文分析
     * <p>前端打开面板时调用：该报告一次都没分析过则返回 {@code null}（前端显示空态 + 开始分析按钮）。</p>
     *
     * @param checkTaskNo 日检流水号
     * @return 最新一次分析；从未分析过返回 null
     */
    ReportAiAnalysisVO latestAiAnalysis(String checkTaskNo);

    /**
     * 查某份报告的全部全文分析记录（保留多次，按 id 倒序 —— 最新在上）
     *
     * @param reportNo 报告编号
     * @return 分析记录列表（无记录返回空列表）
     */
    List<ReportAiAnalysisVO> aiAnalysisList(String reportNo);

    /**
     * 查单次全文分析详情
     *
     * @param id app_report_ai_analysis.id
     * @return 分析记录；不存在返回 null
     */
    ReportAiAnalysisVO aiAnalysisDetail(Long id);

    /**
     * 重新分析（失败后重试或对同一报告再跑一次）
     * <p>语义等同 {@link #startAiAnalysis} —— 每次都新增一条记录、保留历史，
     * 不做原地覆盖。</p>
     *
     * @param reportNo     报告编号
     * @param operatorNo   触发人账号
     * @param operatorName 触发人姓名
     * @return 新建的分析记录（status=RUNNING）
     */
    ReportAiAnalysisVO retryAiAnalysis(String reportNo, String operatorNo, String operatorName);

    /**
     * 触发一次 AI 预警建议生成（前端手动触发，后台异步执行）
     *
     * <p>先落一条 {@code RUNNING} 批次再交给独立线程池执行，因此接口立刻返回、前端凭 status 轮询。</p>
     *
     * <p><b>AI 全文分析结论是可选素材、不是前置条件</b>：该报告已有成功的全文分析时，
     * 自动把结论附进素材并记下 {@code analysisId}（供追溯本次定级参考了哪一版分析）；
     * 没有则只用报告正文 + 风险要点清单，<b>不阻断</b>。</p>
     *
     * <p><b>并发约束</b>：同一 reportNo 同时只允许一条 RUNNING 批次，
     * 重复触发抛 {@link ReportGenerateException}（消息固定为「预警建议生成中，请稍后再试」）。</p>
     *
     * @param reportNo     报告编号
     * @param operatorNo   触发人账号
     * @param operatorName 触发人姓名（为空回落账号）
     * @return 新建的批次（status=RUNNING）
     */
    ReportWarningAdviceVO startWarningAdvice(String reportNo, String operatorNo, String operatorName);

    /**
     * 查某份报告最新一批预警建议（含明细与红橙黄统计）
     *
     * @param reportNo 报告编号
     * @return 最新批次；从未生成过返回 null
     */
    ReportWarningAdviceVO latestWarningAdvice(String reportNo);

    /**
     * 更新某条预警建议的处理状态（采纳 / 无效 / 恢复待处理）
     * <p>只改处理状态与处理人、处理时间，预警信号内容本身不变。</p>
     *
     * @param adviceId     预警建议明细ID（app_report_warning_advice.id）
     * @param status       目标状态：ADOPTED / INVALID / PENDING
     * @param operatorNo   操作人账号
     * @param operatorName 操作人姓名
     */
    void updateWarningAdviceStatus(Long adviceId, String status, String operatorNo, String operatorName);

    /**
     * 一键串行触发：全文分析 → 预警建议（前端「智能体分析」按钮的唯一入口）
     *
     * <p>做法：先在同一个锁里做<b>链级防重</b>（该 reportNo 不能有进行中的全文分析、
     * 也不能有排队中或进行中的预警建议批次），随后预插一条 {@code PENDING} 预警建议批次，
     * 再复用 {@link #startAiAnalysis} 启动全文分析。全文分析结束（成功或失败）后由
     * {@link com.suzhou.bank.service.report.ai.ReportAiChainListener} 续接预警建议。</p>
     *
     * <p>预插批次一物两用：既让前端立刻看到整条链在跑，也是「链式触发」区别于
     * 「单独触发全文分析」的判据（单独触发不会预插，因此不会误启预警建议）。</p>
     *
     * <p>全文分析启动失败时会回滚掉预插的批次，不留悬挂的 PENDING 记录。</p>
     *
     * @param reportNo     报告编号
     * @param operatorNo   触发人账号
     * @param operatorName 触发人姓名（为空回落账号）
     * @return 新建的全文分析记录（status=RUNNING）；预警建议批次已排队（status=PENDING）
     */
    ReportAiAnalysisVO startAiChain(String reportNo, String operatorNo, String operatorName);

    /**
     * 续接预警建议（<b>仅由 {@link com.suzhou.bank.service.report.ai.ReportAiChainListener} 调用</b>）
     *
     * <p>把该报告下最新的 {@code PENDING} 批次翻成 {@code RUNNING} 并投递执行。
     * 查不到 PENDING 批次时<b>什么也不做</b> —— 说明这次全文分析是单独触发的，不属于任何链。</p>
     *
     * @param reportNo   报告编号
     * @param analysisId 本次全文分析记录 id；全文分析失败时也可能为空（软依赖，照样续接）
     */
    void launchChainedWarningAdvice(String reportNo, Long analysisId);

    /**
     * 报告记录分页查询（报告列表页用，支持全部列检索）
     * <p>直接查 report，供列表页展示并跳转到详情。检索条件见 {@link ReportPageQuery}，
     * 条件全空即查全部；返回值带 {@code total} 供分页栏展示总条数。</p>
     *
     * @param query 检索条件 + 分页参数
     * @return 报告记录分页数据
     */
    Page<Report> page(ReportPageQuery query);

    /**
     * 发起报告：手工创建一条报告记录并<b>立即异步触发加工</b>（列表页「发起报告」）
     *
     * <p>两步：① 落 report 主表，状态置 {@code 111}（待开始）—— {@code reportNo} <b>填了就用填的</b>
     * （对齐行内「传入则直接使用、跳过取号」），留空则服务端生成（RPT+时间戳+随机数）；
     * {@code userNo} 取当前登录人；{@code version} 留空，等置 888 时再按流水号取值写入。
     * ② 提交到报告生成线程池执行 {@link #generate(String)}，状态随之流转 111 → 000 → 888。</p>
     *
     * <p><b>本方法立即返回</b>（不等待加工完成）：加工是逐块取数 + 调大模型的长耗时过程，
     * 同步跑会让接口 HTTP 超时。调用方拿到的报告记录通常还是 111 或 000，
     * 需按 {@code status} 判断，完成后才可进详情页。</p>
     *
     * <p><b>防重复</b>：同一日检流水号下<b>不允许重复发起</b>（会让版本序列混乱），
     * 已存在时抛异常提示改用「更新报告」。</p>
     *
     * <p><b>失败兜底</b>：任务提交失败（如线程池已关闭）时不会留下永远 111 的记录 ——
     * 直接置 888 并落 {@code failReason} 软备注（888 是唯一终态），返回值里的 status 也是 888。</p>
     *
     * @param request      业务入参（客户编号 / 客户名称 / 日检流水号 / 报告标题 / 报告类型 / 报告编号(选填)）
     * @param operatorNo   发起人账号（写入 user_no）
     * @param operatorName 发起人姓名（仅日志用）
     * @return 新建的报告记录（加工异步进行，status 多为 111；提交失败时为 888 且带 failReason）
     */
    Report createReport(ReportCreateRequest request, String operatorNo, String operatorName);
}
