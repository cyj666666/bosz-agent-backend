package com.suzhou.bank.service.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.mapper.*;
import com.suzhou.bank.service.report.ReportService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 报告服务实现
 * <p>基于 Know-Kit 分析结果和客户指标数据，生成 H5 交互式贷后管理报告。
 * 报告生成时拍摄数据快照，保证历史报告内容不可变。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {

    private final ReportMapper reportMapper;
    private final CustomerMapper customerMapper;
    private final IndicatorDataMapper indicatorMapper;
    private final KnowKitTaskMapper taskMapper;

    /** 基于 Know-Kit 分析结果生成报告 */
    @Override
    public Report generate(Long customerId, Long knowKitTaskId) {
        Customer customer = customerMapper.selectById(customerId);
        if (customer == null) {
            throw new RuntimeException("客户不存在: " + customerId);
        }

        KnowKitTask task = taskMapper.selectById(knowKitTaskId);
        List<IndicatorData> indicators = indicatorMapper.selectList(
                new LambdaQueryWrapper<IndicatorData>().eq(IndicatorData::getCustomerId, customerId));

        // 解析 Know-Kit 分析结果
        JSONObject analysis = null;
        if (task != null && task.getResponseJson() != null && !task.getResponseJson().equals("{}")) {
            try {
                analysis = JSON.parseObject(task.getResponseJson());
            } catch (Exception e) {
                log.warn("Know-Kit 响应JSON解析失败, taskId={}", knowKitTaskId);
            }
        }

        // 生成报告 HTML
        String html = buildReportHtml(customer, indicators, analysis);

        Report report = new Report();
        report.setCustomerId(customerId);
        report.setReportTitle(customer.getCompanyName() + " - 贷后管理报告");
        report.setReportType("贷后管理报告");
        report.setStatus("GENERATED");
        report.setKnowKitTaskId(knowKitTaskId);
        report.setDataSnapshot(JSON.toJSONString(indicators));
        report.setContentHtml(html);
        report.setCreatedAt(new Date());
        report.setUpdatedAt(new Date());
        reportMapper.insert(report);

        log.info("报告已生成, reportId={}, customerId={}, title={}, htmlSize={}",
                report.getId(), customerId, report.getReportTitle(), html.length());
        return report;
    }

    @Override
    public Report getById(Long id) {
        return reportMapper.selectById(id);
    }

    @Override
    public Page<Report> page(int page, int size, Long customerId) {
        LambdaQueryWrapper<Report> w = new LambdaQueryWrapper<>();
        if (customerId != null) w.eq(Report::getCustomerId, customerId);
        w.orderByDesc(Report::getCreatedAt);
        return reportMapper.selectPage(new Page<>(page, size), w);
    }

    @Override
    public String getReportHtml(Long id) {
        Report r = reportMapper.selectById(id);
        return r != null && r.getContentHtml() != null ? r.getContentHtml() : "";
    }

    @Override
    public void delete(Long id) {
        reportMapper.deleteById(id);
        log.info("报告已删除, reportId={}", id);
    }

    // ==================== HTML 渲染引擎 ====================

    /**
     * 构建完整的报告 HTML（三栏式布局）
     */
    private String buildReportHtml(Customer customer, List<IndicatorData> indicators, JSONObject analysis) {
        StringBuilder html = new StringBuilder();
        String companyName = escapeHtml(customer.getCompanyName());
        String riskLevel = analysis != null ? analysis.getString("overallRiskLevel") : "未分析";
        String riskColor = getRiskColor(riskLevel);
        String summary = analysis != null ? analysis.getString("summary") : "暂无分析结论，请先提交 Know-Kit 分析任务。";

        html.append("<!DOCTYPE html><html lang=\"zh-CN\"><head>")
            .append("<meta charset=\"UTF-8\">")
            .append("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">")
            .append("<title>").append(companyName).append(" - 贷后管理报告</title>")
            .append(buildStyles())
            .append("</head><body>")
            .append("<div class=\"report-shell\">")

            // 左栏：目录导航
            .append(buildNav())

            // 中栏：报告正文
            .append("<div class=\"report-main\">")
            .append(buildTopBar(companyName, riskLevel, riskColor))
            .append(buildCustomerBasicSection(customer))
            .append(buildIndicatorSection(indicators))
            .append(buildAnalysisSection(analysis, summary))
            .append("</div>")

            // 右栏：侧边信息
            .append(buildSidePanel(customer, analysis))

            .append("</div></body></html>");

        return html.toString();
    }

    /** CSS 样式 */
    private String buildStyles() {
        return "<style>" +
            ":root{--bg:#f4f8ff;--panel:rgba(255,255,255,.94);--line:rgba(31,90,181,.14);" +
            "--text:#10233f;--muted:#5d7396;--accent:#1664ff;--shadow:0 20px 56px rgba(35,88,176,.12);" +
            "--radius:16px;--red:#b1342c;--orange:#d7872d;--yellow:#d6a11f}" +
            "*{box-sizing:border-box}body{margin:0;font-family:\"PingFang SC\",\"Microsoft YaHei\",sans-serif;" +
            "color:var(--text);background:linear-gradient(180deg,#fdfefe 0%,#f3f8ff 58%,#eef5ff 100%);min-height:100vh}" +
            ".report-shell{display:grid;grid-template-columns:240px minmax(0,1fr) 340px;gap:16px;align-items:start;padding:24px}" +
            ".panel{border-radius:var(--radius);border:1px solid var(--line);background:var(--panel);box-shadow:var(--shadow)}" +
            ".report-nav,.side-panel{position:sticky;top:20px;max-height:calc(100vh - 40px);overflow:auto;padding:20px}" +
            ".report-nav a{display:block;padding:8px 12px;color:var(--muted);text-decoration:none;border-radius:8px;" +
            "font-size:.92rem;transition:all .2s}" +
            ".report-nav a:hover,.report-nav a.active{color:var(--accent);background:rgba(22,100,255,.06)}" +
            ".report-topbar{display:flex;justify-content:space-between;align-items:start;gap:16px;" +
            "margin-bottom:16px;padding:20px 24px}" +
            ".company-title{margin:0;font-size:1.8rem;font-weight:700}" +
            ".report-subtitle{margin:4px 0 0;color:var(--muted);font-size:.95rem;letter-spacing:.12em}" +
            ".risk-badge{display:inline-flex;align-items:center;gap:6px;padding:8px 20px;border-radius:20px;" +
            "font-weight:700;font-size:.95rem}" +
            ".risk-badge.red{background:#fde8e8;color:var(--red)}" +
            ".risk-badge.orange{background:#fef3e3;color:var(--orange)}" +
            ".risk-badge.yellow{background:#fefce7;color:var(--yellow)}" +
            ".section-card{padding:20px 24px;margin-bottom:16px}" +
            ".section-card h3{margin:0 0 16px;font-size:1.15rem;padding-bottom:10px;border-bottom:2px solid var(--accent)}" +
            ".section-card h4{margin:16px 0 8px;font-size:1.02rem;color:var(--accent)}" +
            "table{width:100%;border-collapse:collapse;font-size:.9rem}" +
            "th,td{padding:10px 14px;text-align:left;border-bottom:1px solid var(--line)}" +
            "th{color:var(--muted);font-weight:600;font-size:.82rem;white-space:nowrap}" +
            ".kv-key{color:var(--muted);width:140px}" +
            ".finding-item{padding:10px 0;border-bottom:1px solid var(--line)}" +
            ".finding-severity{display:inline-block;padding:2px 8px;border-radius:4px;font-size:.78rem;font-weight:700;margin-right:8px}" +
            ".finding-severity.red{background:#fde8e8;color:var(--red)}" +
            ".finding-severity.orange{background:#fef3e3;color:var(--orange)}" +
            ".finding-severity.yellow{background:#fefce7;color:var(--yellow)}" +
            ".rec-item{padding:8px 0;padding-left:24px;position:relative}" +
            ".rec-item::before{content:'•';position:absolute;left:8px;color:var(--accent);font-weight:700}" +
            ".footer-bar{text-align:center;color:var(--muted);font-size:.82rem;padding:24px 0 8px}" +
            "</style>";
    }

    /** 左栏目录 */
    private String buildNav() {
        return "<nav class=\"report-nav panel\">" +
            "<h3 style=\"margin:0 0 12px;font-size:1rem\">报告目录</h3>" +
            "<a href=\"#basic\">一、客户基本信息</a>" +
            "<a href=\"#indicators\">二、指标数据总览</a>" +
            "<a href=\"#analysis\">三、智能分析结论</a>" +
            "<a href=\"#findings\">四、风险发现清单</a>" +
            "<a href=\"#recommendations\">五、建议措施</a>" +
            "</nav>";
    }

    /** 顶栏 */
    private String buildTopBar(String companyName, String riskLevel, String riskColor) {
        return "<div class=\"report-topbar panel\">" +
            "<div>" +
            "<h1 class=\"company-title\">" + companyName + "</h1>" +
            "<p class=\"report-subtitle\">贷 后 管 理 报 告</p>" +
            "</div>" +
            "<span class=\"risk-badge " + riskColor + "\">" + escapeHtml(riskLevel) + "</span>" +
            "</div>";
    }

    /** 客户基本信息 */
    private String buildCustomerBasicSection(Customer c) {
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"section-card panel\" id=\"basic\">")
          .append("<h3>一、客户基本信息</h3>")
          .append("<table>");

        sb.append(basicRow("企业名称", c.getCompanyName()));
        sb.append(basicRow("统一信用代码", c.getCreditCode()));
        sb.append(basicRow("法定代表人", c.getLegalPerson()));
        sb.append(basicRow("实际控制人", c.getActualController()));
        sb.append(basicRow("注册资本", c.getRegisteredCapital()));
        sb.append(basicRow("实缴资本", c.getPaidCapital()));
        sb.append(basicRow("所属行业", c.getIndustry()));
        sb.append(basicRow("主营业务", c.getBizScope()));
        sb.append(basicRow("注册地址", c.getRegisterAddress()));
        sb.append(basicRow("持股方式", c.getHoldingType()));
        sb.append(basicRow("股东", c.getShareholder()));
        sb.append(basicRow("集团归属", c.getGroupName()));
        sb.append(basicRow("客户类型", c.getCustomerType()));
        sb.append(basicRow("基本开户行", c.getMainBank()));
        sb.append(basicRow("主要结算行", c.getSettlementBank()));
        sb.append(basicRow("客户状态", c.getStatus()));

        sb.append("</table></div>");
        return sb.toString();
    }

    private String basicRow(String label, String value) {
        return "<tr><td class=\"kv-key\">" + escapeHtml(label) + "</td>" +
               "<td>" + escapeHtml(value != null ? value : "—") + "</td></tr>";
    }

    /** 指标数据 */
    private String buildIndicatorSection(List<IndicatorData> indicators) {
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"section-card panel\" id=\"indicators\">")
          .append("<h3>二、指标数据总览</h3>");

        if (indicators.isEmpty()) {
            sb.append("<p style=\"color:var(--muted)\">暂无指标数据。请先配置采集器和解析器，完成数据接入。</p>");
        } else {
            sb.append("<table>")
              .append("<thead><tr><th>数据域</th><th>指标名称</th><th>当前值</th><th>上期值</th><th>变动</th></tr></thead>")
              .append("<tbody>");

            for (IndicatorData d : indicators) {
                sb.append("<tr>")
                  .append("<td>").append(escapeHtml(d.getDomain())).append("</td>")
                  .append("<td>").append(escapeHtml(d.getIndicatorName())).append("</td>")
                  .append("<td>").append(escapeHtml(d.getCurrentValue())).append("</td>")
                  .append("<td>").append(escapeHtml(d.getPreviousValue())).append("</td>")
                  .append("<td>").append(escapeHtml(d.getChangeDesc())).append("</td>")
                  .append("</tr>");
            }
            sb.append("</tbody></table>");
            sb.append("<p style=\"color:var(--muted);font-size:.82rem;margin-top:8px\">")
              .append("共 ").append(indicators.size()).append(" 项指标</p>");
        }
        sb.append("</div>");
        return sb.toString();
    }

    /** 分析结论 */
    private String buildAnalysisSection(JSONObject analysis, String summary) {
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"section-card panel\" id=\"analysis\">")
          .append("<h3>三、智能分析结论</h3>")
          .append("<p style=\"line-height:1.8\">").append(escapeHtml(summary)).append("</p>")
          .append("</div>");

        // 风险发现
        sb.append("<div class=\"section-card panel\" id=\"findings\">")
          .append("<h3>四、风险发现清单</h3>");

        if (analysis != null && analysis.getJSONArray("findings") != null) {
            JSONArray findings = analysis.getJSONArray("findings");
            for (int i = 0; i < findings.size(); i++) {
                JSONObject f = findings.getJSONObject(i);
                String severity = f.getString("severity");
                String sevClass = getSeverityClass(severity);
                sb.append("<div class=\"finding-item\">")
                  .append("<span class=\"finding-severity ").append(sevClass).append("\">")
                  .append(escapeHtml(f.getString("dimension"))).append(" | ").append(escapeHtml(severity)).append("</span>")
                  .append("<span>").append(escapeHtml(f.getString("finding"))).append("</span>")
                  .append("</div>");
            }
        } else {
            sb.append("<p style=\"color:var(--muted)\">暂无风险发现记录。</p>");
        }
        sb.append("</div>");

        // 建议措施
        sb.append("<div class=\"section-card panel\" id=\"recommendations\">")
          .append("<h3>五、建议措施</h3>");

        if (analysis != null && analysis.getJSONArray("recommendations") != null) {
            JSONArray recs = analysis.getJSONArray("recommendations");
            for (int i = 0; i < recs.size(); i++) {
                sb.append("<div class=\"rec-item\">").append(escapeHtml(recs.getString(i))).append("</div>");
            }
        } else {
            sb.append("<p style=\"color:var(--muted)\">暂无建议措施。</p>");
        }
        sb.append("</div>");

        // 页脚
        sb.append("<div class=\"footer-bar\">报告生成时间：").append(new Date()).append(" | 苏州银行贷后管理智能体</div>");

        return sb.toString();
    }

    /** 右侧边栏 */
    private String buildSidePanel(Customer c, JSONObject analysis) {
        StringBuilder sb = new StringBuilder();
        sb.append("<div class=\"side-panel panel\">")
          .append("<h3 style=\"margin:0 0 12px\">报告摘要</h3>");

        sb.append("<p style=\"font-size:.88rem;line-height:1.6;color:var(--muted)\">")
          .append("客户：").append(escapeHtml(c.getCompanyName())).append("<br>")
          .append("行业：").append(escapeHtml(c.getIndustry())).append("<br>")
          .append("类型：").append(escapeHtml(c.getCustomerType())).append("<br>");

        if (analysis != null) {
            sb.append("风险等级：").append(escapeHtml(analysis.getString("overallRiskLevel"))).append("<br>")
              .append("风险评分：").append(analysis.getInteger("riskScore")).append("<br>")
              .append("匹配规则数：").append(analysis.getInteger("matchedRuleCount"));
        } else {
            sb.append("风险等级：未分析<br>风险评分：—");
        }

        sb.append("</p>");

        // 快速操作
        sb.append("<hr style=\"border:1px solid var(--line);margin:16px 0\">")
          .append("<h4 style=\"font-size:.92rem;margin:0 0 8px\">快速操作</h4>")
          .append("<p style=\"font-size:.82rem;color:var(--muted);margin:0\">")
          .append("• 点击左侧目录跳转至对应章节<br>")
          .append("• 报告内容由智能体自动生成<br>")
          .append("• 生成时数据已拍快照，内容不可变</p>");

        sb.append("</div>");
        return sb.toString();
    }

    // ==================== 工具方法 ====================

    private String escapeHtml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private String getRiskColor(String level) {
        if (level == null) return "red";
        if (level.contains("红")) return "red";
        if (level.contains("橙")) return "orange";
        if (level.contains("黄")) return "yellow";
        return "red";
    }

    private String getSeverityClass(String severity) {
        if (severity == null) return "red";
        if (severity.contains("红")) return "red";
        if (severity.contains("橙")) return "orange";
        if (severity.contains("黄")) return "yellow";
        return "red";
    }
}
