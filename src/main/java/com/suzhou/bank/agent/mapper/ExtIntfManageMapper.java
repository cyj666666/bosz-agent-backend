package com.suzhou.bank.agent.mapper;


import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import com.suzhou.bank.agent.entity.ExtIntfManageEntity;


@Mapper
public interface ExtIntfManageMapper extends BaseMapper<ExtIntfManageEntity> {

    Page<ExtIntfManageEntity> selectListByFilter(Page<ExtIntfManageEntity> page, @Param("supplierId") String supplierId, @Param("supplierName") String supplierName,@Param("intfNo") String intfNo, @Param("intfName") String intfName);

}
