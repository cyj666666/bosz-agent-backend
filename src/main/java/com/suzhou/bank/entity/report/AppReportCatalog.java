package com.suzhou.bank.entity.report;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.util.Date;

/**
 * 报告目录配置表（app_report_catalog，模板层）
 * <p>报告左侧目录树，支持一级/二级/三级目录，可配置。
 * 目录不建实例表：报告详情按内容实例的 catalogCode 聚合 + 本表属性渲染目录树。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
@TableName("app_report_catalog")
public class AppReportCatalog {

    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /** 目录编号（全局唯一） */
    @TableField("catalogCode")
    private String catalogCode;

    @TableField("catalogName")
    private String catalogName;

    /** 目录级别：1-一级 2-二级 3-三级 */
    @TableField("catalogLevel")
    private Integer catalogLevel;

    /** 上级目录编号（一级目录为 NULL） */
    @TableField("parentCode")
    private String parentCode;

    /** 排序（同一上级目录内） */
    @TableField("sortNo")
    private Integer sortNo;

    /** 是否可用：1-可用 0-停用 */
    @TableField("isEnabled")
    private Integer isEnabled;

    @TableField("inputtime")
    private Date inputtime;
}
