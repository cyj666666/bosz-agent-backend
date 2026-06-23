package com.suzhou.bank.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Customer;

public interface CustomerService {
    Page<Customer> page(int page, int size, String keyword);
    Customer getById(Long id);
    void save(Customer customer);
    void update(Customer customer);
    void delete(Long id);
}
