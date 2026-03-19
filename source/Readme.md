

git clone https://github.com/openclaw/openclaw.git              





## 国内编译

sandbox-browser-setup.sh

```
#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="openclaw-sandbox-browser:bookworm-slim"
APT_MIRROR_HOST="${APT_MIRROR_HOST:-mirrors.tuna.tsinghua.edu.cn}"

docker build --build-arg APT_MIRROR_HOST="${APT_MIRROR_HOST}" -t "${IMAGE_NAME}" -f Dockerfile.sandbox-browser .
echo "Built ${IMAGE_NAME}"
```





sandbox-setup.sh

```
#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="openclaw-sandbox:bookworm-slim"
APT_MIRROR_HOST="${APT_MIRROR_HOST:-mirrors.tuna.tsinghua.edu.cn}"

docker build --build-arg APT_MIRROR_HOST="${APT_MIRROR_HOST}" -t "${IMAGE_NAME}" -f Dockerfile.sandbox .
echo "Built ${IMAGE_NAME}"
```



Dockerfile.sandbox-browser

```
# syntax=docker/dockerfile:1.7

FROM debian:bookworm-slim@sha256:98f4b71de414932439ac6ac690d7060df1f27161073c5036a7553723881bffbe
ARG APT_MIRROR_HOST=mirrors.tuna.tsinghua.edu.cn

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
  if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
    sed -i \
      -e "s|http://deb.debian.org/debian|http://${APT_MIRROR_HOST}/debian|g" \
      -e "s|http://security.debian.org/debian-security|http://${APT_MIRROR_HOST}/debian-security|g" \
      /etc/apt/sources.list.d/debian.sources; \
  fi; \
  if [ -f /etc/apt/sources.list ]; then \
    sed -i \
      -e "s|http://deb.debian.org/debian|http://${APT_MIRROR_HOST}/debian|g" \
      -e "s|http://security.debian.org/debian-security|http://${APT_MIRROR_HOST}/debian-security|g" \
      /etc/apt/sources.list; \
  fi

RUN --mount=type=cache,id=openclaw-sandbox-bookworm-apt-cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,id=openclaw-sandbox-bookworm-apt-lists,target=/var/lib/apt,sharing=locked \
  apt-get update \
  && apt-get upgrade -y --no-install-recommends \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    chromium \
    curl \
    fonts-liberation \
    fonts-noto-color-emoji \
    git \
    jq \
    novnc \
    python3 \
    socat \
    websockify \
    x11vnc \
    xvfb

COPY --chmod=755 scripts/sandbox-browser-entrypoint.sh /usr/local/bin/openclaw-sandbox-browser

RUN useradd --create-home --shell /bin/bash sandbox
USER sandbox
WORKDIR /home/sandbox

EXPOSE 9222 5900 6080

CMD ["openclaw-sandbox-browser"]
```