package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import cn.hutool.crypto.digest.MD5;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.util.UUIDGenerator;
import com.suzhou.bank.agent.config.AgentProperties;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.entity.IndexBaseGroupEntity;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.enums.DataTypeEnum;
import com.suzhou.bank.agent.enums.ParamGroupEnum;
import com.suzhou.bank.agent.enums.ParamTypeEnum;
import com.suzhou.bank.agent.enums.ScriptTypeEnum;
import com.suzhou.bank.agent.model.dto.IndexBaseGroupDTO;
import com.suzhou.bank.agent.model.dto.IndexParamsDTO;
import com.suzhou.bank.agent.model.dto.IndexParamsSimpleDTO;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.IndexBaseGroupVO;
import com.suzhou.bank.agent.service.*;
import com.suzhou.bank.agent.cache.DoubleCache;
import com.suzhou.bank.agent.entity.SysDataSource;
import com.suzhou.bank.agent.util.TreeUtil;
import com.suzhou.bank.agent.service.ISysDataSourceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.Executor;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@Service
public class IndexConfigServiceImpl implements IIndexConfigService {

    @Autowired
    private IIndexParamsService indexParamsService;

    @Autowired
    private IKnowledgeBaseParamsService knowledgeBaseParamsService;

    // 迁移改造点：源工程是裸 @Autowired（依赖容器里恰好存在一个 Executor）。
    // 本工程里若不加限定符，会注入到报告模块的 reportAiAnalysisExecutor（原因见 AgentTaskExecutorConfig），
    // 导致指标任务与报告 AI 分析抢线程、且线程名误导排查。故显式指定 agent 自己的线程池。
    @Autowired
    @Qualifier("agentTaskExecutor")
    private Executor executor;

    @Autowired
    private IIndexBaseGroupService indexBaseGroupService;

    @Autowired
    private IIndexRelateInfoService indexRelateInfoService;

    @Autowired
    private DoubleCache doubleCache;

    /** agent 模块配置：目前用于「角色-指标过滤」开关（见 AgentProperties 的说明） */
    @Autowired
    private AgentProperties agentProperties;

    @Autowired
    private ISysRoleIndexService sysRoleIndexService;

    @Autowired
    private IIndexRelateKnowledgeInfoService indexRelateKnowledgeInfoService;

    @Autowired
    private IIndexRelateIndexInfoService indexRelateIndexInfoService;

    @Autowired
    private ISysDataSourceService sysDataSourceService;

    @Override
    public ListResult<?> queryIndexParamsList(IndexParamQueryReq reqMsg) {
        if (StringUtils.isEmpty(reqMsg.getParentParamNo())) {
            return new ListResult<>(0, 0);
        }
        QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("parentParamNo", reqMsg.getParentParamNo());
        queryWrapper.eq("modelNo", "Public");
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamId()), "paramid", reqMsg.getParamId());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamName()), "paramname", reqMsg.getParamName());
        queryWrapper.orderByDesc("inputtime");
        List<IndexParamsEntity> paramsList = indexParamsService.list(queryWrapper);
        List<IndexParamsEntity> oneAllParams = new ArrayList<>();
        getAllParamsByParentParamNo(paramsList, oneAllParams);
        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(oneAllParams, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        List<IndexParamsDTO> indexParamsDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsDTO indexParamsDTO = new IndexParamsDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return new ListResult<>(indexParamsDTOList);
    }

    @Override
    public ListResult<?> getAllIndexParamsList(IndexParamQueryReq reqMsg) {
        List<String> indexIdList = getIndexIdListByRoleId();
        // 迁移改造点：源工程此处无条件拦断（拿不到角色授权就返回空）。
        // 本工程 sys_role_index 是无数据的空表且无维护入口，无条件拦断会让页面永远空白，
        // 故改为受 AgentProperties#indexRoleFilterEnabled 控制，默认不过滤。
        if (agentProperties.isIndexRoleFilterEnabled() && CollectionUtils.isEmpty(indexIdList)) {
            return new ListResult<>(0, 0);
        }

        int totalSize = 1;
        List<IndexParamsEntity> records = null;
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName, IndexParamsEntity::getParamType,
                IndexParamsEntity::getDataMethod, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getInputMethod, IndexParamsEntity::getInputUserID,
                IndexParamsEntity::getUpdateUserID, IndexParamsEntity::getInputTime, IndexParamsEntity::getUpdateTime, IndexParamsEntity::getScript,
                IndexParamsEntity::getScriptType, IndexParamsEntity::getSupplierId, IndexParamsEntity::getIntfNo);
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamId()), IndexParamsEntity::getParamID, reqMsg.getParamId());
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamName()), IndexParamsEntity::getParamName, reqMsg.getParamName());
        if (StringUtils.isNotBlank(reqMsg.getParentParamNo())) {
            List<IndexParamsEntity> indexParamsEntities = indexParamsService.selectByParentParamNo(reqMsg.getParentParamNo());
            if (CollectionUtils.isEmpty(indexParamsEntities)) {
                return new ListResult<>(0, 0);
            }
            List<String> collect = indexParamsEntities.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
            queryWrapper.and(qr -> qr.in(IndexParamsEntity::getParentParamNo, collect).or().eq(IndexParamsEntity::getParentParamNo, reqMsg.getParentParamNo()));
        }
        if (StringUtils.isNotEmpty(reqMsg.getParamNo())) {
            // 查询父节点
            IndexParamsEntity indexParamsEntity = indexParamsService.getById(reqMsg.getParamNo());
            if (indexParamsEntity != null) {
                String parentParamNo = indexParamsEntity.getParentParamNo();
                IndexParamsEntity parentEntity = indexParamsService.getById(parentParamNo);
                if (Objects.isNull(parentEntity)) {
                    queryWrapper.and(qr -> qr.eq(IndexParamsEntity::getParamNo, reqMsg.getParamNo()).or().eq(IndexParamsEntity::getParentParamNo, indexParamsEntity.getParamNo()));
                } else {
                    queryWrapper.and(qr -> qr.eq(IndexParamsEntity::getParamNo, reqMsg.getParamNo()).or().eq(IndexParamsEntity::getParentParamNo, parentParamNo).or().eq(IndexParamsEntity::getParamNo, parentParamNo));
                }
                records = indexParamsService.list(queryWrapper);
            }
        } else {
            queryWrapper.in(CollectionUtils.isNotEmpty(indexIdList), IndexParamsEntity::getParentParamNo, indexIdList);
            queryWrapper.orderByDesc(IndexParamsEntity::getInputTime);
            Page<IndexParamsEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
            IPage<IndexParamsEntity> pageList = indexParamsService.page(page, queryWrapper);
            if (pageList.getTotal() <= 0) {
                return new ListResult<>(0, 0);
            }
            totalSize = (int) pageList.getTotal();
            records = pageList.getRecords();
            List<String> paramNoList = records.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
            LambdaQueryWrapper<IndexParamsEntity> childWrapper = Wrappers.lambdaQuery();
            childWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName, IndexParamsEntity::getParamType, IndexParamsEntity::getDataMethod, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getInputMethod, IndexParamsEntity::getInputUserID, IndexParamsEntity::getUpdateUserID, IndexParamsEntity::getInputTime, IndexParamsEntity::getUpdateTime, IndexParamsEntity::getScript, IndexParamsEntity::getScriptType, IndexParamsEntity::getSupplierId, IndexParamsEntity::getIntfNo);
            childWrapper.in(IndexParamsEntity::getParentParamNo, paramNoList);
            List<IndexParamsEntity> childList = indexParamsService.list(childWrapper);
            if (CollectionUtils.isNotEmpty(childList)) {
                records.addAll(childList);
            }
        }
        if (CollectionUtils.isEmpty(records)) {
            return new ListResult<>(0, 0);
        }
        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(records, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        List<IndexParamsDTO> indexParamsDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsDTO indexParamsDTO = new IndexParamsDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTO.setScriptType(param.getScriptType());
                indexParamsDTO.setScriptTypeDesc(getScriptTypeDesc(param.getScriptType()));
                indexParamsDTO.setIndexSource(getIndexSource(param));
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return new ListResult<>(totalSize, reqMsg.getPageSize(), reqMsg.getPageIndex(), indexParamsDTOList);
    }

    private String getScriptTypeDesc(String scriptType) {
        if (StringUtils.isEmpty(scriptType)) {
            return "";
        }
        ScriptTypeEnum scriptTypeEnum = ScriptTypeEnum.getById(scriptType);
        return Objects.isNull(scriptTypeEnum) ? "" : scriptTypeEnum.name;
    }

    private String getIndexSource(IndexParamsEntity param) {
        String scriptType = param.getScriptType();
        if (StringUtils.isEmpty(scriptType)) {
            return "";
        }
        if (ScriptTypeEnum.API.id.equals(scriptType)) {
            String supplierId = StringUtils.isEmpty(param.getSupplierId()) ? "" : param.getSupplierId();
            String intfNo = StringUtils.isEmpty(param.getIntfNo()) ? "" : param.getIntfNo();
            return "服务编号：" + supplierId + "\n接口编号：" + intfNo;
        }
        if (ScriptTypeEnum.SQL.id.equals(scriptType)) {
            String script = param.getScript();
            if (StringUtils.isEmpty(script)) {
                return "";
            }
            return buildSqlIndexSource(script);
        }
        return "";
    }

    private String buildSqlIndexSource(String script) {
        try {
            JSONObject scriptJson = JSONObject.parseObject(script);
            String dataSource = scriptJson.getString("dataSource");
            String sql = scriptJson.getString("sql");
            if (StringUtils.isEmpty(dataSource) || StringUtils.isEmpty(sql)) {
                return "";
            }
            // 查询数据源的code和name
            SysDataSource sysDataSource = sysDataSourceService.getById(dataSource);
            String code = Objects.isNull(sysDataSource) ? "" : StringUtils.defaultString(sysDataSource.getCode());
            String name = Objects.isNull(sysDataSource) ? "" : StringUtils.defaultString(sysDataSource.getName());

            // 解析sql中的表名
            Set<String> tableSet = new LinkedHashSet<>();
            Pattern pattern = Pattern.compile("(?i)\\b(from|join)\\s+([a-zA-Z0-9_\\.]+)");
            Matcher matcher = pattern.matcher(sql);
            while (matcher.find()) {
                String table = matcher.group(2);
                if (StringUtils.isNotEmpty(table)) {
                    if (table.contains(".")) {
                        table = table.substring(table.lastIndexOf(".") + 1);
                    }
                    tableSet.add(table);
                }
            }
            String tables = String.join(",", tableSet);
            return "数据库编号：" + code + "\n" +
                   "数据库名称：" + name + "\n" +
                   "涉及查询的表：" + tables;
        } catch (Exception e) {
            log.error("解析Sql指标来源异常，script：{}，异常：{}", script, e.getMessage());
            return "";
        }
    }

    public void getAllParamsByParentParamNo(List<IndexParamsEntity> list, List<IndexParamsEntity> allList) {
        allList.addAll(list);
        // 指标中 只有输入形式为表格和列表才能作为父指标
        Set<String> collect = list.stream().filter(params -> "LIST".equals(params.getParamType()) || "OBJECT".equals(params.getParamType())).map(IndexParamsEntity::getParamNo).collect(Collectors.toSet());
        if (CollectionUtils.isNotEmpty(collect)) {
            QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.in("parentparamno", collect);
            List<IndexParamsEntity> indexParamsEntityList = indexParamsService.list(queryWrapper);
            getAllParamsByParentParamNo(indexParamsEntityList, allList);
        }
    }

    @Override
    public AgentResult<?> insertIndexParamsInfo(IndexParamsInfoSaveReq reqMsg) {
        IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
        BeanUtil.copyProperties(reqMsg, indexParamsEntity, true);
        indexParamsEntity.setInputTime(DateUtil.now());
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        indexParamsEntity.setInputUserID(apiContextModel.getUserName());
        indexParamsEntity.setUpdateTime(DateUtil.now());
        indexParamsEntity.setUpdateUserID(apiContextModel.getUserName());
        indexParamsEntity.setOtherNo(reqMsg.getParentParamNo());
        indexParamsService.save(indexParamsEntity);
        // 处理api指标
        executor.execute(() -> handleApiIntfField(reqMsg.getScriptType(), indexParamsEntity, reqMsg.getIntfField(), indexParamsEntity.getScriptType(), apiContextModel.getUserName()));
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> insertIndexParamsObject(IndexParamsInfoSaveReq reqMsg) {
        IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
        reqMsg.setParamID(UUIDGenerator.generate());
        reqMsg.setReportVersion(StringUtils.isEmpty(reqMsg.getReportVersion()) ? "Public" : reqMsg.getReportVersion());
        reqMsg.setParamType(ParamGroupEnum.Group.id);
        BeanUtil.copyProperties(reqMsg, indexParamsEntity, true);
        indexParamsEntity.setInputTime(DateUtil.now());
        indexParamsService.save(indexParamsEntity);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> deleteIndexParamsList(String paramNo) {
        boolean delete = indexParamsService.removeById(paramNo);
        if (delete) {
            List<IndexParamsEntity> list = indexParamsService.selectByParentParamNo(paramNo);
            if (list != null) {
                for (IndexParamsEntity indexParams : list) {
                    deleteIndexParamsList(indexParams.getParamNo());
                }
            }
        }
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> queryIndexParamsInfo(IndexParamsInfoReq reqMsg) {
        return AgentResult.OK(indexParamsService.getById(reqMsg.getParamNo()));
    }

    @Override
    public AgentResult<?> updateIndexParamsInfo(IndexParamsInfoSaveReq reqMsg) {
        IndexParamsEntity paramsEntity = indexParamsService.getById(reqMsg.getParamNo());
        if (Objects.isNull(paramsEntity)) {
            return AgentResult.error("更新失败！");
        }

        IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
        BeanUtil.copyProperties(reqMsg, indexParamsEntity, true);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        indexParamsEntity.setUpdateTime(DateUtil.now());
        indexParamsEntity.setUpdateUserID(apiContextModel.getUserName());
        // 如果未选父级指标，就查当前指标的父级指标
        if (StringUtils.isEmpty(indexParamsEntity.getParentParamNo())) {
            String groupNo = getGroupNo(indexParamsEntity.getParamNo());
            indexParamsEntity.setParentParamNo(groupNo);
            indexParamsEntity.setOtherNo(groupNo);
        }
        // 存储父级指标
        indexParamsService.updateById(indexParamsEntity);
        // 处理api指标
        executor.execute(() -> handleApiIntfField(reqMsg.getScriptType(), indexParamsEntity, reqMsg.getIntfField(), paramsEntity.getScriptType(), apiContextModel.getUserName()));
        return AgentResult.OK();
    }

    private void handleRelateIndex(IndexParamsEntity indexParamsEntity, String originalScriptType) {
        // 查询所有子指标
        List<String> paramNoList = new ArrayList<>();
        List<IndexParamsEntity> parentParamList = indexParamsService.selectByParentParamNo(indexParamsEntity.getParamNo());
        if (CollectionUtils.isNotEmpty(parentParamList)) {
            paramNoList = parentParamList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
        }
        String paramNo = indexParamsEntity.getParamNo();
        paramNoList.add(paramNo);

        Set<String> newSet = new HashSet<>();
        String scriptType = indexParamsEntity.getScriptType();
        String intfParams = indexParamsEntity.getIntfParams();
        if (StringUtils.isNotEmpty(intfParams) && "Api".equalsIgnoreCase(scriptType)) {
            JSONArray jsonArray = JSONArray.parseArray(intfParams);
            jsonArray.forEach(json -> {
                JSONObject object = (JSONObject) json;
                object.keySet().forEach(key -> {
                    JSONObject value = object.getJSONObject(key);
                    if (Objects.nonNull(value)) {
                        JSONObject relateIndex = value.getJSONObject("relateIndex");
                        if (Objects.nonNull(relateIndex) && StringUtils.isNotEmpty(relateIndex.getString("no"))) {
                            newSet.add(relateIndex.getString("no"));
                        }
                    }
                });
            });
        }
        String script = indexParamsEntity.getScript();
        if (StringUtils.isNotEmpty(script) && "Sql".equalsIgnoreCase(scriptType)) {
            JSONObject jsonObject = JSONObject.parseObject(script);
            JSONArray jsonArray = jsonObject.getJSONArray("paramData");
            if (CollectionUtils.isNotEmpty(jsonArray)) {
                jsonArray.forEach(json -> {
                    JSONObject object = (JSONObject) json;
                    if (Objects.nonNull(object)) {
                        JSONObject relateIndex = object.getJSONObject("relateIndex");
                        if (Objects.nonNull(relateIndex)) {
                            newSet.add(relateIndex.getString("no"));
                        }
                    }
                });
            }
        }

        if (!scriptType.equals(originalScriptType)) {
            indexRelateInfoService.removeRelateInfoByIndexId(paramNoList);
        }

        if (CollectionUtils.isEmpty(newSet)) {
            return;
        }

        List<String> newList = new ArrayList<>(newSet);
        List<String> relateIndexList = indexRelateInfoService.getRelateIndexList(paramNoList);
        if (CollectionUtils.isEmpty(relateIndexList)) {
            indexRelateInfoService.saveRelateInfo(paramNoList, newList);
            return;
        }
        List<String> deleteList = relateIndexList.stream().filter(item -> !newList.contains(item)).collect(Collectors.toList());
        List<String> addList = newList.stream().filter(item -> !relateIndexList.contains(item)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(deleteList)) {
            indexRelateInfoService.removeRelateInfo(paramNoList, deleteList);
        }
        if (CollectionUtils.isNotEmpty(addList)) {
            indexRelateInfoService.saveRelateInfo(paramNoList, addList);
        }
    }

    private void handleApiIntfField(String scriptType, IndexParamsEntity parentIndexParamEntity, String intfField, String parentScriptType, String userName) {
        if (ScriptTypeEnum.API.id.equalsIgnoreCase(scriptType)) {
            List<IndexParamsEntity> indexParamsEntityList = new ArrayList<>();
            List<String> fieldList = JSONArray.parseArray(intfField, String.class);

            for (String field : fieldList) {
                try {
                    IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
                    indexParamsEntity.setModelNo("Public");
                    indexParamsEntity.setDataMethod("Auto");
                    indexParamsEntity.setReportVersion("Public");
                    indexParamsEntity.setInputMethod("label");
                    indexParamsEntity.setScriptType("Api");
                    indexParamsEntity.setIntfField(field);
                    indexParamsEntity.setInputTime(DateUtil.now());
                    indexParamsEntity.setUpdateTime(DateUtil.now());
                    indexParamsEntity.setParentParamNo(parentIndexParamEntity.getParamNo());
                    indexParamsEntity.setParentParamName(parentIndexParamEntity.getParamName());

                    String extendKey = "";
                    String[] split = field.split("@@");
                    for (String s : split) {
                        JSONObject jsonObject = JSONObject.parseObject(s);
                        for (String key : jsonObject.keySet()) {
                            if (StringUtils.isEmpty(extendKey)) {
                                extendKey = key;
                            } else {
                                extendKey = extendKey + "@@" + key;
                            }
                            break;
                        }
                    }
                    indexParamsEntity.setStructure(extendKey);

                    JSONObject object = JSONObject.parseObject(split[split.length - 1]);
                    String paramId = "";
                    JSONObject paramInfo = new JSONObject();
                    for (String key : object.keySet()) {
                        paramId = key;
                        paramInfo = object.getJSONObject(key);
                        break;
                    }
                    indexParamsEntity.setParamID(paramId);
                    indexParamsEntity.setParamName(paramInfo.getString("name"));
                    String transParamType = transParamType(paramInfo.getString("type"));
                    indexParamsEntity.setParamType(transParamType);
                    indexParamsEntityList.add(indexParamsEntity);
                    // 如果为列表类型，新增一条统计数量指标
                    if (ParamTypeEnum.LIST.id.equals(transParamType)) {
                        IndexParamsEntity indexParamsEntityCount = new IndexParamsEntity();
                        indexParamsEntityCount.setModelNo("Public");
                        indexParamsEntityCount.setDataMethod("Auto");
                        indexParamsEntityCount.setReportVersion("Public");
                        indexParamsEntityCount.setInputMethod("label");
                        indexParamsEntityCount.setScriptType("Api");
                        indexParamsEntityCount.setIntfField(field + "@@count");
                        indexParamsEntityCount.setParentParamNo(parentIndexParamEntity.getParamNo());
                        indexParamsEntityCount.setParentParamName(parentIndexParamEntity.getParamName());
                        indexParamsEntityCount.setParamID(paramId + "_count");
                        indexParamsEntityCount.setParamName(paramId + "_count");
                        indexParamsEntityCount.setParamType(ParamTypeEnum.NUMBER.id);
                        indexParamsEntityCount.setInputTime(DateUtil.now());
                        indexParamsEntityCount.setUpdateTime(DateUtil.now());
                        indexParamsEntityList.add(indexParamsEntityCount);
                    }
                } catch (Exception e) {
                    log.error("{}字段处理异常！", field);
                }
            }

            LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
            queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getIntfField, IndexParamsEntity::getParamID, IndexParamsEntity::getStructure);
            queryWrapper.in(IndexParamsEntity::getParentParamNo, parentIndexParamEntity.getParamNo());
            List<IndexParamsEntity> existIndexParamEntityList = indexParamsService.list(queryWrapper);
            List<IndexParamsEntity> deleteIndexParamEntityList = new ArrayList<>();
            List<IndexParamsEntity> newIndexParamsEntityList;
            if (CollectionUtils.isNotEmpty(existIndexParamEntityList)) {
                List<String> collect = indexParamsEntityList.stream().map(IndexParamsEntity::getStructure).collect(Collectors.toList());
                List<String> existCollect = existIndexParamEntityList.stream().map(IndexParamsEntity::getStructure).collect(Collectors.toList());
                deleteIndexParamEntityList = existIndexParamEntityList.stream().filter(index -> !collect.contains(index.getStructure())).collect(Collectors.toList());
                newIndexParamsEntityList = indexParamsEntityList.stream().filter(index -> !existCollect.contains(index.getStructure())).collect(Collectors.toList());
            } else {
                newIndexParamsEntityList = indexParamsEntityList;
            }
            if (CollectionUtils.isNotEmpty(deleteIndexParamEntityList)) {
                List<String> paramNoList = deleteIndexParamEntityList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
                indexParamsService.removeByIds(paramNoList);
            }
            if (CollectionUtils.isNotEmpty(newIndexParamsEntityList)) {
                newIndexParamsEntityList.forEach(index -> {
                    index.setUpdateUserID(userName);
                    index.setInputUserID(userName);
                });
                indexParamsService.saveBatch(newIndexParamsEntityList);
                // 更新父级指标层级关系otherNo
                List<IndexParamsEntity> allIndexParamsEntityList = new ArrayList<>();
                allIndexParamsEntityList.addAll(existIndexParamEntityList);
                allIndexParamsEntityList.addAll(newIndexParamsEntityList);
                Map<String, List<IndexParamsEntity>> structMap = allIndexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getStructure())).collect(Collectors.groupingBy(IndexParamsEntity::getStructure));
                for (IndexParamsEntity entity : newIndexParamsEntityList) {
                    if (StringUtils.isNotEmpty(entity.getStructure())) {
                        String structure = entity.getStructure();
                        if (!structure.contains("@@")) {
                            entity.setOtherNo(entity.getParamNo());
                            continue;
                        }
                        String trimStructure = entity.getStructure().replace("@@" + entity.getParamID(), "");
                        List<IndexParamsEntity> parentIndexParams = structMap.get(trimStructure);
                        if (CollectionUtils.isNotEmpty(parentIndexParams)) {
                            entity.setOtherNo(parentIndexParams.get(0).getParamNo());
                        }
                    }
                }
                indexParamsService.updateBatchById(newIndexParamsEntityList);
            }
        }
        // 处理父级指标的关联指标
        handleRelateIndex(parentIndexParamEntity, parentScriptType);
    }

    private String transParamType(String paramType) {
        String type = "";
        if (DataTypeEnum.OBJECT.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.OBJECT.id;
        }
        if (DataTypeEnum.ARRAY.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.LIST.id;
        }
        if (DataTypeEnum.STRING.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.CHAR.id;
        }
        if (DataTypeEnum.NUMBER.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.NUMBER.id;
        }
        if (DataTypeEnum.DATE.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.DATE.id;
        }
        return type;
    }

    public String getGroupNo(String paramNo) {
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            return "";
        }
        if (paramsEntity.getParamType().equals(ParamGroupEnum.Group.id)) {
            return paramsEntity.getParamNo();
        }
        return getGroupNo(paramsEntity.getParentParamNo());
    }

    @Override
    public AgentResult<?> updateIndexParamsObject(IndexParamsInfoSaveReq reqMsg) {
        LambdaUpdateWrapper<IndexParamsEntity> updateWrapper = Wrappers.lambdaUpdate();
        updateWrapper.set(IndexParamsEntity::getParamName, reqMsg.getParamName());
        updateWrapper.eq(IndexParamsEntity::getParamNo, reqMsg.getParamNo());
        indexParamsService.update(updateWrapper);
        return AgentResult.OK();
    }

    @Async
    @Override
    public void refreshIndexCache() {
        String cacheKey = MD5.create().digestHex("demo_call_all_index_param_cache", StandardCharsets.UTF_8);
        doubleCache.remove(cacheKey);
        List<IndexParamsSimpleDTO> listResult = queryAllIndexParamsList(new IndexParamQueryReq());
        doubleCache.set(cacheKey, JSONObject.toJSONString(listResult), 60 * 60 * 2);
    }

    @Override
    public List<IndexParamsSimpleDTO> queryAllIndexParamsList(IndexParamQueryReq reqMsg) {
        List<IndexParamsSimpleDTO> indexParamsDTOList = new ArrayList<>();
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamName, IndexParamsEntity::getInputMethod, IndexParamsEntity::getScriptType, IndexParamsEntity::getParamType, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getParentParamName);
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParentParamNo()), IndexParamsEntity::getParentParamNo, reqMsg.getParentParamNo());
        queryWrapper.eq(IndexParamsEntity::getModelNo, "Public");
        queryWrapper.ne(IndexParamsEntity::getParamType, "GROUP");
        List<IndexParamsEntity> paramsList = indexParamsService.list(queryWrapper);
        if (CollectionUtils.isEmpty(paramsList)) {
            return indexParamsDTOList;
        }

        LambdaQueryWrapper<IndexBaseGroupEntity> groupQueryWrapper = Wrappers.lambdaQuery();
        groupQueryWrapper.select(IndexBaseGroupEntity::getGroupId, IndexBaseGroupEntity::getGroupName, IndexBaseGroupEntity::getParentGroupId, IndexBaseGroupEntity::getParentGroupName);
        List<IndexBaseGroupEntity> groupList = indexBaseGroupService.list(groupQueryWrapper);
        if (CollectionUtils.isEmpty(groupList)) {
            return indexParamsDTOList;
        }
        groupList.forEach(group -> {
            IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
            indexParamsEntity.setParamNo(group.getGroupId());
            indexParamsEntity.setParamName(group.getGroupName());
            indexParamsEntity.setParentParamNo(group.getParentGroupId());
            indexParamsEntity.setParentParamName(group.getParentGroupName());
            paramsList.add(indexParamsEntity);
        });

        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(paramsList, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        if (CollectionUtils.isNotEmpty(paramsList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsSimpleDTO indexParamsDTO = new IndexParamsSimpleDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return indexParamsDTOList;
    }

    @Override
    public ListResult<?> queryIndexParamsListFromCache(IndexParamQueryReq reqMsg) {
        String cacheKey = MD5.create().digestHex("demo_call_all_index_param_cache", StandardCharsets.UTF_8);
        String cacheValue = doubleCache.getValue(cacheKey);
        if (StringUtils.isNotEmpty(cacheValue)) {
            return new ListResult<>(JSONObject.parseArray(cacheValue, IndexParamsSimpleDTO.class));
        }
        List<IndexParamsSimpleDTO> listResult = queryAllIndexParamsList(reqMsg);
        doubleCache.set(cacheKey, JSONObject.toJSONString(listResult), 60 * 60 * 2);
        return new ListResult<>(listResult);
    }

    @Override
    public boolean addIndexGroup(IndexBaseGroupVO indexBaseGroupVO) {
        IndexBaseGroupEntity indexBaseGroupEntity = new IndexBaseGroupEntity();
        BeanUtil.copyProperties(indexBaseGroupVO, indexBaseGroupEntity, true);
        indexBaseGroupEntity.setInputTime(DateUtil.now());
        indexBaseGroupEntity.setUpdateTime(DateUtil.now());
        return indexBaseGroupService.save(indexBaseGroupEntity);
    }

    @Override
    public ListResult<?> queryIndexBaseGroupTree(String groupName, String groupValue) {
        // 权限过滤（由 agent.index.role-filter-enabled 控制，三态语义见 getIndexIdListByRoleId）
        List<String> indexIdList = getIndexIdListByRoleId();
        if (indexIdList != null && indexIdList.isEmpty()) {
            return new ListResult<>(0, 0);
        }

        LambdaQueryWrapper<IndexBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(IndexBaseGroupEntity::getGroupStatus, "1");
        queryWrapper.like(StringUtils.isNotEmpty(groupName), IndexBaseGroupEntity::getGroupName, groupName);
        queryWrapper.like(StringUtils.isNotEmpty(groupValue), IndexBaseGroupEntity::getGroupValue, groupValue);
        queryWrapper.in(CollectionUtils.isNotEmpty(indexIdList), IndexBaseGroupEntity::getGroupId, indexIdList);
        List<IndexBaseGroupEntity> indexBaseGroupEntityList = indexBaseGroupService.list(queryWrapper);
        if (CollectionUtils.isEmpty(indexBaseGroupEntityList)) {
            return new ListResult<>(0, 0);
        }
        List<IndexBaseGroupEntity> IndexBaseGroupTree = TreeUtil.buildTree(indexBaseGroupEntityList, IndexBaseGroupEntity::getGroupId, IndexBaseGroupEntity::getParentGroupId);
        List<IndexBaseGroupDTO> indexBaseGroupDTOList = new ArrayList<>();
        IndexBaseGroupTree.forEach(know -> {
            IndexBaseGroupDTO indexBaseGroupDTO = new IndexBaseGroupDTO();
            BeanUtil.copyProperties(know, indexBaseGroupDTO, true);
            indexBaseGroupDTOList.add(indexBaseGroupDTO);
        });
        return new ListResult<>(indexBaseGroupDTOList);
    }

    @Override
    public boolean updateIndexBaseGroupInfo(IndexBaseGroupVO reqMsg) {
        IndexBaseGroupEntity indexBaseGroupEntity = new IndexBaseGroupEntity();
        BeanUtil.copyProperties(reqMsg, indexBaseGroupEntity, true);
        indexBaseGroupEntity.setUpdateTime(DateUtil.now());
        return indexBaseGroupService.updateById(indexBaseGroupEntity);
    }

    @Override
    public boolean deleteIndexBaseGroupInfo(String groupId) {
        indexBaseGroupService.removeById(groupId);
        // 异步删除其下所有子分组以及分组下所有子指标
        executor.execute(() -> {
            List<String> childGroupIdList = indexBaseGroupService.getAllChildGroupIdList(groupId);
            if (CollectionUtils.isNotEmpty(childGroupIdList)) {
                childGroupIdList.add(groupId);
            } else {
                childGroupIdList = Collections.singletonList(groupId);
            }
            indexBaseGroupService.removeByIds(childGroupIdList);
            indexParamsService.removeAllChildParams(childGroupIdList);
        });
        return true;
    }

    @Override
    public ListResult<?> queryIndexBaseParamsList(IndexBaseGroupReq reqMsg) {
        if (StringUtils.isEmpty(reqMsg.getGroupId())) {
            return new ListResult<>(0, 0);
        }
        QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("parentParamNo", reqMsg.getGroupId());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamId()), "paramid", reqMsg.getParamId());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamName()), "paramname", reqMsg.getParamName());
        queryWrapper.orderByDesc("inputTime");
        List<IndexParamsEntity> paramsList = indexParamsService.list(queryWrapper);
        List<IndexParamsEntity> oneAllParams = new ArrayList<>();
        getAllParamsByParentParamNo(paramsList, oneAllParams);
        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(oneAllParams, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        List<IndexParamsDTO> indexParamsDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsDTO indexParamsDTO = new IndexParamsDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return new ListResult<>(indexParamsDTOList);
    }

    @Override
    public AgentResult<?> copyIndexParamsInfo(IndexParamsInfoSaveReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo()) || StringUtils.isEmpty(reqMsg.getParentParamNo())) {
            return AgentResult.error("参数异常！");
        }

        IndexParamsEntity paramsEntity = indexParamsService.getById(reqMsg.getParamNo());
        if (Objects.isNull(paramsEntity) || (!ParamTypeEnum.LIST.id.equals(paramsEntity.getParamType()) && !ParamTypeEnum.OBJECT.id.equals(paramsEntity.getParamType()))) {
            return AgentResult.error("选择待复制的指标类型异常！！");
        }

        // 生成父级指标
        IndexParamsEntity newParamEntity = new IndexParamsEntity();
        BeanUtil.copyProperties(paramsEntity, newParamEntity, true);
        newParamEntity.setParamNo(null);
        newParamEntity.setParentParamNo(reqMsg.getParentParamNo());
        newParamEntity.setParamID(paramsEntity.getParamID() + "_copy");
        newParamEntity.setParamName(paramsEntity.getParamName() + "_copy");
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        newParamEntity.setInputUserID(apiContextModel.getUserName());
        newParamEntity.setUpdateUserID(apiContextModel.getUserName());
        newParamEntity.setInputTime(DateUtil.now());
        newParamEntity.setUpdateTime(DateUtil.now());
        indexParamsService.save(newParamEntity);

        // 生成子级指标
        String paramNo = paramsEntity.getParamNo();
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(IndexParamsEntity::getParentParamNo, paramNo);
        List<IndexParamsEntity> childIndexParam = indexParamsService.list(queryWrapper);
        if (CollectionUtils.isEmpty(childIndexParam)) {
            return AgentResult.OK(true);
        }
        childIndexParam.forEach(child -> {
            child.setParamNo(null);
            child.setParentParamNo(newParamEntity.getParamNo());
            child.setInputTime(DateUtil.now());
            child.setUpdateTime(DateUtil.now());
            child.setInputUserID(apiContextModel.getUserName());
            child.setUpdateUserID(apiContextModel.getUserName());
        });

        indexParamsService.saveBatch(childIndexParam);

        // 处理otherNo
        Map<String, List<IndexParamsEntity>> structMap = childIndexParam.stream().filter(index -> StringUtils.isNotEmpty(index.getStructure())).collect(Collectors.groupingBy(IndexParamsEntity::getStructure));
        childIndexParam.forEach(child -> {
            if (StringUtils.isNotEmpty(child.getStructure())) {
                String structure = child.getStructure();
                if (!structure.contains("@@")) {
                    child.setOtherNo(child.getParamNo());
                } else {
                    String trimStructure = child.getStructure().replace("@@" + child.getParamID(), "");
                    List<IndexParamsEntity> parentIndexParams = structMap.get(trimStructure);
                    if (CollectionUtils.isNotEmpty(parentIndexParams)) {
                        child.setOtherNo(parentIndexParams.get(0).getParamNo());
                    }
                }
            }
        });
        indexParamsService.updateBatchById(childIndexParam);
        return AgentResult.OK(true);
    }

    @Override
    public AgentResult<?> moveIndexParamsInfo(IndexMoveReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getGroupId()) || StringUtils.isEmpty(reqMsg.getSelectParamNo())) {
            return AgentResult.error("请求参数异常，移动失败！");
        }

        IndexParamsEntity indexParamsEntity = indexParamsService.getById(reqMsg.getSelectParamNo());
        if (Objects.isNull(indexParamsEntity)) {
            return AgentResult.error("移动失败，选择的指标不存在！");
        }

        String groupId = reqMsg.getGroupId();
        IndexBaseGroupEntity indexBaseGroupEntity = indexBaseGroupService.getById(groupId);
        if (Objects.isNull(indexBaseGroupEntity)) {
            return AgentResult.error("移动失败，选择的指标分组不存在！");
        }

        // 向上追溯到顶级父指标（其上一级为分组）
        IndexParamsEntity topParentParam = findTopParentParam(indexParamsEntity);
        if (Objects.isNull(topParentParam)) {
            return AgentResult.error("移动失败，选择的指标不存在！");
        }

        // 仅更新顶级父指标的父分组，子指标的父子关系保持不变
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        topParentParam.setParentParamNo(groupId);
        topParentParam.setParentParamName(indexBaseGroupEntity.getGroupName());
        topParentParam.setUpdateTime(DateUtil.now());
        topParentParam.setUpdateUserID(apiContextModel.getUserName());
        indexParamsService.updateById(topParentParam);
        return AgentResult.OK(true);
    }

    private IndexParamsEntity findTopParentParam(IndexParamsEntity paramEntity) {
        if (Objects.isNull(paramEntity)) {
            return null;
        }
        String parentParamNo = paramEntity.getParentParamNo();
        if (StringUtils.isEmpty(parentParamNo)) {
            return paramEntity;
        }
        IndexParamsEntity parentEntity = indexParamsService.getById(parentParamNo);
        // 父级不存在或父级为分组类型，说明当前指标即为顶级指标
        if (Objects.isNull(parentEntity) || ParamGroupEnum.Group.id.equals(parentEntity.getParamType())) {
            return paramEntity;
        }
        return findTopParentParam(parentEntity);
    }

    @Override
    public AgentResult<?> getRelateParamsList(IndexParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo())) {
            return AgentResult.error("参数异常！");
        }
        String paramNo = reqMsg.getParamNo();
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            return AgentResult.error("未查询到相关数据！");
        }
        IndexParamsEntity parentParamEntity = indexParamsService.getById(paramsEntity.getParentParamNo());
        if (Objects.isNull(parentParamEntity)) {
            return AgentResult.error("未查询到相关数据！");
        }

        JSONArray resultArray = new JSONArray();
        List<IndexParamsEntity> childIndexParamList = indexParamsService.selectByOtherNo(paramNo, paramsEntity.getScriptType());
        if (CollectionUtils.isNotEmpty(childIndexParamList)) {
            Map<String, String> realParamNameMap = getRealParamName(childIndexParamList, parentParamEntity.getExtendField());
            childIndexParamList.forEach(child -> {
                JSONObject jsonObject = new JSONObject();
                String mapName = realParamNameMap.get(child.getParamNo());
                jsonObject.put("label", StringUtils.isEmpty(mapName) ? child.getParamName() : mapName);
                jsonObject.put("value", StringUtils.isEmpty(mapName) ? child.getParamName() : mapName);
                jsonObject.put("paramNo", child.getParamNo());
                resultArray.add(jsonObject);
            });

        }
        return AgentResult.OK(resultArray);
    }

    private Map<String, String> getRealParamName(List<IndexParamsEntity> childIndexParamList, String extendField) {
        Map<String, String> resultMap = new HashMap<>();
        try {
            childIndexParamList.forEach(child -> {
                String structure = child.getStructure();
                JSONArray extentFieldArray = JSONArray.parseArray(extendField);
                for (Object obj : extentFieldArray) {
                    JSONObject jsonObject = (JSONObject) obj;
                    if (jsonObject.containsKey(structure)) {
                        JSONObject json = jsonObject.getJSONObject(structure);
                        resultMap.put(child.getParamNo(), json.isEmpty() ? child.getParamName() : json.getString("relaPname"));
                        break;
                    }
                }
            });
        } catch (Exception e) {
            log.error("获取指标参数真实名称失败，参数：{}，异常：{}", extendField, e.getMessage());
        }
        return resultMap;
    }

    @Override
    public AgentResult<?> queryRelateKnowledgeInfo(IndexParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo())) {
            throw new AgentBizException("参数异常！");
        }
        String paramNo = reqMsg.getParamNo();
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            throw new AgentBizException("未查询到相关数据！");
        }
        List<String> paramNoList = Collections.emptyList();
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.selectByParentParamNo(paramNo);
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            paramNoList = indexParamsEntityList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
        }
        // 查询关联知识库信息
        return AgentResult.OK(indexRelateKnowledgeInfoService.getListByParamNo(reqMsg, paramNoList));
    }

    @Override
    public AgentResult<?> queryRelateIndexInfo(IndexParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo())) {
            throw new AgentBizException("参数异常！");
        }
        String paramNo = reqMsg.getParamNo();
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            throw new AgentBizException("未查询到相关数据！");
        }
        List<String> paramNoList = Collections.emptyList();
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.selectByParentParamNo(paramNo);
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            paramNoList = indexParamsEntityList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
        }
        return AgentResult.OK(indexRelateIndexInfoService.getListByParamNo(reqMsg, paramNoList));
    }

    @Override
    public AgentResult<?> queryIndexRelateKnowledgeInfo(String paramNo) {
        return AgentResult.OK(knowledgeBaseParamsService.generateIndexRelateKnowledgeInfo(paramNo));
    }

    /**
     * 解析当前调用者可访问的「指标 / 指标分组」范围
     *
     * <p><b>返回值是三态语义，调用方必须区分（不要直接 isEmpty 判断）：</b></p>
     * <table border="1">
     *   <tr><th>返回值</th><th>含义</th><th>调用方应做</th></tr>
     *   <tr><td>{@code null}</td><td><b>不做过滤</b>：过滤开关关闭 / 当前用户是超管 / 取不到角色（技术性失败）</td>
     *       <td>正常查询，不加 in 条件</td></tr>
     *   <tr><td>空列表</td><td><b>已启用过滤，但该角色没有任何授权</b>（fail-closed）</td>
     *       <td>直接返回空结果（页面为空是"没配授权"，不是故障）</td></tr>
     *   <tr><td>非空</td><td>授权范围内的指标编号 + 分组编号</td><td>加 in 条件过滤</td></tr>
     * </table>
     *
     * <p><b>关于 {@code sys_role_index.index_id} 存的是什么</b>：它<b>混合存两类 id</b>——
     * 指标编号（{@code index_params.paramno}）与指标分组编号（{@code index_base_group.groupid}）。
     * 证据是两处消费方式不同：{@code getAllIndexParamsList} 拿它去匹配
     * {@code parentParamNo}，而 {@code queryIndexBaseGroupTree} 拿它去匹配 {@code groupId}。
     * 两者都是 VARCHAR(32)，长度一致所以可以混存。上报/配数据时不要想当然只按其中之一理解。</p>
     *
     * <p><b>为什么"取不到角色"时放行而不是拦断</b>：那是配置或数据层面的技术性失败
     * （如 Token 里没有 userId、sys_user_role 无关联记录），不是"该用户没有授权"。
     * 若按 fail-closed 处理，会让整个指标配置页对所有人不可用且难以定位；
     * 这里选择放行并打 WARN，把问题暴露在日志里。真正的"无授权"仍严格 fail-closed。</p>
     */
    private List<String> getIndexIdListByRoleId() {
        if (!agentProperties.isIndexRoleFilterEnabled()) {
            return null;
        }
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();

        // 超管放行：按「角色编码」判断而不是角色主键 —— 编码可读、可配置、跨环境稳定。
        // 注意这与 sys_role_index.role_id 存主键是两回事：前者用于绕过，后者用于授权数据关联。
        List<String> bypassRoles = agentProperties.getIndexRoleFilterBypassRoles();
        List<String> roleCodes = apiContextModel.getRoleCode();
        if (CollectionUtils.isNotEmpty(bypassRoles) && CollectionUtils.isNotEmpty(roleCodes)) {
            for (String roleCode : roleCodes) {
                if (bypassRoles.contains(roleCode)) {
                    return null;
                }
            }
        }

        // sys_role_index.role_id 的口径是「角色主键」（sys_role.id），由 ApiContext 按 userId 查出。
        List<String> roleIdList = apiContextModel.getRoleIdList();
        if (CollectionUtils.isEmpty(roleIdList)) {
            log.warn("启用角色-指标过滤但取不到当前用户的角色主键（userId={}，roleCode={}），本次不做过滤；"
                            + "请检查 sys_user_role 是否有该用户的关联记录",
                    apiContextModel.getUserId(), roleCodes);
            return null;
        }

        List<String> indexIdList = sysRoleIndexService.getIndexIdListByRoleId(roleIdList);
        // 源实现在查不到授权时返回 null，这里归一成空列表，以便与"不过滤(null)"区分开
        return indexIdList == null ? Collections.<String>emptyList() : indexIdList;
    }
}
