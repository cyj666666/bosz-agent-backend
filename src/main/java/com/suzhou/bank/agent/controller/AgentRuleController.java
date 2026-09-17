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
import com.suzhou.bank.agent.core.SqlDataSetBuilder;
import com.suzhou.bank.agent.util.AgentParamNames;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.model.req.AgentRuleExecuteReq;
import com.suzhou.bank.agent.model.req.AgentRuleParseReq;
import com.suzhou.bank.agent.model.req.AgentRuleReq;
import com.suzhou.bank.agent.model.req.AgentRuleSaveReq;
import com.suzhou.bank.agent.service.IAgentRuleService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
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
        // 检索关键字：界面文案是「请输入规则名称/描述检索关键词」，但源实现只 LIKE 了 rule_name，
        // 按「触发条件（rule_text）」里的内容搜不到任何结果 —— 与文案承诺不符。
        // 2026-09-16 修复：补上 rule_text，属**有意扩面**（只会多命中，不会减少原有结果）。
        if (StringUtils.isNotBlank(req.getRuleName())) {
            String ruleNameKw = req.getRuleName().trim();
            queryWrapper.and(w -> w.like(AgentRuleEntity::getRuleName, ruleNameKw)
                    .or().like(AgentRuleEntity::getRuleText, ruleNameKw));
        }
        if (StringUtils.isNotBlank(req.getRuleStatus())) {
            queryWrapper.eq(AgentRuleEntity::getRuleStatus, req.getRuleStatus());
        }
        if (StringUtils.isNotBlank(req.getRuleCode())) {
            queryWrapper.like(AgentRuleEntity::getRuleCode, req.getRuleCode().trim());
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

        // ── 更新日期区间（2026-09-16 修复：原先传 LocalDateTime，日期检索必然失败）──
        // 缘由：`agent_rule.update_time` 的列类型是 **VARCHAR(30)**（见交付包 DDL / 本地库实测），
        //   而实体字段也是 String；源实现却把 'yyyy-MM-dd' 解析成 LocalDateTime 再 between/ge/le，
        //   JDBC 会把参数按 timestamp 发送 → PG 解析 `character varying >= timestamp without time zone`
        //   **无此运算符**（varchar→timestamp 不是隐式转换）→ 接口直接报错，前端表现为"选完日期点查询就失败"。
        // 修法：改为**字符串比较**。'YYYY-MM-DD HH:mm:ss' 的字典序与时间序一致，
        //   对 varchar 列是正确比较；若将来该列改成 timestamp，字符串字面量也会被 PG 隐式转成 timestamp，
        //   两种列类型都成立，故这是最稳的写法。
        String startFull = dayStart(req.getStartTime());
        String endFull = dayEnd(req.getEndTime());
        if (startFull != null && endFull != null) {
            queryWrapper.between(AgentRuleEntity::getUpdateTime, startFull, endFull);
        } else if (startFull != null) {
            queryWrapper.ge(AgentRuleEntity::getUpdateTime, startFull);
        } else if (endFull != null) {
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
        // 【真实业务执行】打上严格取数标记（2026-09-16 新增）
        // 规则页的"执行"结果会被采纳，属于正式执行，必须"填什么就是什么"：
        // 参数没传全时，宁可这次取不到数，也绝不能让取数层拿配置里预置的样例值
        // （如 '苏州XX精密机械制造有限公司' / '科大讯飞股份有限公司'）兜底顶上。
        // 与 AgentPromptController#getRule（规则判定 + 智策引擎补充分析）保持同一口径。
        // 该标记随 requestParams 透传：handleParam 会把 params 所有键拷进 paramData，最终在
        // SqlDataSetBuilder#build 读到它。
        JSONObject requestParams = req.getRequestParams();
        if (requestParams == null) {
            requestParams = new JSONObject();
            req.setRequestParams(requestParams);
        }
        requestParams.put(SqlDataSetBuilder.STRICT_FETCH_KEY, true);
        // 【入参名归一】兼容旧写法（2026-09-17 新增）：补上规范名键（双写，原键保留），
        // 使上游仍传 reportno/guarantorname 时也能命中配置里已改成驼峰的 :reportNo / :guarantorName。
        AgentParamNames.normalizeInPlace(requestParams);
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

    /**
     * 把前端传来的「日期」归一成可与 varchar 列比较的**字符串**下界。
     *
     * @param date 前端传 {@code yyyy-MM-dd}；若已带时分秒则原样使用，避免二次拼接
     * @return {@code yyyy-MM-dd 00:00:00}；入参为空时返回 {@code null}（表示不加该条件）
     */
    private static String dayStart(String date) {
        String s = StringUtils.trimToEmpty(date);
        if (s.isEmpty()) {
            return null;
        }
        return s.length() > 10 ? s : s + " 00:00:00";
    }

    /** {@link #dayStart} 的上界版本：补 23:59:59，保证「当天」的记录被包含在内。 */
    private static String dayEnd(String date) {
        String s = StringUtils.trimToEmpty(date);
        if (s.isEmpty()) {
            return null;
        }
        return s.length() > 10 ? s : s + " 23:59:59";
    }
}