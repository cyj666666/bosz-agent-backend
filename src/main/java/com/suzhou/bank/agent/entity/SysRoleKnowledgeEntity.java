package com.suzhou.bank.agent.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;
import org.springframework.format.annotation.DateTimeFormat;

@Data
@TableName("sys_role_knowledge")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name = "sys_role_knowledge对象", description = "角色知识库权限表")
public class SysRoleKnowledgeEntity {

    /**
     * id
     */
    @TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "id")
    private String id;
    /**
     * 角色id
     */
    @Schema(description = "角色id")
    private String roleId;
    /**
     * 权限id
     */
    @Schema(description = "权限id")
    private String knowledgeId;
    /**
     * 数据权限ids
     */
    @Schema(description = "数据权限ids")
    private String dataRuleIds;
    /**
     * 操作时间
     */
    @JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd HH:mm:ss")
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @Schema(description = "操作时间")
    private java.util.Date operateDate;
    /**
     * 操作ip
     */
    @Schema(description = "操作ip")
    private String operateIp;
}
