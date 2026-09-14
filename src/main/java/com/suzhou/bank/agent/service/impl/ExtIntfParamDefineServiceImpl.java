package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.collection.CollectionUtil;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import cn.hutool.core.date.DateUtil;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.mapper.ExtIntfParamDefineMapper;
import com.suzhou.bank.agent.model.dto.ExtIntfParamDefineDTO;
import com.suzhou.bank.agent.entity.ExtIntfParamDefineEntity;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.service.ExtIntfParamDefineService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class ExtIntfParamDefineServiceImpl extends ServiceImpl<ExtIntfParamDefineMapper, ExtIntfParamDefineEntity> implements ExtIntfParamDefineService {

    @Autowired
    private ExtIntfParamDefineMapper extIntfParamDefineMapper;

    @Override
    public ListResult<?> queryExtIntfParamDefine(ExtIntfParamDefineListReq reqMsg) {
        QueryWrapper<ExtIntfParamDefineEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", reqMsg.getSupplierId());
        queryWrapper.eq(StringUtils.isNotBlank(reqMsg.getParamCode()), "param_code", reqMsg.getParamCode());
        queryWrapper.orderByDesc("update_time", "input_time");
        Page<ExtIntfParamDefineEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        Page<ExtIntfParamDefineEntity> listPage = extIntfParamDefineMapper.selectPage(page, queryWrapper);
        List<ExtIntfParamDefineDTO> collect = listPage.getRecords().stream().map(extIntfParamDefineEntity -> BeanUtil.toBean(extIntfParamDefineEntity, ExtIntfParamDefineDTO.class)).collect(Collectors.toList());
        return new ListResult<>(Integer.parseInt(String.valueOf(listPage.getTotal())), collect);
    }

    @Override
    public boolean checkParamDefineRepeat(CheckExtIntfParamDefineRepeatReq reqMsg) {
        QueryWrapper<ExtIntfParamDefineEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", reqMsg.getSupplierId());
        queryWrapper.eq("param_code", reqMsg.getParamCode());
        return count(queryWrapper) == 0;
    }

    @Override
    public boolean handleExtIntfParamDefine(ExtIntfParamDefineReq req) {
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        // 有主键更新
        if (StringUtils.isNotBlank(req.getId())) {
            req.setUpdateUserId(apiContextModel.getUserId());
            req.setUpdateUserName(apiContextModel.getRealName());
            req.setUpdateTime(DateUtil.now());
            ExtIntfParamDefineEntity entity = new ExtIntfParamDefineEntity();
            entity.setParamType(req.getParamType());
            entity.setParamCode(req.getParamCode());
            entity.setParamValue(req.getParamValue());
            entity.setParamPosition(req.getParamPosition());
            entity.setParamIsRequired(req.getParamIsRequired());
            entity.setParamCode(req.getParamCode());
            entity.setUpdateUserId(req.getUpdateUserId());
            entity.setUpdateUserName(req.getUpdateUserName());
            entity.setUpdateTime(req.getUpdateTime());
            QueryWrapper<ExtIntfParamDefineEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("id", req.getId());
            return update(entity, queryWrapper);
        }
        req.setInputUserId(apiContextModel.getUserId());
        req.setInputUserName(apiContextModel.getRealName());
        req.setInputTime(DateUtil.now());
        List<ExtIntfParamDefineReq> objects = new ArrayList<>();
        objects.add(req);
        List<ExtIntfParamDefineEntity> collect = objects.stream().map(o -> BeanUtil.toBean(o, ExtIntfParamDefineEntity.class)).collect(Collectors.toList());
        return saveBatch(collect);
    }

    @Override
    public boolean removeExtIntfParamDefine(RemoveExtIntfReq req) {
        return removeByIds(req.getIds());
    }

    @Override
    public List<ExtIntfParamDefineEntity> queryExtIntfParamDefine(List<String> supplierIdList) {
        QueryWrapper<ExtIntfParamDefineEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.in("supplier_id", supplierIdList);
        return list(queryWrapper);
    }

    @Override
    public void saveDistanceExtIntfParamDefine(List<ExtIntfParamDefineEntity> defineEntityList) {
        saveOrUpdateBatch(defineEntityList);
    }
}
