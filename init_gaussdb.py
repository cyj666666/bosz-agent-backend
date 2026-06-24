"""
GaussDB 初始化脚本 —— 使用 pg8000（纯 Python，不依赖 libpq）
"""
import pg8000.native
import sys
import os

BASE = r"D:\suzhou-work\大模型报告\苏州银行\code\bosz-agent-backend"

SQL_FILES = [
    os.path.join(BASE, "src", "main", "resources", "init_auth_gaussdb.sql"),
    os.path.join(BASE, "sql", "init_db_gaussdb.sql"),
]

CONN_PARAMS = {
    "host": "localhost",
    "port": 5432,
    "database": "bosz",
    "user": "as_agent",
    "password": "AsAgent@2024",
}

def run_sql_file(conn, fpath):
    fname = os.path.basename(fpath)
    print(f"\n>>> 执行 {fname} ...")

    with open(fpath, "r", encoding="utf-8") as f:
        full_sql = f.read()

    # 分割语句：处理 $$ 引用块
    statements = []
    current = []
    in_dollar = False
    for line in full_sql.split("\n"):
        stripped = line.strip()
        if stripped.startswith("--"):
            continue
        if "$$" in stripped:
            in_dollar = not in_dollar
        current.append(line)
        if not in_dollar and stripped.endswith(";"):
            stmt = "\n".join(current).strip()
            if stmt and not stmt.startswith("--"):
                statements.append(stmt)
            current = []
    if current:
        remaining = "\n".join(current).strip()
        if remaining and not remaining.startswith("--"):
            statements.append(remaining)

    ok = fail = skip = 0
    for stmt in statements:
        short = stmt.replace("\n", " ")[:80]
        try:
            conn.run(stmt)
            ok += 1
            print(f"    ✅ {short}...")
        except Exception as e:
            err = str(e)
            if "already exists" in err.lower():
                skip += 1
                print(f"    ⏭️ (已存在) {short}...")
            else:
                fail += 1
                print(f"    ❌ {err[:100]}")
                print(f"       SQL: {short}...")

    print(f"    结果: {ok} 成功, {skip} 跳过, {fail} 失败")
    return fail == 0

def main():
    print(">>> 连接 GaussDB (pg8000) ...")
    try:
        conn = pg8000.native.Connection(**CONN_PARAMS)
        print("    ✅ 连接成功")
    except Exception as e:
        print(f"    ❌ 连接失败: {e}")
        sys.exit(1)

    # 设置 search_path
    try:
        conn.run("SET search_path TO as_agent")
        print("    ✅ search_path = as_agent")
    except Exception as e:
        print(f"    ⚠️ 设置 search_path 失败: {e}")

    all_ok = True
    for fpath in SQL_FILES:
        if not os.path.exists(fpath):
            print(f"\n    ⚠️ 文件不存在: {fpath}")
            continue
        if not run_sql_file(conn, fpath):
            all_ok = False

    conn.close()

    # 验证
    print("\n>>> 验证表结构 ...")
    try:
        vconn = pg8000.native.Connection(**CONN_PARAMS)
        vconn.run("SET search_path TO as_agent")
        rows = vconn.run("""
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'as_agent'
            ORDER BY table_name
        """)
        tables = [row[0] for row in rows]
        print(f"    as_agent schema 下表数量: {len(tables)}")
        for t in tables:
            print(f"      - {t}")
        vconn.close()
    except Exception as e:
        print(f"    ⚠️ 验证查询失败: {e}")

    if all_ok:
        print("\n🎉 全部建表完成！")
    else:
        print("\n⚠️ 部分语句执行失败，请检查上方输出")

if __name__ == "__main__":
    main()
