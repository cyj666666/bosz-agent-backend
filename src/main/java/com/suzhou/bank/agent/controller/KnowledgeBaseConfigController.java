package com.suzhou.bank.agent.controller;


import com.alibaba.fastjson.JSONObject;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.entity.KnowledgeRelateIndexEntity;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.KnowledgeBlackConfigSaveVO;
import com.suzhou.bank.agent.model.vo.KnowledgeBlackParamsConfigVO;
import com.suzhou.bank.agent.service.IknowledgeBaseConfigService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

@Slf4j
@RestController
@Tag(name = "知识库配置管理")
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/KnowledgeBase/config"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 统一为 /api/agent（源工程为 /jeecg-boot）。
    @RequestMapping("/api/agent/KnowledgeBase/config")
public class KnowledgeBaseConfigController {

    @Autowired
    private IknowledgeBaseConfigService iknowledgeBaseConfigService;

    @Operation(summary = "指标管理-指标js表达式预览", description = "指标管理-指标js表达式预览")
    @PostMapping(value = "/jsException/preview", name = "指标js表达式预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> previewJsException(@RequestBody PreviewJsExceptionReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.previewJsExpression(reqMsg));
    }

    @Operation(summary = "知识库管理-知识库分组层级列表查询", description = "知识库管理-知识库分组层级列表查询")
    @GetMapping(value = "/group/query", name = "知识库分组层级列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryKnowledgeBaseGroupTree(@RequestParam(name = "authFlag", required = false, defaultValue = "true") boolean authFlag, @RequestParam(name = "spaceId", required = false) Integer spaceId, @RequestParam(name = "relaGroupFlag", required = false) String relaGroupFlag, @RequestParam(name = "modelFlag", required = false) Integer modelFlag, @RequestParam(name = "groupName", required = false) String groupName, @RequestParam(name = "groupValue", required = false) String groupValue) {
        return AgentResult.OK(iknowledgeBaseConfigService.queryKnowledgeBaseGroupTree(authFlag, spaceId, relaGroupFlag, modelFlag, groupName, groupValue));
    }

    @Operation(summary = "知识库管理-知识库最上层分组列表查询", description = "知识库管理-知识库最上层分组列表查询")
    @GetMapping(value = "/group/query/first", name = "知识库最上层分组列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryFirstKnowledgeGroup() {
        return AgentResult.OK(iknowledgeBaseConfigService.queryFirstKnowledgeGroup());
    }

    @Operation(summary = "知识库管理-新增知识库分组", description = "知识库管理-新增知识库分组")
    @PostMapping(value = "/group/add", name = "新增知识库分组", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> insertKnowledgeBaseGroupInfo(@RequestBody KnowledgeBaseGroupReq reqMsg) {
        return iknowledgeBaseConfigService.insertKnowledgeBaseGroupInfo(reqMsg);
    }

    @Operation(summary = "知识库管理-知识库分组更新", description = "知识库管理-知识库分组更新")
    @PostMapping(value = "/group/update", name = "知识库参数组更新", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateKnowledgeBaseGroupInfo(@RequestBody KnowledgeBaseGroupReq reqMsg) {
        return iknowledgeBaseConfigService.updateKnowledgeBaseGroupInfo(reqMsg);
    }

    @Operation(summary = "知识库管理-知识库分组删除", description = "知识库管理-知识库分组删除")
    @PostMapping(value = "/group/delete", name = "知识库分组删除", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> deleteKnowledgeBaseGroupInfo(@RequestBody KnowledgeBaseGroupReq reqMsg) {
        return iknowledgeBaseConfigService.deleteKnowledgeBaseGroupInfo(reqMsg.getGroupId());
    }

    @Operation(summary = "知识库管理-分组下新增知识库", description = "知识库管理-分组下新增知识库")
    @PostMapping(value = "/add", name = "分组下新增知识库", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> insertKnowledgeBaseParamsInfo(@RequestBody KnowledgeBaseParamsInfoSaveReq reqMsg) {
        return iknowledgeBaseConfigService.insertKnowledgeBaseParamsInfo(reqMsg);
    }

    @Operation(summary = "知识库管理-新增制度文件类型知识库", description = "知识库管理-新增制度文件类型知识库")
    @PostMapping(value = "/document/add", name = "新增制度文件类型知识库", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> addDocumentKnowledge(@RequestBody DocumentKnowledgeReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.addDocumentKnowledge(reqMsg));
    }

    @Operation(summary = "知识库管理-知识库解绑", description = "知识库管理-知识库解绑")
    @PostMapping(value = "/unbind", name = "知识库解绑", produces = MediaType.APPLICATION_JSON_VALUE)
    public Object unbindKnowledge(@RequestBody JSONObject reqMsg) {
        return iknowledgeBaseConfigService.unbindKnowledge(reqMsg);
    }

    @Operation(summary = "知识库管理-分组下复制知识库", description = "知识库管理-分组下复制知识库")
    @PostMapping(value = "/copy", name = "分组下复制知识库", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> copyKnowledgeBaseParamsInfo(@RequestBody KnowledgeBaseParamsInfoSaveReq reqMsg) {
        iknowledgeBaseConfigService.copyKnowledgeBaseParamsInfo(reqMsg);
        return AgentResult.OK();
    }

    @Operation(summary = "知识库管理-分组下移动知识库", description = "知识库管理-分组下移动知识库")
    @PostMapping(value = "/move", name = "分组下移动知识库", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> moveKnowledgeBaseParamsInfo(@RequestBody KnowledgeBaseParamsInfoSaveReq reqMsg) {
        iknowledgeBaseConfigService.moveKnowledgeBaseParamsInfo(reqMsg);
        return AgentResult.OK();
    }

    @Operation(summary = "知识库管理-分组下知识库列表查询", description = "知识库管理-分组下知识库列表查询")
    @PostMapping(value = "/queryList", name = "分组下知识库列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryKnowledgeBaseParamsList(@RequestBody KnowledgeBaseParamReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.queryKnowledgeBaseParamsList(reqMsg));
    }

    @Operation(summary = "知识库管理-分组下知识库列表查询", description = "知识库管理-分组下知识库列表查询")
    @PostMapping(value = "/pageList", name = "分组下知识库列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> pageKnowledgeBaseParamsList(@RequestBody KnowledgeBaseParamReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.pageKnowledgeBaseParamsList(reqMsg));
    }

    @Operation(summary = "知识库管理-分组下知识库列表查询", description = "知识库管理-分组下知识库列表查询")
    @PostMapping(value = "/simplePageList", name = "分组下知识库列表查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> simplePageKnowledgeBaseParamsList(@RequestBody KnowledgeBaseParamReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.simplePageKnowledgeBaseParamsList(reqMsg));
    }

    @Operation(summary = "知识库管理-分组下知识库详情查询", description = "知识库管理-分组下知识库详情查询")
    @PostMapping(value = "/queryInfo", name = "分组下知识库详情查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryKnowledgeBaseParamsInfo(@RequestBody KnowledgeBaseParamsInfoReq reqMsg) {
        return iknowledgeBaseConfigService.queryKnowledgeBaseParamsInfo(reqMsg);
    }

    @Operation(summary = "知识库管理-知识库细类参数查询", description = "知识库管理-知识库细类参数查询")
    @PostMapping(value = "/getSourceParamList", name = "知识库细类参数查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> getSourceParamList(@RequestBody KnowledgeBaseParamsInfoReq reqMsg) {
        return iknowledgeBaseConfigService.getSourceParamList(reqMsg.getParamId());
    }

    @Operation(summary = "知识库管理-分组下知识库删除", description = "知识库管理-分组下知识库删除")
    @PostMapping(value = "/delete", name = "分组下知识库删除", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> deleteKnowledgeBaseParamsInfo(@RequestBody KnowledgeBaseParamsInfoReq reqMsg) {
        return iknowledgeBaseConfigService.deleteKnowledgeBaseParamsInfo(reqMsg.getParamId());
    }

    @Operation(summary = "知识库管理-分组下知识库更新", description = "知识库管理-分组下知识库更新")
    @PostMapping(value = "/update", name = "知识库参数更新", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateKnowledgeBaseParamsInfo(@RequestBody KnowledgeBaseParamsInfoSaveReq reqMsg) {
        return iknowledgeBaseConfigService.updateKnowledgeBaseParamsInfo(reqMsg);
    }

    @Operation(summary = "知识库管理-分组下知识库prompt配置预览", description = "知识库管理-分组下知识库prompt配置预览")
    @PostMapping(value = "/preview", name = "分组下知识库prompt配置预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> KnowledgeBasePromptPreview(@RequestBody KnowledgeBasePromptViewReq reqMsg) {
        return iknowledgeBaseConfigService.knowledgeBasePromptPreview(reqMsg);
    }

    @Operation(summary = "知识库管理-分组下知识库溯源配置预览", description = "知识库管理-分组下知识库溯源配置预览")
    @PostMapping(value = "/resource/preview", name = "分组下知识库溯源配置预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> KnowledgeResourcePreview(@RequestBody KnowledgeResourceViewReq reqMsg) {
        return iknowledgeBaseConfigService.KnowledgeResourcePreview(reqMsg);
    }

    @Operation(summary = "知识库管理-分组下知识库溯源配置预览", description = "知识库管理-分组下知识库溯源配置预览")
    @PostMapping(value = "/tracePreview", name = "分组下知识库溯源配置预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> KnowledgeBaseTracePreview(@RequestBody KnowledgeBasePromptViewReq reqMsg) {
        return iknowledgeBaseConfigService.KnowledgeBaseTracePreview(reqMsg);
    }

    @Operation(summary = "知识库管理-分组下知识库图片溯源配置预览", description = "知识库管理-分组下知识库图片溯源配置预览")
    @PostMapping(value = "/imagePreview", name = "分组下知识库图片溯源配置预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> KnowledgeBaseImagePreview(@RequestBody KnowledgeBasePromptViewReq reqMsg) {
        return iknowledgeBaseConfigService.KnowledgeBaseImagePreview(reqMsg);
    }

    @Operation(summary = "知识库管理-分组下知识库全部来源配置预览", description = "知识库管理-分组下知识库全部来源配置预览")
    @PostMapping(value = "/wholeSourcePreview", name = "分组下知识库全部来源配置预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> KnowledgeBaseWholeSourcePreview(@RequestBody KnowledgeBasePromptViewReq reqMsg) {
        return iknowledgeBaseConfigService.KnowledgeBaseWholeSourcePreview(reqMsg);
    }

    @Operation(summary = "知识库管理-AI问答提问", description = "知识库管理-AI问答提问")
    @PostMapping(value = "/getAiAnswerMsgNo", name = "知识库管理-AI问答提问")
    public AgentResult<?> getAiAnswerMsgNo(@RequestBody KnowledgeBasePromptViewReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.getAiAnswerMsgNo(reqMsg));
    }

    @Operation(summary = "知识库管理-AI获取回答", description = "知识库管理-AI获取回答")
    @GetMapping(value = "/summaryAnswer", name = "知识库管理-AI获取回答")
    public SseEmitter getSummaryAnswer(@RequestParam(name = "mainType") String mainType, @RequestParam(name = "entName") String entName, @RequestParam(name = "paramId") String paramId, @RequestParam(name = "largeModelCode") String largeModelCode, @RequestParam(name = "inputParam", required = false) List<JSONObject> inputParam) {
        KnowledgeBasePromptViewReq req = new KnowledgeBasePromptViewReq();
        req.setEntName(entName);
        req.setParamId(paramId);
        req.setMainType(mainType);
        req.setLargeModelCode(largeModelCode);
        req.setInputParam(inputParam);
        req.setAuthFlag(true);
        req.setIgnoreStatus(true);
        SseEmitter emitter = new SseEmitter(0L);
        iknowledgeBaseConfigService.sendAnswer(req, emitter);
        return emitter;
    }

    @Operation(summary = "知识库管理-AI获取回答", description = "知识库管理-AI获取回答")
    @PostMapping(value = "/getSummaryAnswer", name = "知识库管理-AI获取回答")
    public SseEmitter getSummaryAnswer(@RequestBody KnowledgeBasePromptViewReq req) {
        SseEmitter emitter = new SseEmitter(0L);
        req.setAuthFlag(true);
        req.setIgnoreStatus(true);
        iknowledgeBaseConfigService.sendAnswer(req, emitter);
        return emitter;
    }

    @Operation(summary = "知识库配置-结果校验", description = "知识库配置-结果校验")
    @PostMapping(value = "/getResultCheck", name = "知识库配置-结果校验")
    public SseEmitter getCheckBlackParam(@RequestBody @Valid KnowledgeResultCheckReq reqMsg) {
        SseEmitter emitter = new SseEmitter(0L);
        iknowledgeBaseConfigService.sendResultCheck(reqMsg, emitter);
        return emitter;
    }

    @Operation(summary = "知识库配置-结果校验", description = "知识库配置-结果校验")
    @PostMapping(value = "/resultCheck", name = "知识库配置-结果校验")
    public AgentResult<?> checkBlackParam(@RequestBody @Valid KnowledgeResultCheckReq reqMsg) {
        return iknowledgeBaseConfigService.resultCheck(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-参数选择列表", description = "黑盒参数配置-参数选择列表")
    @PostMapping(value = "/getParamSelectList", name = "黑盒参数配置-参数选择列表")
    public AgentResult<?> getParamSelectList(@RequestBody KnowledgeBlackParamsConfigReq reqMsg) {
        return iknowledgeBaseConfigService.getParamSelectList(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-参数配置列表查询", description = "黑盒参数配置-参数配置列表查询")
    @PostMapping(value = "/getKnowledgeParamsList", name = "黑盒参数配置-参数配置列表查询")
    public AgentResult<?> getKnowledgeParamsList(@RequestBody KnowledgeBlackParamsConfigReq reqMsg) {
        return AgentResult.OK(iknowledgeBaseConfigService.getKnowledgeParamsList(reqMsg));
    }

    @Operation(summary = "黑盒参数配置-新增参数配置", description = "黑盒参数配置-新增参数配置")
    @PostMapping(value = "/addKnowledgeParams", name = "黑盒参数配置-新增参数配置")
    public AgentResult<?> addKnowledgeParams(@RequestBody KnowledgeBlackParamsConfigVO reqMsg) {
        return iknowledgeBaseConfigService.addKnowledgeParams(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-批量新增参数配置", description = "黑盒参数配置-批量新增参数配置")
    @PostMapping(value = "/batchAddKnowledgeParams", name = "黑盒参数配置-批量新增参数配置")
    public AgentResult<?> batchAddKnowledgeParams(@RequestBody List<KnowledgeBlackParamsConfigVO> reqMsg) {
        return iknowledgeBaseConfigService.batchAddKnowledgeParams(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-更新参数配置", description = "黑盒参数配置-更新参数配置")
    @PostMapping(value = "/updateKnowledgeParams", name = "黑盒参数配置-更新参数配置")
    public AgentResult<?> updateKnowledgeParams(@RequestBody KnowledgeBlackParamsConfigVO reqMsg) {
        return iknowledgeBaseConfigService.updateKnowledgeParams(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-批量更新参数配置", description = "黑盒参数配置-批量更新参数配置")
    @PostMapping(value = "/batchUpdateKnowledgeParams", name = "黑盒参数配置-批量更新参数配置")
    public AgentResult<?> batchUpdateKnowledgeParams(@RequestBody List<KnowledgeBlackParamsConfigVO> reqMsg) {
        return iknowledgeBaseConfigService.batchUpdateKnowledgeParams(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-删除参数配置", description = "黑盒参数配置-删除参数配置")
    @PostMapping(value = "/deleteKnowledgeParams", name = "黑盒参数配置-删除参数配置")
    public AgentResult<?> deleteKnowledgeParams(@RequestBody KnowledgeBlackParamsConfigReq reqMsg) {
        return iknowledgeBaseConfigService.deleteKnowledgeParams(reqMsg);
    }

    @Operation(summary = "黑盒参数配置-批量删除参数配置", description = "黑盒参数配置-批量删除参数配置")
    @PostMapping(value = "/batchDeleteKnowledgeParams", name = "黑盒参数配置-批量删除参数配置")
    public AgentResult<?> batchDeleteKnowledgeParams(@RequestBody List<Integer> idList) {
        return iknowledgeBaseConfigService.batchDeleteKnowledgeParams(idList);
    }

    @Operation(summary = "黑盒参数配置-黑盒预览保存", description = "黑盒参数配置-黑盒预览保存")
    @PostMapping(value = "/saveBlackParam", name = "黑盒参数配置-黑盒预览保存")
    public AgentResult<?> saveBlackParam(@RequestBody KnowledgeBlackConfigSaveVO reqMsg) {
        return iknowledgeBaseConfigService.saveBlackParam(reqMsg);
    }

    @Operation(summary = "知识库关联指标信息-分页列表查询", description = "知识库关联指标信息-分页列表查询")
    @PostMapping(value = "/relate/index/list")
    public AgentResult<?> queryPageList(@RequestBody @Valid KnowledgeRelateIndexReq knowledgeRelateIndexReq) {
        return AgentResult.OK(iknowledgeBaseConfigService.selectRelateIndexList(knowledgeRelateIndexReq));
    }

    @Operation(summary = "知识库关联指标信息-添加", description = "知识库关联指标信息-添加")
    @PostMapping(value = "/relate/index/add")
    public AgentResult<?> add(@RequestBody KnowledgeRelateIndexEntity knowledgeRelateIndex) {
        return AgentResult.OK(iknowledgeBaseConfigService.saveRelateIndex(knowledgeRelateIndex));
    }

    @Operation(summary = "知识库关联指标信息-编辑", description = "知识库关联指标信息-编辑")
    @PostMapping(value = "/relate/index/edit")
    public AgentResult<?> edit(@RequestBody List<KnowledgeRelateIndexEntity> knowledgeRelateIndexList) {
        iknowledgeBaseConfigService.updateRelateIndex(knowledgeRelateIndexList);
        return AgentResult.OK("编辑成功!");
    }

    @Operation(summary = "知识库关联指标信息-通过id删除", description = "知识库关联指标信息-通过id删除")
    @PostMapping(value = "/relate/index/delete")
    public AgentResult<?> delete(@RequestBody List<Integer> idList) {
        iknowledgeBaseConfigService.removeRelateIndexList(idList);
        return AgentResult.OK("删除成功!");
    }
}
