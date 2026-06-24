import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

/**
 * MySQL vs GaussDB 注释逐表逐字段对比
 */
public class SyncComments {
    static final String MYSQL_URL = "jdbc:mysql://localhost:3306/suzhou_bank_report?useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&characterEncoding=utf-8";
    static final String MYSQL_USER = "root";
    static final String MYSQL_PASS = "amar@2025";

    static final String GAUSS_URL = "jdbc:opengauss://127.0.0.1:5432/bosz?currentSchema=as_agent&characterEncoding=UTF-8";
    static final String GAUSS_USER = "as_agent";
    static final String GAUSS_PASS = "AsAgent@2024";

    /** MySQL 无注释时，默认补齐的注释 */
    static final Map<String, String> FALLBACK = new LinkedHashMap<>();
    static {
        FALLBACK.put("created_at", "创建时间");
        FALLBACK.put("updated_at", "更新时间");
        FALLBACK.put("completed_at", "完成时间");
        FALLBACK.put("collect_time", "采集时间");
    }

    public static void main(String[] args) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Class.forName("org.opengauss.Driver");

        try (Connection mysql = DriverManager.getConnection(MYSQL_URL, MYSQL_USER, MYSQL_PASS);
             Connection gauss = DriverManager.getConnection(GAUSS_URL, GAUSS_USER, GAUSS_PASS)) {

            try (Statement cs = gauss.createStatement()) { cs.execute("SET client_encoding = 'UTF8'"); }

            // 1. 从 MySQL 读所有注释
            Map<String, String> mysqlComments = new TreeMap<>(); // key: "table.col" or "TABLE"
            Set<String> mysqlTables = new TreeSet<>();
            String tableSql = "SELECT TABLE_NAME, TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES "
                            + "WHERE TABLE_SCHEMA = 'suzhou_bank_report' AND TABLE_TYPE = 'BASE TABLE' "
                            + "ORDER BY TABLE_NAME";
            try (Statement s = mysql.createStatement(); ResultSet rs = s.executeQuery(tableSql)) {
                while (rs.next()) {
                    String t = rs.getString("TABLE_NAME");
                    mysqlTables.add(t);
                    String c = rs.getString("TABLE_COMMENT");
                    if (c != null && !c.isEmpty()) mysqlComments.put(t + ".__TABLE__", c);
                }
            }
            for (String t : mysqlTables) {
                String colSql = "SELECT COLUMN_NAME, COLUMN_COMMENT FROM INFORMATION_SCHEMA.COLUMNS "
                              + "WHERE TABLE_SCHEMA = 'suzhou_bank_report' AND TABLE_NAME = ? ORDER BY ORDINAL_POSITION";
                try (PreparedStatement ps = mysql.prepareStatement(colSql)) {
                    ps.setString(1, t);
                    try (ResultSet crs = ps.executeQuery()) {
                        while (crs.next()) {
                            String cn = crs.getString("COLUMN_NAME");
                            String cc = crs.getString("COLUMN_COMMENT");
                            String val = (cc != null && !cc.isEmpty()) ? cc : FALLBACK.getOrDefault(cn, "");
                            mysqlComments.put(t + "." + cn, val);
                        }
                    }
                }
            }

            // 2. 从 GaussDB 读所有注释
            Map<String, String> gaussComments = new TreeMap<>();
            Set<String> gaussTables = new TreeSet<>();
            String gTableSql = "SELECT c.relname, obj_description(c.oid) AS comment "
                             + "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
                             + "WHERE c.relkind = 'r' AND n.nspname = 'as_agent' ORDER BY c.relname";
            try (Statement s = gauss.createStatement(); ResultSet rs = s.executeQuery(gTableSql)) {
                while (rs.next()) {
                    String t = rs.getString("relname");
                    gaussTables.add(t);
                    String c = rs.getString("comment");
                    if (c != null && !c.isEmpty()) gaussComments.put(t + ".__TABLE__", c);
                }
            }
            for (String t : gaussTables) {
                String colSql = "SELECT a.attname, col_description(a.attrelid, a.attnum) AS comment "
                              + "FROM pg_attribute a JOIN pg_class c ON c.oid = a.attrelid "
                              + "JOIN pg_namespace n ON n.oid = c.relnamespace "
                              + "WHERE c.relname = ? AND n.nspname = 'as_agent' AND a.attnum > 0 AND NOT a.attisdropped "
                              + "ORDER BY a.attnum";
                try (PreparedStatement ps = gauss.prepareStatement(colSql)) {
                    ps.setString(1, t);
                    try (ResultSet crs = ps.executeQuery()) {
                        while (crs.next()) {
                            String cn = crs.getString("attname");
                            String cc = crs.getString("comment");
                            if (cc != null && !cc.isEmpty()) gaussComments.put(t + "." + cn, cc);
                        }
                    }
                }
            }

            // 3. 逐表逐字段对比
            Set<String> allTables = new TreeSet<>(mysqlTables);
            allTables.addAll(gaussTables);

            int match = 0, mismatch = 0, missingGauss = 0, extraGauss = 0, missingMysql = 0;
            for (String t : allTables) {
                // 收集该表所有 key
                Set<String> allKeys = new TreeSet<>();
                for (String k : mysqlComments.keySet()) if (k.startsWith(t + ".") || k.startsWith(t + ".__")) allKeys.add(k);
                for (String k : gaussComments.keySet()) if (k.startsWith(t + ".") || k.startsWith(t + ".__")) allKeys.add(k);

                if (allKeys.isEmpty()) continue;
                System.out.println("\n=== " + t + " ===");
                for (String k : allKeys) {
                    String label = k.equals(t + ".__TABLE__") ? "[表注释]" : k.substring(t.length() + 1);
                    String mv = mysqlComments.getOrDefault(k, "");
                    String gv = gaussComments.getOrDefault(k, "");

                    if (!mv.isEmpty() && mv.equals(gv)) {
                        match++;
                        // 不打印匹配成功的，太长了
                    } else if (mv.isEmpty() && gv.isEmpty()) {
                        // 都没注释，跳过
                    } else if (gv.isEmpty() && !mv.isEmpty()) {
                        missingGauss++;
                        System.out.printf("  ❌ %-30s MySQL:[%s]  GaussDB:【缺失】%n", label, mv);
                    } else if (mv.isEmpty() && !gv.isEmpty()) {
                        mismatch++;
                        System.out.printf("  ❌ %-30s MySQL:【无注释】  GaussDB:[%s]%n", label, gv);
                    } else {
                        mismatch++;
                        System.out.printf("  ❌ %-30s MySQL:[%s]  GaussDB:[%s]%n", label, mv, gv);
                    }
                }
            }

            // 4. 汇总
            System.out.println("\n==============================");
            System.out.println("比对完成:");
            System.out.println("  ✅ 一致: " + match);
            System.out.println("  ❌ 不一致: " + mismatch);
            System.out.println("  ❌ GaussDB缺注释: " + missingGauss);
            System.out.println("  ❌ MySQL无注释: " + missingMysql);
            if (mismatch + missingGauss == 0) {
                System.out.println("\n🎉 MySQL 与 GaussDB 注释完全一致！");
            }
        }
    }
}
