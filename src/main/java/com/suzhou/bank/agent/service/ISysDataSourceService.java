package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.model.req.DataSourceTableInfoReq;
import com.suzhou.bank.agent.model.req.IndexTableSyncRcordReq;
import com.suzhou.bank.agent.model.req.TableSyncRcordReq;
import com.suzhou.bank.agent.model.vo.IndexParamsVO;
import com.suzhou.bank.agent.entity.SysDataSource;
import com.suzhou.bank.agent.model.req.DataSourceDataPreviewReq;
import com.suzhou.bank.agent.model.req.ParamsDataSourceDataPreviewReq;
import com.suzhou.bank.agent.model.req.TableInfoQueryReq;
import com.suzhou.bank.agent.model.req.TableListQueryReq;

import java.util.List;

/**
 * @Description: 多数据源管理
 * @Author: jeecg-boot
 * @Date: 2019-12-25
 * @Version: V1.0
 */
public interface ISysDataSourceService extends IService<SysDataSource> {

    ListResult<?>  getSyncTableList(TableListQueryReq tableListQueryReq);

    ListResult<?>  getSyncTableInfo(TableInfoQueryReq tableInfoQueryReq);

    AgentResult<?> getDataPreview(DataSourceDataPreviewReq dataSourceDataPreviewReq);

    AgentResult<?> getParamDataSourcePreview(ParamsDataSourceDataPreviewReq paramsDataSourceDataPreviewReq);

    AgentResult<?> querySourceTableField(TableSyncRcordReq reqMsg);

    ListResult<?>  getDataSourceTableInfo(DataSourceTableInfoReq req);

    AgentResult<?> saveIndexParamsFromSourceTableField(List<IndexParamsVO> reqMsg);

    AgentResult<?> showParamInfo(IndexTableSyncRcordReq reqMsg);

    AgentResult<?> sqlPreviewList(DataSourceDataPreviewReq dataSourceDataPreviewReq);

    List<SysDataSource> listDistanceDataSource(List<String> idList);

    void saveDistanceDataSource(List<SysDataSource> dataSourceList);
}
