package com.suzhou.bank.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.IndicatorData;
import com.suzhou.bank.service.IndicatorDataService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 指标数据接口
 * <p>提供采集+解析后结构化指标的 CRUD 和分页查询，
 * 支持按客户和数据域筛选，是报告分析的核心数据源。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/indicator")
@RequiredArgsConstructor
public class IndicatorDataController {

    private final IndicatorDataService service;

    /**
     * 指标分页查询
     *
     * @param page       页码（从1开始）
     * @param size       每页条数
     * @param customerId 客户ID筛选，可选
     * @param domain     数据域筛选，可选
     * @return 指标分页数据
     */
    @GetMapping("/page")
    public Result<Page<IndicatorData>> page(@RequestParam(defaultValue = "1") int page,
                                            @RequestParam(defaultValue = "10") int size,
                                            @RequestParam(required = false) Long customerId,
                                            @RequestParam(required = false) String domain) {
        return Result.ok(service.page(page, size, customerId, domain));
    }

    /**
     * 根据ID查询指标详情
     */
    @GetMapping("/{id}")
    public Result<IndicatorData> getById(@PathVariable Long id) {
        return Result.ok(service.getById(id));
    }

    /**
     * 新增指标
     */
    @PostMapping
    public Result<Void> save(@RequestBody IndicatorData data) {
        service.save(data);
        return Result.ok();
    }

    /**
     * 更新指标
     */
    @PutMapping
    public Result<Void> update(@RequestBody IndicatorData data) {
        service.update(data);
        return Result.ok();
    }

    /**
     * 删除指标
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return Result.ok();
    }
}
