#使用 docsify-cli 镜像作为基础镜像
FROM node:18-buster-slim

RUN npm i docsify-cli -g

# 复制 docsify 文件到容器内，其中的 . 表示 docsify 根目录
COPY . /docsify

RUN rm /docsify/Dockerfile

WORKDIR /docsify

# docsify 默认监听端口为 3000
EXPOSE 13000

# 执行 docsify serve 命令启动服务
CMD docsify serve -p 13000