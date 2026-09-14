package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 指标参数版本信息表
 * @Author: jeecg-boot
 * @Date: 2026-02-27
 * @Version: V1.0
 */
@Data
@TableName("index_params_version")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "index_params_version对象", description = "指标参数版本信息表")
public class IndexParamsVersionEntity {

    /**
     * 主键ID
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键ID")
    private java.lang.String id;
    /**
     * 指标流水号
     */
    @Schema(description = "指标流水号")
    @TableField("paramno")
    private java.lang.String paramNo;
    /**
     * 指标版本
     */
    @Schema(description = "指标版本")
    @TableField("paramversion")
    private java.lang.String paramVersion;
    /**
     * 指标ID
     */
    @Schema(description = "指标ID")
    @TableField("paramid")
    private java.lang.String paramId;
    /**
     * 指标名称
     */
    @Schema(description = "指标名称")
    @TableField("paramname")
    private java.lang.String paramName;
    /**
     * 指标类型
     */
    @Schema(description = "指标类型")
    @TableField("paramtype")
    private java.lang.String paramType;
    /**
     * 取值方式
     */
    @Schema(description = "取值方式")
    @TableField("codemethod")
    private java.lang.String codeMethod;
    /**
     * 取值字段
     */
    @Schema(description = "取值字段")
    @TableField("codeno")
    private java.lang.String codeNo;
    /**
     * 是否必输
     */
    @Schema(description = "是否必输")
    @TableField("required")
    private java.lang.String required;
    /**
     * 是否只读
     */
    @Schema(description = "是否只读")
    @TableField("readonly")
    private java.lang.String readOnly;
    /**
     * 默认格式
     */
    @Schema(description = "默认格式")
    @TableField("defaultformat")
    private java.lang.String defaultFormat;
    /**
     * 输入形式
     */
    @Schema(description = "输入形式")
    @TableField("inputmethod")
    private java.lang.String inputMethod;
    /**
     * 指标来源編号
     */
    @Schema(description = "指标来源編号")
    @TableField("fromparamno")
    private java.lang.String fromParamNo;
    /**
     * 指标默认值
     */
    @Schema(description = "指标默认值")
    @TableField("defaultvalue")
    private java.lang.String defaultValue;
    /**
     * 父指标ID
     */
    @Schema(description = "父指标ID")
    @TableField("parentparamno")
    private java.lang.String parentParamNo;
    /**
     * 公共指标状态
     */
    @Schema(description = "公共指标状态")
    @TableField("publicparamstatus")
    private java.lang.String publicParamStatus;
    /**
     * 所属模板流水号
     */
    @Schema(description = "所属模板流水号")
    @TableField("modelno")
    private java.lang.String modelNo;
    /**
     * 初始化方法
     */
    @Schema(description = "初始化方法")
    @TableField("initmethod")
    private java.lang.String initMethod;
    /**
     * 指标值获取方式
     */
    @Schema(description = "指标值获取方式")
    @TableField("datamethod")
    private java.lang.String dataMethod;
    /**
     * 父指标名称
     */
    @Schema(description = "父指标名称")
    @TableField("parentparamname")
    private java.lang.String parentParamName;
    /**
     * 指标所属版本
     */
    @Schema(description = "指标所属版本")
    @TableField("reportversion")
    private java.lang.String reportVersion;
    /**
     * 指标所属子版本
     */
    @Schema(description = "指标所属子版本")
    @TableField("versionno")
    private java.lang.String versionNo;
    /**
     * 指标来源(1:XML配置转化；2:前台配置；3:数据源引入)
     */
    @Schema(description = "指标来源(1:XML配置转化；2:前台配置；3:数据源引入)")
    @TableField("paramsource")
    private java.lang.String paramSource;
    /**
     * 图表细类
     */
    @Schema(description = "图表细类")
    @TableField("charttype")
    private java.lang.String chartType;
    /**
     * 排序
     */
    @Schema(description = "排序")
    @TableField("sortno")
    private java.lang.String sortNo;
    /**
     * 提示信息
     */
    @Schema(description = "提示信息")
    @TableField("placeholder")
    private java.lang.String placeholder;
    /**
     * 字段名
     */
    @Schema(description = "字段名")
    @TableField("acturecolumn")
    private java.lang.String actureColumn;
    /**
     * 字段长度
     */
    @Schema(description = "字段长度")
    @TableField("columnlength")
    private java.lang.String columnLength;
    /**
     * 数据类型
     */
    @Schema(description = "数据类型")
    @TableField("columntype")
    private java.lang.String columnType;
    /**
     * 备注
     */
    @Schema(description = "备注")
    @TableField("columnremark")
    private java.lang.String columnRemark;
    /**
     * 是否为空
     */
    @Schema(description = "是否为空")
    @TableField("columnisnull")
    private java.lang.String columnIsNull;
    /**
     * 注释
     */
    @Schema(description = "注释")
    @TableField("columncomment")
    private java.lang.String columnComment;
    /**
     * 来源表
     */
    @Schema(description = "来源表")
    @TableField("columnfromtable")
    private java.lang.String columnFromTable;
    /**
     * 来源数据库
     */
    @Schema(description = "来源数据库")
    @TableField("columnfromdatasource")
    private java.lang.String columnFromDataSource;
    /**
     * 其他配置
     */
    @Schema(description = "其他配置")
    @TableField("otherconfig")
    private java.lang.String otherConfig;
    /**
     * 脚本类型 Sql/Java/Api
     */
    @Schema(description = "脚本类型 Sql/Java/Api")
    @TableField("scripttype")
    private java.lang.String scriptType;
    /**
     * 脚本内容
     */
    @Schema(description = "脚本内容")
    @TableField("script")
    private java.lang.Object script;
    /**
     * 校验规则
     */
    @Schema(description = "校验规则")
    @TableField("validators")
    private java.lang.String validators;
    /**
     * DiyECharts图表初始化方法
     */
    @Schema(description = "DiyECharts图表初始化方法")
    @TableField("chartinitmethod")
    private java.lang.String chartInitMethod;
    /**
     * 登记人
     */
    @Schema(description = "登记人")
    @TableField("inputuserid")
    private java.lang.String inputUserId;
    /**
     * 登记机构
     */
    @Schema(description = "登记机构")
    @TableField("inputorgid")
    private java.lang.String inputOrgId;
    /**
     * 登记日期
     */
    @Schema(description = "登记日期")
    @TableField("inputtime")
    private java.lang.String inputTime;
    /**
     * 更新用户
     */
    @Schema(description = "更新用户")
    @TableField("updateuserid")
    private java.lang.String updateUserId;
    /**
     * 更新机构
     */
    @Schema(description = "更新机构")
    @TableField("updateorgid")
    private java.lang.String updateOrgId;
    /**
     * 更新日期
     */
    @Schema(description = "更新日期")
    @TableField("updatetime")
    private java.lang.String updateTime;
    /**
     * Api接口服务编号
     */
    @Schema(description = "Api接口服务编号")
    @TableField("supplierid")
    private java.lang.String supplierId;
    /**
     * Api接口编号
     */
    @Schema(description = "Api接口编号")
    @TableField("intfno")
    private java.lang.String intfNo;
    /**
     * Api接口参数（JSON字符串存储）
     */
    @Schema(description = "Api接口参数（JSON字符串存储）")
    @TableField("intfparams")
    private java.lang.String intfParams;
    /**
     * Api接口取值字段（层级结构存储）
     */
    @Schema(description = "Api接口取值字段（层级结构存储）")
    @TableField("intffield")
    private java.lang.Object intfField;
    /**
     * Api接口取值字段类型
     */
    @Schema(description = "Api接口取值字段类型")
    @TableField("intffieldtype")
    private java.lang.String intfFieldType;
    /**
     * 接口结构
     */
    @Schema(description = "接口结构")
    @TableField("structure")
    private java.lang.Object structure;
    /**
     * 拓展字段
     */
    @Schema(description = "拓展字段")
    @TableField("extendfield")
    private java.lang.Object extendField;
    /**
     * api层级编号
     */
    @Schema(description = "api层级编号")
    @TableField("otherno")
    private java.lang.String otherNo;
    /**
     * 统计字段
     */
    @Schema(description = "统计字段")
    @TableField("count_field")
    private java.lang.String countField;
}
