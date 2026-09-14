package com.suzhou.bank.agent.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.KnowledgeBaseVersionEntity;
import com.suzhou.bank.agent.model.dto.KnowledgeBaseVersionDTO;
import com.suzhou.bank.agent.model.req.KnowledgeBaseVersionReq;
import com.suzhou.bank.agent.service.IKnowledgeBaseVersionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * @Description: 知识库版本记录表
 * @Author: jeecg-boot
 * @Date: 2025-11-06
 * @Version: V1.0
 */
@Slf4j
@Tag(name = "知识库版本记录表")
@RestController
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/agent/knowledgeBaseVersion"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，故后端路径 = /api + 前端相对路径。
//
// 去重说明（2026-09-14 修正）：源工程该 Controller 路径为 "/agent/rule" 这类【自带 agent 段】的写法，
// 若机械地再拼一层会得到 "/api/agent/agent/rule"（双 agent）。前端 P5 是重写而非搬运，
// 为让前端能 1:1 照抄源工程 api/<x>.js 里的相对路径（"/agent/rule/list"），
// 这里【去掉重复的 agent 段】，而不是让前端到处写双 agent。
    @RequestMapping("/api/agent/knowledgeBaseVersion")
public class KnowledgeBaseVersionController {

    @Autowired
    private IKnowledgeBaseVersionService knowledgeBaseVersionService;

    @Operation(summary = "知识库版本记录表-分页列表查询", description = "知识库版本记录表-分页列表查询")
    @PostMapping(value = "/list")
    public AgentResult<?> queryPageList(@RequestBody KnowledgeBaseVersionReq req) {
        LambdaQueryWrapper<KnowledgeBaseVersionEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeBaseVersionEntity::getParamId, req.getParamId());
        queryWrapper.like(StringUtils.isNotBlank(req.getVersionNo()), KnowledgeBaseVersionEntity::getVersionNo, req.getVersionNo());
        queryWrapper.like(StringUtils.isNotBlank(req.getVersionName()), KnowledgeBaseVersionEntity::getVersionName, req.getVersionName());
        queryWrapper.ne(KnowledgeBaseVersionEntity::getVersionName, "系统自动备份版本");
        queryWrapper.orderByDesc(KnowledgeBaseVersionEntity::getCreateTime);
        queryWrapper.orderByDesc(KnowledgeBaseVersionEntity::getLatestFlag);
        Page<KnowledgeBaseVersionEntity> page = new Page<>(req.getPageIndex(), req.getPageSize());
        IPage<KnowledgeBaseVersionEntity> pageList = knowledgeBaseVersionService.page(page, queryWrapper);
        if (pageList.getRecords().isEmpty()) {
            return AgentResult.OK(new ListResult<>(0, 0));
        }
        return AgentResult.OK(new ListResult<>((int) pageList.getTotal(), req.getPageSize(), req.getPageIndex(), pageList.getRecords()));
    }

    @Operation(summary = "知识库版本记录表-发布", description = "知识库版本记录表-发布")
    @PostMapping(value = "/public")
    public AgentResult<?> publicVersion(@RequestBody KnowledgeBaseVersionDTO knowledgeBaseVersionDTO) {
        return AgentResult.OK(knowledgeBaseVersionService.publicVersion(knowledgeBaseVersionDTO));
    }

    @Operation(summary = "知识库版本记录表-编辑", description = "知识库版本记录表-编辑")
    @PostMapping(value = "/edit")
    public AgentResult<?> edit(@RequestBody KnowledgeBaseVersionEntity knowledgeBaseVersionEntity) {
        knowledgeBaseVersionService.updateById(knowledgeBaseVersionEntity);
        return AgentResult.OK("编辑成功!");
    }

    @Operation(summary = "知识库版本记录表-批量删除", description = "知识库版本记录表-批量删除")
    @PostMapping(value = "/deleteBatch")
    public AgentResult<?> deleteBatch(@RequestBody List<String> ids) {
        knowledgeBaseVersionService.removeByIds(ids);
        return AgentResult.OK("删除成功！");
    }

    @Operation(summary = "知识库版本记录表-通过id查询", description = "知识库版本记录表-通过id查询")
    @GetMapping(value = "/queryById")
    public AgentResult<?> queryById(@RequestParam(name = "id") String id) {
        KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = knowledgeBaseVersionService.getById(id);
        return AgentResult.OK(knowledgeBaseVersionEntity);
    }

}
