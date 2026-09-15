package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.date.DateUtil;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.db.AgentDataSourceProvider;
import com.suzhou.bank.agent.db.DynamicDataSourceModel;
import com.suzhou.bank.agent.db.SqlInjectionUtil;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.enums.*;
import com.suzhou.bank.agent.model.dto.TableInfoDTO;
import com.suzhou.bank.agent.model.req.DataSourceTableInfoReq;
import com.suzhou.bank.agent.model.req.IndexTableSyncRcordReq;
import com.suzhou.bank.agent.model.req.TableSyncRcordReq;
import com.suzhou.bank.agent.model.vo.IndexParamsVO;
import com.suzhou.bank.agent.service.IIndexParamsService;
import com.suzhou.bank.agent.mapper.SysDataSourceMapper;
import com.suzhou.bank.agent.model.dto.DataReviewDTO;
import com.suzhou.bank.agent.model.dto.TableFieldDTO;
import com.suzhou.bank.agent.entity.SysDataSource;
import com.suzhou.bank.agent.model.req.DataSourceDataPreviewReq;
import com.suzhou.bank.agent.model.req.ParamsDataSourceDataPreviewReq;
import com.suzhou.bank.agent.model.req.TableInfoQueryReq;
import com.suzhou.bank.agent.model.req.TableListQueryReq;
import com.suzhou.bank.agent.service.ISysDataSourceService;
import com.suzhou.bank.agent.util.FieldTypeUtil;
import com.suzhou.bank.agent.util.ParamUtil;
import com.suzhou.bank.agent.util.SecurityUtil;
import org.springframework.beans.BeanUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowCountCallbackHandler;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

import static com.suzhou.bank.agent.db.DynamicDBUtil.getJdbcTemplate;
import static com.suzhou.bank.agent.db.DynamicDBUtil.getNamedParameterJdbcTemplate;

/**
 * @Description: 多数据源管理
 * @Author: jeecg-boot
 * @Date: 2019-12-25
 * @Version: V1.0
 */
@Service
@Slf4j
public class SysDataSourceServiceImpl extends ServiceImpl<SysDataSourceMapper, SysDataSource>
        implements ISysDataSourceService, AgentDataSourceProvider {

    @Autowired
    private IIndexParamsService indexParamsService;

    @Override
    public ListResult<?> getSyncTableList(TableListQueryReq tableListQueryReq) {
        String dataSourceId = tableListQueryReq.getDataSourceId();
        if (StringUtils.isEmpty(dataSourceId)) {
            return null;
        }
        DynamicDataSourceModel dataSourceModel = getDynamicDbSourceById(dataSourceId);
        if (Objects.isNull(dataSourceModel)) {
            log.error("数据源信息不存在,dataSourceId:{}", dataSourceId);
            return null;
        }

        ListResult<?> listResult = null;
        JdbcTemplate jdbcTemplate = getJdbcTemplate(dataSourceModel.getCode());
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.MYSQL.id)) {
            listResult = getMysqlDataSourceTableList(jdbcTemplate, tableListQueryReq);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.ORACLE.id)) {
            listResult = getOracleDataSourceTableList(jdbcTemplate, tableListQueryReq);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.HIVE.id)) {
            listResult = getHiveDataSourceTableList(jdbcTemplate, tableListQueryReq);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.DM.id)) {
            // 达梦类型，暂使用oracle类型语法
            listResult = getOracleDataSourceTableList(jdbcTemplate, tableListQueryReq);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.PG.id)) {
            listResult = getPostgresqlDataSourceTableList(jdbcTemplate, tableListQueryReq);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.OPENGauss.id)) {
            listResult = getPostgresqlDataSourceTableList(jdbcTemplate, tableListQueryReq);
        }
        return listResult;
    }

    @Override
    public ListResult<?> getSyncTableInfo(TableInfoQueryReq tableInfoQueryReq) {
        DynamicDataSourceModel dataSourceModel = getDynamicDbSourceById(tableInfoQueryReq.getDataSourceId());
        if (Objects.isNull(dataSourceModel)) {
            log.error("数据源信息不存在,dataSource:{}", tableInfoQueryReq.getDataSourceId());
            return null;
        }
        ListResult<?> listResult = null;
        JdbcTemplate jdbcTemplate = getJdbcTemplate(dataSourceModel.getCode());
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.MYSQL.id)) {
            listResult = queryMysqlTableInfo(jdbcTemplate, tableInfoQueryReq.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.ORACLE.id)) {
            listResult = queryOracleTableInfo(jdbcTemplate, tableInfoQueryReq.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.HIVE.id)) {
            listResult = queryHiveTableInfo(jdbcTemplate, tableInfoQueryReq.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.DM.id)) {
            // 达梦类型，暂使用oracle类型语法
            listResult = queryOracleTableInfo(jdbcTemplate, tableInfoQueryReq.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.PG.id)) {
            String dbUrl = dataSourceModel.getDbUrl();
            String currentSchema = parseCurrentSchemaFromUrl(dbUrl);
            listResult = queryPostgresqlTableInfo(jdbcTemplate, tableInfoQueryReq.getTableName(), currentSchema);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.OPENGauss.id)) {
            String dbUrl = dataSourceModel.getDbUrl();
            String currentSchema = parseCurrentSchemaFromUrl(dbUrl);
            listResult = queryPostgresqlTableInfo(jdbcTemplate, tableInfoQueryReq.getTableName(), currentSchema);
        }
        return listResult;
    }

    @Override
    public AgentResult<?> getDataPreview(DataSourceDataPreviewReq dataSourceDataPreviewReq) {
        DynamicDataSourceModel dataSourceModel = getDynamicDbSourceById(dataSourceDataPreviewReq.getDataSourceId());
        if (Objects.isNull(dataSourceModel)) {
            log.error("数据源信息不存在,dataSource:{}", dataSourceDataPreviewReq.getDataSourceId());
            return null;
        }

        DataReviewDTO reviewDTO = new DataReviewDTO();
        JdbcTemplate jdbcTemplate = getJdbcTemplate(dataSourceModel.getCode());

        String querySql = "";
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.MYSQL.id)) {
            querySql = "select * from " + dataSourceDataPreviewReq.getTableName() + " limit 10";
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.ORACLE.id)) {
            querySql = "select * from " + dataSourceDataPreviewReq.getTableName() + " where rownum <= 10";
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.HIVE.id)) {
            querySql = "select * from " + dataSourceDataPreviewReq.getTableName() + " limit 10";
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.DM.id)) {
            querySql = "select * from " + dataSourceDataPreviewReq.getTableName() + " where rownum <= 10";
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.PG.id)) {
            querySql = "select * from " + dataSourceDataPreviewReq.getTableName().toLowerCase(Locale.ROOT) + " limit 10";
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.OPENGauss.id)) {
            querySql = "select * from " + dataSourceDataPreviewReq.getTableName().toLowerCase(Locale.ROOT) + " limit 10";
        }
        // 获取表字段信息
        RowCountCallbackHandler callbackHandler = new RowCountCallbackHandler();
        jdbcTemplate.query(querySql, callbackHandler);
        String[] columnNames = callbackHandler.getColumnNames();
        reviewDTO.setTableHeaders(Objects.isNull(columnNames) ? Collections.emptyList() : Arrays.asList(columnNames));

        // 获取表数据
        List<Map<String, Object>> mapList = jdbcTemplate.queryForList(querySql);
        reviewDTO.setDataList(mapList);

        return AgentResult.OK(reviewDTO);
    }

    @Override
    public AgentResult<?> getParamDataSourcePreview(ParamsDataSourceDataPreviewReq paramsDataSourceDataPreviewReq) {
        if (StringUtils.isEmpty(paramsDataSourceDataPreviewReq.getSql())) {
            return null;
        }

        // sql注入分析
        SqlInjectionUtil.checkSql(paramsDataSourceDataPreviewReq.getSql());

        DynamicDataSourceModel dataSourceModel = getDynamicDbSourceById(paramsDataSourceDataPreviewReq.getDatasource());
        if (Objects.isNull(dataSourceModel)) {
            log.error("数据源信息不存在,dataSource:{}", paramsDataSourceDataPreviewReq.getDatasource());
            return null;
        }

        DataReviewDTO reviewDTO = new DataReviewDTO();
        NamedParameterJdbcTemplate jdbcTemplate = getNamedParameterJdbcTemplate(dataSourceModel.getCode());

        String dbType = dataSourceModel.getDbType();
        String querySql = paramsDataSourceDataPreviewReq.getSql();
        if (DriverTypeEnum.DM.dbType.equals(dbType) || DriverTypeEnum.ORACLE.dbType.equals(dbType)) {
            querySql = String.format("select * from (%s) where rownum <= 10", querySql);
        } else {
            querySql = String.format("select * from (%s) rs limit 10", querySql);
        }
        List<String> heads = new ArrayList<>();
        // 获取表数据
        List<Map<String, Object>> dataList = new ArrayList<>();
        try {
            dataList = jdbcTemplate.queryForList(querySql, paramsDataSourceDataPreviewReq.getParameters());
        } catch (Exception e) {
            reviewDTO.setMsg("未配置参数默认值");
            reviewDTO.setCode("200000");
            return AgentResult.OK();
        }
        if (dataList.size() > 0) {
            reviewDTO.setCode("0010");// 查询成功，有数据返回
            reviewDTO.setMsg("查询成功，有数据返回");// 查询成功，有数据返回
            // 获取表头
            Map<String, Object> data = dataList.get(0);
            if (data != null) {
                data.forEach((key, value) -> {
                    heads.add(key);
                });
            }
        } else {
            reviewDTO.setCode("0020");// 查询成功，无数据返回
            reviewDTO.setMsg("查询成功，无数据返");// 查询成功，无数据返回
        }
        reviewDTO.setTableHeaders(heads);
        reviewDTO.setDataList(dataList);
        return AgentResult.OK(reviewDTO);
    }

    @Override
    public AgentResult<?> querySourceTableField(TableSyncRcordReq reqMsg) {
        DataSourceTableInfoReq dataSourceTableInfoReq = new DataSourceTableInfoReq();
        BeanUtils.copyProperties(reqMsg, dataSourceTableInfoReq);
        ListResult<TableFieldDTO> listResult = getDataSourceTableInfo(dataSourceTableInfoReq);
        if (null == listResult && CollectionUtils.isEmpty(listResult.getList())) {
            return AgentResult.OK();
        }
        IndexParamsVO indexParamsVO = indexParamsService.queryParamFromSourceTableField(reqMsg, listResult.getList());
        return AgentResult.OK(indexParamsVO);
    }

    @Override
    public ListResult<TableFieldDTO> getDataSourceTableInfo(DataSourceTableInfoReq req) {
        DynamicDataSourceModel dataSourceModel = getDynamicDbSourceById(req.getDataSourceId());
        if (Objects.isNull(dataSourceModel)) {
            log.error("数据源信息不存在,dataSource:{}", req.getDataSourceId());
            return null;
        }
        ListResult<TableFieldDTO> listResult = null;
        JdbcTemplate jdbcTemplate = getJdbcTemplate(dataSourceModel.getCode());
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.MYSQL.id)) {
            listResult = queryMysqlTableInfo(jdbcTemplate, req.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.ORACLE.id)) {
            listResult = queryOracleTableInfo(jdbcTemplate, req.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.HIVE.id)) {
            listResult = queryHiveTableInfo(jdbcTemplate, req.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.DM.id)) {
            // 达梦类型，暂使用oracle类型语法
            listResult = queryOracleTableInfo(jdbcTemplate, req.getTableName());
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.PG.id)) {
            String dbUrl = dataSourceModel.getDbUrl();
            String currentSchema = parseCurrentSchemaFromUrl(dbUrl);
            listResult = queryPostgresqlTableInfo(jdbcTemplate, req.getTableName(), currentSchema);
        }
        if (dataSourceModel.getDbDriver().contains(DriverTypeEnum.OPENGauss.id)) {
            String dbUrl = dataSourceModel.getDbUrl();
            String currentSchema = parseCurrentSchemaFromUrl(dbUrl);
            listResult = queryPostgresqlTableInfo(jdbcTemplate, req.getTableName(), currentSchema);
        }

        return listResult;
    }

    @Override
    public AgentResult<?> saveIndexParamsFromSourceTableField(List<IndexParamsVO> paramsVOList) {
        IndexParamsVO indexParamsVO = paramsVOList.get(0);
        String serialNo = ParamUtil.getSerialNo();
        indexParamsVO.setParamNo(serialNo);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        indexParamsVO.setInputUserID(apiContextModel.getUserName());
        indexParamsVO.setInputTime(DateUtil.now());
        indexParamsVO.setUpdateTime(DateUtil.now());
        indexParamsVO.setUpdateUserID(apiContextModel.getUserName());
        for (IndexParamsVO p : paramsVOList) {
            if (StringUtils.isBlank(p.getParamNo())) {
                p.setParamNo(ParamUtil.getSerialNo());
                p.setParentParamNo(serialNo);
            }
            p.setReadOnly(OnlineEnum.N.name());
            p.setInputTime(DateUtil.now());
            p.setInputUserID(apiContextModel.getUserName());
            p.setUpdateTime(DateUtil.now());
            p.setUpdateUserID(apiContextModel.getUserName());
            p.setScriptType(ScriptTypeEnum.SQL.id);
            p.setParamSource(ParamSourceEnum.TABLE.id);
        }

        if (CollectionUtils.isNotEmpty(paramsVOList)) {
            indexParamsService.saveIndexParamsFromTableField(paramsVOList, indexParamsVO);
            // 更新父指标脚本信息
            List<IndexParamsEntity> childParams = indexParamsService.selectByParentParamNo(indexParamsVO.getParamNo());
            if (CollectionUtils.isNotEmpty(childParams)) {
                List<String> paramIdList = childParams.stream().map(IndexParamsEntity::getParamID).collect(Collectors.toList());
                indexParamsService.setParamSqlScript(paramIdList, indexParamsVO);
            }
        }
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> showParamInfo(IndexTableSyncRcordReq reqMsg) {
        if (StringUtils.isBlank(reqMsg.getParamId())) {
            throw new AgentBizException("未取到指标编号！");
        }
        JSONObject result = new JSONObject(true);
        result.put("paramId", reqMsg.getParamId());
        result.put("tableName", reqMsg.getTableName());
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.getIndexParamsListWithId(reqMsg.getParamId(), reqMsg.getModelNo(), reqMsg.getVersionNo(), reqMsg.getReportVersion());
        // 过滤父节点指标不为GROUP的
        if (CollectionUtils.isEmpty(indexParamsEntityList)) {
            result.put("isImport", "未引入");
            result.put("belongGroup", "");
            result.put("paramName", reqMsg.getParamName());
        } else {
            for (IndexParamsEntity e : indexParamsEntityList) {
                String parentParamNo = e.getParentParamNo();
                if (StringUtils.isNotBlank(parentParamNo)) {
                    IndexParamsEntity params = indexParamsService.getById(parentParamNo);
                    if (null != params && ParamGroupEnum.Group.id.equals(params.getParamType())) {
                        // 上一级为分组
                        result.put("isImport", "已引入");
                        result.put("belongGroup", params.getParamName());
                        result.put("paramName", e.getParamName());
                    } else {
                        result.put("isImport", "未引入");
                        result.put("belongGroup", "");
                        result.put("paramName", reqMsg.getParamName());
                    }
                } else {
                    result.put("isImport", "未引入");
                    result.put("belongGroup", "");
                    result.put("paramName", reqMsg.getParamName());
                }
            }
        }
        return AgentResult.OK(result);
    }

    @Override
    public AgentResult<?> sqlPreviewList(DataSourceDataPreviewReq dataSourceDataPreviewReq) {
        DynamicDataSourceModel dataSourceModel = getDynamicDbSourceById(dataSourceDataPreviewReq.getDataSourceId());
        if (Objects.isNull(dataSourceModel)) {
            log.error("数据源信息不存在,dataSource:{}", dataSourceDataPreviewReq.getDataSourceId());
            return null;
        }

        String sqlContent = dataSourceDataPreviewReq.getSqlContent();
        JSONArray sqlParam = dataSourceDataPreviewReq.getSqlParam();
        if (null != sqlParam && !sqlParam.isEmpty()) {
            for (Object obj : sqlParam) {
                LinkedHashMap object = (LinkedHashMap) obj;
                String name = String.valueOf(object.get("name"));
                Object defaultValue = object.get("defaultValue");
                if (Objects.nonNull(defaultValue)) {
                    sqlContent = sqlContent.replaceAll(java.util.regex.Pattern.quote(":" + name), java.util.regex.Matcher.quoteReplacement(String.valueOf(defaultValue)));
                }
            }
        }

        DataReviewDTO reviewDTO = new DataReviewDTO();

        // 获取表数据
        JdbcTemplate jdbcTemplate = getJdbcTemplate(dataSourceModel.getCode());
        // SQL注入校验
        SqlInjectionUtil.checkSql(sqlContent);
        sqlContent = "select * from (" + sqlContent + ") tab limit 100";
        List<Map<String, Object>> mapList;
        try {
            mapList = jdbcTemplate.queryForList(sqlContent);
        } catch (Exception e) {
            // 获取表字段信息
            String key = "查询出错，错误信息如下：";
            List<String> columnNames = new ArrayList<>();
            columnNames.add(key);
            reviewDTO.setTableHeaders(columnNames);
            List<Map<String, Object>> errList = new ArrayList<>();
            Map<String, Object> errMap = new HashMap<>();
            errMap.put(key, ExceptionUtils.getStackTrace(e));
            errList.add(errMap);
            reviewDTO.setDataList(errList);
            return AgentResult.OK(reviewDTO);
        }

        // 获取表字段信息
        if (CollectionUtils.isNotEmpty(mapList)) {
            Map<String, Object> map = mapList.get(0);
            List<String> columnNames = new ArrayList<>();
            columnNames.addAll(map.keySet());
            reviewDTO.setTableHeaders(columnNames);
            reviewDTO.setDataList(mapList);
        }
        return AgentResult.OK(reviewDTO);
    }

    @Override
    public List<SysDataSource> listDistanceDataSource(List<String> idList) {
        return listByIds(idList);
    }

    @Override
    public void saveDistanceDataSource(List<SysDataSource> dataSourceList) {
        saveBatch(dataSourceList);
    }

    private ListResult<?> getHiveDataSourceTableList(JdbcTemplate jdbcTemplate, TableListQueryReq tableSyncListQueryReq) {
        String showTable = "show tables";

        List<String> talbleNameList = jdbcTemplate.queryForList(showTable, String.class);

        List<TableInfoDTO> tableInfoDTOList = null;
        if (CollectionUtils.isNotEmpty(talbleNameList)) {
            tableInfoDTOList = new ArrayList<>();
            if (tableSyncListQueryReq.getTableName() != null) {
                for (String tableName : talbleNameList) {
                    if (tableName.contains(tableSyncListQueryReq.getTableName())) {
                        TableInfoDTO tableInfoDTO = new TableInfoDTO();
                        tableInfoDTO.setTableName(tableName.toUpperCase(Locale.ENGLISH));
                        tableInfoDTO.setTableComment("");
                        tableInfoDTOList.add(tableInfoDTO);
                    }
                }
            } else {
                for (String tableName : talbleNameList) {
                    TableInfoDTO tableInfoDTO = new TableInfoDTO();
                    tableInfoDTO.setTableName(tableName.toUpperCase(Locale.ENGLISH));
                    tableInfoDTO.setTableComment("");
                    tableInfoDTOList.add(tableInfoDTO);
                }
            }

        }
        int total = 0;
        List<TableInfoDTO> tableInfoDTOS = null;
        Integer pageIndex = tableSyncListQueryReq.getPageIndex();
        Integer pageSize = tableSyncListQueryReq.getPageSize();
        if (CollectionUtils.isNotEmpty(tableInfoDTOList)) {
            total = tableInfoDTOList.size();
            pageIndex = (pageIndex - 1) * pageSize;
            pageSize = pageSize + pageIndex;
            if (pageSize > total) pageSize = total;
            tableInfoDTOS = tableInfoDTOList.subList(pageIndex, pageSize);
        }
        return new ListResult<>(total, pageSize, pageIndex, tableInfoDTOS);
    }

    private ListResult<?> getOracleDataSourceTableList(JdbcTemplate jdbcTemplate, TableListQueryReq tableSyncListQueryReq) {
        StringBuffer countSql = new StringBuffer();
        countSql.append("select count(1) from user_tab_comments where 1=1");

        StringBuffer querySql = new StringBuffer();
        querySql.append("select table_name, comments from (select rownum as rowno, table_name, comments from user_tab_comments where 1=1");

        if (!StringUtils.isEmpty(tableSyncListQueryReq.getTableName())) {
            querySql.append(" and table_name like '%" + tableSyncListQueryReq.getTableName().toUpperCase(Locale.ENGLISH) + "%'");
            countSql.append(" and table_name like '%" + tableSyncListQueryReq.getTableName().toUpperCase(Locale.ENGLISH) + "%'");
        }
        if (!StringUtils.isEmpty(tableSyncListQueryReq.getTableNote())) {
            querySql.append(" and comments like '%" + tableSyncListQueryReq.getTableNote() + "%'");
            countSql.append(" and comments like '%" + tableSyncListQueryReq.getTableNote() + "%'");
        }
        int index = tableSyncListQueryReq.getPageIndex();
        int size = tableSyncListQueryReq.getPageSize();
        BigDecimal pageSize = new BigDecimal(size).multiply(new BigDecimal(index));
        BigDecimal pageIndex = new BigDecimal(size).multiply(new BigDecimal(index - 1));
        querySql.append(" and rownum <= " + pageSize + ") tab1 where tab1.rowno > " + pageIndex);

        int total = jdbcTemplate.queryForObject(countSql.toString(), Integer.class);
        List<Map<String, Object>> queryForList = jdbcTemplate.queryForList(querySql.toString());

        List<TableInfoDTO> tableInfoDTOList = null;
        if (CollectionUtils.isNotEmpty(queryForList)) {
            tableInfoDTOList = new ArrayList<>();
            for (Map<String, Object> map : queryForList) {
                TableInfoDTO tableInfoDTO = new TableInfoDTO();
                String tableName = FieldTypeUtil.getStr(map.get("table_name"));
                String tableComment = FieldTypeUtil.getStr(map.get("comments"));
                tableInfoDTO.setTableName(tableName.toUpperCase(Locale.ENGLISH));
                tableInfoDTO.setTableComment(StringUtils.isEmpty(tableComment) ? "" : tableComment.toUpperCase(Locale.ENGLISH));
                tableInfoDTOList.add(tableInfoDTO);
            }
        }

        return new ListResult<>(total, size, index, tableInfoDTOList);
    }

    private ListResult<?> getMysqlDataSourceTableList(JdbcTemplate jdbcTemplate, TableListQueryReq tableSyncListQueryReq) {
        String showField = "SELECT DATABASE()";
        List<Map<String, Object>> mapList = jdbcTemplate.queryForList(showField);
        if (CollectionUtils.isEmpty(mapList)) {
            return null;
        }
        Map<String, Object> objectMap = mapList.get(0);
        String tableSchema = String.valueOf(objectMap.get("DATABASE()"));

        StringBuffer countSql = new StringBuffer();
        countSql.append("select count(1) from information_schema.tables where table_schema = '" + tableSchema + "'");

        StringBuffer querySql = new StringBuffer();
        querySql.append("select table_name,table_comment from information_schema.tables where table_schema = '" + tableSchema + "'");

        if (!StringUtils.isEmpty(tableSyncListQueryReq.getTableName())) {
            String safeTableName = escapeSqlLikeParam(tableSyncListQueryReq.getTableName());
            querySql.append(" and table_name like '%" + safeTableName + "%'");
            countSql.append(" and table_name like '%" + safeTableName + "%'");
        }
        if (!StringUtils.isEmpty(tableSyncListQueryReq.getTableNote())) {
            String safeTableNote = escapeSqlLikeParam(tableSyncListQueryReq.getTableNote());
            querySql.append(" and table_comment like '%" + safeTableNote + "%'");
            countSql.append(" and table_comment like '%" + safeTableNote + "%'");
        }

        int pageSize = tableSyncListQueryReq.getPageSize();
        int index = tableSyncListQueryReq.getPageIndex();
        Integer pageIndex = (index - 1) * pageSize;
        querySql.append(" limit " + pageIndex + "," + pageSize);

        int total = jdbcTemplate.queryForObject(countSql.toString(), Integer.class);
        List<Map<String, Object>> queryForList = jdbcTemplate.queryForList(querySql.toString());

        List<TableInfoDTO> tableInfoDTOList = null;
        if (CollectionUtils.isNotEmpty(queryForList)) {
            tableInfoDTOList = new ArrayList<>();
            for (Map<String, Object> map : queryForList) {
                TableInfoDTO tableInfoDTO = new TableInfoDTO();
                String tableName = FieldTypeUtil.getStr(map.get("table_name"));
                String tableComment = FieldTypeUtil.getStr(map.get("table_comment"));
                tableInfoDTO.setTableName(tableName.toUpperCase(Locale.ENGLISH));
                tableInfoDTO.setTableComment(StringUtils.isEmpty(tableComment) ? "" : tableComment.toUpperCase(Locale.ENGLISH));
                tableInfoDTOList.add(tableInfoDTO);
            }
        }
        return new ListResult<>(total, pageSize, index, tableInfoDTOList);
    }

    private ListResult<?> getPostgresqlDataSourceTableList(JdbcTemplate jdbcTemplate,
                                                           TableListQueryReq tableSyncListQueryReq) {
        // 1. 获取当前数据库Schema
        String schema = jdbcTemplate.queryForObject("SELECT current_schema()", String.class);
        if (StringUtils.isEmpty(schema)) {
            return new ListResult<>(0, tableSyncListQueryReq.getPageSize(),
                    tableSyncListQueryReq.getPageIndex(), Collections.emptyList());
        }

        // 2. 修正：正确获取表注释的SQL
        // 方法1：使用 pg_class 和 pg_namespace 系统表
        StringBuffer countSql = new StringBuffer();
        countSql.append("SELECT COUNT(1) ");
        countSql.append("FROM pg_class c ");
        countSql.append("INNER JOIN pg_namespace n ON n.oid = c.relnamespace ");
        countSql.append("LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0 ");
        countSql.append("WHERE n.nspname = ? ");
        countSql.append("AND c.relkind = 'r' "); // 'r' 表示普通表

        StringBuffer querySql = new StringBuffer();
        querySql.append("SELECT c.relname as table_name, d.description as table_comment ");
        querySql.append("FROM pg_class c ");
        querySql.append("INNER JOIN pg_namespace n ON n.oid = c.relnamespace ");
        querySql.append("LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0 ");
        querySql.append("WHERE n.nspname = ? ");
        querySql.append("AND c.relkind = 'r' ");

        // 3. 参数列表
        List<Object> countParams = new ArrayList<>();
        List<Object> queryParams = new ArrayList<>();

        // 使用当前schema
        countParams.add(schema);
        queryParams.add(schema);

        // 添加表名过滤条件
        // ⚠️ 必须**大小写不敏感**（2026-09-16 修复）：
        //   本方法在返回前把表名 `toUpperCase` 了（见下方 setTableName，与 MySQL 分支/源工程保持一致），
        //   而 PG/openGauss 的 `pg_class.relname` 存的是**小写**，`LIKE` 又是**大小写敏感**的 →
        //   用户照着界面上显示的大写表名去搜，永远 0 命中（看起来就像"模糊检索坏了"）。
        //   源工程是 MySQL：MySQL 的 `like` 受排序规则约束、默认**不区分大小写**，所以源工程没暴露这个问题。
        //   → 两边都 LOWER() 后再比，等价于把 MySQL 的默认行为搬过来。
        if (!StringUtils.isEmpty(tableSyncListQueryReq.getTableName())) {
            querySql.append(" AND LOWER(c.relname) LIKE LOWER(?)");
            countSql.append(" AND LOWER(c.relname) LIKE LOWER(?)");
            String likePattern = "%" + tableSyncListQueryReq.getTableName() + "%";
            queryParams.add(likePattern);
            countParams.add(likePattern);
        }

        // 添加表注释过滤条件（同上，统一走 LOWER 比对；中文注释下 LOWER 为空操作，只为保持一致）
        if (!StringUtils.isEmpty(tableSyncListQueryReq.getTableNote())) {
            querySql.append(" AND LOWER(d.description) LIKE LOWER(?)");
            countSql.append(" AND LOWER(d.description) LIKE LOWER(?)");
            String likePattern = "%" + tableSyncListQueryReq.getTableNote() + "%";
            queryParams.add(likePattern);
            countParams.add(likePattern);
        }

        // 4. 分页查询
        int pageSize = tableSyncListQueryReq.getPageSize();
        int index = tableSyncListQueryReq.getPageIndex();
        int offset = (index - 1) * pageSize;
        querySql.append(" ORDER BY c.relname LIMIT ? OFFSET ?");
        queryParams.add(pageSize);
        queryParams.add(offset);

        // 5. 执行查询
        int total = 0;
        try {
            total = jdbcTemplate.queryForObject(countSql.toString(), Integer.class, countParams.toArray());
        } catch (Exception e) {
            log.error("查询表总数失败", e);
            return new ListResult<>(0, pageSize, index, Collections.emptyList());
        }

        List<Map<String, Object>> queryForList;
        try {
            queryForList = jdbcTemplate.queryForList(querySql.toString(), queryParams.toArray());
        } catch (Exception e) {
            log.error("查询表列表失败", e);
            return new ListResult<>(0, pageSize, index, Collections.emptyList());
        }

        // 6. 转换结果
        List<TableInfoDTO> tableInfoDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(queryForList)) {
            for (Map<String, Object> map : queryForList) {
                TableInfoDTO tableInfoDTO = new TableInfoDTO();
                String tableName = FieldTypeUtil.getStr(map.get("table_name"));
                String tableComment = FieldTypeUtil.getStr(map.get("table_comment"));
                if (!StringUtils.isEmpty(tableName)) {
                    tableInfoDTO.setTableName(tableName.toUpperCase(Locale.ENGLISH));
                    tableInfoDTO.setTableComment(StringUtils.isEmpty(tableComment) ? "" : tableComment);
                    tableInfoDTOList.add(tableInfoDTO);
                }
            }
        }

        return new ListResult<>(total, pageSize, index, tableInfoDTOList);
    }

    /**
     * 转义SQL LIKE参数中的特殊字符，防止SQL注入
     */
    private String escapeSqlLikeParam(String param) {
        if (param == null) {
            return null;
        }
        return param.replace("\\", "\\\\")
                    .replace("'", "\\'")
                    .replace("\"", "\\\"")
                    .replace("%", "\\%")
                    .replace("_", "\\_");
    }

    private ListResult<TableFieldDTO> queryMysqlTableInfo(JdbcTemplate jdbcTemplate, String tableName) {
        // 查询表信息
        String schema = "SELECT DATABASE()";
        List<Map<String, Object>> schemaList = jdbcTemplate.queryForList(schema);
        if (CollectionUtils.isEmpty(schemaList)) {
            return null;
        }
        Map<String, Object> objectMap = schemaList.get(0);
        String tableSchema = String.valueOf(objectMap.get("DATABASE()"));

        List<TableFieldDTO> tableFieldDTOList = null;
        String showField = "SELECT COLUMN_NAME,COLUMN_TYPE,COLUMN_COMMENT,IS_NULLABLE,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH FROM  INFORMATION_SCHEMA.COLUMNS  where table_name = '" + tableName + "'" + " and table_schema = '" + tableSchema + "'";
        List<Map<String, Object>> mapList = jdbcTemplate.queryForList(showField);
        if (CollectionUtils.isNotEmpty(mapList)) {
            tableFieldDTOList = mapList.stream().map(record -> {
                TableFieldDTO tableFieldDTO = new TableFieldDTO();
                tableFieldDTO.setColumnName(FieldTypeUtil.getStr(record.get("COLUMN_NAME")));
                tableFieldDTO.setColumnComment(FieldTypeUtil.getStr(record.get("COLUMN_COMMENT")));
                tableFieldDTO.setDataType(FieldTypeUtil.getStr(record.get("DATA_TYPE")));
                tableFieldDTO.setLength(FieldTypeUtil.getStr(record.get("CHARACTER_MAXIMUM_LENGTH")));
                tableFieldDTO.setIsNullable("YES".equalsIgnoreCase(FieldTypeUtil.getStr(record.get("IS_NULLABLE"))) ? OnlineEnum.Y.name() : OnlineEnum.N.name());
                return tableFieldDTO;
            }).collect(Collectors.toList());
        }
        return new ListResult<>(tableFieldDTOList);
    }

    private ListResult<TableFieldDTO> queryOracleTableInfo(JdbcTemplate jdbcTemplate, String tableName) {
        List<TableFieldDTO> tableFieldDTOList = null;
        String showField = "SELECT UTC.COLUMN_NAME,UCC.COMMENTS,UTC.DATA_TYPE,UTC.DATA_LENGTH,UTC.NULLABLE FROM USER_TAB_COLUMNS UTC INNER JOIN USER_COL_COMMENTS UCC ON UTC.TABLE_NAME = UCC.TABLE_NAME AND UTC.COLUMN_NAME=UCC.COLUMN_NAME where UTC.TABLE_NAME = '" + tableName + "'";
        List<Map<String, Object>> mapList = jdbcTemplate.queryForList(showField);
        // 保存表以及字段信息
        if (CollectionUtils.isNotEmpty(mapList)) {
            tableFieldDTOList = mapList.stream().map(record -> {
                TableFieldDTO tableFieldDTO = new TableFieldDTO();
                tableFieldDTO.setColumnName(FieldTypeUtil.getStr(record.get("COLUMN_NAME")).toUpperCase(Locale.ENGLISH));
                tableFieldDTO.setColumnComment(FieldTypeUtil.getStr(record.get("COMMENTS")));
                tableFieldDTO.setDataType(FieldTypeUtil.getStr(record.get("DATA_TYPE")).toLowerCase(Locale.ENGLISH));
                tableFieldDTO.setLength(FieldTypeUtil.getStr(record.get("DATA_LENGTH")));
                tableFieldDTO.setIsNullable(FieldTypeUtil.getStr(record.get("NULLABLE")));
                return tableFieldDTO;
            }).collect(Collectors.toList());
        }
        return new ListResult<>(tableFieldDTOList);
    }

    private ListResult<TableFieldDTO> queryHiveTableInfo(JdbcTemplate jdbcTemplate, String tableName) {
        List<TableFieldDTO> tableFieldDTOList = null;
        String showField = "DESCRIBE " + tableName;
        List<Map<String, Object>> mapList = jdbcTemplate.queryForList(showField);
        if (CollectionUtils.isNotEmpty(mapList)) {
            tableFieldDTOList = mapList.stream().map(record -> {
                TableFieldDTO tableFieldDTO = new TableFieldDTO();
                tableFieldDTO.setColumnName(FieldTypeUtil.getStr(record.get("name")));
                tableFieldDTO.setColumnComment(FieldTypeUtil.getStr(record.get("comment")));
                tableFieldDTO.setDataType("varchar");
                tableFieldDTO.setIsNullable(OnlineEnum.Y.name());
                tableFieldDTO.setLength("100");
                return tableFieldDTO;
            }).collect(Collectors.toList());
        }
        return new ListResult<>(tableFieldDTOList);
    }

    // 从 JDBC URL 中解析 currentSchema 参数值，兼容参数位置任意、位于末尾等场景
    private String parseCurrentSchemaFromUrl(String dbUrl) {
        if (StringUtils.isEmpty(dbUrl) || !dbUrl.contains("currentSchema=")) {
            return "public";
        }
        int start = dbUrl.indexOf("currentSchema=") + "currentSchema=".length();
        int end = dbUrl.indexOf("&", start);
        if (end == -1) {
            end = dbUrl.length();
        }
        return dbUrl.substring(start, end);
    }

    private ListResult<TableFieldDTO> queryPostgresqlTableInfo(JdbcTemplate jdbcTemplate, String tableName, String tableSchema) {
        // 分两步查询：先查字段信息，再查注释
        String fieldsSql = "SELECT " +
                           "  column_name, " +
                           "  data_type, " +
                           "  is_nullable, " +
                           "  COALESCE(character_maximum_length::text, '') as max_length, " +
                           "  COALESCE(numeric_precision::text, '') as num_precision, " +
                           "  COALESCE(numeric_scale::text, '') as num_scale " +
                           "FROM information_schema.columns " +
                           "WHERE table_name = ? AND table_schema = ? " +
                           "ORDER BY ordinal_position";

        try {
            List<Map<String, Object>> mapList = jdbcTemplate.queryForList(fieldsSql, tableName.toLowerCase(Locale.ROOT), tableSchema);
            if (CollectionUtils.isEmpty(mapList)) {
                mapList = jdbcTemplate.queryForList(fieldsSql, tableName.toUpperCase(Locale.ROOT), tableSchema);
            }

            List<TableFieldDTO> tableFieldDTOList = new ArrayList<>();

            for (Map<String, Object> record : mapList) {
                TableFieldDTO tableFieldDTO = new TableFieldDTO();
                String columnName = FieldTypeUtil.getStr(record.get("column_name"));
                tableFieldDTO.setColumnName(columnName);
                tableFieldDTO.setDataType(FieldTypeUtil.getStr(record.get("data_type")));

                // 单独查询每个字段的注释
                String commentSql = "SELECT col_description((?::regclass)::oid, ?)";
                String fullTableName = tableSchema + "." + tableName;
                String columnComment = jdbcTemplate.queryForObject(commentSql, String.class, fullTableName, getColumnPosition(jdbcTemplate, tableName, tableSchema, columnName));
                tableFieldDTO.setColumnComment(StringUtils.isEmpty(columnComment) ? "" : columnComment);

                String isNullable = FieldTypeUtil.getStr(record.get("is_nullable"));
                tableFieldDTO.setIsNullable("YES".equalsIgnoreCase(isNullable) ? OnlineEnum.Y.name() : OnlineEnum.N.name());

                // 处理长度
                String maxLength = FieldTypeUtil.getStr(record.get("max_length"));
                if (!StringUtils.isEmpty(maxLength) && !"null".equalsIgnoreCase(maxLength)) {
                    tableFieldDTO.setLength(maxLength);
                } else {
                    String precision = FieldTypeUtil.getStr(record.get("num_precision"));
                    String scale = FieldTypeUtil.getStr(record.get("num_scale"));
                    if (!StringUtils.isEmpty(precision) && !"null".equalsIgnoreCase(precision)) {
                        tableFieldDTO.setLength(scale != null && !"null".equals(scale) ? precision + "," + scale : precision);
                    } else {
                        tableFieldDTO.setLength("");
                    }
                }

                tableFieldDTOList.add(tableFieldDTO);
            }

            return new ListResult<>(tableFieldDTOList);
        } catch (Exception e) {
            log.error("查询PostgreSQL表结构失败，表名：{}，schema：{}", tableName, tableSchema, e);
            return new ListResult<>(Collections.emptyList());
        }
    }

    // 辅助方法：获取字段的位置序号（与字段列表查询保持一致，先小写后大写，避免大小写不一致导致查不到而返回0，从而误取表注释）
    private int getColumnPosition(JdbcTemplate jdbcTemplate, String tableName, String schema, String columnName) {
        String sql = "SELECT ordinal_position FROM information_schema.columns " +
                     "WHERE table_name = ? AND table_schema = ? AND column_name = ?";
        try {
            return jdbcTemplate.queryForObject(sql, Integer.class, tableName.toLowerCase(Locale.ROOT), schema, columnName);
        } catch (Exception e) {
            try {
                return jdbcTemplate.queryForObject(sql, Integer.class, tableName.toUpperCase(Locale.ROOT), schema, columnName);
            } catch (Exception e2) {
                return 0;
            }
        }
    }

    /**
     * 按主键取数据源配置（{@link AgentDataSourceProvider} 实现）
     *
     * <p>迁移改造点：源工程把「取数据源配置」放在 amar-base 的 {@code CommonAPI} 实现里，
     * 与 JeecgBoot 的 Service 体系绑定。本工程改由本类承担（它本来就是数据源配置的服务实现），
     * 使 {@code DynamicDBUtil} / {@code DataSourceCachePool} / {@code SqlDataSetBuilder} 只依赖
     * agent 自己的接口。</p>
     *
     * <p><b>密码处理</b>：库里 {@code db_password} 是密文（{@code SecurityUtil.jiami} 加密），
     * 建连接前必须解密，否则连不上（错误表现为认证失败，容易误判成"账号密码配错了"）。</p>
     */
    @Override
    public DynamicDataSourceModel getDynamicDbSourceById(String dbSourceId) {
        if (StringUtils.isBlank(dbSourceId)) {
            return null;
        }
        return toDynamicModel(getById(dbSourceId));
    }

    /**
     * 按编码取数据源配置（{@link AgentDataSourceProvider} 实现）
     *
     * <p>动态连接池（{@code DataSourceCachePool}）以 {@code code} 作为缓存 key，
     * 故这条路径用得多。</p>
     */
    @Override
    public DynamicDataSourceModel getDynamicDbSourceByCode(String code) {
        if (StringUtils.isBlank(code)) {
            return null;
        }
        SysDataSource dbSource = getOne(
                Wrappers.<SysDataSource>lambdaQuery().eq(SysDataSource::getCode, code), false);
        return toDynamicModel(dbSource);
    }

    /** 实体 → 动态数据源模型（含密码解密） */
    private DynamicDataSourceModel toDynamicModel(SysDataSource dbSource) {
        if (Objects.isNull(dbSource)) {
            return null;
        }
        if (StringUtils.isNotBlank(dbSource.getDbPassword())) {
            dbSource.setDbPassword(SecurityUtil.jiemi(dbSource.getDbPassword()));
        }
        return new DynamicDataSourceModel(dbSource);
    }
}
