package com.suzhou.bank.agent.service.impl;

import com.suzhou.bank.agent.entity.KnowledgeBlackParamsConfigVersionEntity;
import com.suzhou.bank.agent.mapper.KnowledgeBlackParamsConfigVersionMapper;
import com.suzhou.bank.agent.service.IKnowledgeBlackParamsConfigVersionService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

import java.util.List;

/**
 * @Description: 知识库黑盒参数配置版本记录表
 * @Author: jeecg-boot
 * @Date:   2026-03-04
 * @Version: V1.0
 */
@Service
public class KnowledgeBlackParamsConfigVersionServiceImpl extends ServiceImpl<KnowledgeBlackParamsConfigVersionMapper, KnowledgeBlackParamsConfigVersionEntity> implements IKnowledgeBlackParamsConfigVersionService {

    @Override
    public void saveDistanceBlackParamsConfigVersion(List<KnowledgeBlackParamsConfigVersionEntity> backupList) {
        saveBatch(backupList);
    }
}
