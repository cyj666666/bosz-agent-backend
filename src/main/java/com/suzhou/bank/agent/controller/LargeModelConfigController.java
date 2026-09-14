package com.suzhou.bank.agent.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.LargeModelConfigEntity;
import com.suzhou.bank.agent.model.req.LargeModelReq;
import com.suzhou.bank.agent.service.ILargeModelConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@Slf4j
@Tag(name = "大模型信息配置表")
@RestController
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/agent/largeModelConfig"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，故后端路径 = /api + 前端相对路径。
//
// 去重说明（2026-09-14 修正）：源工程该 Controller 路径为 "/agent/rule" 这类【自带 agent 段】的写法，
// 若机械地再拼一层会得到 "/api/agent/agent/rule"（双 agent）。前端 P5 是重写而非搬运，
// 为让前端能 1:1 照抄源工程 api/<x>.js 里的相对路径（"/agent/rule/list"），
// 这里【去掉重复的 agent 段】，而不是让前端到处写双 agent。
    @RequestMapping("/api/agent/largeModelConfig")
public class LargeModelConfigController {

    @Autowired
    private ILargeModelConfigService largeModelConfigService;

    @Operation(summary = "大模型信息配置表-分页列表查询", description = "大模型信息配置表-分页列表查询")
    @PostMapping(value = "/list")
    public AgentResult<?> queryPageList(@RequestBody LargeModelReq largeModelReq) {
        LambdaQueryWrapper<LargeModelConfigEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.like(StringUtils.isNotEmpty(largeModelReq.getLmName()), LargeModelConfigEntity::getLmName, largeModelReq.getLmName());
        queryWrapper.like(StringUtils.isNotEmpty(largeModelReq.getModel()), LargeModelConfigEntity::getModel, largeModelReq.getModel());
        queryWrapper.like(StringUtils.isNotEmpty(largeModelReq.getLmCode()), LargeModelConfigEntity::getLmCode, largeModelReq.getLmCode());
        // queryWrapper.eq(LargeModelConfigEntity::getUseFlag, "Y");
        queryWrapper.orderByDesc(LargeModelConfigEntity::getUpdateTime);
        Page<LargeModelConfigEntity> page = new Page<>(largeModelReq.getPageIndex(), largeModelReq.getPageSize());
        IPage<LargeModelConfigEntity> pageList = largeModelConfigService.page(page, queryWrapper);
        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            return AgentResult.OK(new ListResult<>(0, 0));
        }
        return AgentResult.OK(new ListResult<>((int) pageList.getTotal(), largeModelReq.getPageSize(), largeModelReq.getPageIndex(), pageList.getRecords()));
    }

    @Operation(summary = "大模型信息配置表-添加", description = "大模型信息配置表-添加")
    @PostMapping(value = "/add")
    public AgentResult<?> add(@RequestBody LargeModelConfigEntity largeModelConfigEntity) {
        largeModelConfigService.save(largeModelConfigEntity);
        return AgentResult.OK("添加成功！");
    }

    @Operation(summary = "大模型信息配置表-编辑", description = "大模型信息配置表-编辑")
    @PostMapping(value = "/edit")
    public AgentResult<?> edit(@RequestBody LargeModelConfigEntity largeModelConfigEntity) {
        largeModelConfigService.updateById(largeModelConfigEntity);
        return AgentResult.OK("编辑成功!");
    }

    @Operation(summary = "大模型信息配置表-通过id删除", description = "大模型信息配置表-通过id删除")
    @GetMapping(value = "/delete")
    public AgentResult<?> delete(@RequestParam(name = "id", required = true) String id) {
        largeModelConfigService.removeById(id);
        return AgentResult.OK("删除成功!");
    }

    @Operation(summary = "大模型信息配置表-批量删除", description = "大模型信息配置表-批量删除")
    @PostMapping(value = "/deleteBatch")
    public AgentResult<?> deleteBatch(@RequestBody List<String> ids) {
        largeModelConfigService.removeByIds(ids);
        return AgentResult.OK("批量删除成功！");
    }

    @Operation(summary = "大模型信息配置表-通过id查询", description = "大模型信息配置表-通过id查询")
    @GetMapping(value = "/queryById")
    public AgentResult<?> queryById(@RequestParam(name = "id") String id) {
        return AgentResult.OK(largeModelConfigService.getById(id));
    }

    @Operation(summary = "大模型信息配置表-初始化模型配置", description = "大模型信息配置表-初始化模型配置")
    @GetMapping(value = "/init/modelConfig")
    public AgentResult<?> initModelConfig() {
        largeModelConfigService.initModelConfig();
        return AgentResult.OK("初始化成功！");
    }

}
