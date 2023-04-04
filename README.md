#  导读



前台启动：
```
docsify serve docs --port 13000
```

Dockerfile 运行命令：
```Dockerfile
docker build -t docs:v1 . 
```

docker启动:
```
docker run --name=docs-3.27 -d -p 13000:13000 -m 32m -c 32 docsify-docs
```