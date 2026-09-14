package com.suzhou.bank.agent.entity;


import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * <p>
 * 外部接口公共参数定义表
 * </p>
 */
@Data
@EqualsAndHashCode()
@TableName(value ="ext_intf_param_define")
public class ExtIntfParamDefineEntity {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private String id;

    @TableField(value = "supplier_id")
    private String supplierId;

    @TableField("param_code")
    private String paramCode;

    @TableField("param_type")
    private String paramType;

    @TableField("param_value")
    private String paramValue;

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

    @TableField("param_position")
    private String paramPosition;

    @TableField("param_is_required")
    private String paramIsRequired;

    @TableField(exist = false)
    private String apiUrl;

}
