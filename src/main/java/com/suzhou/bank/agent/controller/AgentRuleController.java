package com.suzhou.bank.agent.controller;

import cn.hutool.core.collection.CollectionUtil;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.Valid;
import javax.validation.constraints.NotBlank;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.model.req.AgentRuleExecuteReq;
import com.suzhou.bank.agent.model.req.AgentRuleParseReq;
import com.suzhou.bank.agent.model.req.AgentRuleReq;
import com.suzhou.bank.agent.model.req.AgentRuleSaveReq;
import com.suzhou.bank.agent.service.IAgentRuleService;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Slf4j
@Tag(name = "规则管理")
@RestController
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/agent/rule"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，故后端路径 = /api + 前端相对路径。
//
// 去重说明（2026-09-14 修正）：源工程该 Controller 路径为 "/agent/rule" 这类【自带 agent 段】的写法，
// 若机械地再拼一层会得到 "/api/agent/agent/rule"（双 agent）。前端 P5 是重写而非搬运，
// 为让前端能 1:1 照抄源工程 api/<x>.js 里的相对路径（"/agent/rule/list"），
// 这里【去掉重复的 agent 段】，而不是让前端到处写双 agent。
    @RequestMapping("/api/agent/rule")
@RequiredArgsConstructor
public class AgentRuleController {

    private final IAgentRuleService agentRuleService;

    @Operation(summary = "规则管理-分页查询", description = "分页查询规则列表")
    @PostMapping(value = "/list")
    public AgentResult<?> queryPageList(@RequestBody @Valid AgentRuleReq req) {
        LambdaQueryWrapper<AgentRuleEntity> queryWrapper = Wrappers.lambdaQuery(AgentRuleEntity.class);
        // 通用模糊、等值条件不变
        if (StringUtils.isNotBlank(req.getRuleName())) {
            queryWrapper.like(AgentRuleEntity::getRuleName, req.getRuleName());
        }
        if (StringUtils.isNotBlank(req.getRuleStatus())) {
            queryWrapper.eq(AgentRuleEntity::getRuleStatus, req.getRuleStatus());
        }
        if (StringUtils.isNotBlank(req.getRuleCode())) {
            queryWrapper.like(AgentRuleEntity::getRuleCode, req.getRuleCode());
        }

        List<AgentRuleReq.TopicPairDTO> pairList = req.getTopicPairList();
        if (CollectionUtil.isNotEmpty(pairList)) {
            List<AgentRuleReq.TopicPairDTO> validPairList = pairList.stream()
                    .filter(p -> StringUtils.isNotBlank(p.getTopic1()) && StringUtils.isNotBlank(p.getTopic2()))
                    .collect(Collectors.toList());
            if (!validPairList.isEmpty()) {
                queryWrapper.and(wrapper -> {
                    for (int i = 0; i < validPairList.size(); i++) {
                        AgentRuleReq.TopicPairDTO pair = validPairList.get(i);
                        // 一组条件：一级+二级同时匹配
                        wrapper.eq(AgentRuleEntity::getTopic1, pair.getTopic1())
                                .eq(AgentRuleEntity::getTopic2, pair.getTopic2());
                        // 不是最后一组，才加OR分隔
                        if (i != validPairList.size() - 1) {
                            wrapper.or();
                        }
                    }
                });
            }
        }

        String startDate = req.getStartTime();
        String endDate = req.getEndTime();
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        LocalDateTime startFull = null, endFull = null;
        if (StringUtils.isNotBlank(startDate)) {
            startFull = LocalDateTime.parse(startDate + " 00:00:00", fmt);
        }
        if (StringUtils.isNotBlank(endDate)) {
            endFull = LocalDateTime.parse(endDate + " 23:59:59", fmt);
        }
        if (Objects.nonNull(startFull) && Objects.nonNull(endFull)) {
            queryWrapper.between(AgentRuleEntity::getUpdateTime, startFull, endFull);
        } else if (Objects.nonNull(startFull)) {
            queryWrapper.ge(AgentRuleEntity::getUpdateTime, startFull);
        } else if (Objects.nonNull(endFull)) {
            queryWrapper.le(AgentRuleEntity::getUpdateTime, endFull);
        }
        queryWrapper.orderByDesc(AgentRuleEntity::getUpdateTime);

        Page<AgentRuleEntity> page = new Page<>(req.getPageIndex(), req.getPageSize());
        IPage<AgentRuleEntity> pageList = agentRuleService.page(page, queryWrapper);
        ListResult listResult = new ListResult<>((int) pageList.getTotal(), req.getPageIndex(), req.getPageSize(), pageList.getRecords());
        return AgentResult.OK(listResult);
    }

    @Operation(summary = "规则管理-主题枚举值", description = "主题枚举值")
    @PostMapping(value = "/topicSelect")
    public AgentResult<?> topicSelect() {
        return AgentResult.OK(agentRuleService.getTopicTreeList());
    }

    @Operation(summary = "规则管理-保存规则", description = "保存规则配置；id为空时新增，id不为空时更新")
    @PostMapping(value = "/save")
    public AgentResult<?> saveRule(@RequestBody @Valid AgentRuleSaveReq req) {
        return AgentResult.OK(agentRuleService.saveRule(req));
    }

    @Operation(summary = "规则管理-解析规则表达式", description = "解析自然语言规则，当前先返回空解析结果")
    @PostMapping(value = "/parse")
    public AgentResult<?> parseRule(@RequestBody @Valid AgentRuleParseReq req) {
        return AgentResult.OK(agentRuleService.parseRule(req));
    }

    @Operation(summary = "规则管理-模拟执行规则", description = "模拟执行规则，当前先返回空执行结果")
    @PostMapping(value = "/execute")
    public AgentResult<?> executeRule(@RequestBody @Valid AgentRuleExecuteReq req) {
        return AgentResult.OK(agentRuleService.executeRule(req));
    }

    @Operation(summary = "规则管理-更新规则状态", description = "根据ID修改规则状态")
    @PostMapping(value = "/updateRuleStatus")
    public AgentResult<?> updateRuleStatus(@RequestBody @Valid AgentRuleReq req) {
        AgentRuleEntity updateEntity = new AgentRuleEntity();
        updateEntity.setId(req.getId());
        updateEntity.setRuleStatus(req.getRuleStatus());

        // 直接判断布尔返回值
        boolean success = agentRuleService.updateById(updateEntity);
        if (!success) {
            return AgentResult.error("规则不存在");
        }
        return AgentResult.OK("状态修改成功");
    }

    @Operation(summary = "规则管理-物理删除规则", description = "根据主键ID物理删除单条规则数据，直接从数据库删除不可恢复")
    @PostMapping(value = "/delete")
    public AgentResult<?> deleteRule(@RequestParam @NotBlank(message = "规则ID不能为空") String id) {
        boolean remove = agentRuleService.removeById(id);
        if (remove) {
            return AgentResult.OK("删除成功");
        } else {
            return AgentResult.error("删除失败，数据不存在");
        }
    }

    @Operation(summary = "规则管理-企业模糊查询", description = "企业模糊查询")
    @PostMapping(value = "/getEnts")
    public AgentResult<?> getEnts(@RequestBody @Valid AgentRuleExecuteReq req) {
        if(StringUtils.isBlank(req.getName())){
            return AgentResult.ERROR("模糊检索关键词为空");
        }
        JSONObject params = new JSONObject();
        params.put("name",req.getName());
        return AgentResult.OK(agentRuleService.getEnts(params));
    }

    @Operation(summary = "知识库管理 - 规则筛选", description = "根据关键词模糊检索：规则名称、规则编号")
    @PostMapping(value = "/tree")
    public AgentResult<?> getTree(@RequestParam(required = false) String keyname) {
        return agentRuleService.getRuleTreeByTopic(keyname);
    }
}