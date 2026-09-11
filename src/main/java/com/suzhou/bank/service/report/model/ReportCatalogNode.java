package com.suzhou.bank.service.report.model;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 报告目录树节点（渲染用）
 * <p>由模板目录表 + 内容实例聚合而成，目录不单独建实例表。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Data
public class ReportCatalogNode {

    private String catalogCode;

    private String catalogName;

    /** 目录级别：1-一级 2-二级 3-三级 */
    private Integer catalogLevel;

    /** 上级目录编号（一级目录为空） */
    private String parentCode;

    private Integer sortNo;

    /** 本目录下的内容块（已按 sortNo 排序） */
    private List<ReportBlockVO> blocks = new ArrayList<>();

    /** 下级目录 */
    private List<ReportCatalogNode> children = new ArrayList<>();
}
