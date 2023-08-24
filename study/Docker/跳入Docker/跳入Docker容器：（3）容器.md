## 3. 操作容器
### 3.1 运行容器

启动容器有两种方式，一种是基于镜像新建一个容器并启动，另外一个是将在终止状态（exited）的容器重新启动。

#### 3.1.1 查命令的小技巧
可以使用 **docker run --help** 查看docker run后面能跟的命令：
想看-i 开头的项目，使用命令：docker run --help | grep -- --i
-i 就是等价于--interactive 
```
-i, --interactive                    Keep STDIN open even if not attached
  --ip string                      IPv4 address (e.g., 172.30.100.104)
  --ip6 string                     IPv6 address (e.g., 2001:db8::33)
  --ipc string                     IPC mode to use
  --isolation string               Container isolation technology
```

#### 3.1.2 例子
> 输出一个 “Hello World”，之后终止容器。
```
docker run ubuntu:18.04 /bin/echo 'Hello world'
```
> 启动一个 bash 终端，允许用户进行交互
```
docker run -it ubuntu /bin/bash
```
> 启动一个终止的容器
```
# 查出容器
docker ps -a
# 启动停止的容器
docker start mysql
```
#### 3.1.3 启动mysql（各种资源限制）
```shell
 docker run -p 3306:3306 --name mysql -d -m 128m -c 512 -e MYSQL_ROOT_PASSWORD=onPrem --restart=always -v /opt/mysql/mss-light-mysql/my.cnf:/etc/mysql/my.cnf -v /opt/mysql/mss-light-mysql/data:/var/lib/mysql mysql:5.7.25
```

| 命令 | 作用 |
| --- | --- |
| -p | 映射端口号 宿主机端口:容器暴露端口 |
| -m | 限制内存 |
| -c | 限制内存 |
| -name | 给容器起名字 |
| -d | 在后台运行 |
| -e | 传递环境变量 |
| -v | 挂载存储 |
| -t | 选项让Docker分配一个伪终端（pseudo-tty）并绑定到容器的标准输入上 |
| -i | 让容器的标准输入保持打开 |
| --restart | 容器退出后可重启 |
| -P | 随机映射一个 49000~49900 的端口到内部容器开放的网络端口 |
### 3.2 终止容器
```
docker stop 容器名/容器id
```
需要注意：
```
# 查询正在运行的容器
docker ps
# 查询全部的容器包括非运行
docker ps -a
```
### 3.3 exec命令
exec 是 Docker 的一个子命令，用于在运行中的容器内部执行命令。

#### 3.3.1 进入容器
```
docker exec -it 容器名/容器id /bin/bash
```

#### 3.3.2 执行容器内部其他命令
##### 查看该容器内进程
```shell
# 查看该容器内进程
docker exec 63df3b34d2b3 ps -ef
```
##### 查看该容器内操作系统信息
```text
docker exec 63df3b34d2b3 uname -a
docker exec 63df3b34d2b3 uname -m
```

### 3.4 容器文件拷贝
#### 3.4.1 拷贝本地文件到容器内：
```
docker cp -r /hostdir webserver:/containerdir
```
*/hostdir 是本地目录的路径，webserver 是 Docker 容器的名称或 ID，/containerdir 是要拷贝到容器中的路径。*

#### 3.4.2 拷贝容器到本地：
```
docker cp mycontainer:/path/to/folder /home/user
```

### 3.5 查看日志
```text
docker logs 容器名/容器id
```

查看更具体的使用方法：
```shell
docker logs --help
```

#### 3.5.1 显示某个容器的后100行的日志
```shell
docker logs -n 100 --follow redis-test
```

### 3.6 运行中的容器做资源限制
```shell
docker stop containerId
docker update containerId -m 256m  --memory-swap -1
docker start containerId
```
解释：
```text
--memory  或  -m  限制容器的内存使用量（如10m,200m等）

--memory-swap # 限制内存和 Swap 的总和，不设置的话默认为--memory的两倍

如果 --memory-swap 和 --memory 设置了相同值，则表示不使用 Swap

如果 --memory-swap 设置为 -1 则表示取消对交换空间的限制，这意味着容器可以使用无限量的交换空间，这可能会导致系统性能问题。

如果设置了 --memory-swap 参数，则必须设置 --memory 参数

update --memory 时数值不能超过 --memory-swap 的值，否则会报错 Memory limit should be smaller than already set memoryswap limit
```

查看是否生效

```text
docker inspect containerId
```

### 3.7 容器内安装命令
```
apt-get update
apt-get install inetutils-ping 
```

### 3.8 删除容器
```
docker rm 容器名/容器id
```