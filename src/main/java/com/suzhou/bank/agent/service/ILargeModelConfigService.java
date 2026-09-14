package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.LargeModelConfigEntity;

import java.util.List;

/**
 * @Description: 大模型信息配置表
 * @Author: jeecg-boot
 * @Date: 2024-11-05
 * @Version: V1.0
 */
public interface ILargeModelConfigService extends IService<LargeModelConfigEntity> {

    LargeModelConfigEntity getByLargeModelCode(String largeModelCode);

    List<LargeModelConfigEntity> listByLargeModelCode(List<String> largeModelCodeList);

    List<LargeModelConfigEntity> listDistanceLargeModelCode(List<String> largeModelCodeList);

    void saveDistanceLargeModelConfig(List<LargeModelConfigEntity> modelConfigEntityList);

    void initModelConfig();
}
