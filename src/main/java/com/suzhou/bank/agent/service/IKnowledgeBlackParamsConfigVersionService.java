package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.KnowledgeBlackParamsConfigVersionEntity;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

/**
 * @Description: 知识库黑盒参数配置版本记录表
 * @Author: jeecg-boot
 * @Date:   2026-03-04
 * @Version: V1.0
 */
public interface IKnowledgeBlackParamsConfigVersionService extends IService<KnowledgeBlackParamsConfigVersionEntity> {

    void saveDistanceBlackParamsConfigVersion(List<KnowledgeBlackParamsConfigVersionEntity> backupList);
}
