package com.suzhou.bank.agent.model.vo;

import lombok.Data;

import java.io.Serializable;
import java.util.List;

/**
 * 树形下拉框节点
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.system.model.TreeSelectModel}。
 * 原类是纯 POJO（只用手写 getter/setter），这里改用 Lombok {@code @Data} 表达同样语义。</p>
 *
 * <p><b>字段名不能改</b>：它是 Jeecg 的树组件（{@code JTreeDict} / {@code JCategorySelect}）
 * 的数据契约，前端按 {@code key} / {@code title} / {@code isLeaf} / {@code parentId} / {@code children}
 * 这些名字取值。改名会直接让指标配置页的分类树渲染不出来。</p>
 *
 * <p><b>注意 {@code isLeaf} 的序列化名</b>：boolean 字段配 Lombok 生成的是 {@code isLeaf()}，
 * fastjson 据此推断出的 JSON 属性名是 <b>{@code leaf}</b>（不是 {@code isLeaf}）。
 * 原实现的手写 getter 也是 {@code isLeaf()}，所以行为一致——别为了"看起来更对"改成
 * {@code getIsLeaf()}，那会让前端拿不到值。</p>
 */
@Data
public class TreeSelectModel implements Serializable {

    private static final long serialVersionUID = 9016390975325574747L;

    /** 节点主键（对应树节点 id） */
    private String key;

    /** 显示名称 */
    private String title;

    /** 是否叶子节点（JSON 里是 leaf） */
    private boolean isLeaf;

    /** 图标 */
    private String icon;

    /** 父节点 id */
    private String parentId;

    /** 节点值 */
    private String value;

    /** 节点编码（分类字典的业务编码，如 B05） */
    private String code;

    /** 同义词 */
    private String synonymWord;

    /** 关键词 */
    private String keyWord;

    /** 关联表 */
    private String relaTable;

    /** 字段属性 */
    private String fieldAttr;

    /** 备注 */
    private String remark;

    /** 是否独立命中 */
    private String hitIndependently;

    /** 子节点 */
    private List<TreeSelectModel> children;
}
