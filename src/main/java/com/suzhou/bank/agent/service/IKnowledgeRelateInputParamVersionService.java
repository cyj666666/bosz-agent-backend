package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamEntity;
import com.suzhou.bank.agent.entity.KnowledgeRelateInputParamVersionEntity;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

/**
 * @Description: 知识库关联参数集版本记录表
 * @Author: jeecg-boot
 * @Date:   2026-03-04
 * @Version: V1.0
 */
public interface IKnowledgeRelateInputParamVersionService extends IService<KnowledgeRelateInputParamVersionEntity> {

    void saveDistanceInputParamsVersion(List<KnowledgeRelateInputParamVersionEntity> inputParamList);
}
