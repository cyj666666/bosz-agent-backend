package com.suzhou.bank.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Customer;
import com.suzhou.bank.mapper.CustomerMapper;
import com.suzhou.bank.service.CustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class CustomerServiceImpl implements CustomerService {
    private final CustomerMapper mapper;

    @Override
    public Page<Customer> page(int page, int size, String keyword) {
        LambdaQueryWrapper<Customer> w = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            w.like(Customer::getCompanyName, keyword).or().like(Customer::getCreditCode, keyword);
        }
        w.orderByDesc(Customer::getCreatedAt);
        return mapper.selectPage(new Page<>(page, size), w);
    }

    @Override public Customer getById(Long id) { return mapper.selectById(id); }
    @Override public void save(Customer c) { mapper.insert(c); }
    @Override public void update(Customer c) { mapper.updateById(c); }
    @Override public void delete(Long id) { mapper.deleteById(id); }
}
