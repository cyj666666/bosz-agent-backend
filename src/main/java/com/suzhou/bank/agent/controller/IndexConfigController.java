package com.suzhou.bank.agent.controller;


import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.IndexBaseGroupVO;
import com.suzhou.bank.agent.service.IIndexConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/**
 * 指标配置接口
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.controller.IndexConfigController}（21 个接口），
 * 方法签名与业务逻辑原样平移。</p>
 *
 * <p><b>迁移改造点（共 3 处，均不改变接口语义）</b>：</p>
 * <ol>
 *   <li><b>路径前缀</b>：源工程为 {@code /index/config}，本工程改为 {@code /api/agent/index/config}。
 *       必须加前缀的原因有两个——宿主 {@code AuthInterceptor} 只拦截 {@code /api/**}
 *       （不在其中则完全无鉴权），且前端 agent 模块的 axios baseURL 是 {@code /api}。</li>
 *   <li><b>返回体</b>：{@code org.jeecg.common.api.vo.Result} → {@code AgentResult}。
 *       注意两者的<b>业务字段名不同</b>：源工程是 {@code result}，本工程是 {@code data}，
 *       这是前端接口层需要适配的点（agent 模块的 api 已按 {@code data} 解包）。</li>
 *   <li><b>移除 {@code @AutoLog}</b>：那是 JeecgBoot 的操作日志注解，本工程无对应切面，
 *       保留只会误导（看起来有日志、实际不落）。宿主已有 {@code ControllerLogAspect} 统一记录。</li>
 * </ol>
 */
@Slf4j
@RestController
@Tag(name = "指标管理")
@RequestMapping("/api/agent/index/config")
public class IndexConfigController {

    @Autowired
    private IIndexConfigService indexConfigService;

    @Operation(summary = "指标管理-指标分组层级列表查询", description = "指标管理-指标分组层级列表查询")
    @GetMapping(value = "/group/query", name = "指标分组层级列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryIndexBaseGroupTree(@RequestParam(name = "groupName", required = false) String groupName, @RequestParam(name = "groupValue", required = false) String groupValue) {
        return AgentResult.OK(indexConfigService.queryIndexBaseGroupTree(groupName, groupValue));
    }

    @Operation(summary = "指标管理-添加指标分组", description = "指标管理-添加指标分组")
    @PostMapping(value = "/add/group", name = "添加指标分组", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> addIndexGroup(@RequestBody IndexBaseGroupVO indexBaseGroupVO) {
        return AgentResult.OK(indexConfigService.addIndexGroup(indexBaseGroupVO));
    }

    @Operation(summary = "指标管理-指标分组更新", description = "指标管理-指标分组更新")
    @PostMapping(value = "/group/update", name = "指标参数组更新", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateIndexBaseGroupInfo(@RequestBody IndexBaseGroupVO reqMsg) {
        return AgentResult.OK(indexConfigService.updateIndexBaseGroupInfo(reqMsg));
    }

    @Operation(summary = "指标管理-指标分组删除", description = "指标管理-指标分组删除")
    @PostMapping(value = "/group/delete", name = "指标分组删除", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> deleteIndexBaseGroupInfo(@RequestBody IndexBaseGroupVO reqMsg) {
        return AgentResult.OK(indexConfigService.deleteIndexBaseGroupInfo(reqMsg.getGroupId()));
    }

    @Operation(summary = "指标管理-分组下指标列表查询", description = "指标管理-分组下指标列表查询")
    @PostMapping(value = "/queryIndexList", name = "分组下指标列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryIndexBaseParamsList(@RequestBody IndexBaseGroupReq reqMsg) {
        return AgentResult.OK(indexConfigService.queryIndexBaseParamsList(reqMsg));
    }

    @Operation(summary = "指标管理-参数信息列表查询", description = "指标管理-参数信息列表查询")
    @PostMapping(value = "/queryList", name = "参数信息列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryIndexParamsList(@RequestBody IndexParamQueryReq reqMsg) {
        return AgentResult.OK(indexConfigService.queryIndexParamsList(reqMsg));
    }

    @Operation(summary = "指标管理-查询全部指标数据", description = "指标管理-查询全部指标数据")
    @PostMapping(value = "/queryAllList", name = "查询全部指标数据", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryAllList(@RequestBody IndexParamQueryReq reqMsg) {
        return AgentResult.OK(indexConfigService.getAllIndexParamsList(reqMsg));
    }

    @Operation(summary = "指标管理-查询所有指标列表", description = "指标管理-查询所有指标列表")
    @PostMapping(value = "/all/queryList", name = "查询所有指标列表", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryAllIndexParamsList(@RequestBody IndexParamQueryReq reqMsg) {
        return AgentResult.OK(indexConfigService.queryIndexParamsListFromCache(reqMsg));
    }

    @Operation(summary = "指标管理-刷新缓存", description = "指标管理-刷新缓存")
    @GetMapping(value = "/refresh/index/cache", name = "指标管理-刷新缓存", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> refreshIndexCache() {
        indexConfigService.refreshIndexCache();
        return AgentResult.OK("刷新成功！");
    }

    @Operation(summary = "指标管理-参数信息详情查询", description = "指标管理-参数信息详情查询")
    @PostMapping(value = "/queryInfo", name = "参数信息详情查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryIndexParamsInfo(@RequestBody IndexParamsInfoReq reqMsg) {
        return indexConfigService.queryIndexParamsInfo(reqMsg);
    }

    @Operation(summary = "查询指标关联知识库信息", description = "查询指标关联知识库信息")
    @GetMapping(value = "/queryIndexRelateKnowledgeInfo", name = "查询指标关联知识库信息", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryIndexRelaKnowledgeInfo(String paramNo) {
        return indexConfigService.queryIndexRelateKnowledgeInfo(paramNo);
    }

    @Operation(summary = "指标管理-指标关联知识库校验查询", description = "指标管理-指标关联知识库校验查询")
    @PostMapping(value = "/queryRelateKnowledgeInfo", name = "指标关联知识库校验查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryRelateKnowledgeInfo(@RequestBody IndexParamsInfoReq reqMsg) {
        return indexConfigService.queryRelateKnowledgeInfo(reqMsg);
    }

    @Operation(summary = "指标管理-指标关联指标校验查询", description = "指标管理-指标关联指标校验查询")
    @PostMapping(value = "/queryRelateIndexInfo", name = "指标关联指标校验查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryRelateIndexInfo(@RequestBody IndexParamsInfoReq reqMsg) {
        return indexConfigService.queryRelateIndexInfo(reqMsg);
    }

    @Operation(summary = "指标管理-根据指标编号查询涉及到的接口或者数据源查询的相关参数", description = "指标管理-根据指标编号查询涉及到的接口或者数据源查询的相关参数")
    @PostMapping(value = "/relate/params", name = "根据指标编号查询涉及到的接口或者数据源查询的相关参数", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> getRelateParamsList(@RequestBody IndexParamsInfoReq reqMsg) {
        return indexConfigService.getRelateParamsList(reqMsg);
    }

    @Operation(summary = "指标管理-新增指标参数组", description = "指标管理-新增指标参数组")
    @PostMapping(value = "/object/add", name = "新增指标参数组", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> insertIndexParamsObject(@RequestBody IndexParamsInfoSaveReq reqMsg) {
        return indexConfigService.insertIndexParamsObject(reqMsg);
    }

    @Operation(summary = "指标管理-新增指标参数", description = "指标管理-新增指标参数")
    @PostMapping(value = "/add", name = "新增指标参数", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> insertIndexParamsInfo(@RequestBody IndexParamsInfoSaveReq reqMsg) {
        return indexConfigService.insertIndexParamsInfo(reqMsg);
    }

    @Operation(summary = "指标管理-复制指标参数", description = "指标管理-复制指标参数")
    @PostMapping(value = "/copy", name = "复制指标参数", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> copyIndexParamsInfo(@RequestBody IndexParamsInfoSaveReq reqMsg) {
        return indexConfigService.copyIndexParamsInfo(reqMsg);
    }

    @Operation(summary = "指标管理-移动指标参数", description = "指标管理-移动指标参数")
    @PostMapping(value = "/move", name = "移动指标参数", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> moveIndexParamsInfo(@RequestBody IndexMoveReq reqMsg) {
        return indexConfigService.moveIndexParamsInfo(reqMsg);
    }

    @Operation(summary = "指标管理-参数信息列表删除", description = "指标管理-参数信息列表删除")
    @PostMapping(value = "/delete", name = "参数信息列表删除接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> deleteIndexParamsList(@RequestBody IndexParamsInfoReq reqMsg) {
        return indexConfigService.deleteIndexParamsList(reqMsg.getParamNo());
    }

    @Operation(summary = "指标管理-指标参数更新", description = "指标管理-指标参数更新")
    @PostMapping(value = "/update", name = "指标参数更新", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateIndexParamsInfo(@RequestBody IndexParamsInfoSaveReq reqMsg) {
        return indexConfigService.updateIndexParamsInfo(reqMsg);
    }

    @Operation(summary = "指标管理-指标参数组更新", description = "指标管理-指标参数组更新")
    @PostMapping(value = "/object/update", name = "指标参数组更新", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateIndexParamsObject(@RequestBody IndexParamsInfoSaveReq reqMsg) {
        return indexConfigService.updateIndexParamsObject(reqMsg);
    }
}
