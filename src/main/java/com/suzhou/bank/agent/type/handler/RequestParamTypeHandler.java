package com.suzhou.bank.agent.type.handler;

import cn.hutool.core.collection.CollectionUtil;
import com.alibaba.fastjson.JSON;
import com.baomidou.mybatisplus.extension.handlers.AbstractJsonTypeHandler;
import com.fasterxml.jackson.core.type.TypeReference;
import org.apache.commons.lang3.StringUtils;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;
import com.suzhou.bank.agent.entity.OpenApiConfEntity;

import java.util.Collections;
import java.util.List;

/**
 * RequestParam专用TypeHandler
 */
@MappedTypes({List.class}) // 映射Java类型
@MappedJdbcTypes({JdbcType.VARCHAR}) // 映射JDBC类型
public class RequestParamTypeHandler extends AbstractJsonTypeHandler<List<OpenApiConfEntity.RequestParam>> {

    /**
     * 【兼容构造】MyBatis-Plus自动调用的Class参数构造
     */
    /**
     * 迁移改造点：源工程的 MyBatis-Plus 版本里 AbstractJsonTypeHandler 有 (Class<?>) 构造器，
     * 而本工程 3.5.5 只有无参构造器（javap 确认），故改为 super()。
     * MyBatis 仍会正常调用 setNonNullParameter / getNullableResult，行为不变。
     */
    public RequestParamTypeHandler(Class<?> type) {
        super();
    }

    @Override
    public List<OpenApiConfEntity.RequestParam> parse(String json) {
        if (StringUtils.isBlank(json) ||  "[]".equals(json)) {
            return Collections.emptyList();
        }

        return JSON.parseArray(json, OpenApiConfEntity.RequestParam.class);
    }

    @Override
    public String toJson(List<OpenApiConfEntity.RequestParam> obj) {
        if (CollectionUtil.isEmpty(obj)) {
            return "";
        }

        return JSON.toJSONString(obj);
    }
}
