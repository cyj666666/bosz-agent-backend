package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import com.suzhou.bank.agent.model.common.BaseTree;

import java.io.Serializable;
import java.util.List;

@Data
@TableName("index_params")
public class IndexParamsEntity extends BaseTree<IndexParamsEntity> implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 参数流水号
     *
     * <p><b>🔴 必须显式声明 {@code IdType.ASSIGN_ID}</b>：本工程 yml 的全局
     * {@code mybatis-plus.global-config.db-config.id-type = auto}（宿主 bigint 自增表需要它），
     * 而这张表的主键是 <b>VARCHAR 且由程序生成</b>（线上数据都是 19 位雪花号，如
     * {@code 2095447359636992001}）。若沿用全局 auto，MyBatis-Plus 不会生成主键，
     * 「新增指标」会把空串当主键插进去（第一次能插、第二次主键冲突）。
     * 源工程在 Jeecg 环境下全局就是 ASSIGN_ID，所以源码里没写 type —— 迁移时必须补上。</p>
     */
    @TableId(value = "paramNo", type = IdType.ASSIGN_ID)
    private String paramNo;

    /**
     * 参数ID
     */
    @TableField("paramID")
    private String paramID;

    /**
     * 参数名称
     */
    @TableField("paramName")
    private String paramName;

    /**
     * 参数类型
     */
    @TableField("paramType")
    private String paramType;

    /**
     * 取值方式
     */
    @TableField("codeMethod")
    private String codeMethod;

    /**
     * 取值字段
     */
    @TableField("codeNo")
    private String codeNo;

    /**
     * 是否必输
     */
    @TableField("required")
    private String required;

    @TableField("readOnly")
    private String readOnly;

    /**
     * 默认格式
     */
    @TableField("defaultFormat")
    private String defaultFormat;

    /**
     * 输入形式
     */
    @TableField("inputMethod")
    private String inputMethod;

    /**
     * 参数来源編号
     */
    @TableField("fromParamNo")
    private String fromParamNo;

    /**
     * 参数默认值
     */
    @TableField("defaultValue")
    private String defaultValue;

    /**
     * 父参数ID
     */
    @TableField("parentParamNo")
    private String parentParamNo;

    /**
     * 公共参数状态
     */
    @TableField("publicParamStatus")
    private String publicParamStatus;

    /**
     * 所属模板流水号
     */
    @TableField("modelNo")
    private String modelNo;

    /**
     * 登记人
     */
    @TableField("inputUserID")
    private String inputUserID;

    /**
     * 登记日期
     */
    @TableField("inputTime")
    private String inputTime;

    /**
     * 更新日期
     */
    @TableField("updateTime")
    private String updateTime;

    /**
     * 更新用户
     */
    @TableField("updateUserID")
    private String updateUserID;

    /**
     * 登记机构
     */
    @TableField("inputOrgID")
    private String inputOrgID;

    /**
     * 更新机构
     */
    @TableField("updateOrgID")
    private String updateOrgID;

    /**
     * 初始化方法
     */
    @TableField("initMethod")
    private String initMethod;

    /**
     * 参数值获取方式
     */
    @TableField("dataMethod")
    private String dataMethod;

    /**
     * 父参数名称
     */
    @TableField("parentParamName")
    private String parentParamName;

    /**
     * 参数所属版本
     */
    @TableField("reportVersion")
    private String reportVersion;

    /**
     * 参数所属子版本
     */
    @TableField("versionNo")
    private String versionNo;

    /**
     * 参数来源(1:XML配置转化；2:前台配置)
     */
    @TableField("paramSource")
    private String paramSource;

    /**
     * 图表细类
     */
    @TableField("chartType")
    private String chartType;

    /**
     * 排序
     */
    @TableField("sortNo")
    private String sortNo;

    /**
     * 提示信息
     */
    @TableField("placeHolder")
    private String placeHolder;

    /**
     * 字段名
     */
    @TableField("actureColumn")
    private String actureColumn;

    /**
     * 字段长度
     */
    @TableField("columnLength")
    private String columnLength;

    /**
     * 数据类型
     */
    @TableField("columnType")
    private String columnType;

    /**
     * 备份
     */
    @TableField("columnRemark")
    private String columnRemark;

    /**
     * 是否为空
     */
    @TableField("columnIsNull")
    private String columnIsNull;

    /**
     * 注释
     */
    @TableField("columnComment")
    private String columnComment;

    /**
     * 来源表
     */
    @TableField("columnFromTable")
    private String columnFromTable;

    /**
     * 来源数据库
     */
    @TableField("columnFromDataSource")
    private String columnFromDataSource;

    /**
     * 脚本类型
     */
    @TableField("ScriptType")
    private String ScriptType;

    /**
     * 脚本内容
     */
    @TableField("Script")
    private String Script;

    /**
     * Api接口服务编号
     */
    @TableField("supplierId")
    private String supplierId;

    /**
     * Api接口编号
     */
    @TableField("intfno")
    private String intfNo;

    /**
     * Api接口参数（JSON字符串存储）
     */
    @TableField("intfparams")
    private String intfParams;

    /**
     * Api接口取值字段（层级结构存储）
     */
    @TableField("intffield")
    private String intfField;

    @TableField("structure")
    private String structure;

    @TableField("extendfield")
    private String extendField;

    @TableField("otherNo")
    private String otherNo;


    private String countField;

    @TableField(exist = false)
    private List<Object> fieldList;

    /**
     * 是否上线
     */
    @TableField("is_online")
    private Integer isOnline;

    /**
     * 指标介绍
     */
    @TableField("metric_intro")
    private String metricIntro;

    /**
     * 数值单位
     */
    @TableField("data_unit")
    private String dataUnit;

    /**
     * 数据样例
     */
    @TableField("data_example")
    private String dataExample;

    /**
     * 数据类型
     */
    @TableField("data_type")
    private String dataType;

    /**
     * 数据内容解析
     */
    @TableField("data_content_parse")
    private String dataContentParse;

    /**
     * 指标唯一标志
     */
    @TableField("paramKey")
    private String paramKey;


}