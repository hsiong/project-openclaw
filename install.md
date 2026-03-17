## 1️⃣ OpenClaw 模型排行榜（社区投票）

👉
[OpenClaw 模型排行榜 (community leaderboard)](https://pricepertoken.com/leaderboards/openclaw?utm_source=chatgpt.com)

这个页面就是 **专门给 OpenClaw 选模型的榜单**。
特点：

- 按 **Agent 使用效果** 排名
- 用户投票 + 实际使用反馈
- 同时显示 **价格 / token 成本**

榜单里的常见高排名模型一般包括：

- Claude 系列
- GPT-4o / GPT 系列
- DeepSeek 系列
- Gemini 系列

这个榜单的目标就是：
**找“最适合 OpenClaw agent”的模型，而不是普通聊天能力。** 

------

## 2️⃣ OpenClaw 相关模型使用统计

👉
[OpenRouter LLM 使用排行榜](https://openrouter.ai/rankings?utm_source=chatgpt.com)

这里是 **真实开发者调用量排行榜**，很多 OpenClaw 用户也参考这个来选模型。 

------

## 3️⃣ 开源模型排行榜（本地部署）

如果你是 **Ollama / 本地 OpenClaw**：

👉
[HuggingFace Open LLM Leaderboard](https://huggingface.co/open-llm-leaderboard?utm_source=chatgpt.com)

这是目前 **最大的开源模型排名榜单**，评测多种任务。 



kimi: 15块钱

glm: 500w token

字节: 50w token

tongyi: 1000w token



# 第一步（外网机器执行）

目标：把 OpenClaw 官方 Docker 镜像下载下来并导出。



```
sh openclaw-push.sh
```



------

# 第四步（导入 OpenClaw 镜像）

进入镜像目录：

```
cd /home/ubuntu/backend/openclaw
```

------

# 第五步

你关心的是两件事：

- **token 不要被 bash/process 看到**
- **browser 不要碰你内网**

所以这版配置的关键点是：

- `sandbox.mode: "all"`：所有会话都进 sandbox。
- `scope: "session"`：每个会话一个容器，隔离最强。
- `workspaceAccess: "none"`：不把宿主机工作区映射进 sandbox。
- `docker.network: "none"`：`exec/bash/process/fs` 这批工具没网络。
- `browser.allowHostControl: false`：不允许沙箱会话接管宿主机浏览器。
- `elevated.enabled: false`：彻底关掉从 sandbox 跳回宿主机执行 `exec` 的逃生口。
- token 用 **文件型 SecretRef**，不再明文写进 `openclaw.json`。官方支持 `file` provider。



### 1）新建 `config/secrets.json`

已知

```
# 火山
 curl --location 'https://ark.cn-beijing.volces.com/api/v3/responses' \
--header "Authorization: Bearer $ARK_API_KEY" \
--header 'Content-Type: application/json' \
--data '{
    "model": "glm-4-7-251222",
    "stream": true,
    "tools": [
        {
            "type": "web_search",
            "max_keyword": 3
        }
    ],
    "input": [
        {
            "role": "user",
            "content": [
                {
                    "type": "input_text",
                    "text": "今天有什么热点新闻"
                }
            ]
        }
    ]
}'    

# 智谱
curl -X POST "https://open.bigmodel.cn/api/paas/v4/chat/completions" \
    -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${auth}" \
    -d '{
        "model": "glm-4.7",
        "messages": [
        {
            "role": "user",
            "content": "作为一名营销专家，请为我的产品创作一个吸引人的口号"
        },
        {
            "role": "assistant",
            "content": "当然，要创作一个吸引人的口号，请告诉我一些关于您产品的信息"
        },
        {
            "role": "user",
            "content": "智谱AI 开放平台"
        }
        ],
        "thinking": {
            "type": "disabled"
        },
        "max_tokens": 65536,
        "temperature": 1.0
    }'
  
  # kimi
  curl https://api.moonshot.cn/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MOONSHOT_API_KEY" \
    -d '{
        "model": "kimi-k2-turbo-preview",
        "messages": [
            {"role": "system", "content": "你是 Kimi，由 Moonshot AI 提供的人工智能助手，你更擅长中文和英文的对话。你会为用户提供安全，有帮助，准确的回答。同时，你会拒绝一切涉及恐怖主义，种族歧视，黄色暴力等问题的回答。Moonshot AI 为专有名词，不可翻译成其他语言。"},
            {"role": "user", "content": "你好，我叫李雷，1+1等于多少？"}
        ],
        "temperature": 0.6
   }'
   
   
   # tongyi - kimi
   curl --location 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions' \
--header "Authorization: Bearer $DASHSCOPE_API_KEY" \
--header 'Content-Type: application/json' \
--data '{
    "model": "kimi/kimi-k2.5",
    "messages":[
        {
            "role": "system",
            "content": "You are a helpful assistant."
        },
        {
            "role": "user",
            "content": "你是谁"
        }
    ],
    "enable_thinking": true
}'
```





```
vim /home/ubuntu/backend/openclaw/config/secrets.json
```

```
参考 config/secrets.json
```







```
chmod 600 /home/ubuntu/backend/openclaw/config/secrets.json
sudo chown 1000:1000 /home/ubuntu/backend/openclaw/config/secrets.json
```



```
cd /home/ubuntu/backend/openclaw
mkdir config node logs
sudo chown -R 1000:1000 /home/ubuntu/backend/openclaw/config /home/ubuntu/backend/openclaw/logs
vim config/openclaw.json  

```

------

```
参考 config/openclaw.json
```





# 第七步（启动 OpenClaw）

直接运行容器：

```
sh  openclaw-start.sh
```

------



```
docker logs --tail 100 openclaw
curl -fsS http://127.0.0.1:18789/healthz
curl -fsS http://127.0.0.1:18789/readyz


ubuntu:config/ $ curl -fsS http://127.0.0.1:18789/healthz            [16:08:26]
{"ok":true,"status":"live"}%                                                    ubuntu:config/ $ curl -fsS http://127.0.0.1:18789/readyz             [16:08:32]
{"ready":true,"failing":[],"uptimeMs":36161}%                                   ubuntu:config/ $                                     
```



`openclaw models status` 会显示默认模型和 fallback；`--probe` 会真的去做认证探测，可能消耗 token。这个就是官方推荐的检查方式。

```
docker exec -it openclaw openclaw models status
docker exec -it openclaw openclaw models status --probe
```

