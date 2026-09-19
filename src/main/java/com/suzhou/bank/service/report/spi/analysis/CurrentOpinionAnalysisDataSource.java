package com.suzhou.bank.service.report.spi.analysis;

import com.suzhou.bank.service.report.spi.ReportAnalysisDataSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.sql.DataSource;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * 全文分析外部数据域①：**本次贷后检查意见**（表 {@code xd_corp_check_current_opinion}，列 {@code phaseopinion}）。
 *
 * <p>用户口径（2026-09-19）：全文分析的素材里要补上这份数据 ——
 * 报告正文只呈现了各章节的加工结果，模型看不到「检查环节上审批人到底写了什么意见」，
 * 因此把 {@code phaseopinion}（本次贷后检查意见）连同环节/审批机构/审批人一并喂给它。</p>
 *
 * <p><b>取数口径</b>：只按 {@code reportno} 查（该表是行内接口落库表，天然按报告编号关联），
 * 严格按本报告的编号取，**不按客户名兜底轮询** —— 同一客户多份报告会互相串数据。
 * 无数据返回 {@code null}（素材组装器会跳过整个小节，不留空标题）。</p>
 *
 * <p>取数失败只记 WARN 并返回 {@code null}：单个数据域失败不能影响整篇分析。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
@Component
public class CurrentOpinionAnalysisDataSource implements ReportAnalysisDataSource {

    /** 源表名（行内接口落库表） */
    private static final String TABLE = "xd_corp_check_current_opinion";

    private static final String SQL =
            "SELECT activename, approveorgname, approveusername, phaseopinion, endtime"
                    + " FROM " + TABLE
                    + " WHERE reportno = :p0"
                    + " ORDER BY inputtime, id";

    private final NamedParameterJdbcTemplate jdbc;

    public CurrentOpinionAnalysisDataSource(DataSource dataSource) {
        this.jdbc = new NamedParameterJdbcTemplate(dataSource);
    }

    @Override
    public String code() {
        return "currentOpinion";
    }

    /** 素材小节标题（用户口径命名） */
    @Override
    public String label() {
        return "本次贷后检查意见";
    }

    @Override
    public String load(String reportNo, String customerId, String customerName) {
        if (!StringUtils.hasText(reportNo)) {
            return null;
        }
        List<Map<String, Object>> rows;
        try {
            rows = jdbc.queryForList(SQL, Collections.singletonMap("p0", reportNo));
        } catch (Exception e) {
            log.warn("【全文分析·外部数据】阶段检查意见取数失败 reportNo={} err={}",
                    reportNo, e.getMessage());
            return null;
        }
        if (rows == null || rows.isEmpty()) {
            return null;
        }
        StringBuilder sb = new StringBuilder();
        int seq = 0;
        for (Map<String, Object> row : rows) {
            String opinion = value(row, "phaseopinion");
            if (!StringUtils.hasText(opinion)) {
                continue;
            }
            seq++;
            sb.append(seq).append(". ");
            String active = value(row, "activename");
            if (StringUtils.hasText(active)) {
                sb.append("【").append(active.trim()).append("】");
            }
            sb.append(opinion.trim());
            String meta = meta(row);
            if (StringUtils.hasText(meta)) {
                sb.append("（").append(meta).append("）");
            }
            sb.append('\n');
        }
        if (sb.length() == 0) {
            log.info("【全文分析·外部数据】阶段检查意见：有行但意见全空 reportNo={}", reportNo);
            return null;
        }
        log.info("【全文分析·外部数据】阶段检查意见：取到 {} 条 reportNo={}", seq, reportNo);
        return sb.toString().trim();
    }

    /** 来源信息拼接：审批机构 / 审批人 / 时间 */
    private static String meta(Map<String, Object> row) {
        StringBuilder meta = new StringBuilder();
        append(meta, "审批机构", value(row, "approveorgname"));
        append(meta, "审批人", value(row, "approveusername"));
        append(meta, "时间", value(row, "endtime"));
        return meta.toString();
    }

    private static void append(StringBuilder sb, String label, String value) {
        if (!StringUtils.hasText(value)) {
            return;
        }
        if (sb.length() > 0) {
            sb.append(" / ");
        }
        sb.append(label).append("：").append(value.trim());
    }

    /** 取值：列名大小写不敏感，null → 空串 */
    private static String value(Map<String, Object> row, String column) {
        Object v = row.get(column);
        if (v == null) {
            for (Map.Entry<String, Object> e : row.entrySet()) {
                if (e.getKey() != null && e.getKey().equalsIgnoreCase(column)) {
                    v = e.getValue();
                    break;
                }
            }
        }
        return v == null ? "" : String.valueOf(v);
    }
}
