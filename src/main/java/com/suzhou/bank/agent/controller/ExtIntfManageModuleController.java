package com.suzhou.bank.agent.controller;


import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.service.ExtIntfManageService;
import com.suzhou.bank.agent.service.ExtIntfParamDefineService;
import com.suzhou.bank.agent.service.ExtIntfParamManageService;
import com.suzhou.bank.agent.service.ExtIntfSupplierManageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.validation.Valid;
import java.util.Map;

@Slf4j
@RestController
@Tag(name = "外部接口配置模块相关接口")
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/extintf"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则该接口完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，不加前缀会 404。
@RequestMapping("/api/agent/extintf")
public class ExtIntfManageModuleController {

    @Autowired
    private ExtIntfSupplierManageService extIntfSupplierManageService;

    @Autowired
    private ExtIntfParamDefineService extIntfParamDefineService;

    @Autowired
    private ExtIntfManageService extIntfManageService;

    @Autowired
    private ExtIntfParamManageService extIntfParamManageService;

    @PostMapping(value = "/supplier/list", name = "外部服务配置列表查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryExtIntfSupplierList(@RequestBody ExtIntfSupplierListReq reqMsg) {
        return AgentResult.OK(extIntfSupplierManageService.queryExtIntfSupplierList(reqMsg));
    }

    @PostMapping(value = "/supplier/checkrepeat", name = "新增外部服务配置校验服务编号是否重复接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> checkExtIntfSupplierRepeat(@RequestBody @Valid CheckExtIntfSupplierRepeatReq reqMsg) {
        return AgentResult.OK(extIntfSupplierManageService.checkExtIntfSupplierRepeat(reqMsg));
    }

    @PostMapping(value = "/supplier/add", name = "新增外部服务配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> addExtIntfSupplier(@RequestBody @Valid AddExtIntfSupplierReq reqMsg) {
        return AgentResult.OK(extIntfSupplierManageService.addExtIntfSupplier(reqMsg));
    }

    @PostMapping(value = "/supplier/update", name = "更新外部服务配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateExtIntfSupplier(@RequestBody @Valid AddExtIntfSupplierReq reqMsg) {
        return AgentResult.OK(extIntfSupplierManageService.updateExtIntfSupplier(reqMsg));
    }

    @PostMapping(value = "/supplier/remove", name = "删除外部服务配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> removeExtIntfSupplier(@RequestBody @Valid RemoveExtIntfSupplierReq reqMsg) {
        return AgentResult.OK(extIntfSupplierManageService.removeExtIntfSupplier(reqMsg));
    }

    @PostMapping(value = "/supplier/select", name = "外部服务配置下拉选项查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryExtIntfSupplierSelectList() {
        return AgentResult.OK(extIntfSupplierManageService.queryExtIntfSupplierSelectList());
    }

    @PostMapping(value = "/paramdefine/list", name = "外部服务公共参数定义列表查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryExtIntfParamDefineList(@RequestBody ExtIntfParamDefineListReq reqMsg) {
        return AgentResult.OK(extIntfParamDefineService.queryExtIntfParamDefine(reqMsg));
    }

    @PostMapping(value = "/paramdefine/checkrepeat", name = "外部服务公共参数定义列表查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> checkParamDefineRepeat(@RequestBody @Valid CheckExtIntfParamDefineRepeatReq reqMsg) {
        return AgentResult.OK(extIntfParamDefineService.checkParamDefineRepeat(reqMsg));
    }

    @PostMapping(value = "/paramdefine/add", name = "新增外部服务公共参数定义接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> addExtIntfParamDefine(@RequestBody @Valid ExtIntfParamDefineReq reqMsg) {
        return AgentResult.OK(extIntfParamDefineService.handleExtIntfParamDefine(reqMsg));
    }

    @PostMapping(value = "/paramdefine/update", name = "更新外部服务公共参数定义接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateExtIntfParamDefine(@RequestBody @Valid ExtIntfParamDefineReq reqMsg) {
        return AgentResult.OK(extIntfParamDefineService.handleExtIntfParamDefine(reqMsg));
    }

    @PostMapping(value = "/paramdefine/remove", name = "删除外部服务公共参数定义接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> removeExtIntfParamDefine(@RequestBody @Valid RemoveExtIntfReq reqMsg) {
        return AgentResult.OK(extIntfParamDefineService.removeExtIntfParamDefine(reqMsg));
    }

    @PostMapping(value = "/intf/list", name = "外部接口明细配置列表查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryExtIntfManageList(@RequestBody ExtIntfManageListReq reqMsg) {
        return AgentResult.OK(extIntfManageService.queryExtIntfManageList(reqMsg));
    }

    @PostMapping(value = "/intf/checkrepeat", name = "外部接口明细配置校验是否重复接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> checkExtIntfManageRepeat(@RequestBody @Valid CheckExtIntfManageRepeatReq reqMsg) {
        return AgentResult.OK(extIntfManageService.checkExtIntfManageRepeat(reqMsg));
    }

    @PostMapping(value = "/intf/add", name = "新增外部接口明细配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> addExtIntfManage(@RequestBody @Valid ExtIntfManageReq reqMsg) {
        return AgentResult.OK(extIntfManageService.handleExtIntfManage(reqMsg));
    }

    @PostMapping(value = "/intf/update", name = "更新外部接口明细配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateExtIntfManage(@RequestBody @Valid ExtIntfManageReq reqMsg) {
        return AgentResult.OK(extIntfManageService.handleExtIntfManage(reqMsg));
    }

    @PostMapping(value = "/intf/remove", name = "删除外部接口明细配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> removeExtIntfManage(@RequestBody @Valid RemoveExtIntfReq reqMsg) {
        return AgentResult.OK(extIntfManageService.removeExtIntfManage(reqMsg));
    }

    @PostMapping(value = "/intfparam/list", name = "外部接口参数配置列表查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryExtIntfParamManageList(@RequestBody ExtIntfParamManageListReq reqMsg) {
        return AgentResult.OK(extIntfParamManageService.queryExtIntfParamManageList(reqMsg));
    }

    @PostMapping(value = "/intfparam/checkrepeat", name = "外部接口参数配置校验是否重复接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> checkExtIntfParamManageRepeat(@RequestBody @Valid CheckExtIntfParamManageRepeatReq reqMsg) {
        return AgentResult.OK(extIntfParamManageService.checkExtIntfParamManageRepeat(reqMsg));
    }

    @PostMapping(value = "/intfparam/add", name = "新增外部接口参数配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> addExtIntfParamManage(@RequestBody @Valid ExtIntfParamManageReq reqMsg) {
        return AgentResult.OK(extIntfParamManageService.handleExtIntfParamManage(reqMsg));
    }

    @PostMapping(value = "/intfparam/update", name = "更新外部接口参数配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> updateExtIntfParamManage(@RequestBody @Valid ExtIntfParamManageReq reqMsg) {
        return AgentResult.OK(extIntfParamManageService.handleExtIntfParamManage(reqMsg));
    }

    @PostMapping(value = "/intfparam/remove", name = "删除外部接口参数配置接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> removeExtIntfParamManage(@RequestBody @Valid RemoveExtIntfReq reqMsg) {
        return AgentResult.OK(extIntfParamManageService.removeExtIntfParamManage(reqMsg));
    }

    @PostMapping(value = "/intf/preview", name = "外部接口预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> intfPreview(@RequestBody @Valid ExtIntfPreviewReq reqMsg) {
        JSONObject paramJson = StringUtils.isNotEmpty(reqMsg.getParamJsonStr()) ? JSON.parseObject(reqMsg.getParamJsonStr()) : new JSONObject();
        Map<String, String> dataMap = extIntfParamManageService.getIntfData("", reqMsg.getSupplierId(), reqMsg.getIntfNo(), paramJson, null, null);
        if (null == dataMap || dataMap.isEmpty()) {
            return AgentResult.OK();
        }
        String result = "";
        for (Map.Entry<String, String> entry : dataMap.entrySet()) {
            result = entry.getValue();
            break;
        }
        return AgentResult.OK(result);
    }

    @PostMapping(value = "/intf/structure/select", name = "外部接口结构查询", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> getIntfStructure(@RequestBody @Valid CheckExtIntfManageRepeatReq reqMsg) {
        return AgentResult.OK(extIntfParamManageService.getIntfStructure(reqMsg));
    }

}
