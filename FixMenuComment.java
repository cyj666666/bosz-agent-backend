import java.sql.*;

public class FixMenuComment {
    public static void main(String[] args) throws Exception {
        Class.forName("org.opengauss.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:opengauss://127.0.0.1:5432/bosz?currentSchema=as_agent&characterEncoding=UTF-8",
                "as_agent", "AsAgent@2024")) {
            try (Statement s = conn.createStatement()) {
                s.execute("SET client_encoding = 'UTF8'");
                s.execute("COMMENT ON COLUMN sys_role.menu_permissions IS '菜单权限 JSON数组'");
                System.out.println("✅ sys_role.menu_permissions 注释已修正为: 菜单权限 JSON数组");
            }
        }
    }
}
