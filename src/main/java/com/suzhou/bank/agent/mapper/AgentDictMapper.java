package com.suzhou.bank.agent.mapper;

import com.suzhou.bank.agent.dict.DictItemRow;
import com.suzhou.bank.agent.dict.DictRow;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
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

    /**
     * 字典主表列表（供前端「关联数据字典」下拉使用）
     *
     * <p>口径对齐源工程 {@code /sys/dict/list}：<b>不过滤 {@code del_flag}</b>（源实现就是无过滤取全量），
     * 按创建时间倒序。源前端取的是 {@code result.records}，本工程 Controller 会包成同形状。</p>
     */
    @Select("select dict_code as dictCode, "
            + "       dict_name as dictName "
            + "  from sys_dict "
            + " order by create_time desc")
    List<DictRow> selectDictList();

    /**
     * 按字典编码取启用中的字典项（供前端 {@code /sys/dict/getDictItems/{code}} 使用）
     *
     * <p>与 {@link #selectAllEnabledDictItems()} 同一口径（只取 {@code status = 1}，按 {@code sort_order} 升序），
     * 只是把过滤下推到 SQL，避免为一次下拉查询把全量字典项拉进内存。</p>
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
            + "   and d.dict_code = #{dictCode} "
            + " order by i.sort_order")
    List<DictItemRow> selectEnabledItemsByDictCode(@Param("dictCode") String dictCode);
}
