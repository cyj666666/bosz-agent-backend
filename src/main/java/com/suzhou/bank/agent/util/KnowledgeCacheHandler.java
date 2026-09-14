package com.suzhou.bank.agent.util;

import cn.hutool.crypto.digest.MD5;
import com.alibaba.excel.EasyExcel;
import com.alibaba.excel.support.ExcelTypeEnum;
import com.alibaba.excel.util.StringUtils;
import com.alibaba.fastjson.JSON;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import com.suzhou.bank.agent.entity.ModuleCodePromptCacheEntity;
import com.suzhou.bank.agent.model.dto.ModuleCodePromptCacheDto;
import com.suzhou.bank.agent.enums.OnlineEnum;
import com.suzhou.bank.agent.service.IModuleCodePromptCacheService;
import com.suzhou.bank.agent.mapper.SysCategoryMapper;
import com.suzhou.bank.agent.service.ISysCategoryService;
import com.suzhou.bank.agent.util.ParamUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.DigestUtils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

@Component
@Slf4j
public class KnowledgeCacheHandler {

    @Autowired
    private SysCategoryMapper sysCategoryMapper;

    @Autowired
    private ISysCategoryService sysCategoryService;

    @Autowired
    private IModuleCodePromptCacheService moduleCodePromptCacheService;

    public void excelDataExecutor(InputStream inputStream, String fileName) {
        List<ModuleCodePromptCacheDto> objectList;
        try {
            objectList = EasyExcel.read(inputStream, ModuleCodePromptCacheDto.class, null).excelType(ExcelTypeEnum.XLSX).sheet().doReadSync();
        } catch (Exception e) {
            log.error("处理文件 {} 失败", fileName, e);
            return;
        }
        if (CollectionUtils.isEmpty(objectList)) {
            return;
        }
        log.info("解析到 {} 条数据,开始进行解析....", objectList.size());
        List<ModuleCodePromptCacheEntity> promptCacheEntityList = objectList.stream().map(item -> {
            ModuleCodePromptCacheEntity promptCacheEntity = new ModuleCodePromptCacheEntity();
            promptCacheEntity.setModuleCode(item.getModuleCode());
            promptCacheEntity.setModuleName(item.getModuleName());
            // 参数 md5 加密
            String params = item.getParams();
            if (StringUtils.isNotBlank(params)) {
                promptCacheEntity.setParams(params);
                // 替换空格和换行
                promptCacheEntity.setParamsMd5(MD5.create().digestHex(ParamUtil.sortJSONObject(JSON.parseObject(params)).toJSONString().replace(" ", "").replace("\n", ""), StandardCharsets.UTF_8));
            }
            promptCacheEntity.setPrompt(item.getPrompt());
            promptCacheEntity.setStatus(OnlineEnum.Y.name());
            return promptCacheEntity;
        }).collect(Collectors.toList());
        // 过滤掉参数为空的
        promptCacheEntityList = promptCacheEntityList.stream().filter(item -> StringUtils.isNotBlank(item.getParamsMd5())).collect(Collectors.toList());
        // 根据参数 params 和 moduleCode，如果有重复数据，过滤掉
        List<ModuleCodePromptCacheEntity> existList = moduleCodePromptCacheService.list(new LambdaQueryWrapper<ModuleCodePromptCacheEntity>().eq(ModuleCodePromptCacheEntity::getStatus, OnlineEnum.Y.name()).isNotNull(ModuleCodePromptCacheEntity::getParamsMd5));
        if (CollectionUtils.isNotEmpty(existList)) {
            promptCacheEntityList = promptCacheEntityList.stream().filter(item -> existList.stream().noneMatch(existItem -> existItem.getParamsMd5().equals(item.getParamsMd5()) && existItem.getModuleCode().equals(item.getModuleCode()))).collect(Collectors.toList());
        }
        if (CollectionUtils.isNotEmpty(promptCacheEntityList)) {
            // 迁移改造点：源实现用的是 saveOrUpdateBatch，本工程改为 saveBatch。
            // 原因：module_code_prompt_cache 的主键是【复合主键】(module_code, params_md5)，
            // MyBatis-Plus 的 @TableId 只能表达单主键，因此 ModuleCodePromptCacheEntity
            // 无法标注主键（启动期会打 WARN "Not found @TableId annotation"）。
            // 而 saveOrUpdateBatch 的内部实现是一句
            //     Assert.notEmpty(tableInfo.getKeyProperty(), "...can not find column for id from entity!")
            // —— 无主键时【直接抛异常】，会让「知识库缓存解析入库」整条链路失败。
            // 语义上这里本就该是纯插入：上面第 70-73 行已按 (module_code, params_md5)
            // 过滤掉已存在的记录，剩下的全是新增，故 saveBatch 与原意图完全一致。
            moduleCodePromptCacheService.saveBatch(promptCacheEntityList);
        }
        log.info("解析完成，共处理 {} 条数据，成功 {} 条，失败 {} 条....", objectList.size(), promptCacheEntityList.size(), objectList.size() - promptCacheEntityList.size());
    }
}
