package com.suzhou.bank.controller;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.suzhou.bank.common.Result;
import com.suzhou.bank.config.AuthHelper;
import com.suzhou.bank.entity.Customer;
import com.suzhou.bank.service.CustomerService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
@RestController
@RequestMapping("/api/customer")
@RequiredArgsConstructor
public class CustomerController {
    private final CustomerService service;
    @GetMapping("/page")
    public Result<Page<Customer>> page(@RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size, @RequestParam(required = false) String keyword) { return Result.ok(service.page(page, size, keyword)); }
    @GetMapping("/{id}")
    public Result<Customer> getById(@PathVariable Long id) { AuthHelper.verifyCustomerAccess(id); return Result.ok(service.getById(id)); }
    @PostMapping
    public Result<Void> save(@RequestBody Customer c) { AuthHelper.verifyCustomerAccess(c.getId()); service.save(c); return Result.ok(); }
    @PutMapping
    public Result<Void> update(@RequestBody Customer c) { AuthHelper.verifyCustomerAccess(c.getId()); service.update(c); return Result.ok(); }
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) { AuthHelper.verifyCustomerAccess(id); service.delete(id); return Result.ok(); }
}
