package com.suzhou.bank.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Customer;
import com.suzhou.bank.entity.IndicatorData;
import com.suzhou.bank.mapper.CustomerMapper;
import com.suzhou.bank.mapper.IndicatorDataMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 指标数据服务
 * <p>管理采集+解析后的结构化指标，支持按客户和数据域筛选。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class IndicatorDataService {

    private final IndicatorDataMapper mapper;
    private final CustomerMapper customerMapper;

    /**
     * 指标分页查询，支持按客户ID和数据域筛选，自动填充客户名称
     */
    public Page<IndicatorData> page(int page, int size, Long customerId, String domain, String keyword) {
        LambdaQueryWrapper<IndicatorData> w = new LambdaQueryWrapper<>();
        if (customerId != null) {
            w.eq(IndicatorData::getCustomerId, customerId);
        }
        if (domain != null && !domain.isEmpty()) {
            w.eq(IndicatorData::getDomain, domain);
        }
        if (keyword != null && !keyword.isEmpty()) {
            w.and(wr -> wr.like(IndicatorData::getIndicatorKey, keyword)
                        .or().like(IndicatorData::getIndicatorName, keyword));
        }
        w.orderByAsc(IndicatorData::getDomain).orderByAsc(IndicatorData::getSortOrder);
        Page<IndicatorData> result = mapper.selectPage(new Page<>(page, size), w);

        // 批量填充客户名称
        Set<Long> customerIds = result.getRecords().stream()
                .map(IndicatorData::getCustomerId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        if (!customerIds.isEmpty()) {
            List<Customer> customers = customerMapper.selectBatchIds(customerIds);
            Map<Long, String> nameMap = customers.stream()
                    .collect(Collectors.toMap(Customer::getId, Customer::getCompanyName));
            result.getRecords().forEach(d -> d.setCompanyName(nameMap.get(d.getCustomerId())));
        }
        return result;
    }

    public IndicatorData getById(Long id) {
        return mapper.selectById(id);
    }

    public void save(IndicatorData data) {
        data.setCreatedAt(new Date());
        if (data.getSortOrder() == null) data.setSortOrder(0);
        mapper.insert(data);
        log.info("指标数据已新增, id={}, key={}", data.getId(), data.getIndicatorKey());
    }

    public void update(IndicatorData data) {
        mapper.updateById(data);
        log.info("指标数据已更新, id={}, key={}", data.getId(), data.getIndicatorKey());
    }

    public void delete(Long id) {
        mapper.deleteById(id);
        log.info("指标数据已删除, id={}", id);
    }
}
