# Komga PostgreSQL 运行指南

本指南介绍如何使用 PostgreSQL 作为数据库后端运行 Komga。

## 前置要求

- Java 17 或更高版本
- PostgreSQL 14 或更高版本
- PostgreSQL `unaccent` 扩展（通常随 PostgreSQL 一起安装）

## 方式一：Docker Compose（推荐）

### 1. 准备环境变量

```bash
cd komga/docker
cp .env.example .env
```

编辑 `.env` 文件，修改密码和媒体库路径：

```ini
POSTGRES_PASSWORD=your_secure_password_here
# LIBRARY_PATH=/path/to/your/media/library
```

### 2. 启动服务

```bash
cd komga/docker
docker compose -f docker-compose.postgresql.yml up -d
```

### 3. 访问 Komga

打开浏览器访问 `http://localhost:25600`，首次启动会引导你创建管理员账户。

### 4. 查看日志

```bash
docker compose -f komga/docker/docker-compose.postgresql.yml logs -f komga
```

### 5. 停止服务

```bash
docker compose -f komga/docker/docker-compose.postgresql.yml down
```

数据保存在 Docker volume `postgres_data` 中，不会丢失。

---

## 方式二：手动安装

### 1. 安装并启动 PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS (Homebrew):**
```bash
brew install postgresql@16
brew services start postgresql@16
```

**Windows:**
从 [PostgreSQL 官网](https://www.postgresql.org/download/windows/) 下载安装程序。

### 2. 创建数据库和用户

```bash
# 切换到 postgres 用户
sudo -u postgres psql

# 在 psql 中执行：
CREATE USER komga WITH PASSWORD 'your_password';
CREATE DATABASE komga OWNER komga;
\q
```

### 3. 安装 unaccent 扩展

```bash
sudo -u postgres psql -d komga -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
```

> 如果提示权限不足，需要超级用户授权：
> ```sql
> GRANT CREATE ON DATABASE komga TO komga;
> ```

### 4. 下载 Komga

从 [GitHub Releases](https://github.com/gotson/komga/releases) 下载最新的 JAR 文件。

### 5. 创建配置目录

```bash
mkdir -p ~/.komga
```

### 6. 创建配置文件

创建 `~/.komga/application.yml`：

```yaml
komga:
  database:
    type: postgresql
    file: jdbc:postgresql://localhost:5432/komga
    username: komga
    password: your_password
    max-pool-size: 10
  libraries-scan-startup: true

spring:
  flyway:
    locations: classpath:db/migration/postgresql
```

### 7. 启动 Komga

```bash
java -jar komga-*.jar --spring.profiles.active=postgresql
```

或者，不使用配置文件，直接通过环境变量启动：

```bash
export KOMGA_DATABASE_TYPE=postgresql
export KOMGA_DATABASE_URL=jdbc:postgresql://localhost:5432/komga
export KOMGA_DATABASE_USERNAME=komga
export KOMGA_DATABASE_PASSWORD=your_password

java -jar komga-*.jar
```

### 8. 访问 Komga

打开浏览器访问 `http://localhost:25600`。

---

## 方式三：从 SQLite 迁移数据

如果你已经有运行中的 SQLite 版本 Komga，可以将数据迁移到 PostgreSQL。

### 1. 停止 Komga

确保 Komga 已停止运行。

### 2. 准备 PostgreSQL

按照上述「手动安装」步骤 1-3 创建数据库。

### 3. 运行迁移脚本

```bash
# 安装依赖
pip install psycopg2-binary

# 运行迁移（先用 --dry-run 检查）
python3 komga/scripts/migrate_sqlite_to_postgresql.py \
    --sqlite-db ~/.komga/database.sqlite \
    --pg-url postgresql://komga:your_password@localhost:5432/komga \
    --tasks-sqlite ~/.komga/tasks.sqlite \
    --dry-run

# 确认无误后执行迁移
python3 komga/scripts/migrate_sqlite_to_postgresql.py \
    --sqlite-db ~/.komga/database.sqlite \
    --pg-url postgresql://komga:your_password@localhost:5432/komga \
    --tasks-sqlite ~/.komga/tasks.sqlite
```

### 4. 修改配置

将 `~/.komga/application.yml` 中的数据库配置改为 PostgreSQL（参考方式二的步骤 6）。

### 5. 启动 Komga

```bash
java -jar komga-*.jar --spring.profiles.active=postgresql
```

---

## 环境变量参考

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| `KOMGA_DATABASE_TYPE` | 数据库类型 | `sqlite` |
| `KOMGA_DATABASE_URL` | JDBC 连接 URL | `jdbc:postgresql://localhost:5432/komga` |
| `KOMGA_DATABASE_USERNAME` | 数据库用户名 | `komga` |
| `KOMGA_DATABASE_PASSWORD` | 数据库密码 | （空） |
| `KOMGA_DATABASE_MAX_POOL_SIZE` | 最大连接池大小 | `10` |
| `KOMGA_CONFIGDIR` | 配置目录 | `~/.komga` |

---

## 与 SQLite 的差异

| 特性 | SQLite | PostgreSQL |
|------|--------|-----------|
| 部署方式 | 单文件 | 需要数据库服务器 |
| 读写分离 | 支持 WAL 模式 | 单一连接池 |
| 并发性能 | 适合单用户 | 适合多用户 |
| 大数据量 | 一般 | 优秀 |
| 全文搜索 | 需要自定义函数 | 原生支持 `unaccent` |
| 备份 | 复制文件 | `pg_dump` 命令 |

---

## 常见问题

### Q: 启动时报 `unaccent` 函数不存在

```
ERROR: function unaccent(text) does not exist
```

**解决方案：** 安装 `unaccent` 扩展：
```bash
sudo -u postgres psql -d komga -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
```

### Q: 连接被拒绝

```
Connection refused: localhost:5432
```

**解决方案：**
1. 检查 PostgreSQL 是否运行：`sudo systemctl status postgresql`
2. 检查监听地址：编辑 `postgresql.conf`，确保 `listen_addresses = 'localhost'`
3. 检查 `pg_hba.conf` 是否允许本地连接

### Q: 如何备份 PostgreSQL 数据库

```bash
pg_dump -U komga -d komga -F c -f komga_backup.dump
```

恢复：
```bash
pg_restore -U komga -d komga komga_backup.dump
```

### Q: 如何查看数据库连接数

```sql
SELECT count(*) FROM pg_stat_activity WHERE datname = 'komga';
```

---

## 从源码构建

如果你想从源码构建并使用 PostgreSQL：

```bash
# 克隆仓库
git clone https://github.com/gotson/komga.git
cd komga

# 切换到 PostgreSQL 分支
git checkout feature/postgres

# 构建
./gradlew :komga:bootJar

# 运行
java -jar komga/build/libs/komga-*.jar --spring.profiles.active=postgresql
```

---

## 相关文档

- [数据库迁移维护指南](komga/docs/DATABASE_MIGRATION.md)
- [Komga 官方文档](https://komga.org)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
