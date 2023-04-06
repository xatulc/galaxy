## 6. 制作镜像-Dockerfile
### 6.1 打镜像的命令
#### 6.1.1 使用默认的Dockerfile
```
docker build -t name:v1 .
```

#### 6.1.2 使用自定义名的Dockerfile
```
dokcer build -t name:v1 -f nginx.Dokcerfile .
```
### 6.2 Dockerfile是什么
Dockerfile 是一个文本文件，它包含了构建 Docker 镜像的指令和参数。通过在 Dockerfile 文件中定义每一层所需的操作和步骤。

### 6.3 一个基本的 Dockerfile 通常包含以下几个部分

1. 指定基础镜像：使用 FROM 指令指定要使用的基础镜像。例如，FROM ubuntu:18.04 告诉 Docker 构建镜像，并以 Ubuntu 18.04 作为基础镜像。

2. 设置工作目录：使用 WORKDIR 指令设置在容器内运行命令所在的工作目录。这可以使我们的工作更加轻松，并且可以避免一些路径相关的问题。

3. 复制文件：使用 COPY 或 ADD 指令将构建上下文内的文件或者远程 URL 所指向的文件复制到镜像中。例如，COPY app.py /app/ 可以将本地左侧的 app.py 文件复制到镜像中的 /app 目录下。

4. 运行命令：使用 RUN 指令在镜像内运行命令。例如，RUN apt-get update -y && apt-get install -y python3-pip 可以在镜像中运行 apt-get 命令以更新软件包并安装 python3-pip 软件包。

5. 配置环境变量：使用 ENV 指令设置环境变量。例如，ENV APP_PORT=8080 可以将环境变量 APP_PORT 设置为 8080。

6. 暴露端口：使用 EXPOSE 指令指定容器将侦听的端口数，但并不实际映射这些端口。例如，EXPOSE 8080 声明容器将在 8080 端口上侦听。

7. 设置启动命令：使用 CMD 或 ENTRYPOINT 指令指定在容器启动时要运行的命令。例如，CMD ["python3", "app.py"] 可以在容器启动时运行 python3 app.py 命令。

### 6.4 具体指令解释

#### 6.4.1 FROM
指定基础镜像

#### 6.4.2 WORKDIR
指定工作目录
使用 WORKDIR 指令可以来指定工作目录（或者称为当前目录），以后各层的当前目录就被改为指定的目录，如该目录不存在，WORKDIR 会帮你建立目录。

#### 6.4.3 USER
改变之后层的执行 RUN, CMD 以及 ENTRYPOINT 这类命令的身份。

USER 只是帮助你切换到指定用户而已，这个用户必须是事先建立好的，否则无法切换。

```
RUN groupadd -r redis && useradd -r -g redis redis
USER redis
RUN [ "redis-server" ]
```

#### 6.4.4 COPY
复制文件
格式：
COPY [--chown=<user>:<group>] <源路径>... <目标路径>
COPY [--chown=<user>:<group>] ["<源路径1>",... "<目标路径>"]

> 将上下文当前目录的package.json 复制到镜像的/usr/src/app/ 目录
```
COPY package.json /usr/src/app/
```

> 可以使用通配符
```
# 可以使用通配符
COPY hom* /mydir/
COPY hom?.txt /mydir/
```

> 复制时还可以修改文件的权限
```
COPY --chown=55:mygroup files* /mydir/
COPY --chown=bin files* /mydir/
COPY --chown=1 files* /mydir/
COPY --chown=10:11 files* /mydir/
```

使用 COPY 指令，源文件的各种元数据都会保留。比如读、写、执行权限、文件变更时间等。目标路径不需要事先创建，如果目录不存在会在复制文件前先行创建缺失目录。

#### 6.4.5 ADD
所有的文件复制均使用 COPY 指令，仅在需要自动解压缩的场合使用 ADD。

ADD和COPY命令都可以用来复制文件和目录到镜像中，但是二者有一些不同点：
1. ADD指令支持从 URL 中获取并添加到镜像中，而COPY指令只支持从构建上下文拷贝文件到镜像中。
2. ADD指令在拷贝压缩格式的文件时，会自动解压缩压缩文件，并将所解压的文件添加到镜像中；

#### 6.4.6 CMD
CMD 指令就是用于指定默认的容器主进程的启动命令的。

shell 格式：CMD <命令>
exec 格式：CMD ["可执行文件", "参数1", "参数2"...]

使用 shell 格式的话，实际的命令会被包装为 sh -c 的参数的形式进行执行
```
CMD echo $HOME
```
实际等价于
```
# $HOME使用了环境变量
CMD [ "sh", "-c", "echo $HOME" ]
```

==**在运行时可以指定新的命令来替代镜像设置中的这个默认命令**==
例如：
```Dockerfile
FROM arm64v8/alpine:3.14

CMD echo "Hello World"
```

使用该Dockerfile打镜像：docker build -t hello:v2 .

使用命令：docker run hello:v2 echo "hhhhh" 则输出：hhhhh

可以观察到 echo "hhhhh" 覆盖掉了Dockerfile中这个默认命令：CMD echo "Hello World"

#### 6.4.7 ENTRYPOINT

ENTRYPOINT 的格式和 RUN 指令格式一样，分为 exec 格式和 shell 格式。

ENTRYPOINT 的目的和 CMD 一样，都是在指定容器启动程序及参数。

##### 6.4.7.1 ENTRYPOINT和CMD同时使用

当指定了 ENTRYPOINT 后，CMD 的含义就发生了改变，不再是直接的运行其命令，而是将 CMD 的内容作为参数传给 ENTRYPOINT 指令，换句话说实际执行时，将变为：

```
<ENTRYPOINT> "<CMD>"
```

例如：
docker-entrypoint.sh
```shell
#!/bin/bash

if [ $# -eq 1 ] && [ $1 -eq 1 ]
then
  echo "答对了"
else
  echo "答错了"
fi
```
docker-entrypoint.Dokcerfil
```Dockerfile
FROM arm64v8/alpine:3.14

WORKDIR /app

COPY docker-entrypoint.sh .

ENTRYPOINT ["sh", "docker-entrypoint.sh"]

CMD ["1"]
```
使用该Dockerfile打镜像：docker build -t docker-entrypoint:v1 -f docker-entrypoint.Dokcerfil .

使用命令：docker run docker-entrypoint:v1 则输出：答对

使用命令：docker run docker-entrypoint:v1 2  则输出：答错了

可以观察到 ENTRYPOINT 和 CMD结合的效果

##### 6.4.7.2 ENTRYPOINT和CMD区别
在docker run时CMD是替代镜像设置中的默认命令，ENTRYPOINT是追加

```Dockerfile
FROM arm64v8/alpine:3.14

ENTRYPOINT ["echo", "Hello World"]
```
使用该Dockerfile打镜像：docker build -t hello:v3 .
使用命令：docker run hello:v3 "hhhhh" 则输出：Hello World hhhhh
可以观察到 Hello World 后面追加输出了参数hhhhh

#### 6.4.8 ENV
设置环境变量

格式有两种：
ENV <key> <value>
ENV <key1>=<value1> <key2>=<value2>...

#### 6.4.9 ARG
构建参数

格式：ARG <参数名>[=<默认值>]

ARG 所设置的构建环境的环境变量，在将来容器运行时是不会存在这些环境变量。
该默认值可以在构建命令 docker build 中用 --build-arg <参数名>=<值> 来覆盖。
ARG 指令有生效范围，如果在 FROM 指令之前指定，那么只能用于 FROM 指令中。

#### 6.4.10 EXPOSE
暴露端口
格式为 EXPOSE <端口1> [<端口2>...]

EXPOSE 指令是声明容器运行时提供服务的端口，这只是一个声明，在容器运行时并不会因为这个声明应用就会开启这个端口的服务。

**主要作用：**
1. 是帮助镜像使用者理解这个镜像服务的守护端口，以方便配置映射；
2. docker run -P 时，会自动随机映射 EXPOSE 的端口。

### 6.5 镜像构建上下文理解 -> docker build 在干什么？

#### 6.5.1 docker是一种c/s架构
Docker 在运行时分为服务端守护进程和客户端工具。服务端提供了一组 REST API，被称为 Docker Remote API。虽然表面上我们好像是在本机执行各种 Docker 功能，但实际上一切都是通过远程调用Docker 引擎完成。

#### 6.5.2 Dockerfile中的COPY 指令、ADD 指令实际在docker build时在干什么
COPY、ADD指令在docker build 命令构建镜像，其实并非在本地构建，而是在服务端，也就是 Docker 引擎中构建的。这样需要客户端向服务端打包本地资源，这就引入了上下文的概念。

#### 6.5.3 举一个例子进行说明
```Dockerfile
FROM eclipse-temurin:8-focal

WORKDIR /app
 
COPY HelloWorld.java .

RUN javac HelloWorld.java

CMD ["java", "HelloWorld"]
```

执行 ***docker build -t hello:v8 .*** 执行后输出：

```shell
[+] Building 0.1s (9/9) FINISHED                                                                                                  
 => [internal] load build definition from Dockerfile                                                                         0.0s
 => => transferring dockerfile: 166B                                                                                         0.0s
 => [internal] load .dockerignore                                                                                            0.0s
 => => transferring context: 2B                                                                                              0.0s
 => [internal] load metadata for docker.io/library/eclipse-temurin:8-focal                                                   0.0s
 => [internal] load build context                                                                                            0.0s
 => => transferring context: 36B                                                                                             0.0s
 => [1/4] FROM docker.io/library/eclipse-temurin:8-focal                                                                     0.0s
 => CACHED [2/4] WORKDIR /app                                                                                                0.0s
 => CACHED [3/4] COPY HelloWorld.java .                                                                                      0.0s
 => CACHED [4/4] RUN javac HelloWorld.java                                                                                   0.0s
 => exporting to image                                                                                                       0.0s
 => => exporting layers                                                                                                      0.0s
 => => writing image sha256:3218f0976a08bd9ba0f65dd624582efa950d0b63a9fb62e2cbf9b9eda677fd69                                 0.0s
 => => naming to docker.io/library/hello:v8                                                                                  0.0s
```

对输出解释：
```text
load build definition from Dockerfile  加载 Dockerfile 中定义的构建步骤。

transferring dockerfile 传输 Dockerfile 文件本身。

transferring context 传输构建上下文（Dockerfile 所在目录）。
```

可以得到如下结论：

1. 可以看到dokcer build将Dockerfile和其所在目录下文件（上下文）传输到了docker服务端，所以之后docker引擎打镜像使用到资源都是根据传输拿到的上下文资源进行的。

2. 在执行 COPY HelloWorld.java . 是复制上下文（context）的HelloWorld.java文件到镜像中。如果我们使用绝对路径，比如/opt/tmp/HelloWorld.java 就会出错。因为传给docker引擎的上下文只有Dockerfile所在目录文件，它理解不了/opt/tmp/HelloWorld.java是什么，因此可以看到copy大多是相对路径而不是绝对路径。如果非要写到绝对路径，那需要将Dockerfile放到根目录，可想而知传递的上下文得发送多少东西。
