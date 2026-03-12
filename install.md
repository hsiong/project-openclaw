# 第一步（外网机器执行）

目标：把 OpenClaw 官方 Docker 镜像下载下来并导出。

拉取官方镜像：

```
docker pull ghcr.io/openclaw/openclaw:2026.3.11
```



```
docker login ccr.ccs.tencentyun.com --username=100030931965
docker tag ghcr.io/openclaw/openclaw:2026.3.11 ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11
# 删除tag docker rmi ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.03.11
docker push ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11
```





------

# 第四步（导入 OpenClaw 镜像）

进入镜像目录：

```
cd /home/ubuntu/backend/openclaw
```

```
docker login ccr.ccs.tencentyun.com --username=100030931965
docker pull ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11
```

------

# 第五步（创建运行目录）

```
cd /home/ubuntu/backend/openclaw
mkdir config node logs
vim config/openclaw.json  
sudo chown -R 1000:1000 /home/ubuntu/backend/openclaw/config /home/ubuntu/backend/openclaw/logs

```

------

```
{
  gateway: {
    mode: "local",
    port: 18789,
    bind: "loopback",
    auth: {
      mode: "token",
      token: "k3KL0I53QSgtIlik-XWS98-TJHBGmyaX8iscnOBPWvM"
    }
  },

  agents: {
    defaults: {
      workspace: "~/.openclaw/workspace"
    }
  },

  tools: {
    profile: "minimal",
    deny: [
      "group:runtime",
      "group:fs",
      "group:automation",
      "browser",
      "canvas",
      "nodes"
    ],
    elevated: {
      enabled: false
    },
    loopDetection: {
      enabled: true,
      historySize: 30,
      warningThreshold: 10,
      criticalThreshold: 20,
      globalCircuitBreakerThreshold: 30,
      detectors: {
        genericRepeat: true,
        knownPollNoProgress: true,
        pingPong: true
      }
    }
  }
}

```



# 

# 第七步（启动 OpenClaw）

直接运行容器：

```
docker rm -f openclaw

docker run -d \
--name openclaw \
--restart unless-stopped \
--network host \
-v /home/ubuntu/backend/openclaw/config:/home/node/.openclaw \
-v /home/ubuntu/backend/openclaw/logs:/var/log/openclaw \
ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11

# 端口应该在 openclaw.json 里配置

# 确实需要保留缓存
# -v /home/ubuntu/backend/openclaw/node:/home/node \

docker logs --tail 100 openclaw
curl -fsS http://127.0.0.1:18789/healthz
curl -fsS http://127.0.0.1:18789/readyz
```

------



```
://127.0.0.1:18791/ (auth=token)
ubuntu:config/ $ curl -fsS http://127.0.0.1:18789/healthz            [16:08:26]
{"ok":true,"status":"live"}%                                                    ubuntu:config/ $ curl -fsS http://127.0.0.1:18789/readyz             [16:08:32]
{"ready":true,"failing":[],"uptimeMs":36161}%                                   ubuntu:config/ $                                     
```





# 安全增强

关于你前面贴的那段“`mode: all` + `openclaw-sandbox:bookworm-slim`”，我的建议是：

**现在先不要加。**
因为一旦你要在“容器里的 gateway”上再启 Docker sandbox，官方文档要求对应的 sandbox 镜像要先构建好，而且非本地 `OPENCLAW_IMAGE` 还要保证镜像里有 Docker CLI 支持；同时 `docker.sock` 挂载本身就是明显的安全风险。官方还写明了：默认 `network: "none"`、`workspaceAccess: "none"`、`docker.network: "host"` 被阻止，`mode` 可以是 `off / non-main / all`。这些都说明 sandbox 是第二阶段能力，不是你现在这套手工 `docker run` 最该先上的东西。

**先别在这一步开 sandbox**。官方 Docker 文档说 Docker 网关启用 sandbox 需要额外的 `docker-setup.sh` 路径、Docker CLI 支持，必要时还会处理 `docker.sock`；而官方安全文档又反复强调最小权限和谨慎对待额外挂载。对你现在这个阶段，先让 gateway 稳定起来更重要。