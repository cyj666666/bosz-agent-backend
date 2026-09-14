package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.model.dto.IndexParamsSimpleDTO;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.IndexBaseGroupVO;

import java.util.List;

public interface IIndexConfigService {

    ListResult<?> queryIndexParamsList(IndexParamQueryReq reqMsg);

    ListResult<?> getAllIndexParamsList(IndexParamQueryReq reqMsg);

    AgentResult<?> insertIndexParamsInfo(IndexParamsInfoSaveReq reqMsg);

    AgentResult<?> insertIndexParamsObject(IndexParamsInfoSaveReq reqMsg);

    AgentResult<?> deleteIndexParamsList(String paramNo);

    AgentResult<?> queryIndexParamsInfo(IndexParamsInfoReq reqMsg);

    AgentResult<?> updateIndexParamsInfo(IndexParamsInfoSaveReq reqMsg);

    AgentResult<?> updateIndexParamsObject(IndexParamsInfoSaveReq reqMsg);

    List<IndexParamsSimpleDTO> queryAllIndexParamsList(IndexParamQueryReq reqMsg);

    ListResult<?> queryIndexParamsListFromCache(IndexParamQueryReq reqMsg);

    boolean addIndexGroup(IndexBaseGroupVO indexBaseGroupVO);

    ListResult<?> queryIndexBaseGroupTree(String groupName, String groupValue);

    boolean updateIndexBaseGroupInfo(IndexBaseGroupVO reqMsg);

    boolean deleteIndexBaseGroupInfo(String groupId);

    ListResult<?> queryIndexBaseParamsList(IndexBaseGroupReq reqMsg);

    AgentResult<?> copyIndexParamsInfo(IndexParamsInfoSaveReq reqMsg);

    AgentResult<?> moveIndexParamsInfo(IndexMoveReq reqMsg);

    AgentResult<?> getRelateParamsList(IndexParamsInfoReq reqMsg);

    AgentResult<?> queryRelateKnowledgeInfo(IndexParamsInfoReq reqMsg);

    AgentResult<?> queryRelateIndexInfo(IndexParamsInfoReq reqMsg);

    AgentResult<?> queryIndexRelateKnowledgeInfo(String paramNo);

    void refreshIndexCache();
}
