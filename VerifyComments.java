import java.sql.*;

public class VerifyComments {
    static final String URL = "jdbc:opengauss://127.0.0.1:5432/bosz?currentSchema=as_agent";
    static final String USER = "as_agent";
    static final String PASS = "AsAgent@2024";

    public static void main(String[] args) throws Exception {
        Class.forName("org.opengauss.Driver");
        try (Connection conn = DriverManager.getConnection(URL, USER, PASS)) {
            String sql = "SELECT c.relname AS table_name, obj_description(c.oid) AS table_comment "
                       + "FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace "
                       + "WHERE c.relkind = 'r' AND n.nspname = 'as_agent' "
                       + "ORDER BY c.relname";
            try (Statement s = conn.createStatement(); ResultSet rs = s.executeQuery(sql)) {
                while (rs.next()) {
                    System.out.printf("%-25s | %s%n", rs.getString(1), rs.getString(2));
                }
            }
        }
    }
}
