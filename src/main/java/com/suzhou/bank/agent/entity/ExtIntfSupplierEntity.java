package com.suzhou.bank.agent.entity;


import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * <p>
 * 外部服务配置表
 * </p>
 */
@Data
@EqualsAndHashCode()
@TableName(value ="ext_intf_supplier_manage")
public class ExtIntfSupplierEntity {

    private static final long serialVersionUID = 1L;

    @TableId(value = "supplier_id")
    private String supplierId;

    @TableField("supplier_name")
    private String supplierName;

    @TableField("intf_type")
    private String intfType;

    @TableField("intf_path")
    private String intfPath;

    @TableField("status")
    private String status;

    @TableField("input_user_id")
    private String inputUserId;

    @TableField("input_user_name")
    private String inputUserName;

    @TableField("input_time")
    private String inputTime;

    @TableField("update_user_id")
    private String updateUserId;

    @TableField("update_user_name")
    private String updateUserName;

    @TableField("update_time")
    private String updateTime;

}
