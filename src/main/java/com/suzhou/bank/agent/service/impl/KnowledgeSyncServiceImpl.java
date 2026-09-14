package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.google.common.collect.Maps;
import com.google.common.collect.Sets;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.entity.*;
import com.suzhou.bank.agent.enums.ExcepitonStageEnum;
import com.suzhou.bank.agent.enums.SyncStatusEnum;
import com.suzhou.bank.agent.enums.SyncTypeEnum;
import com.suzhou.bank.agent.mapper.IndexBaseGroupMapper;
import com.suzhou.bank.agent.mapper.IndexParamsMapper;
import com.suzhou.bank.agent.mapper.KnowledgeBaseGroupMapper;
import com.suzhou.bank.agent.model.req.KnowledgeSyncTaskReq;
import com.suzhou.bank.agent.service.*;
import com.suzhou.bank.agent.entity.SysDataSource;
import com.suzhou.bank.agent.service.ISysDataSourceService;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 知识库同步服务实现类
 * 1、知识库：涉及知识库及分组配置+指标+数据源
 * 2、指标：涉及指标及分组配置+数据源
 * 3、数据源：涉及API服务、接口、数据库配置同步
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeSyncServiceImpl implements IKnowledgeSyncService {

    private final IndexBaseGroupMapper indexBaseGroupMapper;
    private final IIndexBaseGroupService indexBaseGroupService;
    private final IndexParamsMapper indexParamsMapper;
    private final IIndexParamsService indexParamsService;
    private final IIndexRelateInfoService indexRelateInfoService;
    private final KnowledgeBaseGroupMapper knowledgeBaseGroupMapper;
    private final IKnowledgeBaseGroupService knowledgeBaseGroupService;
    private final IKnowledgeBaseParamsService knowledgeBaseParamsService;
    private final IKnowledgeBaseVersionService knowledgeBaseVersionService;
    private final ExtIntfSupplierManageService extIntfSupplierManageService;
    private final ExtIntfParamDefineService extIntfParamDefineService;
    private final ExtIntfManageService extIntfManageService;
    private final ExtIntfParamManageService extIntfParamManageService;
    private final ISysDataSourceService sysDataSourceService;
    private final IIndexParamsVersionService indexParamsVersionService;
    private final IKnowledgeBlackParamsConfigEntityService knowledgeBlackParamsConfigEntityService;
    private final IKnowledgeBlackParamsConfigVersionService knowledgeBlackParamsConfigVersionService;
    private final IKnowledgeRelateInputParamService knowledgeRelateInputParamService;
    private final IKnowledgeRelateInputParamVersionService knowledgeRelateInputParamVersionService;
    private final IKnowledgeRelateIndexService knowledgeRelateIndexService;
    private final IKnowledgeRelateIndexVersionService knowledgeRelateIndexVersionService;
    private final IKnowledgeSyncTaskService knowledgeSyncTaskService;
    private final IKnowledgeSyncTaskExceptionRecordService knowledgeSyncTaskExceptionRecordService;
    private final ILargeModelConfigService largeModelConfigService;

    /**
     * 同步知识库及其关联信息
     *
     * @param knowledgeIdList 知识库ID列表
     */
    @Override
    @Async
    public void syncKnowledge(List<String> knowledgeIdList, String taskId) {
        long startTime = System.currentTimeMillis();
        String taskStatus = SyncStatusEnum.PROCESSING.id;

        try {
            // 查询当前库的知识库信息(优先考虑同步已发布版本)
            List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList = new ArrayList<>();
            knowledgeIdList.forEach(paramId -> {
                KnowledgeBaseParamsEntity knowledgeBaseParamsEntity = knowledgeBaseParamsService.getById(paramId);
                KnowledgeBaseVersionEntity knowledgeBaseVersionEntity = knowledgeBaseVersionService.getLatestVersion(paramId);
                if (Objects.nonNull(knowledgeBaseVersionEntity)) {
                    BeanUtil.copyProperties(knowledgeBaseVersionEntity, knowledgeBaseParamsEntity, "inputTime", "updateTime");

                }
                knowledgeBaseParamsList.add(knowledgeBaseParamsEntity);
            });

            if (CollectionUtils.isEmpty(knowledgeBaseParamsList)) {
                log.info("未查询到相关知识库，无需同步！");
                saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.INIT.id, "未查询到相关指标，无需同步！");
                return;
            }

            // 更新任务状态为处理中
            updateSyncStatus(taskId, taskStatus, startTime);

            // 同步知识库配置信息
            handleKnowledgeParams(taskId, knowledgeBaseParamsList);

            // 同步大模型信息
            Set<String> largeModelCodeSet = knowledgeBaseParamsList.stream()
                    .map(KnowledgeBaseParamsEntity::getLargeModelCode)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toSet());
            handleKnowledgeLargeModelSource(taskId, new ArrayList<>(largeModelCodeSet));

            // 同步知识库分组信息
            Set<String> groupIdSet = knowledgeBaseParamsList.stream()
                    .map(KnowledgeBaseParamsEntity::getGroupId)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toSet());
            handleKnowledgeGroup(taskId, groupIdSet);

            // 查询指标信息
            List<IndexParamsEntity> indexParamsList = getKnowledgeRelateIndexList(knowledgeBaseParamsList);
            if (CollectionUtils.isEmpty(indexParamsList)) {
                log.info("未查询到相关指标，无需同步！");
                taskStatus = SyncStatusEnum.SUCCESS.id;
                return;
            }

            // 同步指标信息
            handleKnowledgeRelateIndex(taskId, indexParamsList);

            // 同步指标分组信息
            Set<String> indexGroupIdSet = indexParamsList.stream()
                    .map(IndexParamsEntity::getParentParamNo)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toSet());
            handleKnowledgeRelateIndexGroup(taskId, indexGroupIdSet);

            // 同步数据源信息
            handleKnowledgeDataSource(taskId, indexParamsList);

            taskStatus = SyncStatusEnum.SUCCESS.id;
        } catch (Exception e) {
            log.error("同步知识库失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.INIT.id, ExceptionUtils.getStackTrace(e));
        } finally {
            log.info("知识库同步完成!");
            // 更新任务状态(判断异常信息表是否为空,为空则为成功,否则为失败)
            if (checkSyncException(taskId)) {
                taskStatus = SyncStatusEnum.FAILED.id;
            }
            updateSyncStatus(taskId, taskStatus, startTime);
        }
    }

    private List<IndexParamsEntity> getKnowledgeRelateIndexList(List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList) {
        List<String> relateIndexList = new ArrayList<>();
        knowledgeBaseParamsList.forEach(param -> {
            String relateIndexSet = param.getRelateIndexSet();
            if (StringUtils.isNotEmpty(relateIndexSet)) {
                JSONArray.parseArray(relateIndexSet).forEach(index -> {
                    relateIndexList.add(((JSONObject) index).getString("paramNo"));
                });
            }
        });

        if (CollectionUtils.isEmpty(relateIndexList)) {
            return new ArrayList<>();
        }

        return indexParamsMapper.selectAllGroupIndexList(String.join(",", relateIndexList), relateIndexList);
    }

    private void handleKnowledgeLargeModelSource(String taskId, List<String> largeModelCodeList) {
        try {
            if (CollectionUtils.isEmpty(largeModelCodeList)) {
                log.info("未查询到相关大模型，无需同步！");
                return;
            }
            List<LargeModelConfigEntity> modelConfigEntityList = largeModelConfigService.listByLargeModelCode(largeModelCodeList);
            List<LargeModelConfigEntity> existingModelConfigList = largeModelConfigService.listDistanceLargeModelCode(largeModelCodeList);

            if (CollectionUtils.isNotEmpty(existingModelConfigList)) {
                Set<String> existingLargeModelCodeSet = existingModelConfigList.stream()
                        .map(LargeModelConfigEntity::getLmCode)
                        .collect(Collectors.toSet());

                // 只同步不存在的大模型
                modelConfigEntityList = modelConfigEntityList.stream()
                        .filter(dataSource -> !existingLargeModelCodeSet.contains(dataSource.getLmCode()))
                        .collect(Collectors.toList());
            }

            if (CollectionUtils.isNotEmpty(modelConfigEntityList)) {
                // 将知识库关联大模型列表中的ID设置为新ID
                modelConfigEntityList.forEach(index -> index.setId(null));
                largeModelConfigService.saveDistanceLargeModelConfig(modelConfigEntityList);
                log.info("同步了{}个大模型！", modelConfigEntityList.size());
            }

        } catch (Exception e) {
            log.error("同步大模型失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.LARGE_MODEL_SOURCE.id, "同步大模型失败！");
        }
    }

    @Async
    @Override
    public void syncIndex(List<String> syncIdList, String taskId) {
        long startTime = System.currentTimeMillis();
        String taskStatus = SyncStatusEnum.PROCESSING.id;
        try {
            String paramNoListStr = String.join(",", syncIdList);
            List<IndexParamsEntity> indexParamsList = indexParamsMapper.selectAllGroupIndexList(paramNoListStr, syncIdList);
            if (CollectionUtils.isEmpty(indexParamsList)) {
                log.info("未查询到相关指标，无需同步！");
                taskStatus = SyncStatusEnum.FAILED.id;
                saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.INIT.id, "未查询到相关指标，无需同步！");
                return;
            }

            // 更新任务状态为处理中
            updateSyncStatus(taskId, taskStatus, startTime);

            // 同步指标信息
            handleKnowledgeRelateIndex(taskId, indexParamsList);

            // 同步指标分组信息
            Set<String> indexGroupIdSet = indexParamsList.stream()
                    .map(IndexParamsEntity::getParentParamNo)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toSet());
            handleKnowledgeRelateIndexGroup(taskId, indexGroupIdSet);

            // 同步数据源信息
            handleKnowledgeDataSource(taskId, indexParamsList);
            taskStatus = SyncStatusEnum.SUCCESS.id;
        } catch (Exception e) {
            log.error("同步指标失败！", e);
            taskStatus = SyncStatusEnum.FAILED.id;
        } finally {
            log.info("指标同步完成!");
            updateSyncStatus(taskId, taskStatus, startTime);
        }
    }

    @Async
    @Override
    public void syncApiSource(List<String> syncIdList, String taskId) {
        long startTime = System.currentTimeMillis();
        String taskStatus = SyncStatusEnum.PROCESSING.id;
        try {
            List<ExtIntfManageEntity> extIntfManageList = extIntfManageService.listByIds(syncIdList);
            if (CollectionUtils.isEmpty(extIntfManageList)) {
                log.info("未查询到相关接口，无需同步！");
                taskStatus = SyncStatusEnum.FAILED.id;
                saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.INIT.id, "未查询到相关接口，同步失败！");
                return;
            }

            // 更新任务状态为处理中
            updateSyncStatus(taskId, taskStatus, startTime);

            // 同步外部服务供应商
            Set<String> supplierIdSet = extIntfManageList.stream()
                    .map(ExtIntfManageEntity::getSupplierId)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toSet());
            syncExtSupplierList(supplierIdSet);

            // 同步外部服务接口配置
            Set<String> intfNoSet = extIntfManageList.stream()
                    .map(ExtIntfManageEntity::getIntfNo)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toSet());
            syncExtManageList(supplierIdSet, intfNoSet);

            taskStatus = SyncStatusEnum.SUCCESS.id;
        } catch (Exception e) {
            log.error("同步外部服务接口配置失败！", e);
            taskStatus = SyncStatusEnum.FAILED.id;
        } finally {
            log.info("外部服务接口配置同步完成!");
            updateSyncStatus(taskId, taskStatus, startTime);
        }
    }

    @Override
    public void syncDataSource(List<String> syncIdList, String taskId) {
        long startTime = System.currentTimeMillis();
        String taskStatus = SyncStatusEnum.PROCESSING.id;
        try {
            // 更新任务状态为处理中
            updateSyncStatus(taskId, taskStatus, startTime);

            // 同步数据源信息
            syncDataSourceList(new HashSet<>(syncIdList));

            taskStatus = SyncStatusEnum.SUCCESS.id;
        } catch (Exception e) {
            log.error("同步数据源失败！", e);
            taskStatus = SyncStatusEnum.FAILED.id;
        } finally {
            log.info("数据源同步完成!");
            updateSyncStatus(taskId, taskStatus, startTime);
        }
    }

    @Override
    public String saveSyncTask(String syncType, String syncStatus) {
        KnowledgeSyncTaskEntity entity = new KnowledgeSyncTaskEntity();
        entity.setId(ParamUtil.getSerialNo());
        entity.setSyncType(syncType);
        entity.setSyncStatus(syncStatus);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        entity.setUserId(apiContextModel.getUserId());
        entity.setUserName(apiContextModel.getUserName());
        knowledgeSyncTaskService.saveOrUpdate(entity);
        return entity.getId();
    }

    @Override
    public void updateSyncStatus(String taskId, String syncStatus, long startTime) {
        LambdaQueryWrapper<KnowledgeSyncTaskEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeSyncTaskEntity::getId, taskId);
        KnowledgeSyncTaskEntity entity = new KnowledgeSyncTaskEntity();
        entity.setSyncStatus(syncStatus);
        entity.setCostTime((int) (System.currentTimeMillis() - startTime));
        knowledgeSyncTaskService.update(entity, queryWrapper);
    }

    @Override
    public ListResult<?> getSyncTaskList(KnowledgeSyncTaskReq req) {
        LambdaQueryWrapper<KnowledgeSyncTaskEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(StringUtils.isNotEmpty(req.getSyncType()), KnowledgeSyncTaskEntity::getSyncType, req.getSyncType());
        queryWrapper.eq(StringUtils.isNotEmpty(req.getSyncStatus()), KnowledgeSyncTaskEntity::getSyncStatus, req.getSyncStatus());
        queryWrapper.ge(StringUtils.isNotEmpty(req.getStartTimeBegin()), KnowledgeSyncTaskEntity::getInputTime, req.getStartTimeBegin());
        queryWrapper.le(StringUtils.isNotEmpty(req.getStartTimeEnd()), KnowledgeSyncTaskEntity::getInputTime, req.getStartTimeEnd());
        queryWrapper.orderByDesc(KnowledgeSyncTaskEntity::getInputTime);
        Page<KnowledgeSyncTaskEntity> page = knowledgeSyncTaskService.page(new Page<>(req.getPageIndex(), req.getPageSize()), queryWrapper);
        if (page.getTotal() <= 0) {
            return new ListResult<>(0, 0);
        }
        page.getRecords().forEach(item -> {
            try {
                item.setSyncType(SyncTypeEnum.getById(item.getSyncType()).name);
                item.setSyncStatus(SyncStatusEnum.getById(item.getSyncStatus()).name);
                item.setCostTimeDesc((item.getCostTime() / 1000) == 0 ? "< 1 秒" : item.getCostTime() / 1000 + " 秒");
            } catch (Exception e) {
                log.error("获取同步任务详情失败！", e);
            }
        });
        return new ListResult<>((int) page.getTotal(), req.getPageSize(), req.getPageIndex(), page.getRecords());
    }

    @Override
    public List<KnowledgeSyncTaskExceptionRecordEntity> getSyncTaskDetail(String taskId) {
        LambdaQueryWrapper<KnowledgeSyncTaskExceptionRecordEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeSyncTaskExceptionRecordEntity::getTaskId, taskId);
        List<KnowledgeSyncTaskExceptionRecordEntity> list = knowledgeSyncTaskExceptionRecordService.list(queryWrapper);
        if (CollectionUtils.isNotEmpty(list)) {
            list.forEach(item -> item.setExceptionStage(ExcepitonStageEnum.getById(item.getExceptionStage()).name));
        }
        return list;
    }

    @Override
    public void syncLargeModelSource(List<String> syncIdList, String taskId) {
        long startTime = System.currentTimeMillis();
        String taskStatus = SyncStatusEnum.PROCESSING.id;
        try {
            // 更新任务状态为处理中
            updateSyncStatus(taskId, taskStatus, startTime);

            // 同步大模型信息
            handleKnowledgeLargeModelSource(taskId, syncIdList);

            taskStatus = SyncStatusEnum.SUCCESS.id;
        } catch (Exception e) {
            log.error("同步大模型失败！", e);
            taskStatus = SyncStatusEnum.FAILED.id;
        } finally {
            log.info("大模型同步完成!");
            updateSyncStatus(taskId, taskStatus, startTime);
        }
    }

    @Override
    public boolean checkSyncException(String taskId) {
        LambdaQueryWrapper<KnowledgeSyncTaskExceptionRecordEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(KnowledgeSyncTaskExceptionRecordEntity::getTaskId, taskId);
        return knowledgeSyncTaskExceptionRecordService.count(queryWrapper) > 0;
    }

    private void saveSyncTaskExceptionRecord(String taskId, String exceptionStage, String failReason) {
        KnowledgeSyncTaskExceptionRecordEntity entity = new KnowledgeSyncTaskExceptionRecordEntity();
        entity.setTaskId(taskId);
        entity.setExceptionStage(exceptionStage);
        entity.setFailReason(failReason);
        knowledgeSyncTaskExceptionRecordService.save(entity);
    }

    /**
     * 同步知识库
     *
     * @param knowledgeBaseParamsList 知识库列表
     */
    private void handleKnowledgeParams(String taskId, List<KnowledgeBaseParamsEntity> knowledgeBaseParamsList) {
        try {
            List<String> paramIdList = knowledgeBaseParamsList.stream()
                    .map(KnowledgeBaseParamsEntity::getParamId)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toList());

            // 检查目标库中已存在的知识库配置
            List<KnowledgeBaseParamsEntity> existingParams = knowledgeBaseParamsService.listDistanceKnowledgeBaseParams(paramIdList);

            // 备份已存在的知识库配置
            if (CollectionUtils.isNotEmpty(existingParams)) {
                String versionNo = DateUtil.now() + "_" + System.currentTimeMillis();
                List<KnowledgeBaseVersionEntity> backupList = existingParams.stream()
                        .map(param -> {
                            KnowledgeBaseVersionEntity backup = BeanUtil.copyProperties(param, KnowledgeBaseVersionEntity.class);
                            backup.setId(ParamUtil.getSerialNo());
                            backup.setVersionNo(versionNo);
                            backup.setVersionName("系统自动备份版本");
                            backup.setLatestFlag("0");
                            return backup;
                        })
                        .collect(Collectors.toList());

                if (CollectionUtils.isNotEmpty(backupList)) {
                    knowledgeBaseVersionService.saveDistanceKnowledgeBaseVersion(backupList);
                    log.info("备份了{}个已存在的知识库配置！", backupList.size());
                }
            }

            // 同步知识库
            knowledgeBaseParamsService.saveDistanceKnowledgeBaseParams(knowledgeBaseParamsList);
            log.info("同步了{}个知识库配置！", knowledgeBaseParamsList.size());

            // 同步发布知识库版本
            knowledgeBaseVersionService.publicDistanceKnowledgeBaseVersion(knowledgeBaseParamsList);
            log.info("同步发布了{}个知识库配置！", knowledgeBaseParamsList.size());

            // 同步知识库关联信息，包含溯源+黑盒+参数集
            handleKnowledgeResourceIndex(taskId, paramIdList);
            handleKnowledgeBlackParamsConfig(taskId, paramIdList);
            handleKnowledgeRelateInputParam(taskId, paramIdList);
        } catch (Exception e) {
            log.error("同步知识库配置失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.KNOWLEDGE.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 同步知识库关联溯源表信息
     *
     * @param paramIdList 知识库ID列表
     */
    private void handleKnowledgeResourceIndex(String taskId, List<String> paramIdList) {
        try {
            // 检查目标库中已存在的知识库关联溯源配置
            List<KnowledgeRelateIndexEntity> existingRelateIndexList = knowledgeRelateIndexService.listDistanceInputParams(paramIdList);
            if (CollectionUtils.isNotEmpty(existingRelateIndexList)) {
                // 备份已存在的知识库关联溯源配置
                String versionNo = DateUtil.now() + "_" + System.currentTimeMillis();
                List<KnowledgeRelateIndexVersionEntity> backupList = existingRelateIndexList.stream()
                        .map(param -> {
                            KnowledgeRelateIndexVersionEntity backup = BeanUtil.copyProperties(param, KnowledgeRelateIndexVersionEntity.class);
                            backup.setVersionNo(versionNo);
                            return backup;
                        })
                        .collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(backupList)) {
                    knowledgeRelateIndexVersionService.saveDistanceRelateIndexVersion(backupList);
                    log.info("备份了{}个已存在的知识库关联溯源配置！", backupList.size());
                }
                // 删除目标库中已存在的知识库关联溯源配置
                knowledgeRelateIndexService.removeDistanceRelateIndex(existingRelateIndexList.stream()
                        .map(KnowledgeRelateIndexEntity::getId)
                        .collect(Collectors.toList()));
                log.info("删除了{}个已存在的知识库关联溯源配置！", existingRelateIndexList.size());
            }

            List<KnowledgeRelateIndexEntity> relateIndexEntityList = knowledgeRelateIndexService.listByKnowledgeId(paramIdList);
            if (CollectionUtils.isNotEmpty(relateIndexEntityList)) {
                // 将知识库关联溯源实体列表中的ID设置为新ID
                relateIndexEntityList.forEach(index -> index.setId(null));
                knowledgeRelateIndexService.saveDistanceRelateIndex(relateIndexEntityList);
                log.info("同步了{}个知识库关联溯源配置信息！", relateIndexEntityList.size());
            }
        } catch (Exception e) {
            log.error("同步知识库关联溯源表信息失败！异常信息：{}", ExceptionUtils.getStackTrace(e));
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.KNOWLEDGE_RELATE_INDEX.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 同步知识库关联黑盒参数配置表信息
     *
     * @param paramIdList 知识库ID列表
     */
    private void handleKnowledgeBlackParamsConfig(String taskId, List<String> paramIdList) {
        try {
            // 检查目标库中已存在的知识库关联黑盒参数配置
            List<KnowledgeBlackParamsConfigEntity> existingBlackParamsConfigList = knowledgeBlackParamsConfigEntityService.listDistanceInputParams(paramIdList);
            if (CollectionUtils.isNotEmpty(existingBlackParamsConfigList)) {
                // 备份已存在的知识库关联黑盒参数配置
                String versionNo = DateUtil.now() + "_" + System.currentTimeMillis();
                List<KnowledgeBlackParamsConfigVersionEntity> backupList = existingBlackParamsConfigList.stream()
                        .map(param -> {
                            KnowledgeBlackParamsConfigVersionEntity backup = BeanUtil.copyProperties(param, KnowledgeBlackParamsConfigVersionEntity.class);
                            backup.setVersionNo(versionNo);
                            return backup;
                        })
                        .collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(backupList)) {
                    knowledgeBlackParamsConfigVersionService.saveDistanceBlackParamsConfigVersion(backupList);
                    log.info("备份了{}个已存在的知识库关联黑盒参数配置！", backupList.size());
                }
                // 删除目标库中已存在的知识库关联黑盒参数配置
                knowledgeBlackParamsConfigEntityService.removeDistanceBlackParamsConfig(existingBlackParamsConfigList.stream()
                        .map(KnowledgeBlackParamsConfigEntity::getId)
                        .collect(Collectors.toList()));
                log.info("删除了{}个已存在的知识库关联黑盒参数配置！", existingBlackParamsConfigList.size());
            }

            List<KnowledgeBlackParamsConfigEntity> blackParamsConfigEntityList = knowledgeBlackParamsConfigEntityService.listByKnowledgeId(paramIdList);
            if (CollectionUtils.isNotEmpty(blackParamsConfigEntityList)) {
                // 将知识库关联黑盒参数配置实体列表中的ID设置为NULL
                blackParamsConfigEntityList.forEach(param -> param.setId(null));
                knowledgeBlackParamsConfigEntityService.saveDistanceBlackParamsConfig(blackParamsConfigEntityList);
                log.info("同步了{}个知识库关联黑盒参数配置信息！", blackParamsConfigEntityList.size());
            }
        } catch (Exception e) {
            log.error("同步知识库关联黑盒参数配置表信息失败！异常信息：{}", ExceptionUtils.getStackTrace(e));
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.KNOWLEDGE_BLACK_PARAMS.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 同步知识库关联参数集表信息
     *
     * @param paramIdList 知识库ID列表
     */
    private void handleKnowledgeRelateInputParam(String taskId, List<String> paramIdList) {
        try {
            // 检查目标库中已存在的知识库关联参数集
            List<KnowledgeRelateInputParamEntity> existingRelateInputParamList = knowledgeRelateInputParamService.listDistanceInputParams(paramIdList);
            if (CollectionUtils.isNotEmpty(existingRelateInputParamList)) {
                // 备份已存在的知识库关联参数集
                String versionNo = DateUtil.now() + "_" + System.currentTimeMillis();
                List<KnowledgeRelateInputParamVersionEntity> backupList = existingRelateInputParamList.stream()
                        .map(param -> {
                            KnowledgeRelateInputParamVersionEntity backup = BeanUtil.copyProperties(param, KnowledgeRelateInputParamVersionEntity.class);
                            backup.setId(ParamUtil.getSerialNo());
                            backup.setVersionNo(versionNo);
                            return backup;
                        })
                        .collect(Collectors.toList());
                if (CollectionUtils.isNotEmpty(backupList)) {
                    knowledgeRelateInputParamVersionService.saveDistanceInputParamsVersion(backupList);
                    log.info("备份了{}个已存在的知识库关联参数集！", backupList.size());
                }
                // 删除目标库中已存在的知识库关联参数集
                knowledgeRelateInputParamService.removeDistanceInputParams(existingRelateInputParamList.stream()
                        .map(KnowledgeRelateInputParamEntity::getId)
                        .collect(Collectors.toList()));
                log.info("删除了{}个已存在的知识库关联参数集！", existingRelateInputParamList.size());
            }

            List<KnowledgeRelateInputParamEntity> relateInputParamList = knowledgeRelateInputParamService.listByKnowledgeId(paramIdList);
            if (CollectionUtils.isNotEmpty(relateInputParamList)) {
                // 将知识库关联参数集实体列表中的ID设置为新ID
                relateInputParamList.forEach(param -> param.setId(ParamUtil.getSerialNo()));
                knowledgeRelateInputParamService.saveDistanceInputParams(relateInputParamList);
                log.info("同步了{}个知识库关联参数集信息！", relateInputParamList.size());
            }
        } catch (Exception e) {
            log.error("同步知识库关联参数集信息失败！异常信息：{}", ExceptionUtils.getStackTrace(e));
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.KNOWLEDGE_INPUT_PARAM.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 同步知识库分组
     *
     * @param groupIdSet 分组ID集合
     */
    private void handleKnowledgeGroup(String taskId, Set<String> groupIdSet) {
        try {
            if (CollectionUtils.isEmpty(groupIdSet)) {
                log.info("未查询到相关知识库分组，无需同步！");
                return;
            }
            List<KnowledgeBaseGroupEntity> groupList = knowledgeBaseGroupMapper.getKnowledgeBaseGroupList(
                    String.join(",", groupIdSet), new ArrayList<>(groupIdSet));

            if (CollectionUtils.isNotEmpty(groupList)) {
                knowledgeBaseGroupService.saveDistanceKnowledgeBaseGroup(groupList);
                log.info("同步了{}个知识库分组！", groupList.size());
            }
        } catch (Exception e) {
            log.error("同步知识库分组失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.KNOWLEDGE_GROUP.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 同步知识库关联的指标
     *
     * @param indexParamsList 指标列表
     */
    private void handleKnowledgeRelateIndex(String taskId, List<IndexParamsEntity> indexParamsList) {
        try {
            // 检查目标库中已存在的指标
            List<String> paramNoList = indexParamsList.stream()
                    .map(IndexParamsEntity::getParamNo)
                    .filter(StringUtils::isNotEmpty)
                    .collect(Collectors.toList());

            if (CollectionUtils.isNotEmpty(paramNoList)) {
                List<IndexParamsEntity> existingIndexParams = indexParamsService.listDistanceIndexParams(paramNoList);

                // 备份已存在的指标
                if (CollectionUtils.isNotEmpty(existingIndexParams)) {
                    String paramVersion = DateUtil.now() + "_" + System.currentTimeMillis();
                    List<IndexParamsVersionEntity> backupList = existingIndexParams.stream()
                            .map(index -> {
                                IndexParamsVersionEntity backup = BeanUtil.copyProperties(index, IndexParamsVersionEntity.class);
                                backup.setId(ParamUtil.getSerialNo());
                                backup.setParamVersion(paramVersion);
                                return backup;
                            })
                            .collect(Collectors.toList());

                    if (CollectionUtils.isNotEmpty(backupList)) {
                        indexParamsVersionService.saveDistanceIndexParamsVersion(backupList);
                        log.info("备份了{}个已存在的指标！", backupList.size());
                    }
                }
            }

            // 同步指标配置
            indexParamsService.saveDistanceIndexParams(indexParamsList);
            log.info("同步了{}个指标！", indexParamsList.size());

            // 同步关联指标
            handleRelatedIndexes(taskId, indexParamsList);
        } catch (Exception e) {
            log.error("同步知识库关联指标失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.KNOWLEDGE_RELATE_INDEX.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 处理关联指标的同步
     *
     * @param indexParamsList 指标列表
     */
    private void handleRelatedIndexes(String taskId, List<IndexParamsEntity> indexParamsList) {
        Set<String> relatedIndexSet = Sets.newHashSet();

        Map<String, Set<String>> relateIndexMap = Maps.newHashMap();
        for (IndexParamsEntity indexParams : indexParamsList) {
            Set<String> curRelatedIndexSet = Sets.newHashSet();
            String intfParams = indexParams.getIntfParams();
            if (StringUtils.isEmpty(intfParams)) {
                relateIndexMap.put(indexParams.getParamNo(), curRelatedIndexSet);
                continue;
            }

            try {
                JSONArray intfParamsJson = JSONArray.parseArray(intfParams);
                for (Object item : intfParamsJson) {
                    if (item instanceof JSONObject) {
                        JSONObject itemJson = (JSONObject) item;
                        for (String key : itemJson.keySet()) {
                            JSONObject relateIndexJson = itemJson.getJSONObject(key);
                            if (relateIndexJson != null) {
                                String relateIndex = relateIndexJson.getString("relateIndex");
                                if (StringUtils.isNotEmpty(relateIndex) && !relateIndex.equals("{}")) {
                                    JSONObject jsonObject = JSONObject.parseObject(relateIndex);
                                    curRelatedIndexSet.add(jsonObject.getString("no"));
                                }
                            }
                        }
                    }
                }
                relateIndexMap.put(indexParams.getParamNo(), curRelatedIndexSet);
                relatedIndexSet.addAll(curRelatedIndexSet);
            } catch (Exception e) {
                log.error("解析指标接口参数失败，指标ID: {}, 异常信息: {}", indexParams.getParamNo(), ExceptionUtils.getStackTrace(e));
            }
        }

        // 同步指标关联信息表
        relateIndexMap.forEach((indexId, relateIndexSet) -> {
            indexRelateInfoService.removeDistanceRelateInfo(indexId);
            if (CollectionUtils.isNotEmpty(relateIndexSet)) {
                indexRelateInfoService.saveDistanceRelateInfo(indexId, new ArrayList<>(relateIndexSet));
            }
        });

        if (CollectionUtils.isNotEmpty(relatedIndexSet)) {
            String paramNoListStr = String.join(",", relatedIndexSet);
            List<IndexParamsEntity> innerIndexParamsList = indexParamsMapper.selectAllGroupIndexList(paramNoListStr, new ArrayList<>(relatedIndexSet));
            if (CollectionUtils.isNotEmpty(innerIndexParamsList)) {
                // 递归同步关联指标
                handleKnowledgeRelateIndex(taskId, innerIndexParamsList);
            }
        }
    }

    /**
     * 同步知识库关联的指标分组
     *
     * @param indexGroupIdSet 指标分组ID集合
     */
    private void handleKnowledgeRelateIndexGroup(String taskId, Set<String> indexGroupIdSet) {
        try {
            List<IndexBaseGroupEntity> indexBaseGroupList = indexBaseGroupMapper.getIndexBaseGroupList(
                    String.join(",", indexGroupIdSet), new ArrayList<>(indexGroupIdSet));

            if (CollectionUtils.isNotEmpty(indexBaseGroupList)) {
                indexBaseGroupService.saveDistanceIndexBaseGroup(indexBaseGroupList);
                log.info("同步了{}个指标分组！", indexBaseGroupList.size());
            }
        } catch (Exception e) {
            log.error("同步指标分组失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.INDEX_GROUP.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 同步知识库关联的数据源
     *
     * @param indexParamsList 指标列表
     */
    private void handleKnowledgeDataSource(String taskId, List<IndexParamsEntity> indexParamsList) {
        try {
            // 处理API接口数据源
            handleApiDataSource(indexParamsList);

            // 处理数据库数据源
            handleDatabaseDataSource(indexParamsList);
        } catch (Exception e) {
            log.error("同步数据源失败！", e);
            saveSyncTaskExceptionRecord(taskId, ExcepitonStageEnum.SOURCE.id, ExceptionUtils.getStackTrace(e));
        }
    }

    /**
     * 处理API接口数据源
     *
     * @param indexParamsList 指标列表
     */
    private void handleApiDataSource(List<IndexParamsEntity> indexParamsList) {
        // 筛选出有供应商ID和接口号的指标
        List<IndexParamsEntity> apiIndexParams = indexParamsList.stream()
                .filter(index -> index.getSupplierId() != null && StringUtils.isNotEmpty(index.getIntfNo()))
                .collect(Collectors.toList());

        if (CollectionUtils.isEmpty(apiIndexParams)) {
            return;
        }

        // 提取供应商ID
        Set<String> supplierIdSet = apiIndexParams.stream()
                .map(IndexParamsEntity::getSupplierId)
                .collect(Collectors.toSet());

        // 同步外部服务供应商
        syncExtSupplierList(supplierIdSet);

        // 提取接口号
        Set<String> intfNoSet = apiIndexParams.stream()
                .map(IndexParamsEntity::getIntfNo)
                .collect(Collectors.toSet());

        // 同步外部服务接口配置
        syncExtManageList(supplierIdSet, intfNoSet);
    }

    private void syncExtSupplierList(Set<String> supplierIdSet) {
        // 同步外部服务配置（为保障安全，只新增，不更新）
        List<ExtIntfSupplierEntity> supplierEntityList = extIntfSupplierManageService.listByIds(supplierIdSet);
        if (CollectionUtils.isNotEmpty(supplierEntityList)) {
            List<ExtIntfSupplierEntity> existingSuppliers = extIntfSupplierManageService.listDistanceSupplier(new ArrayList<>(supplierIdSet));
            if (CollectionUtils.isNotEmpty(existingSuppliers)) {
                Set<String> existingSupplierIds = existingSuppliers.stream()
                        .map(ExtIntfSupplierEntity::getSupplierId)
                        .map(String::toLowerCase)
                        .collect(Collectors.toSet());

                // 只同步不存在的供应商: 根据SupplierId去重，忽略大小写
                supplierEntityList = supplierEntityList.stream()
                        .filter(supplier -> !existingSupplierIds.contains(supplier.getSupplierId().toLowerCase()))
                        .collect(Collectors.toList());
            }

            if (CollectionUtils.isNotEmpty(supplierEntityList)) {
                extIntfSupplierManageService.saveDistanceSupplier(supplierEntityList);
                log.info("同步了{}个外部服务供应商！", supplierEntityList.size());
            }
        }

        // 同步外部服务参数配置
        List<ExtIntfParamDefineEntity> paramDefineList = extIntfParamDefineService.queryExtIntfParamDefine(new ArrayList<>(supplierIdSet));
        if (CollectionUtils.isNotEmpty(paramDefineList)) {
            extIntfParamDefineService.saveDistanceExtIntfParamDefine(paramDefineList);
            log.info("同步了{}个外部服务供应商参数！", paramDefineList.size());
        }
    }

    private void syncExtManageList(Set<String> supplierIdSet, Set<String> intfNoSet) {
        // 同步外部服务接口配置
        List<ExtIntfManageEntity> extIntfManageList = extIntfManageService.listExtIntfManage(new ArrayList<>(supplierIdSet), new ArrayList<>(intfNoSet));
        if (CollectionUtils.isNotEmpty(extIntfManageList)) {
            extIntfManageService.saveDistanceExtIntfManage(extIntfManageList);
            log.info("同步了{}个外部服务接口！", extIntfManageList.size());
        }

        // 同步外部服务接口参数配置
        List<ExtIntfParamManageEntity> paramManageList = extIntfParamManageService.listExtIntfParamManage(new ArrayList<>(supplierIdSet), new ArrayList<>(intfNoSet));
        if (CollectionUtils.isNotEmpty(paramManageList)) {
            extIntfParamManageService.saveDistanceExtIntfParamManage(paramManageList);
            log.info("同步了{}个外部服务接口参数！", paramManageList.size());
        }
    }

    /**
     * 处理数据库数据源
     *
     * @param indexParamsList 指标列表
     */
    private void handleDatabaseDataSource(List<IndexParamsEntity> indexParamsList) {
        // 筛选出有脚本的指标
        List<IndexParamsEntity> dbIndexParams = indexParamsList.stream()
                .filter(index -> index.getSupplierId() == null && StringUtils.isNotEmpty(index.getScript()))
                .collect(Collectors.toList());

        if (CollectionUtils.isEmpty(dbIndexParams)) {
            return;
        }

        Set<String> dataSourceSet = Sets.newHashSet();

        for (IndexParamsEntity index : dbIndexParams) {
            try {
                JSONObject scriptJson = JSONObject.parseObject(index.getScript());
                String dataSource = scriptJson.getString("dataSource");
                if (StringUtils.isNotEmpty(dataSource)) {
                    dataSourceSet.add(dataSource);
                }
            } catch (Exception e) {
                log.error("解析指标脚本失败，指标ID: {}, 异常信息: {}", index.getParamNo(), ExceptionUtils.getStackTrace(e));
            }
        }

        // 同步数据库数据源（为保障安全，只新增，不更新）
        if (CollectionUtils.isNotEmpty(dataSourceSet)) {
            syncDataSourceList(dataSourceSet);
        }
    }

    private void syncDataSourceList(Set<String> dataSourceSet) {
        List<SysDataSource> dataSourceList = sysDataSourceService.listByIds(new ArrayList<>(dataSourceSet));
        List<SysDataSource> existingDataSources = sysDataSourceService.listDistanceDataSource(new ArrayList<>(dataSourceSet));

        if (CollectionUtils.isNotEmpty(existingDataSources)) {
            Set<String> existingDataSourceIds = existingDataSources.stream()
                    .map(SysDataSource::getId)
                    .collect(Collectors.toSet());

            // 只同步不存在的数据源
            dataSourceList = dataSourceList.stream()
                    .filter(dataSource -> !existingDataSourceIds.contains(dataSource.getId()))
                    .collect(Collectors.toList());
        }

        if (CollectionUtils.isNotEmpty(dataSourceList)) {
            sysDataSourceService.saveDistanceDataSource(dataSourceList);
            log.info("同步了{}个数据库数据源！", dataSourceList.size());
        }
    }
}
