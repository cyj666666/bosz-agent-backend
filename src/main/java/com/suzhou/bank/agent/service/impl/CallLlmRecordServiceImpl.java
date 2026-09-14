package com.suzhou.bank.agent.service.impl;

import com.suzhou.bank.agent.entity.CallLlmRecordEntity;
import com.suzhou.bank.agent.mapper.CallLlmRecordMapper;
import com.suzhou.bank.agent.service.ICallLlmRecordService;
import org.springframework.stereotype.Service;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;

/**
 * @Description: 大模型请求记录表
 * @Author: jeecg-boot
 * @Date:   2025-11-14
 * @Version: V1.0
 */
@Service
public class CallLlmRecordServiceImpl extends ServiceImpl<CallLlmRecordMapper, CallLlmRecordEntity> implements ICallLlmRecordService {

}
