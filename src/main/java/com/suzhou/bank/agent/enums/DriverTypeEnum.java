package com.suzhou.bank.agent.enums;

/**
 * 数据库驱动类型枚举
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.enums.DriverTypeEnum}，原样平移。</p>
 *
 * <p>{@code id} 为字典 {@code database_type} 的编码，
 * {@code name} 为 JDBC 驱动类，{@code dbType} 为方言标识。</p>
 */
public enum DriverTypeEnum {

    DB2("db2", "com.ibm.db2.jdbc.app.DB2Driver", "3"),
    MYSQL("mysql", "com.mysql.jdbc.Driver", "4"),
    ORACLE("oracle", "oracle.jdbc.driver.OracleDriver", "2"),
    HIVE("hive", "org.apache.hive.jdbc.HiveDriver", "6"),
    DM("dm", "dm.jdbc.driver.DmDriver", "5"),
    OPENSEARCH("opensearch", "org.opensearch.jdbc.Driver", "5"),
    PG("postgresql", "org.postgresql.Driver", "7"),
    // 常量名 OPENGauss 沿用源工程原样（不符合 Java 全大写常量的命名规范，但改名会波及
    // SysDataSourceServiceImpl 里 5 处调用点，且与源工程比对时容易出现"找不到符号"的误判）。
    // 这里的 id 是 "opengauss"（小写），才是参与字典比对的值，常量名本身不参与业务判断。
    OPENGauss("opengauss", "org.opengauss.Driver", "8");

    public final String id;
    public final String name;
    public final String dbType;

    DriverTypeEnum(String id, String name, String dbType) {
        this.id = id;
        this.name = name;
        this.dbType = dbType;
    }

    /**
     * 通过 id 找枚举对象
     */
    public static DriverTypeEnum getById(String id) {
        if (id == null) {
            return null;
        }
        for (DriverTypeEnum tt : DriverTypeEnum.values()) {
            if (tt.id.equals(id)) {
                return tt;
            }
        }
        return null;
    }
}
