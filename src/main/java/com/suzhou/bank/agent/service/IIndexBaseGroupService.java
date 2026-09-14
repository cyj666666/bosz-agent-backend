package com.suzhou.bank.agent.service;

import com.suzhou.bank.agent.entity.IndexBaseGroupEntity;
import com.baomidou.mybatisplus.extension.service.IService;

import java.util.List;

/**
 * @Description: 指标分组表
 * @Author: jeecg-boot
 * @Date:   2024-09-13
 * @Version: V1.0
 */
public interface IIndexBaseGroupService extends IService<IndexBaseGroupEntity> {

    List<String> getAllChildGroupIdList(String groupId);

    void saveDistanceIndexBaseGroup(List<IndexBaseGroupEntity> indexBaseGroupList);
}
