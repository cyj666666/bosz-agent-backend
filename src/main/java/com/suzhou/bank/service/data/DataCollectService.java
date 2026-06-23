package com.suzhou.bank.service.data;

import com.suzhou.bank.entity.RawDataLog;

/**
 * 数据采集编排服务接口
 * <p>协调采集器（Collector）和解析器（Parser），
 * 执行数据获取、解析、入库的完整流程。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface DataCollectService {

    /**
     * 根据采集器配置执行数据采集
     *
     * @param collectorId 采集器配置ID
     * @param customerId  目标客户ID
     * @return 原始数据日志记录
     */
    RawDataLog collect(Long collectorId, Long customerId);

    /**
     * 解析原始数据并入库
     * <p>根据采集器关联的解析器配置，将原始数据解析为
     * 指标数据（indicator_data）和文本数据（text_data）并写入数据库。</p>
     *
     * @param rawDataLogId 原始数据日志ID
     */
    void parseAndStore(Long rawDataLogId);
}
