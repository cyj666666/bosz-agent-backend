package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.CollectionUtils;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentBizException;
import cn.hutool.core.date.DateUtil;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.entity.ExtIntfManageEntity;
import com.suzhou.bank.agent.mapper.ExtIntfManageMapper;
import com.suzhou.bank.agent.model.dto.ExtIntfManageDTO;
import com.suzhou.bank.agent.model.req.CheckExtIntfManageRepeatReq;
import com.suzhou.bank.agent.model.req.ExtIntfManageListReq;
import com.suzhou.bank.agent.model.req.ExtIntfManageReq;
import com.suzhou.bank.agent.model.req.RemoveExtIntfReq;
import com.suzhou.bank.agent.service.ExtIntfManageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class ExtIntfManageServiceImpl extends ServiceImpl<ExtIntfManageMapper, ExtIntfManageEntity> implements ExtIntfManageService {

    @Autowired
    private ExtIntfManageMapper extIntfManageMapper;

    @Override
    public ListResult<?> queryExtIntfManageList(ExtIntfManageListReq reqMsg) {
        Page<ExtIntfManageEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
        Page<ExtIntfManageEntity> listPage = extIntfManageMapper.selectListByFilter(page, reqMsg.getSupplierId(), reqMsg.getSupplierName(), reqMsg.getIntfNo(), reqMsg.getIntfName());
        List<ExtIntfManageDTO> collect = listPage.getRecords().stream().map(extIntfManageEntity -> BeanUtil.toBean(extIntfManageEntity, ExtIntfManageDTO.class)).collect(Collectors.toList());
        return new ListResult<>(Integer.parseInt(String.valueOf(listPage.getTotal())), collect);
    }

    @Override
    public boolean checkExtIntfManageRepeat(CheckExtIntfManageRepeatReq reqMsg) {
        QueryWrapper<ExtIntfManageEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", reqMsg.getSupplierId());
        queryWrapper.eq("intf_no", reqMsg.getIntfNo());
        return count(queryWrapper) == 0;
    }

    @Override
    public boolean handleExtIntfManage(ExtIntfManageReq req) {
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        if (StringUtils.isNotBlank(req.getId())) {
            ExtIntfManageEntity extIntfManageEntity = new ExtIntfManageEntity();
            BeanUtil.copyProperties(req, extIntfManageEntity, true);
            extIntfManageEntity.setUpdateUserId(apiContextModel.getUserId());
            extIntfManageEntity.setUpdateUserName(apiContextModel.getRealName());
            extIntfManageEntity.setUpdateTime(DateUtil.now());
            QueryWrapper<ExtIntfManageEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.eq("id", req.getId());
            return update(extIntfManageEntity, queryWrapper);
        }

        ExtIntfManageEntity extIntfManageEntity = BeanUtil.toBean(req, ExtIntfManageEntity.class);
        extIntfManageEntity.setInputUserId(apiContextModel.getUserId());
        extIntfManageEntity.setInputUserName(apiContextModel.getRealName());
        extIntfManageEntity.setInputTime(DateUtil.now());
        return save(extIntfManageEntity);
    }

    @Override
    public boolean removeExtIntfManage(RemoveExtIntfReq req) {
        return removeByIds(req.getIds());
    }


    @Override
    public Map<String, String> getExtIntfInfoList(List<String> intfNoList, List<String> supplierIdList) {
        QueryWrapper<ExtIntfManageEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.in("supplier_id", supplierIdList);
        queryWrapper.in("intf_no", intfNoList);
        List<ExtIntfManageEntity> list = list(queryWrapper);
        if (CollectionUtils.isEmpty(list)) {
            return Collections.emptyMap();
        }
        return list.stream().collect(Collectors.toMap(intf -> intf.getSupplierId() + intf.getIntfNo(), ExtIntfManageEntity::getIntfName, (existing, replacement) -> existing));
    }

    @Override
    public ExtIntfManageEntity getExtIntfManage(String intfNo, String supplierId) {
        QueryWrapper<ExtIntfManageEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("supplier_id", supplierId);
        queryWrapper.eq("intf_no", intfNo);
        return getOne(queryWrapper);
    }

    @Override
    public List<ExtIntfManageEntity> listExtIntfManage(List<String> supplierIdList, List<String> intfNoList) {
        QueryWrapper<ExtIntfManageEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.in("supplier_id", supplierIdList);
        queryWrapper.in("intf_no", intfNoList);
        return list(queryWrapper);
    }

    @Override
    public void saveDistanceExtIntfManage(List<ExtIntfManageEntity> extIntfManageList) {
        saveOrUpdateBatch(extIntfManageList);
    }
}
