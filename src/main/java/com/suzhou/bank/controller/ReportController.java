package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.config.AuthHelper;
import com.suzhou.bank.entity.Report;
import com.suzhou.bank.service.report.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/report")
@RequiredArgsConstructor
public class ReportController {
    private final ReportService service;
    @PostMapping("/generate")
    public Result<Report> generate(@RequestParam Long customerId, @RequestParam Long knowKitTaskId) { AuthHelper.verifyCustomerAccess(customerId); return Result.ok(service.generate(customerId, knowKitTaskId)); }
    @GetMapping("/page")
    public Result<Page<Report>> page(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam Long customerId) { AuthHelper.verifyCustomerAccess(customerId); return Result.ok(service.page(page, size, customerId)); }
    @GetMapping("/{id}")
    public Result<Report> getById(@PathVariable Long id) { Report r = service.getById(id); if (r != null) AuthHelper.verifyCustomerAccess(r.getCustomerId()); return Result.ok(r); }
    @GetMapping("/{id}/html")
    public Result<String> getHtml(@PathVariable Long id) { Report r = service.getById(id); if (r != null) AuthHelper.verifyCustomerAccess(r.getCustomerId()); return Result.ok(service.getReportHtml(id)); }
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) { Report r = service.getById(id); if (r != null) AuthHelper.verifyCustomerAccess(r.getCustomerId()); service.delete(id); return Result.ok(); }
}
