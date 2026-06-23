package com.suzhou.bank.service.data;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.entity.ParserConfig;

import java.util.List;

/**
 * 数据源配置服务接口
 * <p>管理采集器和解析器的配置，采集器定义"数据从哪来"，
 * 解析器定义"数据怎么转换"，两者通过策略模式解耦。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface DataConfigService {

    // ==================== 采集器配置 ====================

    /**
     * 采集器分页查询
     *
     * @param page 页码
     * @param size 每页条数
     * @param type 采集器类型筛选（如 HTTP_API），可选
     * @return 采集器分页数据
     */
    Page<CollectorConfig> pageCollector(int page, int size, String type);

    /**
     * 根据ID查询采集器
     */
    CollectorConfig getCollector(Long id);

    /**
     * 新增采集器配置
     */
    void saveCollector(CollectorConfig config);

    /**
     * 更新采集器配置
     */
    void updateCollector(CollectorConfig config);

    /**
     * 删除采集器配置
     */
    void deleteCollector(Long id);

    /**
     * 查询所有启用的采集器
     *
     * @return 已启用的采集器列表
     */
    List<CollectorConfig> listEnabledCollectors();

    // ==================== 解析器配置 ====================

    /**
     * 查询某采集器下的所有解析器（按排序号升序）
     *
     * @param collectorId 采集器ID
     * @return 解析器配置列表
     */
    List<ParserConfig> listParserByCollector(Long collectorId);

    /**
     * 根据ID查询解析器
     */
    ParserConfig getParser(Long id);

    /**
     * 新增解析器配置
     */
    void saveParser(ParserConfig config);

    /**
     * 更新解析器配置
     */
    void updateParser(ParserConfig config);

    /**
     * 删除解析器配置
     */
    void deleteParser(Long id);
}
