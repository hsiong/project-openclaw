#!/bin/bash
set -euo

VERSION="2026.3.12"
REGISTRY="ccr.ccs.tencentyun.com/openclaw-jf"
PROJECT_DIR="openclaw"

SRC_IMAGE="ghcr.io/openclaw/openclaw:${VERSION}"
DST_IMAGE_DOCKERCLI="${REGISTRY}/openclaw:${VERSION}-dockercli"
DST_SANDBOX_IMAGE="${REGISTRY}/openclaw-sandbox:${VERSION}"
DST_SANDBOX_BROWSER_IMAGE="${REGISTRY}/openclaw-sandbox-browser:${VERSION}"

echo "==> VERSION: ${VERSION}"
echo "==> REGISTRY: ${REGISTRY}"

echo "==> 拉取源镜像"
docker pull "${SRC_IMAGE}"

echo "==> 删除本地旧的 ghcr.io/openclaw/openclaw:* tag（排除当前版本 ${VERSION}）"
docker images "ghcr.io/openclaw/openclaw" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}$" \
| xargs -r docker rmi || true

docker images "ccr.ccs.tencentyun.com/openclaw-jf/openclaw" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}$" \
| xargs -r docker rmi || true

docker images "ccr.ccs.tencentyun.com/openclaw-jf/openclaw-sandbox-browser" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}$" \
| xargs -r docker rmi || true

docker images "ccr.ccs.tencentyun.com/openclaw-jf/openclaw-sandbox" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}$" \
| xargs -r docker rmi || true

cat > Dockerfile.gateway-dockercli <<EOF
FROM ghcr.io/openclaw/openclaw:${VERSION}
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends docker.io \
 && rm -rf /var/lib/apt/lists/*
USER node
EOF


echo "==> 构建 dockercli 镜像"
docker rmi -f "${DST_IMAGE_DOCKERCLI}" 2>/dev/null || true
docker build -t "${DST_IMAGE_DOCKERCLI}" -f Dockerfile.gateway-dockercli .

echo "==> 准备源码目录"
rm -rf "${PROJECT_DIR}"

echo "==> 克隆 openclaw 仓库"
git clone --depth 1 --branch "v${VERSION}" https://github.com/openclaw/openclaw.git "${PROJECT_DIR}"

cd "${PROJECT_DIR}"

echo "==> 构建 sandbox 镜像"
./scripts/sandbox-setup.sh

echo "==> 构建 sandbox-browser 镜像"
./scripts/sandbox-browser-setup.sh

echo "==> 给 sandbox 镜像打 tag"
docker tag "openclaw-sandbox:bookworm-slim" "${DST_SANDBOX_IMAGE}"
docker tag "openclaw-sandbox-browser:bookworm-slim" "${DST_SANDBOX_BROWSER_IMAGE}"

echo "==> 推送 dockercli 镜像"
docker push "${DST_IMAGE_DOCKERCLI}"

echo "==> 推送 sandbox 镜像"
docker push "${DST_SANDBOX_IMAGE}"

echo "==> 推送 sandbox-browser 镜像"
docker push "${DST_SANDBOX_BROWSER_IMAGE}"

echo "==> 全部完成"
echo "dockercli 镜像: ${DST_IMAGE_DOCKERCLI}"
echo "sandbox 镜像: ${DST_SANDBOX_IMAGE}"
echo "sandbox-browser 镜像: ${DST_SANDBOX_BROWSER_IMAGE}"