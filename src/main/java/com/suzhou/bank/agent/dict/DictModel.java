package com.suzhou.bank.agent.dict;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

import java.io.Serializable;

/**
 * 数据字典项模型
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.common.system.vo.DictModel}，
 * 字段原样保留（含 Jeecg 遗留的 {@code sortOrder} / {@code synonymWord} 等，
 * 这些字段在本模块虽未使用，但字典查询 SQL 会一并返回，保留可避免 select 列与模型不匹配）。</p>
 */
@Data
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@JsonIgnoreProperties(ignoreUnknown = true)
public class DictModel implements Serializable {

    private static final long serialVersionUID = 1L;

    public DictModel() {
    }

    public DictModel(String value, String text) {
        this.value = value;
        this.text = text;
    }

    /** 字典 value */
    private String value;

    /** 字典文本 */
    private String text;

    private Integer sortOrder;

    private String synonymWord;

    private String keyWord;

    private String relaTable;

    private String fieldAttr;

    public String getTitle() {
        return this.text;
    }
}
