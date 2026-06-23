package com.suzhou.bank.service.data.collector.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.service.data.collector.DataCollector;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 数据库同步采集器
 * <p>直连数据库执行 SQL 增量拉取数据，适用于银行内部系统的数据同步。
 * 支持 MySQL/Oracle/PostgreSQL 等，通过 JDBC URL 自动适配。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class DbSyncCollector implements DataCollector {

    @Override
    public String getType() {
        return "DB_SYNC";
    }

    @Override
    public String collect(CollectorConfig config, Long customerId) {
        JSONObject cfg = JSON.parseObject(config.getConfigJson());
        String driverClass = getDriverClass(cfg.getString("dbType"));
        String url = buildJdbcUrl(cfg);
        String username = cfg.getString("username");
        String password = cfg.getString("password");
        String sql = cfg.getString("querySql");

        try {
            Class.forName(driverClass);
            try (Connection conn = DriverManager.getConnection(url, username, password);
                 PreparedStatement ps = conn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {

                ResultSetMetaData meta = rs.getMetaData();
                int colCount = meta.getColumnCount();
                List<Map<String, Object>> rows = new ArrayList<>();

                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= colCount; i++) {
                        row.put(meta.getColumnLabel(i), rs.getObject(i));
                    }
                    rows.add(row);
                }
                String result = JSON.toJSONString(rows);
                log.info("DB_SYNC 采集完成, rowCount={}, size={}chars", rows.size(), result.length());
                return result;
            }
        } catch (Exception e) {
            log.error("DB_SYNC 采集失败", e);
            throw new RuntimeException("DB_SYNC 采集失败: " + e.getMessage(), e);
        }
    }

    private String getDriverClass(String dbType) {
        switch (dbType != null ? dbType.toLowerCase() : "mysql") {
            case "oracle": return "oracle.jdbc.OracleDriver";
            case "postgresql": return "org.postgresql.Driver";
            default: return "com.mysql.cj.jdbc.Driver";
        }
    }

    private String buildJdbcUrl(JSONObject cfg) {
        String dbType = cfg.getString("dbType");
        String host = cfg.getString("host");
        int port = cfg.getIntValue("port", 3306);
        String database = cfg.getString("database");
        boolean useSsl = cfg.getBooleanValue("useSSL", false);
        if ("oracle".equalsIgnoreCase(dbType)) {
            return "jdbc:oracle:thin:@" + host + ":" + port + ":" + database;
        }
        if ("postgresql".equalsIgnoreCase(dbType)) {
            return "jdbc:postgresql://" + host + ":" + port + "/" + database
                    + (useSsl ? "?sslmode=require" : "");
        }
        return "jdbc:mysql://" + host + ":" + port + "/" + database
                + "?useUnicode=true&useSSL=" + useSsl + "&serverTimezone=Asia/Shanghai";
    }

    @Override
    public boolean validateConfig(String configJson) {
        try {
            JSONObject cfg = JSON.parseObject(configJson);
            return cfg.containsKey("dbType") && cfg.containsKey("host")
                    && cfg.containsKey("database") && cfg.containsKey("querySql");
        } catch (Exception e) {
            return false;
        }
    }
}
