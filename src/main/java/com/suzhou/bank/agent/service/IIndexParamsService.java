package com.suzhou.bank.agent.service;


import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.model.req.IndexVersionReq;
import com.suzhou.bank.agent.model.req.TableSyncRcordReq;
import com.suzhou.bank.agent.model.vo.IndexParamsVO;
import com.suzhou.bank.agent.model.vo.ReportVersionVO;
import com.suzhou.bank.agent.model.dto.TableFieldDTO;

import java.util.List;

public interface IIndexParamsService extends IService<IndexParamsEntity> {

    ListResult<IndexParamsEntity> queryParamsGroupList(IndexVersionReq reqMsg, ReportVersionVO versionVO, String paramType);

    List<IndexParamsEntity> selectByParentParamNoList(List<String> paramNoList);

    List<IndexParamsEntity> selectByOtherNoList(List<String> paramNoList);

    List<IndexParamsEntity> selectByParentParamNo(String paramNo);

    List<IndexParamsEntity> selectByOtherNo(String paramNo, String scriptType);

    void saveIndexParamsFromTableField(List<IndexParamsVO> indexParamsVOList, IndexParamsVO indexParamsVO);

    void setParamSqlScript(List<String> paramIdList, IndexParamsVO paramsVO);

    IndexParamsVO queryParamFromSourceTableField(TableSyncRcordReq reqMsg, List<TableFieldDTO> tableFieldDTOS);

    List<IndexParamsEntity> getIndexParamsListWithId(String paramId, String modelNo, String versionNo, String reportVersion);

    void removeAllChildParams(List<String> groupIdList);

    List<IndexParamsEntity> getParamsList(List<String> paramNoList);

    List<IndexParamsEntity> listDistanceIndexParams(List<String> paramNoList);

    void saveDistanceIndexParams(List<IndexParamsEntity> indexParamsList);
}
