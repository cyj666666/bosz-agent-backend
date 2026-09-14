package com.suzhou.bank.agent.entity;


import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * <p>
 * 外部接口参数配置表
 * </p>
 */
@Data
@EqualsAndHashCode()
@TableName(value ="ext_intf_param_manage")
public class ExtIntfParamManageEntity {

    private static final long serialVersionUID = 1L;

    @TableId(value = "id", type = IdType.ASSIGN_ID)
    private String id;

    @TableField(value = "supplier_id")
    private String supplierId;

    @TableField(value = "intf_no")
    private String intfNo;

    @TableField("param_code")
    private String paramCode;

    @TableField("param_name")
    private String paramName;

    @TableField("param_type")
    private String paramType;

    @TableField("param_value")
    private String paramValue;

    @TableField("child_param_code")
    private String childParamCode;

    @TableField("child_param_name")
    private String childParamName;

    @TableField("child_param_type")
    private String childParamType;

    @TableField("param_is_required")
    private String paramIsRequired;

    @TableField("param_position")
    private String paramPosition;

    @TableField("param_source")
    private String paramSource;

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

    @TableField("source_type_detail")
    private String sourceTypeDetail;

    @TableField("source_param_code")
    private String sourceParamCode;

    @TableField("source_param_type")
    private String sourceParamType;

    @TableField("source_field")
    private String sourceField;

    @TableField("source_field_name")
    private String sourceFieldName;

    @TableField("source_field_dict_id")
    private String sourceFieldDictId;

}
