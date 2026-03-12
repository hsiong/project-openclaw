



https://cloud.tencent.com/document/product/1141/63910



```
docker login ccr.ccs.tencentyun.com --username=100030931965
```





```bash
docker pull ghcr.io/openclaw/openclaw:2026.3.11
docker tag ghcr.io/openclaw/openclaw:2026.3.11 ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11
# 删除tag docker rmi ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.03.11
docker push ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11
```



```
docker pull ccr.ccs.tencentyun.com/openclaw-jf/openclaw:2026.3.11
```

