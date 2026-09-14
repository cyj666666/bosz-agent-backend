package com.suzhou.bank.agent.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 表字段元数据
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.system.model.dto.TableFieldDTO}，原样平移。</p>
 *
 * <p><b>注意</b>：源实现把它放在 {@code org.jeecg.modules.system.model.dto} 包下（属于系统管理域），
 * 但实际使用方是指标配置（{@code IIndexParamsService.getValueWithDataBase} 返回它）。
 * 迁入 agent 模块时归到 {@code model.dto} 统一管理，避免为它单独造一个 system 子包。</p>
 */
@Data
public class TableFieldDTO {

    @Schema(description = "字段名称")
    private String columnName;

    @Schema(description = "字段类型")
    private String columnType;

    @Schema(description = "字段描述")
    private String columnComment;

    @Schema(description = "是否为空")
    private String isNullable;

    @Schema(description = "数据类型")
    private String dataType;

    @Schema(description = "长度")
    private String length;
}
