import java.io.*;
import java.sql.*;

/**
 * 从 MySQL 读取表注释和字段注释，导出 GaussDB COMMENT ON SQL 文件
 */
public class ExportComments {
    static final String MYSQL_URL = "jdbc:mysql://localhost:3306/suzhou_bank_report?useUnicode=true&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true&characterEncoding=utf-8";
    static final String MYSQL_USER = "root";
    static final String MYSQL_PASS = "amar@2025";

    public static void main(String[] args) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");

        String outPath = "D:/suzhou-work/大模型报告/苏州银行/code/bosz-agent-backend/sql/init_db_comments.sql";
        try (Connection mysql = DriverManager.getConnection(MYSQL_URL, MYSQL_USER, MYSQL_PASS);
             PrintWriter pw = new PrintWriter(new OutputStreamWriter(
                 new FileOutputStream(outPath), "UTF-8"))) {

            pw.println("-- =============================================");
            pw.println("-- GaussDB 表注释 & 字段注释");
            pw.println("-- 来源：MySQL suzhou_bank_report 库原始注释");
            pw.println("-- 生成时间：" + new java.util.Date());
            pw.println("-- 执行方式：通过 GaussDBInit 或 psql 连接后执行");
            pw.println("-- =============================================");
            pw.println();

            String tableSql = "SELECT TABLE_NAME, TABLE_COMMENT FROM INFORMATION_SCHEMA.TABLES "
                            + "WHERE TABLE_SCHEMA = 'suzhou_bank_report' AND TABLE_TYPE = 'BASE TABLE' "
                            + "ORDER BY TABLE_NAME";

            try (Statement s = mysql.createStatement();
                 ResultSet rs = s.executeQuery(tableSql)) {
                while (rs.next()) {
                    String tableName = rs.getString("TABLE_NAME");
                    String tableComment = rs.getString("TABLE_COMMENT");

                    pw.println("-- ====== " + tableName + (tableComment != null && !tableComment.isEmpty() ? " (" + tableComment + ")" : "") + " ======");

                    if (tableComment != null && !tableComment.isEmpty()) {
                        pw.println("COMMENT ON TABLE " + tableName + " IS '" + escape(tableComment) + "';");
                    }

                    String colSql = "SELECT COLUMN_NAME, COLUMN_COMMENT FROM INFORMATION_SCHEMA.COLUMNS "
                                  + "WHERE TABLE_SCHEMA = 'suzhou_bank_report' AND TABLE_NAME = ? "
                                  + "ORDER BY ORDINAL_POSITION";
                    try (PreparedStatement ps = mysql.prepareStatement(colSql)) {
                        ps.setString(1, tableName);
                        try (ResultSet crs = ps.executeQuery()) {
                            while (crs.next()) {
                                String colName = crs.getString("COLUMN_NAME");
                                String colComment = crs.getString("COLUMN_COMMENT");
                                if (colComment != null && !colComment.isEmpty()) {
                                    pw.println("COMMENT ON COLUMN " + tableName + "." + colName + " IS '" + escape(colComment) + "';");
                                }
                            }
                        }
                    }
                    pw.println();
                }
            }
        }

        System.out.println("注释已导出到: " + outPath);
        System.out.println("文件编码: UTF-8");
    }

    static String escape(String s) {
        return s.replace("'", "''");
    }
}
