package com.suzhou.bank.agent.model.common;

import com.baomidou.mybatisplus.annotation.TableField;
import lombok.Data;
import com.suzhou.bank.agent.entity.IndexParamsEntity;

import java.util.List;

@Data
public abstract class BaseTree<T> {

    @TableField(exist = false)
    protected List<T> children; // 子参数

    @TableField(exist = false)
    protected IndexParamsEntity parent; // 父参数

    @TableField(exist = false)
    protected List<IndexParamsEntity> paramsList; // 子参数
}
