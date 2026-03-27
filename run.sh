#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
JAR=$(ls -t "$PROJECT_DIR"/komga/build/libs/komga-*.jar 2>/dev/null | head -1)

if [ -z "$JAR" ]; then
  echo "❌ 未找到 jar，请先运行 ./build-and-run.sh 构建"
  exit 1
fi

echo "=== 启动 Komga (PostgreSQL 模式) ==="
echo "   JAR: $JAR"
echo "   数据库: 10.10.10.12:5432/devdatabase"
echo "   端口: 25600"
echo ""

exec java -jar "$JAR" --spring.profiles.active=postgresql
