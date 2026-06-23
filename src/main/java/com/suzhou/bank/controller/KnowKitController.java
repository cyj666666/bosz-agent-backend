package com.suzhou.bank.controller;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.config.AuthHelper;
import com.suzhou.bank.entity.KnowKitTask;
import com.suzhou.bank.service.knowkit.KnowKitService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/know-kit")
@RequiredArgsConstructor
public class KnowKitController {
    private final KnowKitService service;
    @PostMapping("/analyze")
    public Result<KnowKitTask> submitAnalysis(@RequestParam Long customerId, @RequestBody List<String> scenarioTags) { AuthHelper.verifyCustomerAccess(customerId); return Result.ok(service.submitAnalysis(customerId, scenarioTags)); }
    @GetMapping("/task/{taskId}")
    public Result<KnowKitTask> getTask(@PathVariable Long taskId) { KnowKitTask t = service.getTaskResult(taskId); if (t != null) AuthHelper.verifyCustomerAccess(t.getCustomerId()); return Result.ok(t); }
    @PostMapping("/task/{taskId}/retry")
    public Result<KnowKitTask> retryTask(@PathVariable Long taskId) { KnowKitTask t = service.getTaskResult(taskId); if (t != null) AuthHelper.verifyCustomerAccess(t.getCustomerId()); return Result.ok(service.retryTask(taskId)); }
}
