package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.mapper.ExtIntfSupplierMapper;
import com.suzhou.bank.agent.model.dto.ExtIntfSupplierDTO;
import com.suzhou.bank.agent.entity.ExtIntfSupplierEntity;
import com.suzhou.bank.agent.model.req.AddExtIntfSupplierReq;
import com.suzhou.bank.agent.model.req.CheckExtIntfSupplierRepeatReq;
import com.suzhou.bank.agent.model.req.ExtIntfSupplierListReq;
import com.suzhou.bank.agent.model.req.RemoveExtIntfSupplierReq;
import com.suzhou.bank.agent.service.ExtIntfSupplierManageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;


@Service
public class ExtIntfSupplierManageServiceImpl extends ServiceImpl<ExtIntfSupplierMapper, ExtIntfSupplierEntity> implements ExtIntfSupplierManageService {

    @Autowired
    private ExtIntfSupplierMapper extIntfSupplierMapper;

    @Override
    public ListResult<?> queryExtIntfSupplierList(ExtIntfSupplierListReq reqMsg) {
        QueryWrapper<ExtIntfSupplierEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq(StringUtils.isNotBlank(reqMsg.getSupplierId()), "supplier_id", reqMsg.getSupplierId());
        queryWrapper.like(StringUtils.isNotBlank(reqMsg.getSupplierName()), "supplier_name", reqMsg.getSupplierName());
        if (StringUtils.isNotBlank(reqMsg.getSupplierType())) {
            if ("hub".equals(reqMsg.getSupplierType())) {
                // 查询hub供应商：supplier_id包含hubservice或supplier_name包含hubservice
                queryWrapper.and(wrapper -> wrapper
                    .like("supplier_id", "hubservice")
                    .or()
                    .like("supplier_name", "hubservice")
                );
            } else if ("third".equals(reqMsg.getSupplierType())) {
                // 查询非hub供应商：supplier_id不包含hubservice且supplier_name不包含hubservice
                queryWrapper.and(wrapper -> wrapper
                    .notLike("supplier_id", "hubservice")
                    .and(w -> w.notLike("supplier_name", "hubservice"))
                );
            }
        }
        queryWrapper.orderByDesc("input_time");
        Page<ExtIntfSupplierEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        Page<ExtIntfSupplierEntity> listPage = extIntfSupplierMapper.selectPage(page, queryWrapper);
        List<ExtIntfSupplierDTO> collect = listPage.getRecords().stream().map(extIntfSupplierEntity -> BeanUtil.toBean(extIntfSupplierEntity, ExtIntfSupplierDTO.class)).collect(Collectors.toList());
        return new ListResult<>(Integer.parseInt(String.valueOf(listPage.getTotal())), collect);
    }

    @Override
    public boolean checkExtIntfSupplierRepeat(CheckExtIntfSupplierRepeatReq reqMsg) {
        QueryWrapper<ExtIntfSupplierEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", reqMsg.getSupplierId());
        return count(queryWrapper) == 0;
    }

    @Override
    public ListResult<?> queryExtIntfSupplierSelectList() {
        LambdaQueryWrapper<ExtIntfSupplierEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(ExtIntfSupplierEntity::getSupplierId, ExtIntfSupplierEntity::getSupplierName);
        return new ListResult<>(list(queryWrapper));
    }

    @Override
    public boolean addExtIntfSupplier(AddExtIntfSupplierReq req) {
        ExtIntfSupplierEntity extIntfSupplierEntity = new ExtIntfSupplierEntity();
        BeanUtil.copyProperties(req, extIntfSupplierEntity);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        extIntfSupplierEntity.setInputTime(DateUtil.now());
        extIntfSupplierEntity.setInputUserId(apiContextModel.getUserId());
        extIntfSupplierEntity.setInputUserName(apiContextModel.getUserName());
        return save(extIntfSupplierEntity);
    }

    @Override
    public boolean updateExtIntfSupplier(AddExtIntfSupplierReq req) {
        ExtIntfSupplierEntity extIntfSupplierEntity = new ExtIntfSupplierEntity();
        BeanUtil.copyProperties(req, extIntfSupplierEntity);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        extIntfSupplierEntity.setUpdateTime(DateUtil.now());
        extIntfSupplierEntity.setUpdateUserId(apiContextModel.getUserId());
        extIntfSupplierEntity.setUpdateUserName(apiContextModel.getUserName());
        return updateById(extIntfSupplierEntity);
    }

    @Override
    public boolean removeExtIntfSupplier(RemoveExtIntfSupplierReq req) {
        return removeByIds(req.getSupplierIds());
    }

    @Override
    public List<ExtIntfSupplierEntity> listDistanceSupplier(List<String> supplierIdList) {
        LambdaQueryWrapper<ExtIntfSupplierEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.in(ExtIntfSupplierEntity::getSupplierId, supplierIdList);
        return list(queryWrapper);
    }

    @Override
    public void saveDistanceSupplier(List<ExtIntfSupplierEntity> supplierEntityList) {
        saveBatch(supplierEntityList);
    }
}