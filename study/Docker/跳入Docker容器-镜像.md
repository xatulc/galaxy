## 2. 操作镜像
***使用docker* images --help 或者 docker image --help获取**
### 2.1 获取镜像
```shell
docker pull 镜像名:标签
```
### 2.2 列出镜像
#### 2.2.1 获取本地镜像
```
docker image ls
docker images -a
```
输出：
```shell
REPOSITORY                     TAG                           IMAGE ID       CREATED        SIZE
hello_springboot_docker        latest                        42a6063b5bd0   9 hours ago    264MB
adoptopenjdk/openjdk8          aarch64-ubuntu-jre8u362-b09   a362ed695dbd   10 hours ago   215MB
alpine                         latest                        d74e625d9115   5 weeks ago    7.46MB
hellp-world                    latest                        deadd92e8470   5 weeks ago    7.46MB
ubuntu                         latest                        4c2c87c6c36e   3 months ago   69.2MB
moby/buildkit                  buildx-stable-1               71ac63309b0f   5 months ago   134MB
ibex/debian-mysql-server-5.7   5.7.22                        36794136ff31   4 years ago    302MB
```
| 英文 | 含义 |
| --- | --- |
| REPOSITORY | 镜像名称 |
| TAG | 镜像tag |
| IMAGE ID | 镜像id |
| CREATED | 创建时间 |
| SIZE | 镜像大小 |
#### 2.2.2 查找镜像
```shell
docker image ls | grep hello
```
#### 2.2.3 获取虚悬镜像
```shell
docker image ls -f dangling=true
```
#### 2.2.4 以特定格式显示
--format是指定输出格式
```shell
docker image ls --format "{{.ID}}: {{.Repository}}"
```
### 2.3 删除镜像
```
docker image rm 镜像名/镜像id 镜像名/镜像id
docker rmi 镜像名/镜像id 镜像名/镜像id
```
#### 2.3.1 结合docker image ls来使用
删除所有仓库名为 redis 的镜像：
```
docker image rm $(docker image ls -q redis)
```
删除镜像名带hello的镜像
```
docker rmi $(docker image ls | grep hello）
```
### 2.4 导入导出镜像
#### 2.4.1 导出镜像为tar
```
docker save -o ubuntu_14.04.tar ubuntu:14.04
```
#### 2.4.2 tar包恢复为镜像
```
docker load -i ubuntu_14.04.tar
```
#### 2.4.3 镜像打tar.gz
```
docker save <image>:<tag> | gzip > 压缩包名称.tar.gz
```
#### 2.4.4 tar.gz恢复为镜像
```
gunzip -c 压缩包名称.tar.gz.tar.gz | docker load
```