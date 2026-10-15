# 本地 openGauss 库 · 同事连接说明

> 提供方：曹哥本机（Docker 容器 `opengauss`，镜像 `opengauss/opengauss:5.0.0`）
> 最近实测：**2026-09-21 09:57** ｜ 容器内 → 宿主机 `192.168.100.195:5432` = **TCP_OPEN**

---

## 一、连接信息（当前）

| 项 | 值 |
|---|---|
| **主机** | **`192.168.100.195`** ← **必须同一个 WiFi / 同网段** |
| **端口** | `5432` |
| **数据库** | `bosz` |
| **Schema** | `as_agent` |
| 用户 / 密码 | ⚠️ 见曹哥本机 `bosz-agent-backend/src/main/resources/application-dev.yml`（曹哥填给你） |
| 驱动 | 🔴 **openGauss 官方 JDBC 驱动**（不是 PostgreSQL 驱动，见第四节） |

**JDBC 连接串**：
```
jdbc:opengauss://192.168.100.195:5432/bosz?currentSchema=as_agent
```

**DBeaver / Navicat 直接填**：
```
主机 192.168.100.195   端口 5432   库 bosz   schema as_agent
```

---

## 二、🔴 IP 会变 —— 先看这里（2026-09-21 已变过一次）

这台机器用的是 **DHCP 动态地址**，重启 / 换网络 / 换 WiFi 后 IP **会变**：

| 日期 | WLAN 地址 |
|---|---|
| 2026-09-20 | `192.168.0.7` |
| **2026-09-21（今天）** | **`192.168.100.195`** ← 连网段都换了 |

**⇒ 连不上时，第一步永远是先确认当前 IP，别死磕旧地址。**

**曹哥这边查（PowerShell 一行）**：
```powershell
Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | ForEach-Object { $_.InterfaceAlias + ' -> ' + $_.IPv4Address.IPAddress }
```
> 输出形如 `WLAN -> 192.168.100.195` —— **取那个 IP**。
> 原理：**有默认网关的网卡**才是真实上网网卡；虚拟网卡（VMware / WSL / OpenVPN）都没网关。

**同事这边自检**：
```powershell
ping 192.168.100.195
```
不通 ⇒ 要么不在同一网段，要么 IP 变了 ⇒ 找曹哥重新查一次。

---

## 三、为什么网络侧不用额外配置（2026-09-21 实测）

| 环节 | 现状 | 结论 |
|---|---|---|
| Docker 端口映射 | `0.0.0.0:5432 -> 5432/tcp` | ✅ 全网监听（**非**仅 127.0.0.1） |
| openGauss `listen_addresses` | `'*'` | ✅ |
| `pg_hba.conf` | `host all all 0.0.0.0/0 sha256` | ✅ 任意 IP 都允许（**需密码**） |
| Windows 防火墙 | `Docker Desktop Backend` 规则：`Inbound / Allow / **Profile=Public**` | ✅ 正好覆盖当前的"公用网络"位置 |
| 真实路径实测 | 容器内 → `192.168.100.195:5432` = **TCP_OPEN** | ✅ 防火墙未拦 |

👉 **曹哥本机不需要改任何配置，同事直接连即可**（容器重启过也不影响 —— 端口映射与防火墙规则都还在）。

> 📌 当前网络位置是 **Public（公用网络）**。若将来换成 Private，同一条 Docker 规则**依然覆盖**（它的 Profile 就配的 Public），无需调整。

---

## 四、🔴 客户端必须用 openGauss 驱动（最容易踩的坑）

本库对**远程连接**指定的是 **`sha256`** 认证（openGauss 自研实现），
**标准 PostgreSQL 驱动不支持** ⇒ DBeaver 用默认 PG 驱动会报：

```
The authentication type 10 is not supported
SCRAM 校验失败 / Invalid or unsupported by client SCRAM mechanisms
```

**驱动 jar**（找曹哥拿，或从项目里取）：
```
bosz-agent-backend/lib/opengauss-jdbc-6.0.0-og.jar
```
**驱动类**：`org.opengauss.Driver`

### DBeaver 配置步骤

1. 新建连接 → 选 **PostgreSQL**
2. 点「**编辑驱动设置**」→ 切到「**库**」页
3. **删掉**默认的 `postgresql-*.jar` → 点「添加文件」选 `opengauss-jdbc-6.0.0-og.jar`
4. 「**设置**」页 → 「驱动类」填 `org.opengauss.Driver`
5. 「URL 模板」填 `jdbc:opengauss://{host}:{port}/{database}`
6. 主面板填：主机 `192.168.100.195` / 端口 `5432` / 数据库 `bosz` / 用户 / 密码 → 「测试连接」

> 💡 同理：任何工具（IDEA Database、Navicat 等）都要指定 openGauss 驱动 + `org.opengauss.Driver`。

---

## 五、常见报错速查

| 报错 | 原因 | 处理 |
|---|---|---|
| `The authentication type 10 is not supported`<br>`... SCRAM mechanisms` | 用了标准 PostgreSQL 驱动 | 换成 `opengauss-jdbc-*.jar`（第四节） |
| `Connection refused` / 连接超时 | 不在同一 WiFi；或 **IP 变了**；或被防火墙拦 | 先 `ping 192.168.100.195`；不通就找曹哥重查 IP |
| `FATAL: no pg_hba.conf entry for host "..."` | 源 IP 不在白名单（仅"白名单模式"才会出现） | 找曹哥加白名单 |
| `FATAL: Invalid username/password` | 账号密码不对 | 找曹哥要（本机是免密信任，密码得单独问） |
| `database "xxx" does not exist` | 库名写错 | 本库是 **`bosz`**；schema 是 **`as_agent`** |

---

## 六、两个容易误判的点

**1. 「曹哥本机连库不用输密码」≠「远程也不用」**
`pg_hba.conf` 里 `127.0.0.1/32` 是 **`trust`**（免密），只有本机才免密；
远程走 `0.0.0.0/0` 那条 = **`sha256`，必须账号 + 密码**。

**2. 别选错 IP**
曹哥本机有多张网卡，只有 **WLAN 那张（当前 `192.168.100.195`）** 是真实局域网地址。
以下都是虚拟网卡，**同事连不上**：

| 网卡 | 地址 | 说明 |
|---|---|---|
| VMware VMnet8 / VMnet1 | `192.168.131.1` / `192.168.136.1` | 虚拟机网段 |
| vEthernet (WSL) | `172.26.0.1` | WSL |
| OpenVPN ×2 | `169.254.240.67` / `169.254.29.17` | VPN 虚拟口 |
| 本地连接* / 以太网 ×4 | `169.254.*` | 未获取到 IP 的网卡 |

> ✅ **判别口诀**：**有默认网关的那张才是真的**（第二节那条命令就是按这个原理写的）。

---

## 七、其他约定

- 这是**开发用库**，数据随时可能被重建/清空 —— **不要放重要数据**。
- 只读 / 写入范围按曹哥那边的约定来（避免误改他正在调试的数据）。
- 曹哥本机用的是 8080 端口跑后端服务；如果同事要连**后端接口**（不是数据库），
  那是另一套配置（需要放开 8080 并改前端的 API 地址），跟本文档无关。
