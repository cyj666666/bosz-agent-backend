package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.enums.OnlineEnum;
import com.suzhou.bank.agent.enums.ParamGroupEnum;
import com.suzhou.bank.agent.enums.ScriptTypeEnum;
import com.suzhou.bank.agent.mapper.IndexParamsMapper;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.model.req.IndexVersionReq;
import com.suzhou.bank.agent.model.req.TableSyncRcordReq;
import com.suzhou.bank.agent.model.vo.IndexParamsVO;
import com.suzhou.bank.agent.model.vo.ReportVersionVO;
import com.suzhou.bank.agent.service.IIndexParamsService;
import com.suzhou.bank.agent.model.dto.TableFieldDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

@Slf4j
@Service
public class IndexParamsServiceImpl extends ServiceImpl<IndexParamsMapper, IndexParamsEntity> implements IIndexParamsService {

    @Override
    public ListResult<IndexParamsEntity> queryParamsGroupList(IndexVersionReq reqMsg, ReportVersionVO versionVO, String paramType) {
        QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("modelNo", reqMsg.getModelNo());
        queryWrapper.eq("paramType", paramType);
        queryWrapper.eq("reportVersion", versionVO.getReportVersion());
        if (!"Public".equals(versionVO.getReportVersion())) {
            queryWrapper.eq("versionNo", versionVO.getVersionNo());
        }
        queryWrapper.orderByAsc("inputtime");
        List<IndexParamsEntity> indexParamsEntityList = list(queryWrapper);
        return new ListResult<>(Integer.valueOf(indexParamsEntityList.size() + ""), indexParamsEntityList);
    }

    @Override
    public List<IndexParamsEntity> selectByParentParamNoList(List<String> paramNoList) {
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getOtherNo, IndexParamsEntity::getParamName);
        queryWrapper.in(IndexParamsEntity::getParentParamNo, paramNoList);
        return list(queryWrapper);
    }

    @Override
    public List<IndexParamsEntity> selectByOtherNoList(List<String> paramNoList) {
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getOtherNo, IndexParamsEntity::getParamName);
        queryWrapper.in(IndexParamsEntity::getOtherNo, paramNoList);
        return list(queryWrapper);
    }

    @Override
    public List<IndexParamsEntity> selectByParentParamNo(String paramNo) {
        LambdaQueryWrapper<IndexParamsEntity> objectQueryWrapper = Wrappers.lambdaQuery();
        objectQueryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID);
        objectQueryWrapper.eq(IndexParamsEntity::getParentParamNo, paramNo);
        return list(objectQueryWrapper);
    }

    @Override
    public List<IndexParamsEntity> selectByOtherNo(String paramNo, String scriptType) {
        if (scriptType.equalsIgnoreCase("Api")) {
            LambdaQueryWrapper<IndexParamsEntity> objectQueryWrapper = Wrappers.lambdaQuery();
            objectQueryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName, IndexParamsEntity::getStructure);
            objectQueryWrapper.eq(IndexParamsEntity::getOtherNo, paramNo);
            return list(objectQueryWrapper);
        } else {
            LambdaQueryWrapper<IndexParamsEntity> objectQueryWrapper = Wrappers.lambdaQuery();
            objectQueryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName);
            objectQueryWrapper.eq(IndexParamsEntity::getParentParamNo, paramNo);
            return list(objectQueryWrapper);
        }
    }

    @Override
    public void saveIndexParamsFromTableField(List<IndexParamsVO> indexParamsVOList, IndexParamsVO indexParamsVO) {
        List<IndexParamsEntity> indexParamsEntityList = new ArrayList<>();
        for (IndexParamsVO indexParams : indexParamsVOList) {
            // 父节点
            if (indexParams.getParamID().equals(indexParamsVO.getParamID())) {
                indexParams.setParamType(StringUtils.isBlank(indexParams.getParamType()) ? "LIST" : indexParams.getParamType());
                indexParams.setInputMethod(StringUtils.isBlank(indexParams.getInputMethod()) ? "calc" : indexParams.getInputMethod());
                indexParams.setScriptType(ScriptTypeEnum.SQL.id);
            } else {
                indexParams.setParentParamName(indexParamsVO.getParamName());
                indexParams.setParentParamNo(indexParamsVO.getParamNo());
            }
            IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
            BeanUtil.copyProperties(indexParams, indexParamsEntity);
            indexParamsEntityList.add(indexParamsEntity);
        }
        saveBatch(indexParamsEntityList);
    }

    @Override
    public void setParamSqlScript(List<String> paramIdList, IndexParamsVO paramsVO) {
        QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("paramno", paramsVO.getParamNo());
        IndexParamsEntity one = getOne(queryWrapper);
        if (one == null) {
            return;
        }
        String sql = JoinSql(paramIdList, one.getColumnFromDataSource(), one.getColumnFromTable(), one.getScript());
        if (StringUtils.isBlank(sql)) {
            // JoinSql 判定为「配置缺失、拒绝生成」⇒ 保持原状，不写回任何 SQL。
            // 这样该指标的 script 继续为空，由取数侧（concatIndexParam / getIndexValueMap）
            // 按"未取到值"处理，而不是拿一个无过滤条件的全表查询去算结论。
            return;
        }
        one.setScriptType(ScriptTypeEnum.SQL.id);
        one.setScript(sql);
        IndexParamsEntity newParams = new IndexParamsEntity();
        BeanUtil.copyProperties(one, newParams);
        updateById(newParams);
    }

    private String JoinSql(List<String> paramID, String columnFromDataSource, String columnFromTable, String script) {
        StringBuffer columnBuilder = new StringBuffer();
        for (String s : paramID) {
            columnBuilder.append(",").append(s);
        }
        StringBuffer selectBuilder = new StringBuffer("SELECT ");
        selectBuilder.append(columnBuilder.deleteCharAt(0)).append(" FROM ").append(columnFromTable);
        /*
         * 🔴 拒绝生成"无过滤条件的全表查询"（2026-09-19 改）。
         *
         * 原实现：script 为空时直接拼 `SELECT 列 FROM 表` —— **没有 WHERE**、paramData 也是空数组。
         * 后果（实测）：这类指标取数时不带 reportNo、连 entName 都没有，等于把整张表当作
         * 该报告的数据来用 —— 同一批数据会服务所有报告版本（V1/V2 内容逐字相同就是这么来的）。
         * 本轮排查出 748 个指标处于这种状态（其中被规则引用的 153 个）。
         *
         * 现在的口径：**宁可保持"未配置"，也不生成一个看起来能用、实则会给出假结论的 SQL**。
         * 返回 null ⇒ 调用方（setParamSqlScript）跳过写回；该指标继续按"取数配置缺失"处理。
         */
        if (StringUtils.isBlank(script)) {
            log.warn("【取数配置缺失】指标[{}] 未配置取数SQL，且拒绝自动生成「无过滤条件的全表查询」"
                            + "（自动生成只会得到 `SELECT 列 FROM {}` —— 没有 reportNo 等任何条件）。"
                            + "请人工补配带 `WHERE REPORTNO = :reportNo` 的 SQL。",
                    paramID, columnFromTable);
            return null;
        }
        // 有配置时更新字段，保留条件，但是无法保留 表别名.字段 方式查询的sql
        JSONObject parsed = JSONArray.parseObject(script);
        String sql = parsed.getString("sql");
        // 分割结构 where
        String[] split = sql.split(" (?i)WHERE ");
        if (split.length > 1) {
            selectBuilder.append(" WHERE ").append(split[split.length - 1]);
        }
        parsed.put("sql", selectBuilder);
        parsed.put("paramData", parsed.getJSONArray("paramData"));
        return parsed.toString();
    }

    @Override
    public IndexParamsVO queryParamFromSourceTableField(TableSyncRcordReq reqMsg, List<TableFieldDTO> tableFieldDTOS) {
        String tableName = reqMsg.getTableName();
        String modelNo = reqMsg.getModelNo();
        String reportVersion = reqMsg.getReportVersion();
        String versionNo = reqMsg.getVersionNo();
        String paramNo = reqMsg.getParamNo();
        String paramName = reqMsg.getParamName();
        String datasourceId = reqMsg.getDataSourceId();
        String paramId = reqMsg.getParamId();

        IndexParamsVO indexParamsVO = new IndexParamsVO();
        indexParamsVO.setParamName(paramName);
        indexParamsVO.setParentParamNo(paramNo);

        // 获取分组指标的名称
        IndexParamsEntity paramsEntity = getById(paramNo);
        if (paramsEntity != null) {
            indexParamsVO.setParentParamName(paramsEntity.getParamName());
        }

        indexParamsVO.setModelNo(modelNo);
        indexParamsVO.setReportVersion(reportVersion);
        indexParamsVO.setVersionNo(versionNo);
        indexParamsVO.setParamSource("3");
        String realParamId = StringUtils.isBlank(paramId) ? tableName : paramId;
        indexParamsVO.setParamID(realParamId.toUpperCase(Locale.ENGLISH));
        indexParamsVO.setColumnFromDataSource(datasourceId);
        indexParamsVO.setColumnFromTable(tableName.toUpperCase(Locale.ENGLISH));
        indexParamsVO.setActureColumn(tableName.toUpperCase(Locale.ENGLISH));
        indexParamsVO.setDataMethod("Auto");

        List<IndexParamsVO> indexParamsVOList = new ArrayList<>();
        for (TableFieldDTO tableFieldDTO : tableFieldDTOS) {
            IndexParamsVO paramsVO = new IndexParamsVO();
            paramsVO.setParamID(tableFieldDTO.getColumnName().toUpperCase(Locale.ENGLISH));
            paramsVO.setParamName(tableFieldDTO.getColumnComment());
            paramsVO.setColumnComment(tableFieldDTO.getColumnComment());
            paramsVO.setColumnFromDataSource(datasourceId);
            paramsVO.setParamType(tableFieldDTO.getDataType());
            paramsVO.setColumnFromTable(reqMsg.getTableName());
            paramsVO.setVersionNo(versionNo);
            paramsVO.setReportVersion(reportVersion);
            paramsVO.setModelNo(modelNo);
            paramsVO.setColumnLength(tableFieldDTO.getLength());
            paramsVO.setRequired(tableFieldDTO.getIsNullable());
            paramsVO.setColumnIsNull(Objects.equals(tableFieldDTO.getIsNullable(), OnlineEnum.N.name()) ? "否" : "是");
            paramsVO.setActureColumn(tableFieldDTO.getColumnName().toUpperCase(Locale.ENGLISH));
            paramsVO.setParentParamNo(paramNo);
            paramsVO.setParamType("CHAR");
            paramsVO.setDataMethod("Auto");
            paramsVO.setInputMethod("label");
            paramsVO.setColumnType(tableFieldDTO.getDataType());
            indexParamsVOList.add(paramsVO);
        }

        List<IndexParamsEntity> paramsEntityList = getIndexParamsListWithId(StringUtils.isBlank(paramId) ? tableName : paramId, modelNo, versionNo, reportVersion);
        IndexParamsEntity paramsInfo = null;
        if (CollectionUtils.isNotEmpty(paramsEntityList)) {
            for (IndexParamsEntity e : paramsEntityList) {
                String parentParamNo = e.getParentParamNo();
                if (StringUtils.isNotBlank(parentParamNo)) {
                    IndexParamsEntity params = getById(parentParamNo);
                    if (null != params && ParamGroupEnum.Group.id.equals(params.getParamType())) {
                        // 上一级为分组
                        paramsInfo = e;
                        break;
                    }
                }
            }
        }
        if (Objects.nonNull(paramsInfo)) {
            // 关联已有的指标编号和父指标编号
            indexParamsVO.setParamNo(paramsInfo.getParamNo());
            indexParamsVO.setParentParamNo(paramsInfo.getParentParamNo());
            indexParamsVO.setParamType(paramsInfo.getParamType());
            indexParamsVO.setInputMethod(paramsInfo.getInputMethod());
        }
        indexParamsVO.setChildList(indexParamsVOList);
        return indexParamsVO;
    }

    @Override
    public List<IndexParamsEntity> getIndexParamsListWithId(String paramId, String modelNo, String versionNo, String reportVersion) {
        QueryWrapper<IndexParamsEntity> wrapper = new QueryWrapper<>();
        wrapper.eq("paramId", paramId);
        wrapper.eq("modelNo", modelNo);
        wrapper.eq("reportVersion", reportVersion);
        wrapper.eq(StringUtils.isNotBlank(versionNo), "versionNo", versionNo);
        return list(wrapper);
    }

    @Override
    public void removeAllChildParams(List<String> groupIdList) {
        if (CollectionUtils.isEmpty(groupIdList)) {
            return;
        }
        List<String> deleteParamNoList = new ArrayList<>();
        groupIdList.forEach(paramNo -> {
            deleteParamNoList.add(paramNo);
            getDeleteParamNoList(paramNo, deleteParamNoList);
        });

        deleteParamNoList.addAll(groupIdList);
        removeByIds(deleteParamNoList);
    }

    @Override
    public List<IndexParamsEntity> getParamsList(List<String> paramNoList) {
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo,IndexParamsEntity::getDefaultValue, IndexParamsEntity::getParamName, IndexParamsEntity::getScriptType, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getParentParamName,IndexParamsEntity::getDataUnit);
        queryWrapper.in(IndexParamsEntity::getParamNo, paramNoList);
        return list(queryWrapper);
    }

    @Override
    public List<IndexParamsEntity> listDistanceIndexParams(List<String> paramNoList) {
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.in(IndexParamsEntity::getParamNo, paramNoList);
        return list(queryWrapper);
    }

    @Override
    public void saveDistanceIndexParams(List<IndexParamsEntity> indexParamsList) {
        saveOrUpdateBatch(indexParamsList);
    }

    private void getDeleteParamNoList(String paramNo, List<String> deleteParamNoList) {
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo);
        queryWrapper.eq(IndexParamsEntity::getParentParamNo, paramNo);
        List<IndexParamsEntity> indexParamsEntityList = list(queryWrapper);
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            indexParamsEntityList.forEach(item -> {
                deleteParamNoList.add(item.getParamNo());
                getDeleteParamNoList(item.getParamNo(), deleteParamNoList);
            });
        }
    }

}
