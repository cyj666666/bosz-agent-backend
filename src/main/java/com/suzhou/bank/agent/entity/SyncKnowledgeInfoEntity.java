package com.suzhou.bank.agent.entity;

import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.tags.Tag;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;


import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.experimental.Accessors;

/**
 * @Description: 知识库同步信息表
 * @Author: jeecg-boot
 * @Date:   2025-03-24
 * @Version: V1.0
 */
@Data
@TableName("sync_knowledge_info")
@EqualsAndHashCode(callSuper = false)
@Accessors(chain = true)
@Tag(name="sync_knowledge_info对象", description="知识库同步信息表")
public class SyncKnowledgeInfoEntity {
    
	/**主键ID*/
	@TableId(type = IdType.ASSIGN_ID)
    @Schema(description = "主键ID")
	private Integer id;
	/**知识库编码*/
    @Schema(description = "知识库编码")
	private String knowledgeCode;
	/**同步标记*/
    @Schema(description = "同步标记 Y-同步 N-不同步")
	private String syncFlag;
}
