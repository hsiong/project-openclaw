#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/source/openclaw"
REGISTRY="${REGISTRY:-ccr.ccs.tencentyun.com/openclaw-jf}"
LOCAL_SANDBOX_IMAGE="${LOCAL_SANDBOX_IMAGE:-openclaw-sandbox:bookworm-slim}"
LOCAL_SANDBOX_BROWSER_IMAGE="${LOCAL_SANDBOX_BROWSER_IMAGE:-openclaw-sandbox-browser:bookworm-slim}"

read_version() {
  package_json="${SOURCE_DIR}/package.json"

  if [ ! -f "${package_json}" ]; then
    echo "ERROR: 未找到 ${package_json}" >&2
    exit 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "${package_json}" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    print(json.load(f)["version"])
PY
    return
  fi

  if command -v node >/dev/null 2>&1; then
    node -p "require(process.argv[1]).version" "${package_json}"
    return
  fi

  sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "${package_json}" | head -n 1
}

VERSION="${VERSION:-$(read_version)}"
LOCAL_DOCKERCLI_IMAGE="${LOCAL_DOCKERCLI_IMAGE:-openclaw:${VERSION}-dockercli-local}"
DST_IMAGE_DOCKERCLI="${REGISTRY}/openclaw:${VERSION}-dockercli"
DST_SANDBOX_IMAGE="${REGISTRY}/openclaw-sandbox:${VERSION}"
DST_SANDBOX_BROWSER_IMAGE="${REGISTRY}/openclaw-sandbox-browser:${VERSION}"

require_image() {
  image="$1"

  if ! docker image inspect "${image}" >/dev/null 2>&1; then
    echo "ERROR: 本地镜像不存在: ${image}" >&2
    echo "请先运行: ${SCRIPT_DIR}/openclaw-build.sh" >&2
    exit 1
  fi
}

echo "==> REPO_ROOT: ${REPO_ROOT}"
echo "==> SOURCE_DIR: ${SOURCE_DIR}"
echo "==> VERSION: ${VERSION}"
echo "==> REGISTRY: ${REGISTRY}"
echo "==> LOCAL_DOCKERCLI_IMAGE: ${LOCAL_DOCKERCLI_IMAGE}"
echo "==> LOCAL_SANDBOX_IMAGE: ${LOCAL_SANDBOX_IMAGE}"
echo "==> LOCAL_SANDBOX_BROWSER_IMAGE: ${LOCAL_SANDBOX_BROWSER_IMAGE}"

if [ ! -d "${SOURCE_DIR}" ]; then
  echo "ERROR: 源码目录不存在: ${SOURCE_DIR}" >&2
  exit 1
fi

require_image "${LOCAL_DOCKERCLI_IMAGE}"
require_image "${LOCAL_SANDBOX_IMAGE}"
require_image "${LOCAL_SANDBOX_BROWSER_IMAGE}"

echo "==> 删除本地旧的 ${REGISTRY} tag（排除当前版本 ${VERSION}）"
docker images "${REGISTRY}/openclaw" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}-dockercli$" \
| xargs -r docker rmi || true

docker images "${REGISTRY}/openclaw-sandbox-browser" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}$" \
| xargs -r docker rmi || true

docker images "${REGISTRY}/openclaw-sandbox" --format "{{.Repository}}:{{.Tag}}" \
| grep -v ":${VERSION}$" \
| xargs -r docker rmi || true

echo "==> 给本地源码构建镜像打目标 tag"
docker tag "${LOCAL_DOCKERCLI_IMAGE}" "${DST_IMAGE_DOCKERCLI}"
docker tag "${LOCAL_SANDBOX_IMAGE}" "${DST_SANDBOX_IMAGE}"
docker tag "${LOCAL_SANDBOX_BROWSER_IMAGE}" "${DST_SANDBOX_BROWSER_IMAGE}"

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
