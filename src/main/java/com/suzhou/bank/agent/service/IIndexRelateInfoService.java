package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.IndexRelateInfoEntity;

import java.util.List;

/**
 * @Description: 指标关联信息表
 * @Author: jeecg-boot
 * @Date: 2024-11-04
 * @Version: V1.0
 */
public interface IIndexRelateInfoService extends IService<IndexRelateInfoEntity> {

    List<String> getRelateIndexList(List<String> indexList);

    boolean removeRelateInfo(List<String> indexIdList, List<String> relateIndexList);

    boolean saveRelateInfo(List<String> indexIdList, List<String> relateIndexList);

    void saveDistanceRelateInfo(String indexId, List<String> relateIndexList);

    void removeDistanceRelateInfo(String indexId);

    boolean removeRelateInfoByIndexId(List<String> indexIdList);
}
