package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.Customer;
import org.apache.ibatis.annotations.Mapper;

/**
 * 客户表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface CustomerMapper extends BaseMapper<Customer> {
}
