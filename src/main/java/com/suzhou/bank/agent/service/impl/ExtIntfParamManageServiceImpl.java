package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.crypto.digest.MD5;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.suzhou.bank.agent.client.CommonApiClient;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentBizException;
import cn.hutool.core.date.DateUtil;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.enums.IntfParamTypeEnum;
import com.suzhou.bank.agent.enums.OnlineEnum;
import com.suzhou.bank.agent.mapper.ExtIntfParamManageMapper;
import com.suzhou.bank.agent.model.dto.ExtIntfParamManageDTO;
import com.suzhou.bank.agent.entity.ExtIntfManageEntity;
import com.suzhou.bank.agent.entity.ExtIntfParamDefineEntity;
import com.suzhou.bank.agent.entity.ExtIntfParamManageEntity;
import com.suzhou.bank.agent.entity.ExtIntfSupplierEntity;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.service.ExtIntfParamManageService;
import com.suzhou.bank.agent.cache.DoubleCache;
import com.suzhou.bank.agent.entity.SysCategory;
import com.suzhou.bank.agent.service.ISysCategoryService;
import com.suzhou.bank.agent.util.APIClient;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.stream.Collectors;


@Slf4j
@Service
public class ExtIntfParamManageServiceImpl extends ServiceImpl<ExtIntfParamManageMapper, ExtIntfParamManageEntity> implements ExtIntfParamManageService {

    @Autowired
    private ExtIntfParamManageMapper extIntfParamManageMapper;
    @Autowired
    private ExtIntfManageServiceImpl extIntfManageService;
    @Autowired
    private ExtIntfSupplierManageServiceImpl extIntfSupplierManageService;
    @Autowired
    private ExtIntfParamDefineServiceImpl extIntfParamDefineService;
    @Autowired
    private DoubleCache doubleCache;
    @Autowired
    private CommonApiClient commonApiClient;
    @Autowired
    private ISysCategoryService sysCategoryService;
    @Autowired
    private APIClient apiClient;

    @Override
    public ListResult<?> queryExtIntfParamManageList(ExtIntfParamManageListReq reqMsg) {
        QueryWrapper<ExtIntfParamManageEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", reqMsg.getSupplierId());
        queryWrapper.eq("intf_no", reqMsg.getIntfNo());
        queryWrapper.orderByDesc("update_time", "input_time");
        Page<ExtIntfParamManageEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        Page<ExtIntfParamManageEntity> listPage = page(page, queryWrapper);
        List<ExtIntfParamManageDTO> collect = listPage.getRecords().stream().map(extIntfParamManageEntity -> BeanUtil.toBean(extIntfParamManageEntity, ExtIntfParamManageDTO.class)).collect(Collectors.toList());
        return new ListResult<>(Integer.parseInt(String.valueOf(listPage.getTotal())), collect);
    }

    @Override
    public boolean checkExtIntfParamManageRepeat(CheckExtIntfParamManageRepeatReq req) {
        QueryWrapper<ExtIntfParamManageEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", req.getSupplierId());
        queryWrapper.eq("intf_no", req.getIntfNo());
        queryWrapper.eq("param_code", req.getParamCode());
        return count(queryWrapper) == 0;
    }

    @Override
    public boolean handleExtIntfParamManage(ExtIntfParamManageReq req) {
        if (StringUtils.isNotEmpty(req.getSourceFieldDictId())) {
            SysCategory sysCategory = sysCategoryService.getById(req.getSourceFieldDictId());
            if (Objects.nonNull(sysCategory)) {
                req.setSourceField(sysCategory.getParamValue());
                req.setSourceFieldName(sysCategory.getName());
                req.setSourceTypeDetail(sysCategory.getSourceTypeDetail());
            }
        } else {
            req.setSourceFieldDictId("");
            req.setSourceField("");
            req.setSourceFieldName("");
            req.setSourceTypeDetail("");
        }

        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        if (StringUtils.isNotBlank(req.getId())) {
            ExtIntfParamManageEntity entity = new ExtIntfParamManageEntity();
            BeanUtil.copyProperties(req, entity, true);
            entity.setUpdateUserId(apiContextModel.getUserId());
            entity.setUpdateUserName(apiContextModel.getUserName());
            entity.setUpdateTime(DateUtil.now());
            QueryWrapper<ExtIntfParamManageEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("id", req.getId());
            return update(entity, queryWrapper);
        }

        List<ExtIntfParamManageReq> objects = new ArrayList<>();
        req.setInputUserId(apiContextModel.getUserId());
        req.setInputUserName(apiContextModel.getRealName());
        req.setInputTime(DateUtil.now());
        objects.add(req);
        List<ExtIntfParamManageEntity> collect = objects.stream().map(o -> BeanUtil.toBean(o, ExtIntfParamManageEntity.class)).collect(Collectors.toList());
        return saveBatch(collect);
    }

    @Override
    public boolean removeExtIntfParamManage(RemoveExtIntfReq req) {
        return removeByIds(req.getIds());
    }

    @Override
    public Map<String, String> getIntfData(String paramNo, String supplierId, String intfNo, JSONObject paramJson, JSONArray intfParamArr, String relateIndexSet) {
        ExtIntfSupplierEntity extIntfSupplierEntity = extIntfSupplierManageService.getById(supplierId);
        if (Objects.isNull(extIntfSupplierEntity)) {
            throw new AgentBizException("查询异常！");
        }

        LambdaQueryWrapper<ExtIntfManageEntity> extIntfQueryWrapper = Wrappers.lambdaQuery();
        extIntfQueryWrapper.eq(ExtIntfManageEntity::getSupplierId, supplierId);
        extIntfQueryWrapper.eq(ExtIntfManageEntity::getIntfNo, intfNo);
        extIntfQueryWrapper.eq(ExtIntfManageEntity::getIntfStatus, "1");
        List<ExtIntfManageEntity> extIntfManageEntityList = extIntfManageService.list(extIntfQueryWrapper);
        if (CollectionUtils.isEmpty(extIntfManageEntityList)) {
            throw new AgentBizException("查询异常！");
        }

        // 请求头参数
        JSONObject headerParams = new JSONObject();

        // 查询公共参数(过滤出请求头参数、请求体参数、url参数）
        JSONObject publicParam = new JSONObject();
        JSONObject urlParam = new JSONObject();
        LambdaQueryWrapper<ExtIntfParamDefineEntity> lambdaQueryWrapper = Wrappers.lambdaQuery();
        lambdaQueryWrapper.eq(ExtIntfParamDefineEntity::getSupplierId, supplierId);
        List<ExtIntfParamDefineEntity> paramDefineEntityList = extIntfParamDefineService.list(lambdaQueryWrapper);
        if (CollectionUtils.isNotEmpty(paramDefineEntityList)) {
            paramDefineEntityList.forEach(param -> {
                String paramPosition = param.getParamPosition();
                String paramIsRequired = param.getParamIsRequired();
                if (StringUtils.isNotEmpty(paramPosition) && "2".equals(paramPosition) && "1".equals(paramIsRequired)) {
                    headerParams.put(param.getParamCode(), param.getParamValue());
                }
                if (StringUtils.isNotEmpty(paramPosition) && "3".equals(paramPosition) && "1".equals(paramIsRequired)) {
                    urlParam.put(param.getParamCode(), param.getParamValue());
                }
                if (StringUtils.isNotEmpty(paramPosition) && "1".equals(paramPosition)) {
                    publicParam.put(param.getParamCode(), param.getParamValue());
                }
            });
        }

        // 查询接口参数（过滤出请求头参数、请求体参数）
        LambdaQueryWrapper<ExtIntfParamManageEntity> extIntfParamQueryWrapper = Wrappers.lambdaQuery();
        extIntfParamQueryWrapper.eq(ExtIntfParamManageEntity::getSupplierId, supplierId);
        extIntfParamQueryWrapper.eq(ExtIntfParamManageEntity::getIntfNo, intfNo);
        List<ExtIntfParamManageEntity> extIntfParamManageEntityList = list(extIntfParamQueryWrapper);

        // 细类参数解析
        JSONObject xlParamObj = new JSONObject();
        if (StringUtils.isNotEmpty(relateIndexSet)) {
            JSONArray jsonArray = JSON.parseArray(relateIndexSet);
            if (null != jsonArray && !jsonArray.isEmpty()) {
                List<JSONObject> collect = jsonArray.stream().map(json -> (JSONObject) json).filter(json -> paramNo.equals(json.getString("paramNo"))).collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(collect)) {
                    List<JSONObject> paramsList = collect.get(0).getJSONArray("params").stream().map(json -> (JSONObject) json).filter(json -> "1".equals(json.getString("sourceFlag"))).collect(Collectors.toList());
                    if (CollectionUtils.isNotEmpty(paramsList)) {
                        paramsList.forEach(params -> {
                            String pField = params.getString("field");
                            String pSourceField = params.getString("sourceField");
                            if (StringUtils.isNotEmpty(pSourceField)) {
                                String[] split = pSourceField.split("-");
                                if (split.length == 2) {
                                    xlParamObj.put(pField, split[1]);
                                } else if (split.length == 3) {
                                    xlParamObj.put(pField, split[2]);
                                } else if (split.length > 3) {
                                    int index = pSourceField.indexOf("-", split[0].length() + 1);
                                    xlParamObj.put(pField, pSourceField.substring(index + 1));
                                }
                            }
                        });
                    }
                }
            }
        }

        if (CollectionUtils.isNotEmpty(extIntfParamManageEntityList)) {
            // 过滤出请求头参数、url参数
            extIntfParamManageEntityList.forEach(param -> {
                String paramPosition = param.getParamPosition();
                String paramIsRequired = param.getParamIsRequired();
                if (StringUtils.isNotEmpty(paramPosition) && "2".equals(paramPosition) && "1".equals(paramIsRequired)) {
                    headerParams.put(param.getParamCode(), param.getParamValue());
                }
                if (StringUtils.isNotEmpty(paramPosition) && "3".equals(paramPosition) && "1".equals(paramIsRequired)) {
                    urlParam.put(param.getParamCode(), param.getParamValue());
                }
            });

            // 过滤请求参数：指标配置时设定了否隐藏某些参数
            List<String> fiterKeyList = new ArrayList<>();
            if (null != intfParamArr && !intfParamArr.isEmpty()) {
                intfParamArr.forEach(param -> {
                    JSONObject json = (JSONObject) param;
                    for (String key : json.keySet()) {
                        JSONObject jsonObject = json.getJSONObject(key);
                        if (jsonObject.containsKey("isHide") && OnlineEnum.Y.name().equalsIgnoreCase(jsonObject.getString("isHide"))) {
                            fiterKeyList.add(key);
                        }
                        break;
                    }
                });
            }
            extIntfParamManageEntityList = extIntfParamManageEntityList.stream().filter(p -> !fiterKeyList.contains(p.getParamCode()) && "1".equals(p.getParamPosition())).collect(Collectors.toList());

            for (ExtIntfParamManageEntity param : extIntfParamManageEntityList) {
                Object paramValue = null;

                String paramCode = param.getParamCode(); // 父级参数
                String parentParamType = param.getParamType(); // 父级参数类型
                String childParamCode = param.getChildParamCode(); // 子参数
                String childParamType = StringUtils.isNotEmpty(param.getChildParamType()) ? param.getChildParamType() : parentParamType; // 子参数类型
                String sourceParamCode = param.getSourceParamCode(); // 关联参数
                String sourceParamType = param.getSourceParamType(); // 关联参数类型
                String sourceField = param.getSourceField(); // 细类字段
                String sourceTypeDetail = param.getSourceTypeDetail(); // 细类类型

                // 新细分逻辑取值
                if (xlParamObj.containsKey(paramCode)) {
                    String sourceKey = xlParamObj.getString(paramCode);
                    JSONObject extensions = paramJson.getJSONObject("extensions");
                    try {
                        if (Objects.isNull(extensions)) {
                            String extensionsStr = String.valueOf(paramJson.get("extensions_str"));
                            if (StringUtils.isNotBlank(extensionsStr)) {
                                extensions = JSON.parseObject(extensionsStr);
                            }
                        }
                    } catch (Exception e) {
                        log.error("extensions_str取值异常！");
                    }
                    if (Objects.nonNull(extensions)) {
                        paramValue = extensions.get(sourceKey);
                        if (StringUtils.isNotEmpty(param.getChildParamType()) && "4".equals(param.getChildParamType())) {
                            if ("5".equals(parentParamType) && Objects.nonNull(paramValue)) {
                                JSONArray newArr = new JSONArray();
                                for (Object obj : (JSONArray) paramValue) {
                                    newArr.add(JSONObject.parseObject(obj.toString()));
                                }
                                paramValue = newArr;
                            }
                        }
                    }
                }
                // 原细分取值逻辑
                if (Objects.isNull(paramValue) && StringUtils.isNotEmpty(sourceTypeDetail)) {
                    JSONObject extensions = paramJson.getJSONObject("extensions");
                    try {
                        if (Objects.isNull(extensions)) {
                            String extensionsStr = String.valueOf(paramJson.get("extensions_str"));
                            if (StringUtils.isNotBlank(extensionsStr)) {
                                extensions = JSON.parseObject(extensionsStr);
                            }
                        }
                    } catch (Exception e) {
                        log.error("extensions_str取值异常！");
                    }
                    if (Objects.nonNull(extensions)) {
                        JSONObject paramMapping = extensions.getJSONObject("paramMapping");
                        if (Objects.nonNull(paramMapping)) {
                            JSONArray jsonArray = paramMapping.getJSONArray(sourceField);
                            if (null != jsonArray && !jsonArray.isEmpty() && jsonArray.contains(intfNo.concat(".").concat(paramCode))) {
                                JSONObject jsonObject = extensions.getJSONObject(sourceTypeDetail);
                                if (Objects.nonNull(jsonObject)) {
                                    paramValue = jsonObject.get(sourceField);
                                    if (StringUtils.isNotEmpty(param.getChildParamType()) && "4".equals(param.getChildParamType())) {
                                        if ("5".equals(parentParamType) && Objects.nonNull(paramValue)) {
                                            JSONArray newArr = new JSONArray();
                                            for (Object obj : (JSONArray) paramValue) {
                                                newArr.add(JSONObject.parseObject(obj.toString()));
                                            }
                                            paramValue = newArr;
                                        }
                                    }
                                }
                            }
                        }
                        if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                            JSONObject extensionsDetail = extensions.getJSONObject(sourceTypeDetail);
                            if (Objects.nonNull(extensionsDetail)) {
                                paramValue = ParamUtil.getValue(param, childParamType, extensionsDetail.get(sourceParamCode));
                            }
                        }
                    }
                }
                // 关联参数取值逻辑
                if (Objects.isNull(paramValue) && StringUtils.isNotEmpty(sourceParamCode)) {
                    Object sourceValue = paramJson.get(sourceParamCode);
                    if (Objects.nonNull(sourceValue) && StringUtils.isNotEmpty(String.valueOf(sourceValue))) {
                        paramValue = ParamUtil.getValue(param, sourceParamType, sourceValue);
                    }
                    if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                        paramValue = ParamUtil.getValue(param, childParamType, paramJson.get(paramCode));
                    }
                }
                // 默认字段取值逻辑
                if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                    paramValue = ParamUtil.getValue(param, childParamType, paramJson.get(paramCode));
                }
                // R1536接口参数特殊处理
                if ("R1536".equals(intfNo)) {
                    JSONObject extensions = paramJson.getJSONObject("extensions");
                    try {
                        if (Objects.isNull(extensions)) {
                            String extensionsStr = String.valueOf(paramJson.get("extensions_str"));
                            if (StringUtils.isNotBlank(extensionsStr)) {
                                extensions = JSON.parseObject(extensionsStr);
                            }
                        }
                    } catch (Exception e) {
                        log.error("extensions_str取值异常！");
                    }
                    if (Objects.nonNull(extensions) && !extensions.isEmpty()) {
                        JSONObject icObject = extensions.getJSONObject("IC");
                        if (Objects.nonNull(icObject)) {
                            String[] split = paramCode.split("\\.");
                            if (split.length == 1) {
                                paramValue = icObject.get(paramCode);
                            } else {
                                paramValue = icObject.get(split[split.length - 1]);
                            }
                        }
                    }
                }
                // 黑盒配置取值
                if ((Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) && Objects.nonNull(paramJson.get("blackParams"))) {
                    Map<String, Object> blackParams = (Map<String, Object>) paramJson.get("blackParams");
                    String newParamCode = paramNo + "--" + paramCode;
                    if (blackParams.containsKey(newParamCode)) {
                        paramValue = ParamUtil.getValue(param, param.getParamType(), blackParams.get(newParamCode));
                    }
                }
                // 默认值取值逻辑
                if (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue))) {
                    paramValue = ParamUtil.getValue(param, param.getParamType(), param.getParamValue());
                }
                // 不是必填字段，如果值为空，则不作为传参
                String paramIsRequired = param.getParamIsRequired();
                if ("0".equals(paramIsRequired) && (Objects.isNull(paramValue) || StringUtils.isEmpty(String.valueOf(paramValue)))) {
                    continue;
                }
                // 组装接口请求参数
                if (paramCode.contains(".")) {
                    String[] split = paramCode.split("\\.");
                    if (split.length > 2) {
                        // 通用多层嵌套：逐层导航至倒数第二级，再根据 parentParamType 处理叶子节点
                        JSONObject current = publicParam;
                        // 从 split[0] 到 split[length-3]，逐层创建/获取 JSONObject
                        for (int i = 0; i < split.length - 2; i++) {
                            String key = split[i];
                            if (current.containsKey(key)) {
                                current = current.getJSONObject(key);
                            } else {
                                JSONObject newObj = new JSONObject();
                                current.put(key, newObj);
                                current = newObj;
                            }
                        }
                        // current 现在是 split[length-3] 对应的 JSONObject，处理最后两级
                        String parentKey = split[split.length - 2];
                        // 如果配置了子参数编码，优先使用子参数编码作为叶子节点key
                        String leafKey = StringUtils.isNotEmpty(childParamCode) ? childParamCode : split[split.length - 1];
                        // 如果配置了子参数类型，按子参数类型进行值转换
                        Object leafValue = paramValue;
                        if (StringUtils.isNotEmpty(childParamType)) {
                            leafValue = ParamUtil.getValue(param, childParamType, paramValue);
                        }
                        if (IntfParamTypeEnum.LIST.id.equals(parentParamType)) {
                            if (current.containsKey(parentKey)) {
                                JSONArray parentArr = current.getJSONArray(parentKey);
                                // 如果最后一个元素是JSONObject，合并字段到同一元素中
                                if (!parentArr.isEmpty() && parentArr.get(parentArr.size() - 1) instanceof JSONObject) {
                                    parentArr.getJSONObject(parentArr.size() - 1).put(leafKey, leafValue);
                                } else {
                                    JSONObject childJson = new JSONObject();
                                    childJson.put(leafKey, leafValue);
                                    parentArr.add(childJson);
                                }
                            } else {
                                JSONArray parentArr = new JSONArray();
                                JSONObject childJson = new JSONObject();
                                childJson.put(leafKey, leafValue);
                                parentArr.add(childJson);
                                current.put(parentKey, parentArr);
                            }
                        } else {
                            // OBJECT 或其他类型统一按 OBJECT 处理
                            if (current.containsKey(parentKey)) {
                                JSONObject parentObj = current.getJSONObject(parentKey);
                                parentObj.put(leafKey, leafValue);
                            } else {
                                JSONObject parentObj = new JSONObject();
                                parentObj.put(leafKey, leafValue);
                                current.put(parentKey, parentObj);
                            }
                        }
                    } else {
                        // 多主体类型处理
                        JSONArray childArray = new JSONArray();
                        if ("1".equals(paramJson.getString("isMutiEnt"))) {
                            if (Objects.nonNull(paramValue) && StringUtils.isNotEmpty(childParamCode)) {
                                try {
                                    JSONArray list = (JSONArray) paramValue;
                                    list.forEach(json -> {
                                        JSONObject obj = new JSONObject();
                                        obj.put(childParamCode, json);
                                        childArray.add(obj);
                                    });
                                } catch (Exception e) {
                                    log.error("参数值为：{}的多主体类型解析异常，异常信息{}", JSON.toJSONString(paramValue), ExceptionUtils.getStackTrace(e));
                                }
                                if (publicParam.containsKey(split[0])) {
                                    publicParam.getJSONObject(split[0]).put(split[1], childArray);
                                } else {
                                    JSONObject innerParam = new JSONObject();
                                    innerParam.put(split[1], childArray);
                                    publicParam.put(split[0], innerParam);
                                }
                            } else {
                                if (publicParam.containsKey(split[0])) {
                                    publicParam.getJSONObject(split[0]).put(split[1], paramValue);
                                } else {
                                    JSONObject innerParam = new JSONObject();
                                    innerParam.put(split[1], paramValue);
                                    publicParam.put(split[0], innerParam);
                                }
                            }
                        } else {
                            if (IntfParamTypeEnum.LIST.id.equals(parentParamType) && StringUtils.isNotEmpty(childParamCode)) {
                                // LIST类型 + 子参数：创建并合并数组元素到同一对象中
                                JSONObject childJson = new JSONObject();
                                childJson.put(childParamCode, paramValue);
                                if (publicParam.containsKey(split[0])) {
                                    JSONObject parentObj = publicParam.getJSONObject(split[0]);
                                    if (parentObj.containsKey(split[1]) && parentObj.get(split[1]) instanceof JSONArray) {
                                        JSONArray existArr = parentObj.getJSONArray(split[1]);
                                        if (!existArr.isEmpty() && existArr.get(existArr.size() - 1) instanceof JSONObject) {
                                            existArr.getJSONObject(existArr.size() - 1).put(childParamCode, paramValue);
                                        } else {
                                            existArr.add(childJson);
                                        }
                                    } else {
                                        JSONArray newArr = new JSONArray();
                                        newArr.add(childJson);
                                        parentObj.put(split[1], newArr);
                                    }
                                } else {
                                    JSONArray newArr = new JSONArray();
                                    newArr.add(childJson);
                                    JSONObject innerParam = new JSONObject();
                                    innerParam.put(split[1], newArr);
                                    publicParam.put(split[0], innerParam);
                                }
                            } else {
                                if (publicParam.containsKey(split[0])) {
                                    publicParam.getJSONObject(split[0]).put(split[1], paramValue);
                                } else {
                                    JSONObject innerParam = new JSONObject();
                                    innerParam.put(split[1], paramValue);
                                    publicParam.put(split[0], innerParam);
                                }
                            }
                        }
                    }
                } else {
                    publicParam.put(paramCode, paramValue);
                }
            }
        }

        // 先从缓存中取，如果缓存不存在再调用接口
        String cacheKey = MD5.create().digestHex(supplierId + intfNo + ParamUtil.sortJSONObject(publicParam).toJSONString(), StandardCharsets.UTF_8);
        try {
            Map value = doubleCache.getValue(cacheKey, Map.class);
            if (value != null && !value.isEmpty()) {
                return value;
            }
        } catch (Exception e) {
            log.error("从缓存中查询失败，失败原因：{}", ExceptionUtils.getStackTrace(e));
        }

        // 接口调用
        ExtIntfManageEntity extIntfManageEntity = extIntfManageEntityList.get(0);
        String intfRequestType = extIntfManageEntity.getIntfRequestType();
        String intfPath = extIntfSupplierEntity.getIntfPath() + extIntfManageEntity.getIntfPath();

        JSONObject result;
        if ("GetEnterpriseLabelData".equals(intfNo)) {
            result = apiClient.sendRequest(intfNo, intfPath, publicParam);
        } else {
            result = commonApiClient.execute(intfPath, intfNo, intfRequestType, publicParam, headerParams, urlParam);
        }

        Map<String, String> dataMap = new HashMap<>();
        dataMap.put(publicParam.toJSONString(), Objects.isNull(result) ? "" : JSON.toJSONString(result, SerializerFeature.WriteBigDecimalAsPlain));
        try {
            if (Objects.nonNull(result) && StringUtils.isNotEmpty(result.getString("code")) && ("0000".equals(result.getString("code")) || result.getInteger("code") == 0)) {
                doubleCache.set(cacheKey, dataMap);
            }
        } catch (Exception e) {
            log.error("设置缓存异常，异常信息：{}", ExceptionUtils.getStackTrace(e));
        }

        return dataMap;
    }

    @Override
    public JSONObject getIntfStructure(CheckExtIntfManageRepeatReq reqMsg) {
        LambdaQueryWrapper<ExtIntfManageEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(ExtIntfManageEntity::getSupplierId, reqMsg.getSupplierId());
        queryWrapper.eq(ExtIntfManageEntity::getIntfNo, reqMsg.getIntfNo());
        List<ExtIntfManageEntity> extIntfManageEntityList = extIntfManageService.list(queryWrapper);
        if (CollectionUtils.isEmpty(extIntfManageEntityList)) {
            return null;
        }
        return JSON.parseObject(extIntfManageEntityList.get(0).getIntfStructure());
    }

    @Override
    public List<ExtIntfParamManageEntity> listExtIntfParamManage(List<String> supplierIdList, ArrayList<String> intfNoList) {
        LambdaQueryWrapper<ExtIntfParamManageEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.in(ExtIntfParamManageEntity::getSupplierId, supplierIdList);
        queryWrapper.in(ExtIntfParamManageEntity::getIntfNo, intfNoList);
        return list(queryWrapper);
    }

    @Override
    public void saveDistanceExtIntfParamManage(List<ExtIntfParamManageEntity> paramManageList) {
        saveOrUpdateBatch(paramManageList);
    }

    @Override
    public List<ExtIntfParamManageEntity> listExtIntfParamManage(String supplierId, String intfNo) {
        LambdaQueryWrapper<ExtIntfParamManageEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(ExtIntfParamManageEntity::getSupplierId, supplierId);
        queryWrapper.eq(ExtIntfParamManageEntity::getIntfNo, intfNo);
        return list(queryWrapper);
    }

}
