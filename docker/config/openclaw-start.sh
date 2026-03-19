#!/usr/bin/env bash
set -euo

VERSION="2026.3.12"
REGISTRY="ccr.ccs.tencentyun.com/openclaw-jf"
USERNAME="100030931965"

APP_NAME="openclaw"

OPENCLAW_IMAGE="${REGISTRY}/openclaw:${VERSION}-dockercli"
SANDBOX_IMAGE="${REGISTRY}/openclaw-sandbox:${VERSION}"
SANDBOX_BROWSER_IMAGE="${REGISTRY}/openclaw-sandbox-browser:${VERSION}"

CONFIG_DIR="/home/ubuntu/backend/openclaw/config"
LOG_DIR="/home/ubuntu/backend/openclaw/logs"

CONFIG_FILE="${CONFIG_DIR}/openclaw.json"
echo "配置文件路径: ${CONFIG_FILE}"
echo "==> 更新 openclaw.json 中的 sandbox 版本为 ${VERSION}"
if [ -f "${CONFIG_FILE}" ]; then
  sudo sed -i -E "s#openclaw-sandbox:[0-9.]+#openclaw-sandbox:${VERSION}#g" "${CONFIG_FILE}"
  sudo sed -i -E "s#openclaw-sandbox-browser:[0-9.]+#openclaw-sandbox-browser:${VERSION}#g" "${CONFIG_FILE}"
else
  echo "警告: ${CONFIG_FILE} 不存在，跳过版本替换"
fi

echo "==> 当前版本: ${VERSION}"

echo "==> 登录腾讯云镜像仓库"
docker login ccr.ccs.tencentyun.com --username="${USERNAME}"

echo "==> 拉取当前版本镜像"
docker pull "${OPENCLAW_IMAGE}"
docker pull "${SANDBOX_IMAGE}"
docker pull "${SANDBOX_BROWSER_IMAGE}"

echo "==> 停止并删除旧容器（如果存在）"
docker rm -f "${APP_NAME}" 2>/dev/null || true

echo "==> 创建目录"
mkdir -p "${CONFIG_DIR}" "${LOG_DIR}"

echo "==> 删除本地旧 openclaw 镜像（排除当前版本 ${VERSION}）"
docker images "${REGISTRY}/openclaw" --format "{{.Repository}}:{{.Tag}}" \
  | grep -E '^[^ ]+:[^ ]+$' \
  | grep -v ":${VERSION}-dockercli$" \
  | xargs -r docker rmi -f || true

echo "==> 删除本地旧 sandbox 镜像（排除当前版本 ${VERSION}）"
docker images "${REGISTRY}/openclaw-sandbox" --format "{{.Repository}}:{{.Tag}}" \
  | grep -E '^[^ ]+:[^ ]+$' \
  | grep -v ":${VERSION}$" \
  | xargs -r docker rmi -f || true

echo "==> 删除本地旧 sandbox-browser 镜像（排除当前版本 ${VERSION}）"
docker images "${REGISTRY}/openclaw-sandbox-browser" --format "{{.Repository}}:{{.Tag}}" \
  | grep -E '^[^ ]+:[^ ]+$' \
  | grep -v ":${VERSION}$" \
  | xargs -r docker rmi -f || true
  
  
cd /home/ubuntu/backend/openclaw
mkdir -p config node logs

echo "直接把宿主机上的配置目录改成 root 拥有："
sudo chown -R root:root /home/ubuntu/backend/openclaw/config
sudo chmod 755 /home/ubuntu/backend/openclaw/config
sudo chmod 600 /home/ubuntu/backend/openclaw/config/secrets.json
sudo chmod 755 /home/ubuntu/backend/openclaw/config/openclaw.json
sudo setfacl -R -m u:ubuntu:rwX /home/ubuntu/backend/openclaw/config


echo "==> 启动容器"
docker run -d \
  --name "${APP_NAME}" \
  --restart unless-stopped \
  --network host \
  --user root \
  -v "${CONFIG_DIR}:/root/.openclaw" \
  -v "${LOG_DIR}:/var/log/openclaw" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e DOCKER_HOST=unix:///var/run/docker.sock \
  "${OPENCLAW_IMAGE}"

echo "==> 当前运行中的容器"
docker ps --filter "name=${APP_NAME}"

echo "==> 部署完成"
echo "openclaw: ${OPENCLAW_IMAGE}"
echo "sandbox: ${SANDBOX_IMAGE}"
echo "sandbox-browser: ${SANDBOX_BROWSER_IMAGE}"
