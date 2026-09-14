package com.suzhou.bank.agent.db;

import lombok.Data;
import lombok.ToString;
import org.springframework.beans.BeanUtils;

/**
 * 动态数据源配置模型（对应表 {@code sys_data_source}）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.common.system.vo.DynamicDataSourceModel}，
 * 字段与行为保持不变，仅迁入 agent 包。</p>
 *
 * <p><b>{@code @ToString} 排除密码</b>：防止日志/异常信息里打印出外部库明文口令。</p>
 */
@Data
@ToString(exclude = "dbPassword")
public class DynamicDataSourceModel {

    public DynamicDataSourceModel() {
    }

    /**
     * 由实体对象拷贝构造（源工程用法：{@code new DynamicDataSourceModel(entity)}）
     */
    public DynamicDataSourceModel(Object dbSource) {
        if (dbSource != null) {
            BeanUtils.copyProperties(dbSource, this);
        }
    }

    /** 主键 */
    private String id;

    /** 数据源编码，动态连接池以此作为缓存 key */
    private String code;

    /** 数据库类型（mysql/oracle/postgresql/dm/hive/opengauss/db2/opensearch） */
    private String dbType;

    /** 驱动类全限定名 */
    private String dbDriver;

    /** JDBC 连接串 */
    private String dbUrl;

    /** 数据库名称 */
    private String dbName;

    /** 用户名 */
    private String dbUsername;

    /** 密码 */
    private String dbPassword;
}
