package com.suzhou.bank.agent.entity;


import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * <p>
 * 外部接口详细配置表
 * </p>
 */
@Data
@EqualsAndHashCode()
@TableName(value ="ext_intf_manage")
public class ExtIntfManageEntity {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private String id;

    @TableField("supplier_id")
    private String supplierId;

    @TableField(exist = false)
    private String supplierName;

    @TableField("intf_no")
    private String intfNo;

    @TableField("intf_name")
    private String intfName;

    @TableField("intf_path")
    private String intfPath;

    @TableField("intf_type_name")
    private String intfTypeName;

    @TableField("intf_request_type")
    private String intfRequestType;

    @TableField("intf_time_out")
    private Integer intfTimeOut;

    @TableField("intf_status")
    private String intfStatus;

    @TableField("intf_desc")
    private String intfDesc;

    @TableField("intf_structure")
    private String intfStructure;

    @TableField("refer_intf_no")
    private String referIntfNo;

    @TableField("refer_intf_status")
    private String referIntfStatus;

    @TableField("async_save")
    private String asyncSave;

    @TableField("battle_flag")
    private String battleFlag;

    @TableField("battle_report_content")
    private String battleReportContent;

    @TableField("before_handler")
    private String beforeHandler;

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
