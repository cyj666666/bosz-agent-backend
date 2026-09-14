package com.suzhou.bank.agent.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import com.suzhou.bank.agent.entity.ExtIntfSupplierEntity;

import java.util.List;


@Mapper
public interface ExtIntfSupplierMapper extends BaseMapper<ExtIntfSupplierEntity> {

    @Select("select supplier_id, supplier_name from ext_intf_supplier_manage where status = '1' order by update_time desc, input_time desc")
    List<ExtIntfSupplierEntity> selectSupplierList();
}
