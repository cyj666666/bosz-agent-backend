package com.suzhou.bank.agent.dict;

import lombok.Data;

import java.io.Serializable;

/**
 * 字典主表行模型（{@code sys_dict} 的 {dictCode, dictName} 投影）
 *
 * <p>存在的理由：{@link DictModel} 表达的是「字典项」，而前端「关联数据字典」下拉需要的是
 * 「字典本身」的列表（源工程调 {@code /sys/dict/list} 取 {@code result.records}，每项含
 * {@code dictCode} 与 {@code dictName}）。两者字段语义不同，共用一个模型会造成误用，
 * 故单独建一个最小投影类。</p>
 */
@Data
public class DictRow implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 字典编码（{@code sys_dict.dict_code}） */
    private String dictCode;

    /** 字典名称（{@code sys_dict.dict_name}） */
    private String dictName;
}
