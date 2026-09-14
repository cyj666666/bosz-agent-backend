package com.suzhou.bank.agent.mapper;

import com.suzhou.bank.agent.dict.DictItemRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 数据字典查询 Mapper（只读）
 *
 * <p>agent 模块自带，用于填充 {@code AgentDictCache}。不引入 JeecgBoot 的字典 Service 体系。</p>
 *
 * <p><b>查询口径对齐源工程</b>（{@code SysDictServiceImpl.queryAllDictItems}）：
 * 字典主表取全量（不加 {@code del_flag} 过滤），字典项<b>只取 {@code status = 1} 的启用项</b>，
 * 按 {@code sort_order} 升序。这一点很关键——
 * 源实现就是"无过滤取字典 + 只取启用项"，改成别的口径会导致下拉项/取值分支与源系统不一致。</p>
 *
 * <p>列名显式起驼峰别名，不依赖 {@code map-underscore-to-camel-case} 配置，
 * 避免宿主调整 MyBatis 配置时这里被牵连。</p>
 */
@Mapper
public interface AgentDictMapper {

    /**
     * 取全部启用中的字典项（含所属字典编码）
     */
    @Select("select d.dict_code        as dictCode, "
            + "       i.item_value      as value, "
            + "       i.item_text       as text, "
            + "       i.sort_order      as sortOrder, "
            + "       i.synonym_word    as synonymWord, "
            + "       i.key_word        as keyWord, "
            + "       i.rela_table      as relaTable, "
            + "       i.field_attr      as fieldAttr "
            + "  from sys_dict d "
            + " inner join sys_dict_item i on i.dict_id = d.id "
            + " where i.status = 1 "
            + " order by d.dict_code, i.sort_order")
    List<DictItemRow> selectAllEnabledDictItems();
}
