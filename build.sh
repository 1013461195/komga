#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Komga 构建脚本 (使用 Docker 容器)
#
# 使用 gradle:jdk21-alpine 镜像构建项目，无需本地安装 Java
#
# 用法:
#   ./build.sh              # 构建 JAR
#   ./build.sh --with-image # 构建 JAR 并打包 Docker 镜像
# ============================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION=$(grep "^version" "$PROJECT_DIR/gradle.properties" | cut -d'=' -f2)
JAR_NAME="komga-${VERSION}.jar"
JAR_PATH="komga/build/libs/${JAR_NAME}"

echo "=========================================="
echo "  Komga PostgreSQL 构建"
echo "  版本: ${VERSION}"
echo "=========================================="
echo ""

# ---------- 检查 Docker ----------
if ! command -v docker &>/dev/null; then
  echo "[ERROR] 未找到 docker，请先安装 Docker"
  exit 1
fi
echo "[OK] Docker: $(docker --version | head -1)"

# ---------- 使用 Gradle 容器构建 ----------
echo ""
echo "=== 使用 Gradle 容器构建 JAR ==="
echo "   镜像: gradle:8.14.3-jdk21-alpine"
echo "   这可能需要几分钟，请耐心等待..."
echo ""

docker run --rm \
  -v "${PROJECT_DIR}:/home/gradle/project" \
  -w /home/gradle/project \
  -e GRADLE_OPTS="-Xmx2G" \
  gradle:8.14.3-jdk21-alpine \
  gradle :komga:bootJar -x test --no-daemon

# ---------- 检查构建结果 ----------
if [ ! -f "${PROJECT_DIR}/${JAR_PATH}" ]; then
  echo ""
  echo "[ERROR] 构建失败，未找到 JAR: ${JAR_PATH}"
  exit 1
fi

echo ""
echo "[OK] JAR 构建成功: ${JAR_PATH}"
echo "   大小: $(du -h "${PROJECT_DIR}/${JAR_PATH}" | cut -f1)"

# ---------- 可选: 构建 Docker 镜像 ----------
if [[ "${1:-}" == "--with-image" ]]; then
  echo ""
  echo "=== 构建 Docker 镜像 ==="

  docker build \
    -f "${PROJECT_DIR}/komga/docker/Dockerfile" \
    --build-arg "JAR=${JAR_PATH}" \
    -t komga:local \
    "${PROJECT_DIR}"

  echo ""
  echo "[OK] Docker 镜像构建成功: komga:local"
fi

echo ""
echo "=========================================="
echo "  构建完成!"
echo ""
echo "  下一步:"
echo "    cd komga/docker"
echo "    docker compose -f docker-compose.postgresql.yml up -d --build"
echo "=========================================="
