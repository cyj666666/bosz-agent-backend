package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.*;
import com.suzhou.bank.service.data.DataConfigService;
import com.suzhou.bank.service.data.DataCollectService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * 数据源配置接口
 * <p>管理采集器和解析器的配置，支持动态增删改查。
 * 采集器定义"数据从哪来"，解析器定义"数据怎么转换"，
 * 两者通过策略模式解耦，新增数据源无需修改代码。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/data-config")
@RequiredArgsConstructor
public class DataConfigController {
    private final DataConfigService configService;
    private final DataCollectService collectService;

    // ==================== 采集器配置 ====================

    /**
     * 采集器配置分页查询
     *
     * @param page 页码
     * @param size 每页条数
     * @param type 采集器类型筛选（如 HTTP_API、SFTP_FILE），可选
     * @return 采集器配置分页数据
     */
    @GetMapping("/collector/page")
    public Result<Page<CollectorConfig>> pageCollector(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) String type) { return Result.ok(configService.pageCollector(page, size, type)); }

    /**
     * 查询单个采集器配置
     *
     * @param id 采集器配置ID
     * @return 采集器配置详情
     */
    @GetMapping("/collector/{id}")
    public Result<CollectorConfig> getCollector(@PathVariable Long id) { return Result.ok(configService.getCollector(id)); }

    /**
     * 新增采集器配置
     *
     * @param c 采集器配置（包含名称、类型、配置JSON、Cron表达式等）
     * @return 操作结果
     */
    @PostMapping("/collector")
    public Result<Void> saveCollector(@RequestBody CollectorConfig c) { configService.saveCollector(c); return Result.ok(); }

    /**
     * 更新采集器配置
     *
     * @param c 采集器配置（需包含ID）
     * @return 操作结果
     */
    @PutMapping("/collector")
    public Result<Void> updateCollector(@RequestBody CollectorConfig c) { configService.updateCollector(c); return Result.ok(); }

    /**
     * 删除采集器配置
     *
     * @param id 采集器配置ID
     * @return 操作结果
     */
    @DeleteMapping("/collector/{id}")
    public Result<Void> deleteCollector(@PathVariable Long id) { configService.deleteCollector(id); return Result.ok(); }

    // ==================== 解析器配置 ====================

    /**
     * 查询某采集器下的全部解析器
     *
     * @param collectorId 采集器ID
     * @return 解析器配置列表（按排序号升序）
     */
    @GetMapping("/parser/list/{collectorId}")
    public Result<List<ParserConfig>> listParser(@PathVariable Long collectorId) { return Result.ok(configService.listParserByCollector(collectorId)); }

    /**
     * 新增解析器配置
     *
     * @param p 解析器配置（包含类型、数据域、配置JSON、所属采集器ID等）
     * @return 操作结果
     */
    @PostMapping("/parser")
    public Result<Void> saveParser(@RequestBody ParserConfig p) { configService.saveParser(p); return Result.ok(); }

    /**
     * 更新解析器配置
     *
     * @param p 解析器配置（需包含ID）
     * @return 操作结果
     */
    @PutMapping("/parser")
    public Result<Void> updateParser(@RequestBody ParserConfig p) { configService.updateParser(p); return Result.ok(); }

    /**
     * 删除解析器配置
     *
     * @param id 解析器配置ID
     * @return 操作结果
     */
    @DeleteMapping("/parser/{id}")
    public Result<Void> deleteParser(@PathVariable Long id) { configService.deleteParser(id); return Result.ok(); }

    // ==================== 采集触发 ====================

    /**
     * 手动触发数据采集任务
     * <p>根据采集器配置执行数据获取和解析入库流程。</p>
     *
     * @param collectorId 采集器配置ID
     * @param customerId  目标客户ID
     * @return 原始数据日志记录
     */
    @PostMapping("/collect/{collectorId}")
    public Result<RawDataLog> triggerCollect(@PathVariable Long collectorId, @RequestParam Long customerId) { return Result.ok(collectService.collect(collectorId, customerId)); }
}
