package com.suzhou.bank.agent.service.impl;

import cn.hutool.crypto.digest.MD5;
import com.alibaba.excel.util.StringUtils;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import com.suzhou.bank.agent.entity.ModuleCodePromptCacheEntity;
import com.suzhou.bank.agent.enums.OnlineEnum;
import com.suzhou.bank.agent.mapper.ModuleCodePromptCacheMapper;
import com.suzhou.bank.agent.service.IModuleCodePromptCacheService;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * @Description: 知识库文案缓存表
 * @Author: jeecg-boot
 * @Date: 2025-08-01
 * @Version: V1.0
 */
@EnableAsync
@Slf4j
@Service
public class ModuleCodePromptCacheServiceImpl extends ServiceImpl<ModuleCodePromptCacheMapper, ModuleCodePromptCacheEntity> implements IModuleCodePromptCacheService {

    @Override
    public String getPromptCache(String moduleCode, String params) {
        String paramsMd5 = MD5.create().digestHex(ParamUtil.sortJSONObject(JSON.parseObject(params)).toJSONString().replace(" ", "").replace("\n", ""), StandardCharsets.UTF_8);
        LambdaQueryWrapper<ModuleCodePromptCacheEntity> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(ModuleCodePromptCacheEntity::getModuleCode, moduleCode);
        queryWrapper.eq(ModuleCodePromptCacheEntity::getParamsMd5, paramsMd5);
        queryWrapper.eq(ModuleCodePromptCacheEntity::getStatus, OnlineEnum.Y.name());
        List<ModuleCodePromptCacheEntity> list = list(queryWrapper);
        if (CollectionUtils.isEmpty(list)) {
            return null;
        }
        return list.get(0).getPrompt();
    }

    @Async
    @Override
    public void savePromptCache(String moduleCode, String params, Object prompt) {
        // 先查询是否已存在
        try {
            LambdaQueryWrapper<ModuleCodePromptCacheEntity> queryWrapper = new LambdaQueryWrapper<>();
            queryWrapper.eq(ModuleCodePromptCacheEntity::getModuleCode, moduleCode);
            // 参数 md5 加密
            String paramsMd5 = null;
            if (StringUtils.isNotBlank(params)) {
                paramsMd5 = MD5.create().digestHex(ParamUtil.sortJSONObject(JSON.parseObject(params)).toJSONString().replace(" ", "").replace("\n", ""), StandardCharsets.UTF_8);
            }
            queryWrapper.eq(ModuleCodePromptCacheEntity::getParamsMd5, paramsMd5);
            ModuleCodePromptCacheEntity promptCacheEntity = new ModuleCodePromptCacheEntity();
            promptCacheEntity.setModuleCode(moduleCode);
            promptCacheEntity.setModuleName(moduleCode);
            promptCacheEntity.setParams(params);
            promptCacheEntity.setParamsMd5(paramsMd5);
            promptCacheEntity.setPrompt(JSON.toJSONString(prompt));
            promptCacheEntity.setStatus(OnlineEnum.Y.name());

            // 判断是否存在，存在则更新，否则插入
            LambdaQueryWrapper<ModuleCodePromptCacheEntity> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(ModuleCodePromptCacheEntity::getModuleCode, moduleCode);
            wrapper.eq(ModuleCodePromptCacheEntity::getParamsMd5, paramsMd5);
            List<ModuleCodePromptCacheEntity> existEntityList = list(wrapper);
            if (CollectionUtils.isNotEmpty(existEntityList)) {
                LambdaUpdateWrapper<ModuleCodePromptCacheEntity> updateWrapper = new LambdaUpdateWrapper<>();
                updateWrapper.eq(ModuleCodePromptCacheEntity::getModuleCode, moduleCode);
                updateWrapper.eq(ModuleCodePromptCacheEntity::getParamsMd5, paramsMd5);
                updateWrapper.set(ModuleCodePromptCacheEntity::getPrompt, JSON.toJSONString(prompt));
                updateWrapper.set(ModuleCodePromptCacheEntity::getUpdateTime, new java.util.Date());
                update(updateWrapper);
            } else {
                save(promptCacheEntity);
            }
        } catch (Exception e) {
            log.error("保存知识库文案缓存失败,异常信息：{}", ExceptionUtils.getStackTrace(e));
        }
    }
}
