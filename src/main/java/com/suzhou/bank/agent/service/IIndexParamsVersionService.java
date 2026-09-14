package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.IndexParamsVersionEntity;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

/**
 * @Description: 指标参数版本信息表
 * @Author: jeecg-boot
 * @Date:   2026-02-27
 * @Version: V1.0
 */
public interface IIndexParamsVersionService extends IService<IndexParamsVersionEntity> {


    void saveDistanceIndexParamsVersion(List<IndexParamsVersionEntity> indexParamsVersionEntityList);
}
