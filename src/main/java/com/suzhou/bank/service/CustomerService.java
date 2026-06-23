package com.suzhou.bank.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.entity.Customer;

/**
 * 客户服务接口
 * <p>提供客户信息的增删改查功能，客户是贷后管理系统的核心实体。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
public interface CustomerService {

    /**
     * 客户分页查询
     *
     * @param page    页码（从1开始）
     * @param size    每页条数
     * @param keyword 模糊搜索关键词（公司名称或信用代码），可选
     * @return 客户分页数据
     */
    Page<Customer> page(int page, int size, String keyword);

    /**
     * 根据ID查询客户
     *
     * @param id 客户ID
     * @return 客户信息
     */
    Customer getById(Long id);

    /**
     * 新增客户
     *
     * @param customer 客户信息
     */
    void save(Customer customer);

    /**
     * 更新客户信息
     *
     * @param customer 客户信息（需包含ID）
     */
    void update(Customer customer);

    /**
     * 删除客户
     *
     * @param id 客户ID
     */
    void delete(Long id);
}
