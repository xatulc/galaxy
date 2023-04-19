## 999. 其他使用记录
### 清理docker
```shell
docker system prune
```
会删除所有未使用的资源，包括未被标记或引用的镜像、已停止的容器、未被使用的卷和网络以及所有悬空的构建缓存。执行此命令将会释放磁盘空间并提高 Docker 的性能。

具体来说，docker system prune 命令将删除以下内容：
所有没有被任何容器引用的镜像；
所有已经停止的容器；
所有没有关联容器的卷；
所有没有被连接的网络；
所有悬空的构建缓存。

除了 docker system prune 命令之外，还有一些类似的命令可以用于清理 Docker 资源：
```shell
# 删除所有已停止的容器
docker container prune
# 删除没有被标记或引用的镜像
docker image prune
# 删除所有没有关联容器的卷
docker volume prune
# 删除所有没有被连接的网络
docker network prune
```