package com.suzhou.bank.service.impl;
import com.alibaba.fastjson2.JSON;
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
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j @Service @RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {
    private final ReportMapper reportMapper;
    private final CustomerMapper customerMapper;
    private final IndicatorDataMapper indicatorMapper;
    private final KnowKitTaskMapper taskMapper;
    @Override public Report generate(Long customerId, Long knowKitTaskId) {
        Customer c = customerMapper.selectById(customerId);
        List<IndicatorData> indicators = indicatorMapper.selectList(new LambdaQueryWrapper<IndicatorData>().eq(IndicatorData::getCustomerId, customerId));
        Report r = new Report();
        r.setCustomerId(customerId);
        r.setReportTitle(c.getCompanyName() + " - 贷后管理报告");
        r.setReportType("贷后管理报告");
        r.setStatus("DRAFT");
        r.setKnowKitTaskId(knowKitTaskId);
        r.setDataSnapshot(JSON.toJSONString(indicators));
        r.setContentHtml("");
        r.setCreatedAt(new Date());
        reportMapper.insert(r);
        log.info("报告已生成, reportId={}, customerId={}, title={}", r.getId(), customerId, r.getReportTitle());
        return r;
    }
    @Override public Report getById(Long id) { return reportMapper.selectById(id); }
    @Override public Page<Report> page(int page, int size, Long customerId) { LambdaQueryWrapper<Report> w = new LambdaQueryWrapper<>(); if (customerId != null) w.eq(Report::getCustomerId, customerId); w.orderByDesc(Report::getCreatedAt); return reportMapper.selectPage(new Page<>(page, size), w); }
    @Override public String getReportHtml(Long id) { Report r = reportMapper.selectById(id); return r != null ? r.getContentHtml() : ""; }
    @Override public void delete(Long id) { reportMapper.deleteById(id); log.info("报告已删除, reportId={}", id); }
}
