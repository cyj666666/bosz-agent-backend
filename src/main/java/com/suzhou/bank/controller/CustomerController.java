package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.Customer;
import com.suzhou.bank.service.CustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 客户管理接口
 * <p>提供客户的增删改查和分页查询功能，
 * 客户是贷后管理的核心实体，所有数据采集、分析和报告均围绕客户展开。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
public class CustomerController {
    private final CustomerService service;

    /**
     * 客户分页查询
     *
     * @param page    页码（从1开始）
     * @param size    每页条数
     * @param keyword 模糊搜索关键词（公司名称或信用代码）
     * @return 客户分页数据
     */
    @GetMapping("/page")
    public Result<Page<Customer>> page(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) String keyword) { return Result.ok(service.page(page, size, keyword)); }

    /**
     * 根据ID查询客户详情
     *
     * @param id 客户ID
     * @return 客户信息
     */
    @GetMapping("/{id}")
    public Result<Customer> getById(@PathVariable Long id) { return Result.ok(service.getById(id)); }

    /**
     * 新增客户
     *
     * @param c 客户信息
     * @return 操作结果
     */
    @PostMapping
    public Result<Void> save(@RequestBody Customer c) { service.save(c); return Result.ok(); }

    /**
     * 更新客户信息
     *
     * @param c 客户信息（需包含ID）
     * @return 操作结果
     */
    @PutMapping
    public Result<Void> update(@RequestBody Customer c) { service.update(c); return Result.ok(); }

    /**
     * 删除客户
     *
     * @param id 客户ID
     * @return 操作结果
     */
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) { service.delete(id); return Result.ok(); }
}
