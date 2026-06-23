package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.service.data.DataConfigService;
import com.suzhou.bank.service.data.DataCollectService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/data-config")
@RequiredArgsConstructor
public class DataConfigController {
    private final DataConfigService configService;
    private final DataCollectService collectService;
    @GetMapping("/collector/page")
    public Result<Page<CollectorConfig>> pageCollector(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) String type) { return Result.ok(configService.pageCollector(page, size, type)); }
    @GetMapping("/collector/{id}")
    public Result<CollectorConfig> getCollector(@PathVariable Long id) { return Result.ok(configService.getCollector(id)); }
    @PostMapping("/collector")
    public Result<Void> saveCollector(@RequestBody CollectorConfig c) { configService.saveCollector(c); return Result.ok(); }
    @PutMapping("/collector")
    public Result<Void> updateCollector(@RequestBody CollectorConfig c) { configService.updateCollector(c); return Result.ok(); }
    @DeleteMapping("/collector/{id}")
    public Result<Void> deleteCollector(@PathVariable Long id) { configService.deleteCollector(id); return Result.ok(); }
    @GetMapping("/parser/list/{collectorId}")
    public Result<List<ParserConfig>> listParser(@PathVariable Long collectorId) { return Result.ok(configService.listParserByCollector(collectorId)); }
    @PostMapping("/parser")
    public Result<Void> saveParser(@RequestBody ParserConfig p) { configService.saveParser(p); return Result.ok(); }
    @PutMapping("/parser")
    public Result<Void> updateParser(@RequestBody ParserConfig p) { configService.updateParser(p); return Result.ok(); }
    @DeleteMapping("/parser/{id}")
    public Result<Void> deleteParser(@PathVariable Long id) { configService.deleteParser(id); return Result.ok(); }
    @PostMapping("/collect/{collectorId}")
    public Result<RawDataLog> triggerCollect(@PathVariable Long collectorId, @RequestParam Long customerId) { return Result.ok(collectService.collect(collectorId, customerId)); }
}
