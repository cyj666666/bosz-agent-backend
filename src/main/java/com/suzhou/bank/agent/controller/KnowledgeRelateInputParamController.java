package com.suzhou.bank.agent.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;
import com.suzhou.bank.agent.model.req.KnowledgeRelateInputParamReq;
import com.suzhou.bank.agent.service.IKnowledgeRelateInputParamService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@Slf4j
@Tag(name = "知识库管理数据集")
@RestController
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/agent/knowledgeRelateInputParam"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，故后端路径 = /api + 前端相对路径。
//
// 去重说明（2026-09-14 修正）：源工程该 Controller 路径为 "/agent/rule" 这类【自带 agent 段】的写法，
// 若机械地再拼一层会得到 "/api/agent/agent/rule"（双 agent）。前端 P5 是重写而非搬运，
// 为让前端能 1:1 照抄源工程 api/<x>.js 里的相对路径（"/agent/rule/list"），
// 这里【去掉重复的 agent 段】，而不是让前端到处写双 agent。
    @RequestMapping("/api/agent/knowledgeRelateInputParam")
public class KnowledgeRelateInputParamController {

    @Autowired
    private IKnowledgeRelateInputParamService knowledgeRelateInputParamService;

    @Operation(summary = "知识库管理数据集-分页列表查询", description = "知识库管理数据集-分页列表查询")
    @PostMapping(value = "/list")
    public AgentResult<?> queryPageList(@RequestBody KnowledgeRelateInputParamReq req) {
        LambdaQueryWrapper<KnowledgeRelateInputParamEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(KnowledgeRelateInputParamEntity::getKnowledgeId, req.getKnowledgeId());
        queryWrapper.orderByDesc(KnowledgeRelateInputParamEntity::getInputTime);
        queryWrapper.eq(StringUtils.isNotBlank(req.getInputParamName()), KnowledgeRelateInputParamEntity::getInputParamName, req.getInputParamName());
        Page<KnowledgeRelateInputParamEntity> page = new Page<>(req.getPageIndex(), req.getPageSize());
        IPage<KnowledgeRelateInputParamEntity> pageList = knowledgeRelateInputParamService.page(page, queryWrapper);
        if (CollectionUtils.isEmpty(pageList.getRecords())) {
            return AgentResult.OK(new ListResult<>(0, 0));
        }
        return AgentResult.OK(new ListResult<>((int) pageList.getTotal(), req.getPageSize(), req.getPageIndex(), pageList.getRecords()));
    }

    @Operation(summary = "知识库管理数据集-添加", description = "知识库管理数据集-添加")
    @PostMapping(value = "/add")
    public AgentResult<?> add(@RequestBody KnowledgeRelateInputParamEntity knowledgeRelateInputParamEntity) {
        knowledgeRelateInputParamService.save(knowledgeRelateInputParamEntity);
        return AgentResult.OK("添加成功！");
    }

    @Operation(summary = "知识库管理数据集-编辑", description = "知识库管理数据集-编辑")
    @PostMapping(value = "/edit")
    public AgentResult<?> edit(@RequestBody KnowledgeRelateInputParamEntity knowledgeRelateInputParamEntity) {
        knowledgeRelateInputParamService.updateById(knowledgeRelateInputParamEntity);
        return AgentResult.OK("编辑成功!");
    }

    @Operation(summary = "知识库管理数据集-批量删除", description = "知识库管理数据集-批量删除")
    @PostMapping(value = "/deleteBatch")
    public AgentResult<?> deleteBatch(@RequestBody List<String> idList) {
        this.knowledgeRelateInputParamService.removeByIds(idList);
        return AgentResult.OK("批量删除成功！");
    }

    @Operation(summary = "知识库管理数据集-通过id查询", description = "知识库管理数据集-通过id查询")
    @GetMapping(value = "/queryById")
    public AgentResult<?> queryById(@RequestParam String id) {
        KnowledgeRelateInputParamEntity knowledgeRelateInputParamEntity = knowledgeRelateInputParamService.getById(id);
        return AgentResult.OK(knowledgeRelateInputParamEntity);
    }
}
