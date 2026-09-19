package com.suzhou.bank.agent.controller;

import com.alibaba.fastjson.JSONObject;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.servlet.http.HttpServletRequest;
import javax.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.util.JSONTools;
import com.suzhou.bank.agent.util.AgentParamNames;
import com.suzhou.bank.agent.core.SqlDataSetBuilder;
import com.suzhou.bank.agent.entity.AgentRuleEntity;
import com.suzhou.bank.agent.model.req.AgentRuleExecuteReq;
import com.suzhou.bank.agent.model.req.IndexInfoSearchReq;
import com.suzhou.bank.agent.model.req.KnowledgePreviewReq;
import com.suzhou.bank.agent.model.vo.AgentRuleExecuteVO;
import com.suzhou.bank.agent.service.IAgentRuleService;
import com.suzhou.bank.agent.service.IknowledgeBaseConfigService;
import com.suzhou.bank.agent.util.CallLlmUtil;
import com.suzhou.bank.agent.util.ParamUtil;
import com.suzhou.bank.agent.util.QLExpressUtil;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.io.InputStream;
import java.util.*;

@Slf4j
@Tag(name = "Agent服务公共接口")
@RestController
@RequiredArgsConstructor
// 迁移改造点：源工程【没有类级映射】，只有方法级裸路径（"/get"、"/callLlm" 等）。
// 本工程必须补一个类级前缀，原因有两个：
//   ① 宿主 AuthInterceptor 只拦 /api/**，裸路径完全无鉴权；
//   ② "/get" 这种极短路径挂在根下，极易与宿主既有映射冲突。
// 前端相应地把 axios baseURL 换成 /api/agent，各 api 文件里的相对路径无需改动。
@RequestMapping("/api/agent")
public class AgentPromptController {

    /**
     * 允许上传的文件扩展名白名单
     */
    private static final Set<String> ALLOWED_EXTENSIONS = new HashSet<>(Arrays.asList(
            "jpg", "jpeg", "png", "gif", "bmp", "svg",
            "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
            "txt", "csv", "json", "xml",
            "zip", "rar", "7z", "tar", "gz"
    ));

    /**
     * 最大文件上传大小：10MB
     */
    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024;

    private final IknowledgeBaseConfigService knowledgeBaseConfigService;

    private final CallLlmUtil callLlmUtil;

    private final IAgentRuleService agentRuleService;

    /**
     * 给「配置页预览 / 试跑」类入口注入「允许样例值兜底」标记（2026-09-19）。
     *
     * <p>⛔ <b>本标记不会让样例值覆盖真实入参</b> —— 取数层只在**该参数调用方没传值**时
     * 才可能用到 {@code defaultValue}；传了值就永远用传入的值。
     * 它表达的只有一件事：<b>"这个入口允许不填参数、拿配置里的样例值看效果"</b>。</p>
     *
     * <p>背景：取数层已改成 <b>fail-closed</b> —— 没显式声明就一律严格，参数缺失时
     * 宁可不取数也不碰样例值（那些样例值是真实企业/合同编号，吃了会产出
     * "看着正常实则张冠李戴"的结论）。而配置页预览本来就要能用样例值，所以由入口显式放行。</p>
     *
     * <p>⚠️ 若将来有**真实业务**链路复用这些入口（用真实入参跑生产数据），
     * 应去掉这个标记 —— 那种场景缺少参数时**就该取不到数**，而不是拿样例值顶上。</p>
     */
    private static String asSampleFallbackRequest(String paramStr) {
        try {
            JSONObject jo = JSONObject.parseObject(paramStr);
            if (jo == null) {
                jo = new JSONObject();
            }
            jo.put(SqlDataSetBuilder.ALLOW_SAMPLE_FALLBACK_KEY, true);
            return jo.toJSONString();
        } catch (Throwable e) {
            // 解析不了就原样透传（严格模式），绝不让"注入标记"这件事本身变成故障点
            log.warn("样例兜底标记注入失败，按严格模式透传：{}", e.getMessage());
            return paramStr;
        }
    }

    @Operation(summary = "获取prompt文案", description = "获取prompt文案")
    @PostMapping(value = "/get", name = "获取prompt文案", produces = MediaType.APPLICATION_JSON_VALUE)
    public Object getPrompt(@RequestBody String paramStr) {
        SseEmitter emitter = new SseEmitter(0L);
        // 配置页预览 ⇒ 允许"没填参数时"用样例值兜底（传了真实参数仍用真实参数）
        return knowledgeBaseConfigService.getPromptContent(asSampleFallbackRequest(paramStr), emitter);
    }

    @Operation(summary = "获取规则文案", description = "获取规则文案")
    @PostMapping(value = "/get/rule", name = "获取规则文案", produces = MediaType.APPLICATION_JSON_VALUE)
    public Object getRule(@RequestBody String paramStr) {
        JSONObject params = JSONObject.parseObject(paramStr);
        // 【入参名归一】兼容旧写法（2026-09-17 新增）
        // 配置侧参数名已统一成驼峰（reportNo / entName / guarantorName），调用方可能仍传
        // reportno / guarantorname 等历史写法。这里补上规范名键（**双写**，原键保留）——
        // 于是上游一行都不用改，新旧写法都能命中；归一动作会打 【入参归一】 日志便于观察。
        AgentParamNames.normalizeInPlace(params);
        // 【真实业务执行】打上严格取数标记（2026-09-16 新增）
        // 本条链路是"规则判定 + 智策引擎补充分析"的正式执行路径，必须"填什么就是什么"：
        // 参数没传全时，宁可这次取不到数，也绝不能让取数层拿配置里预置的样例值
        // （如 '苏州XX精密机械制造有限公司' / '科大讯飞股份有限公司'）兜底顶上。
        // 该标记随 params 一路透传：既进 executeRule 的 requestParams，也进 getPromptContent 的 getParams。
        params.put(SqlDataSetBuilder.STRICT_FETCH_KEY, true);
        String ruleCode = JSONTools.getString(params,"ruleCode");
        AgentRuleEntity agentRuleEntity = agentRuleService.getRule(ruleCode);
        if(agentRuleEntity!=null){
            AgentRuleExecuteReq req = new AgentRuleExecuteReq();

            req.setRuleCode(ruleCode);

            req.setName(JSONTools.getString(params, "name"));

            req.setId(agentRuleEntity.getId());
            req.setRuleStatus(agentRuleEntity.getRuleStatus());
            req.setParsedExpression(agentRuleEntity.getParsedExpression());
            req.setPromptKey(agentRuleEntity.getPromptKey());
            if(StringUtils.isNotBlank(agentRuleEntity.getFactAnalysis())){
                req.setFactAnalysis(agentRuleEntity.getFactAnalysis());
            }
            req.setRequestParams(params);
            AgentRuleExecuteVO agentRuleExecuteVO = agentRuleService.executeRule(req);
            JSONObject jo = new JSONObject();
            if(agentRuleExecuteVO!=null) {
                jo.put("ruleResult", agentRuleExecuteVO.getResultStatus());
                jo.put("ruleData", agentRuleExecuteVO.getMatchedMetrics());
                jo.put("factExpression", agentRuleExecuteVO.getFactExpression());
            }

            String isRule = JSONTools.getString(params,"isRule");
            if("Y".equals(isRule)){
                jo.put("code",200);
                return jo;
            }
            if(QLExpressUtil.getResultAsBool(agentRuleExecuteVO.getResultStatus())) {
                JSONObject getParams = new JSONObject();
                //1.处置意见
                getParams.put("content", agentRuleEntity.getDisposalAdvice());
                // 2.阈值设定
                getParams.put("input", agentRuleEntity.getThresholdConfig());
                // 3.指标溯源（规则引擎解析出来的溯源明细）
                getParams.put("data", agentRuleExecuteVO.getMatchedMetrics());
                // 4.风险释义
                getParams.put("risk", agentRuleEntity.getRiskRemark());
                // 5.命中结果（字符串"命中"/"未命中" 或者布尔值）
                getParams.put("result", agentRuleExecuteVO.getResultStatus());
                // 6.检查项名称
                getParams.put("rule_name", agentRuleEntity.getRuleName());
                // 7.事实分析表达式
                if(StringUtils.isNotBlank(agentRuleExecuteVO.getFactExpression())) {
                    getParams.put("factExpression", agentRuleExecuteVO.getFactExpression());
                }
                // 兼容透传原有前端基础参数（promptKey、objectName）
                getParams.put("moduleCode", "IntelligentStrategyEngine");
                params.keySet().forEach(key -> {
                    getParams.put(key, params.get(key));
                });
                SseEmitter emitter = new SseEmitter(0L);
                return knowledgeBaseConfigService.getPromptContent(getParams.toJSONString(), emitter);
            }
            jo.put("code",200);
            return jo;
        }
        JSONObject jo = new JSONObject();
        jo.put("ruleResult", "");
        jo.put("ruleData", new ArrayList<>());
        jo.put("factExpression", "");
        jo.put("code",500);
        jo.put("message","该规则不存在");
        return jo;
    }

    @Operation(summary = "获取prompt文案", description = "获取prompt文案")
    @PostMapping(value = "/get/prompt", name = "获取prompt文案", produces = MediaType.APPLICATION_JSON_VALUE)
    public Object getPromptContent(@RequestBody String paramStr) {
        SseEmitter emitter = new SseEmitter(0L);
        // 配置页预览 ⇒ 允许"没填参数时"用样例值兜底（传了真实参数仍用真实参数）
        return knowledgeBaseConfigService.getPromptContent(asSampleFallbackRequest(paramStr), emitter);
    }

    @Operation(summary = "流式获取prompt文案", description = "流式获取prompt文案")
    @PostMapping(value = "/get/knowledge", name = "流式获取prompt文案", produces = MediaType.APPLICATION_JSON_VALUE)
    public Object getKnowledge(@RequestBody String paramStr) {
        SseEmitter emitter = new SseEmitter(0L);
        // 配置页流式预览 ⇒ 允许"没填参数时"用样例值兜底（传了真实参数仍用真实参数）
        return knowledgeBaseConfigService.getPromptStream(asSampleFallbackRequest(paramStr), emitter);
    }

    @Operation(summary = "大模型文案渲染", description = "大模型文案渲染")
    @PostMapping(value = "/callLlm", name = "大模型文案渲染")
    public Object callLlm(@RequestBody JSONObject param) {
        SseEmitter emitter = new SseEmitter(0L);
        return callLlmUtil.callLlm(param, emitter, false, true, false);
    }

    @Operation(summary = "应用提示词文案渲染", description = "应用提示词文案渲染")
    @PostMapping(value = "/applyPrompt", name = "应用提示词文案渲染", produces = MediaType.APPLICATION_JSON_VALUE)
    public Object applyPrompt(@RequestBody JSONObject param) {
        SseEmitter emitter = new SseEmitter(0L);
        return knowledgeBaseConfigService.getApplyPrompt(param, emitter);
    }

    @Operation(summary = "知识库开始预览", description = "知识库开始预览")
    @PostMapping(value = "/knowledge/preview")
    public Object knowledgePreview(@RequestBody @Valid KnowledgePreviewReq knowledgePreviewReq) {
        return knowledgeBaseConfigService.knowledgePreview(knowledgePreviewReq);
    }

    @Operation(summary = "大模型调用", description = "大模型调用")
    @PostMapping(value = "/knowledge/callLlm")
    public Object knowledgeCallLlm(@RequestBody @Valid JSONObject req) {
        SseEmitter emitter = new SseEmitter(0L);
        knowledgeBaseConfigService.knowledgeCallLlm(req, emitter);
        return emitter;
    }


    @Operation(summary = "通过指标ID查询指标结果", description = "通过指标ID查询指标结果")
    @PostMapping(value = "/get/index/result")
    public AgentResult<?> getIndexResult(@RequestBody IndexInfoSearchReq indexInfoSearchReq) {
        String indexId = indexInfoSearchReq.getIndexId();
        if (StringUtils.isEmpty(indexId)) {
            return AgentResult.error("参数异常！");
        }

        // 生成一个追踪ID，用于在日志中追踪请求
        JSONObject params = indexInfoSearchReq.getParams();
        String plumeLogId = params.getString("plumeLogId");
        String traceId = StringUtils.isNotEmpty(plumeLogId) ? plumeLogId : ParamUtil.getSessionNo("");
        params.put("traceId", traceId);

        Map<String, Object> indexValueMap = knowledgeBaseConfigService.getIndexValueMap("", params, Collections.singletonList(indexId), null);
        if (null == indexValueMap || indexValueMap.isEmpty()) {
            return AgentResult.OK();
        }

        return AgentResult.OK(indexValueMap.get(indexId));
    }

    @Operation(summary = "通过指标ID查询指标结果", description = "通过指标ID查询指标结果")
    @PostMapping(value = "/query/index/result")
    public AgentResult<?> queryIndexResult(@RequestBody IndexInfoSearchReq indexInfoSearchReq) {
        List<String> indexIdList = indexInfoSearchReq.getIndexIdList();
        String indexId = indexInfoSearchReq.getIndexId();
        if (CollectionUtils.isEmpty(indexIdList) && StringUtils.isEmpty(indexId)) {
            return AgentResult.error("参数异常！");
        }

        // 生成一个追踪ID，用于在日志中追踪请求
        JSONObject params = indexInfoSearchReq.getParams();
        String plumeLogId = params.getString("plumeLogId");
        String traceId = StringUtils.isNotEmpty(plumeLogId) ? plumeLogId : ParamUtil.getSessionNo("");
        params.put("traceId", traceId);

        List<String> idList = CollectionUtils.isEmpty(indexIdList) ? Collections.singletonList(indexId) : indexIdList;
        Map<String, Object> indexValueMap = knowledgeBaseConfigService.getIndexValueMap("", params, idList, null);
        if (Objects.isNull(indexValueMap) || indexValueMap.isEmpty()) {
            return AgentResult.OK();
        }

        if (CollectionUtils.isEmpty(indexIdList)) {
            return AgentResult.OK(indexValueMap.get(indexId));
        } else {
            indexValueMap.put("traceId", traceId);
            JSONObject result = new JSONObject();
            result.put("traceId", traceId);
            idList.forEach(id -> result.put(id, indexValueMap.get(id)));
            return AgentResult.OK(result);
        }
    }

    @Operation(summary = "缓存知识库文案解析入库", description = "缓存知识库文案解析入库")
    @PostMapping(value = "/knowledge/cache/parse")
    public Object knowledgeCacheParse(HttpServletRequest request) {
        MultipartHttpServletRequest multipartRequest = (MultipartHttpServletRequest) request;
        MultipartFile file = multipartRequest.getFile("file");
        if (null == file || file.isEmpty()) {
            throw new AgentBizException("参数异常！");
        }
        // 文件大小校验
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new AgentBizException("上传文件大小不能超过10MB!");
        }
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !isAllowedExtension(originalFilename)) {
            throw new AgentBizException("不支持的文件类型，仅允许上传: " + String.join(", ", ALLOWED_EXTENSIONS));
        }
        try (InputStream inputStream = file.getInputStream()) {
            String fileName = file.getOriginalFilename();
            knowledgeBaseConfigService.knowledgeCacheParse(inputStream, fileName);
        } catch (IOException e) {
            throw new AgentBizException("知识库缓存文件上传失败！");
        }
        return AgentResult.OK("知识库缓存文件上传成功！");
    }

    /**
     * 校验文件扩展名是否在白名单中
     */
    private static boolean isAllowedExtension(String filename) {
        if (filename == null || filename.isEmpty()) {
            return false;
        }
        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex == -1 || dotIndex == filename.length() - 1) {
            return false;
        }
        String extension = filename.substring(dotIndex + 1).toLowerCase();
        return ALLOWED_EXTENSIONS.contains(extension);
    }
}
