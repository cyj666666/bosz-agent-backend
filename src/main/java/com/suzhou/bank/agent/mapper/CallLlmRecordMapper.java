package com.suzhou.bank.agent.mapper;

import com.suzhou.bank.agent.entity.CallLlmRecordEntity;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * @Description: 大模型请求记录表
 * @Author: jeecg-boot
 * @Date:   2025-11-14
 * @Version: V1.0
 */
@Mapper
public interface CallLlmRecordMapper extends BaseMapper<CallLlmRecordEntity> {

}
