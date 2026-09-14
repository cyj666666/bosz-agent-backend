package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import com.suzhou.bank.agent.type.handler.HeaderTypeHandler;
import com.suzhou.bank.agent.type.handler.RequestParamTypeHandler;
import com.suzhou.bank.agent.type.handler.ResponseParamTypeHandler;

import java.io.Serializable;
import java.util.List;

/**
 * OpenAPI配置表实体类
 * 对应表：open_api_conf
 *
 * @author 自定义作者名
 * @date 2026-03-10
 */
@Data
@TableName(value = "open_api_conf", autoResultMap = true)
public class OpenApiConfEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.ASSIGN_ID) // 主键为字符串，手动输入，非自增
    private String id;

    /**
     * 关联供应商ID，参考ext_intf_supplier_manage表的supplier_id，针对将知识库作为工具使用，该字段为空
     */
    @TableField("provider_id")
    private String providerId;

    /**
     * api接口编号,针对hub接口，请直接用transCode进行编码
     */
    @TableField("api_code")
    private String apiCode;

    /**
     * api类型，枚举值：hub、knowledge、custom（针对智能体封装的python工具服务）、third(其他第三方上游接口)
     * 建议定义枚举类 ApiTypeEnum 来约束取值，避免硬编码
     */
    @TableField("api_type")
    private String apiType;

    /**
     * api接口描述
     */
    @TableField("api_desc")
    private String apiDesc;

    /**
     * api业务分类编号,同一个业务分类下，provider_id必须相同。针对custom自定义服务，此值必填
     */
    @TableField("api_category_code")
    private String apiCategoryCode;

    /**
     * 上游API路径（拼接在base_url后），主要针对other进行定义
     */
    @TableField("upstream_path")
    private String upstreamPath;

    /**
     * 请求方式：GET/POST/PUT/DELETE
     * 建议定义枚举类 HttpMethodEnum 来约束取值
     */
    @TableField("http_method")
    private String httpMethod;

    /**
     * 请求消息类型，枚举值：json/form，没配置默认json
     */
    @TableField("message_type")
    private String messageType;

    /**
     * 请求头，json array格式，格式为[{"name":"请求头的名称","value":"请求头的值"}]，每个请求头对应一个jsonarray元素的定义
     */
    @TableField(value = "header", typeHandler = HeaderTypeHandler.class)
    // private String header;
    private List<Header> headers;

    /**
     * 请求参数定义，格式统一，json array格式定义，每个元素为json对象，有属性： name、type、desc、required、defaultValue、toolParamFlag(boolean型，true表示为工具参数，false表示不是工具参数，open api生成时，不会输出该参数定义)
     */
    @TableField(value = "request_param", typeHandler = RequestParamTypeHandler.class)
    // private String requestParam;
    private List<RequestParam> requestParams;

    /**
     * 成功码，针对api_type等于other时，必填
     */
    @TableField("success_code_field")
    private String successCodeField;

    /**
     * 成功码，针对api_type等于other时，必填
     */
    @TableField("success_code_value")
    private String successCodeValue;


    /**
     * 成功响应时的业务数据根字段
     */
    @TableField("response_biz_data_field")
    private String responseBizDataField;

    /**
     * 功响应时的业务数据类型：object or array
     */
    @TableField("response_biz_data_type")
    private String responseBizDataType;

    /**
     * 响应参数字段定义，格式统一，json array格式定义，每个元素为json对象，案例[{"name":"字段名","desc":"字段描述","type":"数据类型-枚举类型：string（字符串）、number(数字)、boolean（布尔类型）、array（数组、里面的元素只能是基础类型）"}]
     */
    @TableField(value = "response_param", typeHandler = ResponseParamTypeHandler.class)
    // private String responseParam;
    private List<ResponseParam> responseParams;

    /**
     * 是否流式接口，true表示流式接口、false表示非流式接口，主要针对custom python定义的工具
     * 未定义，默认流式
     */
    @TableField(value = "stream_flag")
    private String streamFlag = "false";

    /**
     * 创建时间
     * 备注：建议数据库字段改为datetime类型，实体类用LocalDateTime接收，此处按原表结构定义为String
     */
    @TableField("create_time")
    private String createTime;

    /**
     * 创建人
     */
    @TableField("create_by")
    private String createBy;

    /**
     * 更新时间
     * 备注：建议数据库字段改为datetime类型，实体类用LocalDateTime接收，此处按原表结构定义为String
     */
    @TableField("update_time")
    private String updateTime;

    /**
     * 更新人
     */
    @TableField("update_by")
    private String updateBy;

    /**
     * 工具展示中文名
     */
    @TableField("api_name")
    private String apiName;

    /**
     * 参数json字符串
     */
    @TableField(exist = false)
    private String paramJsonStr;

    /**
     * 参数类型：header/request/response
     */
    @TableField(exist = false)
    private String paramType;

    @TableField(exist = false)
    private String isIntroduce;

    @TableField(exist = false)
    private boolean toolRelateFlag;

    /**
     * 请求参数定义（对应request_param的JSON元素结构）
     */
    @Data
    public static class RequestParam {
        /**
         * 参数名
         */
        private String name;
        /**
         * 参数类型（string/number/boolean等）
         */
        private String type;
        /**
         * 参数描述
         */
        private String description;
        /**
         * 是否必填
         */
        private Boolean required;
        /**
         * 默认值
         */
        private String defaultValue;
        /**
         * 是否为工具参数（不是工具参数，OpenAPI不输出）
         */
        private Boolean toolParamFlag = true;
        /**
         * 参数的位置，枚举值:head、query、body、path
         */
        private String location;
        /**
         * 参数枚举值
         */
        private List<String> enums;
        /**
         * 关联参数名
         */
        private String relateParamName;
    }

    /**
     * 请求头定义（对应header的JSON元素结构）
     */
    @Data
    public static class Header {
        /**
         * 请求头名称
         */
        private String name;
        /**
         * 请求头值
         */
        private String value;
    }

    /**
     * 响应业务参数定义（对应response_param的JSON元素结构）
     */
    @Data
    public static class ResponseParam {
        /**
         * 字段名
         */
        private String name;
        /**
         * 字段描述
         */
        private String desc;
        /**
         * 数据类型（string/number/boolean/array）
         */
        private String type;
    }
}
