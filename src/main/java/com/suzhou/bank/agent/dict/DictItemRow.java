package com.suzhou.bank.agent.dict;

import lombok.Data;

/**
 * 字典项查询的扁平行（字典编码 + 字典项字段）
 *
 * <p>数据库里是 {@code sys_dict} 与 {@code sys_dict_item} 两张表，
 * 这里用一张扁平行承接 join 结果，再由 {@code AgentDictProviderImpl} 在内存里按字典编码分组，
 * 免去 resultMap 嵌套映射的复杂度。</p>
 */
@Data
public class DictItemRow {

    /** 所属字典编码（{@code sys_dict.dict_code}） */
    private String dictCode;

    /** 字典值（{@code sys_dict_item.item_value}） */
    private String value;

    /** 字典文本（{@code sys_dict_item.item_text}） */
    private String text;

    private Integer sortOrder;

    private String synonymWord;

    private String keyWord;

    private String relaTable;

    private String fieldAttr;
}
