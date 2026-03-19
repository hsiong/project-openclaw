#!/bin/sh
set -eu
#  sh openclaw-build.sh 
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/source/openclaw"
STAGE_DIR="${REPO_ROOT}/docker/.openclaw-runtime-stage"
APT_MIRROR_HOST="${APT_MIRROR_HOST:-mirrors.tuna.tsinghua.edu.cn}"
OPENCLAW_FORCE_INSTALL="${OPENCLAW_FORCE_INSTALL:-0}"

pnpm config set registry https://registry.npmmirror.com

echo "强制重新安装依赖: OPENCLAW_FORCE_INSTALL=1 sh openclaw-build.sh"

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

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: 缺少依赖命令: $1" >&2
    exit 1
  fi
}

has_build_deps() {
  [ -x "${SOURCE_DIR}/node_modules/.bin/tsdown" ] && [ -x "${SOURCE_DIR}/node_modules/.bin/tsx" ]
}

copy_stage_path() {
  rel="$1"
  mkdir -p "${STAGE_DIR}/$(dirname "${rel}")"
  cp -a "${SOURCE_DIR}/${rel}" "${STAGE_DIR}/${rel}"
}

VERSION="${VERSION:-$(read_version)}"
LOCAL_DOCKERCLI_IMAGE="${LOCAL_DOCKERCLI_IMAGE:-openclaw:${VERSION}-dockercli-local}"

require_cmd docker
require_cmd node
require_cmd pnpm

if [ ! -d "${SOURCE_DIR}" ]; then
  echo "ERROR: 源码目录不存在: ${SOURCE_DIR}" >&2
  exit 1
fi

echo "==> REPO_ROOT: ${REPO_ROOT}"
echo "==> SOURCE_DIR: ${SOURCE_DIR}"
echo "==> VERSION: ${VERSION}"
echo "==> LOCAL_DOCKERCLI_IMAGE: ${LOCAL_DOCKERCLI_IMAGE}"
echo "==> APT_MIRROR_HOST: ${APT_MIRROR_HOST}"
echo "==> OPENCLAW_FORCE_INSTALL: ${OPENCLAW_FORCE_INSTALL}"

if [ "${OPENCLAW_FORCE_INSTALL}" = "1" ]; then
  echo "==> 强制重新安装依赖"
  (
    cd "${SOURCE_DIR}"
    CI=true pnpm install --frozen-lockfile
  )
elif [ -d "${SOURCE_DIR}/node_modules" ] && has_build_deps; then
  echo "==> 复用已有 node_modules，跳过 pnpm install"
else
  echo "==> 当前 node_modules 不完整，自动补装构建依赖"
  (
    cd "${SOURCE_DIR}"
    CI=true pnpm install --frozen-lockfile
  )
fi

echo "==> 宿主机构建 gateway 产物"
(
  cd "${SOURCE_DIR}"
  pnpm canvas:a2ui:bundle || {
    echo "A2UI bundle: creating stub (non-fatal)"
    mkdir -p src/canvas-host/a2ui
    printf '%s\n' "/* A2UI bundle unavailable in this build */" > src/canvas-host/a2ui/a2ui.bundle.js
    printf '%s\n' "stub" > src/canvas-host/a2ui/.bundle.hash
  }
  pnpm build:docker
  OPENCLAW_PREFER_PNPM=1 pnpm ui:build
  find dist -type f \( -name '*.d.ts' -o -name '*.d.mts' -o -name '*.d.cts' -o -name '*.map' \) -delete
)

echo "==> 准备 runtime 构建上下文"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"

copy_stage_path "dist"
copy_stage_path "node_modules"
copy_stage_path "package.json"
copy_stage_path "openclaw.mjs"
copy_stage_path "extensions"
copy_stage_path "skills"
copy_stage_path "docs"

echo "==> 精简 runtime 依赖"
(
  cd "${STAGE_DIR}"
  CI=true pnpm prune --prod
)

echo "==> 基于本地产物构建 dockercli 镜像"
docker build \
  -t "${LOCAL_DOCKERCLI_IMAGE}" \
  --build-arg APT_MIRROR_HOST="${APT_MIRROR_HOST}" \
  --build-arg OPENCLAW_INSTALL_DOCKER_CLI=1 \
  -f "${SCRIPT_DIR}/Dockerfile.gateway-runtime-prebuilt" \
  "${STAGE_DIR}"

echo "==> 构建 sandbox 镜像"
(
  cd "${SOURCE_DIR}"
  ./scripts/sandbox-setup.sh
)

echo "==> 构建 sandbox-browser 镜像; 构建 openclaw-sandbox-browser:bookworm-slim 时会显示详细构建日志"
(
  cd "${SOURCE_DIR}"
  DOCKER_BUILDKIT=1 BUILDKIT_PROGRESS=plain ./scripts/sandbox-browser-setup.sh
)

echo "==> 本地编译完成"
echo "dockercli 镜像: ${LOCAL_DOCKERCLI_IMAGE}"
echo "sandbox 镜像: openclaw-sandbox:bookworm-slim"
echo "sandbox-browser 镜像: openclaw-sandbox-browser:bookworm-slim"
