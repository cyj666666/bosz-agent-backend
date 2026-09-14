package com.suzhou.bank.agent.service.impl;

import com.suzhou.bank.agent.entity.KnowledgeRelateIndexVersionEntity;
import com.suzhou.bank.agent.mapper.KnowledgeRelateIndexVersionMapper;
import com.suzhou.bank.agent.service.IKnowledgeRelateIndexVersionService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

import java.util.List;

/**
 * @Description: 知识库关联指标版本记录表
 * @Author: jeecg-boot
 * @Date:   2026-03-04
 * @Version: V1.0
 */
@Service
public class KnowledgeRelateIndexVersionServiceImpl extends ServiceImpl<KnowledgeRelateIndexVersionMapper, KnowledgeRelateIndexVersionEntity> implements IKnowledgeRelateIndexVersionService {

    @Override
    public void saveDistanceRelateIndexVersion(List<KnowledgeRelateIndexVersionEntity> backupList) {
        saveBatch(backupList);
    }
}
