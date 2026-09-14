package com.suzhou.bank.agent.service.impl;

import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamVersionEntity;
import com.suzhou.bank.agent.mapper.KnowledgeRelateInputParamVersionMapper;
import com.suzhou.bank.agent.service.IKnowledgeRelateInputParamVersionService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

import java.util.List;

/**
 * @Description: 知识库关联参数集版本记录表
 * @Author: jeecg-boot
 * @Date:   2026-03-04
 * @Version: V1.0
 */
@Service
public class KnowledgeRelateInputParamVersionServiceImpl extends ServiceImpl<KnowledgeRelateInputParamVersionMapper, KnowledgeRelateInputParamVersionEntity> implements IKnowledgeRelateInputParamVersionService {

    @Override
    public void saveDistanceInputParamsVersion(List<KnowledgeRelateInputParamVersionEntity> inputParamList) {
        saveBatch(inputParamList);
    }
}
