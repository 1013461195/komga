#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Komga PostgreSQL 模式 - 构建 & 运行脚本
#
# 前置条件:
#   1. JDK 21+
#   2. PostgreSQL 数据库已创建:
#      psql -h 10.10.10.12 -U devuser -c "CREATE DATABASE devdatabase;"
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/komga/build/libs"
PROFILE="postgresql"
GRADLE="/home/software/env/gradle/gradle-8.14.3-all/bin/gradle"

# ---------- 环境检查 ----------
echo "=== 环境检查 ==="

if ! command -v java &>/dev/null; then
  echo "❌ 未找到 java，请安装 JDK 21+"
  exit 1
fi
echo "✅ Java: $(java -version 2>&1 | head -1)"

if [ ! -x "$GRADLE" ]; then
  echo "❌ 未找到 Gradle: $GRADLE"
  exit 1
fi
echo "✅ Gradle: $($GRADLE --version 2>&1 | grep '^Gradle' | head -1)"

# ---------- 构建 ----------
echo ""
echo "=== 构建 Komga ==="
cd "$PROJECT_DIR"

$GRADLE :komga:flywayMigrateMain :komga:flywayMigrateTasks --no-daemon
$GRADLE :komga:generateJooq --no-daemon
$GRADLE :komga:bootJar -x test --no-daemon

JAR=$(ls -t "$BUILD_DIR"/komga-*.jar 2>/dev/null | head -1)
if [ -z "$JAR" ]; then
  echo "❌ 构建失败，未找到 jar 文件"
  exit 1
fi
echo ""
echo "✅ 构建成功: $JAR"

# ---------- 运行 ----------
echo ""
echo "=== 启动 Komga (PostgreSQL 模式) ==="
echo "   数据库: 10.10.10.12:5432/devdatabase"
echo "   端口: 25600"
echo "   按 Ctrl+C 停止"
echo ""

exec java -jar "$JAR" --spring.profiles.active="$PROFILE"
