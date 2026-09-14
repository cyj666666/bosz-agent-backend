package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.springframework.format.annotation.DateTimeFormat;


@Data
@TableName("sys_data_source")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "SysDataSource对象", description = "多数据源管理")
public class SysDataSource {

    /**
     * id
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    /**
     * 数据源编码
     */
    @Schema(description = "数据源编码")
    private String code;
    /**
     * 数据源名称
     */
    @Schema(description = "数据源名称")
    private String name;
    /**
     * 描述
     */
    @Schema(description = "备注")
    private String remark;
    /**
     * 数据库类型
     */
    @Schema(description = "数据库类型")
    private String dbType;
    /**
     * 驱动类
     */
    @Schema(description = "驱动类")
    private String dbDriver;
    /**
     * 数据源地址
     */
    @Schema(description = "数据源地址")
    private String dbUrl;
    /**
     * 数据库名称
     */
    @Schema(description = "数据库名称")
    private String dbName;
    /**
     * 用户名
     */
    @Schema(description = "用户名")
    private String dbUsername;
    /**
     * 密码
     */
    @Schema(description = "密码")
    private String dbPassword;
    /**
     * 创建人
     */
    @Schema(description = "创建人")
    private String createBy;
    /**
     * 创建日期
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "创建日期")
    private java.util.Date createTime;
    /**
     * 更新人
     */
    @Schema(description = "更新人")
    private String updateBy;
    /**
     * 更新日期
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "更新日期")
    private java.util.Date updateTime;
    /**
     * 所属部门
     */
    @Schema(description = "所属部门")
    private String sysOrgCode;
}
