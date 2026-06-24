import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.sql.*;
import java.util.*;

/**
 * GaussDB 初始化工具 —— 通过 PostgreSQL JDBC 驱动执行建表
 */
public class GaussDBInit {
    static final String URL = "jdbc:opengauss://127.0.0.1:5432/bosz?currentSchema=as_agent&characterEncoding=UTF-8";
    static final String USER = "as_agent";
    static final String PASS = "AsAgent@2024";
    static final String BASE = "D:/suzhou-work/大模型报告/苏州银行/code/bosz-agent-backend";

    static final String[] SQL_FILES = {
        "sql/init_db_comments.sql",
    };

    public static void main(String[] args) throws Exception {
        Class.forName("org.opengauss.Driver");

        System.out.println(">>> 连接 GaussDB (JDBC) ...");
        try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {
            System.out.println("    ✅ 连接成功");
            conn.setAutoCommit(false);

            // 确保 UTF-8 编码，防止中文注释乱码
            try (Statement cs = conn.createStatement()) {
                cs.execute("SET client_encoding = 'UTF8'");
                System.out.println("    ✅ client_encoding = UTF8");
            }

            for (String relPath : SQL_FILES) {
                String fpath = BASE + "/" + relPath;
                File f = new File(fpath);
                System.out.println("\n>>> 执行 " + f.getName() + " ...");
                if (!f.exists()) {
                    System.out.println("    ⚠️ 文件不存在: " + fpath);
                    continue;
                }
                String sql = new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8);
                executeScript(conn, sql);
            }

            conn.commit();
            System.out.println("\n🎉 全部建表完成！");

            // 验证
            verify(conn);
        }
    }

    static void executeScript(Connection conn, String sql) {
        // 分割语句：处理 $$ 引用块
        List<String> statements = new ArrayList<>();
        StringBuilder current = new StringBuilder();
        boolean inDollar = false;
        for (String line : sql.split("\n")) {
            String trimmed = line.trim();
            if (trimmed.startsWith("--")) continue;
            if (trimmed.contains("$$")) inDollar = !inDollar;
            current.append(line).append("\n");
            if (!inDollar && trimmed.endsWith(";")) {
                String stmt = current.toString().trim();
                if (!stmt.isEmpty() && !stmt.startsWith("--"))
                    statements.add(stmt);
                current.setLength(0);
            }
        }
        String remainder = current.toString().trim();
        if (!remainder.isEmpty() && !remainder.startsWith("--"))
            statements.add(remainder);

        int ok = 0, skip = 0, fail = 0;
        for (String stmt : statements) {
            String shortSql = stmt.replace("\n", " ").trim();
            if (shortSql.length() > 80) shortSql = shortSql.substring(0, 77) + "...";
            try (Statement s = conn.createStatement()) {
                s.execute(stmt);
                ok++;
                System.out.println("    ✅ " + shortSql);
            } catch (SQLException e) {
                String msg = e.getMessage();
                if (msg != null && msg.toLowerCase().contains("already exists")) {
                    skip++;
                    System.out.println("    ⏭️ (已存在) " + shortSql);
                } else {
                    fail++;
                    System.out.println("    ❌ " + (msg != null ? msg.substring(0, Math.min(100, msg.length())) : "unknown"));
                    System.out.println("       SQL: " + shortSql);
                }
                try { conn.rollback(); } catch (Exception ignored) {}
            }
        }
        System.out.println("    结果: " + ok + " 成功, " + skip + " 跳过, " + fail + " 失败");
    }

    static void verify(Connection conn) throws Exception {
        System.out.println("\n>>> 验证表结构 ...");
        String query = "SELECT table_name FROM information_schema.tables " +
                       "WHERE table_schema = 'as_agent' ORDER BY table_name";
        try (Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery(query)) {
            int count = 0;
            while (rs.next()) {
                System.out.println("      - " + rs.getString(1));
                count++;
            }
            System.out.println("    as_agent schema 下表数量: " + count);
        }
    }
}
