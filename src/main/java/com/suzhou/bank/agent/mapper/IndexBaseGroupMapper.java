package com.suzhou.bank.agent.mapper;

import org.apache.ibatis.annotations.Mapper;

import org.apache.ibatis.annotations.Param;
import com.suzhou.bank.agent.entity.IndexBaseGroupEntity;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;

import java.util.List;

/**
 * @Description: 指标分组表
 * @Author: jeecg-boot
 * @Date:   2024-09-13
 * @Version: V1.0
 */
@Mapper
public interface IndexBaseGroupMapper extends BaseMapper<IndexBaseGroupEntity> {

    List<IndexBaseGroupEntity> getIndexBaseGroupList(@Param("groupIdListStr") String groupIdListStr, @Param("groupIdList") List<String> groupIdList);
}
