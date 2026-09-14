package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.entity.ModuleCodePromptCacheEntity;

/**
 * @Description: 知识库文案缓存表
 * @Author: jeecg-boot
 * @Date:   2025-08-01
 * @Version: V1.0
 */
public interface IModuleCodePromptCacheService extends IService<ModuleCodePromptCacheEntity> {

    String getPromptCache(String moduleCode, String paramStr);

    void savePromptCache(String moduleCode, String params, Object prompt);
}
