## 7. 多阶段构建镜像

==**需要注意**==：多阶段构建是一项新功能，需要守护程序和客户端上使用Docker 17.05或更高版本。

顾名思义 多阶段构建 是指可以利用多个阶段的不同从而做更多的事

多阶段构建镜像主要解决：
1. 需要多个Dockerfile且下一个Dockerfile需要上一个Dockerfile生成的镜像为基础镜像
2. 缩小镜像大小

### 直接用一个例子来说明

需求：用go语言写一个hello world并打成镜像

#### 1. hello.go
```go
package main

import "fmt"

func main() {  
    fmt.Println("Hello, World!")  
}
```

#### 2. multi-stage.Dockerfile
```Dockerfile
#阶段1 使用go环境的基础镜像，将hello.go编译为二进制文件

FROM arm64v8/golang:1.17

WORKDIR /go

COPY hello.go ./

RUN go build -o myapp hello.go

#阶段2 使用scratch空镜像将一阶段生成到二进制文件直接拷贝过来

FROM scratch

WORKDIR /server

COPY --from=0 /go/myapp ./

CMD ["./myapp"]
```
#### 3. 打镜像
```shell
docker build -t multi-stage:v1 -f multi-stage.Dockerfile .
```

第一个镜像的依赖，我们在一个Dockerfile中定义实现

我们看到FROM的基础镜像和生成的hello-go:v1镜像大小对比大大缩小

```
arm64v8/golang   1.17     8685b3216ef4   8 months ago     806MB
multi-stage      v1       7dd4ea53d97e   31 minutes ago   1.84MB
```

#### 4. 解释

multi-stage.Dockerfile中提现多阶段构建。我们规定了第一阶段`FROM arm64v8/golang:1.17`使用go的环境编译出了二进制文件。第二阶段`FROM scratch`使用镜像`COPY --from=0 /go/myapp ./`并将第一阶段编译出的myapp复制到当前二阶段空间。

需要特别关注`COPY --from=0 /go/myapp ./` --from=0 就是表示第一阶段即`FROM arm64v8/golang:1.17` 阶段。当然我们也可以自定义名称：给第一阶段命名：`FROM arm64v8/golang:1.17 as builder` 然后指定阶段：`--from=builder`

```
#阶段1 使用go环境的基础镜像，将hello.go编译为二进制文件

FROM arm64v8/golang:1.17 as builder

WORKDIR /go

COPY hello.go ./

RUN go build -o myapp hello.go

#阶段2 使用scratch空镜像将一阶段生成到二进制文件直接拷贝过来

FROM scratch

WORKDIR /server

COPY --from=builder /go/myapp ./

CMD ["./myapp"]
```

### 只构建某一阶段的镜像
```
# 使用--target 指定运行那个阶段
docker build --target builder -t my-golang-app -f multi-stage.Dockerfile .
```

命令执行输出可以看到执行`RUN go build -o myapp hello.go`就结束了
```
[+] Building 0.1s (9/9) FINISHED                                                                                                  
 => [internal] load build definition from multi-stage.Dockerfile                                                             0.0s
 => => transferring dockerfile: 255B                                                                                         0.0s
 => [internal] load .dockerignore                                                                                            0.0s
 => => transferring context: 2B                                                                                              0.0s
 => [internal] load metadata for docker.io/arm64v8/golang:1.17                                                               0.0s
 => [builder 1/4] FROM docker.io/arm64v8/golang:1.17                                                                         0.0s
 => [internal] load build context                                                                                            0.0s
 => => transferring context: 29B                                                                                             0.0s
 => CACHED [builder 2/4] WORKDIR /go                                                                                         0.0s
 => CACHED [builder 3/4] COPY hello.go ./                                                                                    0.0s
 => CACHED [builder 4/4] RUN go build -o myapp hello.go                                                                      0.0s
 => exporting to image                                                                                                       0.0s
 => => exporting layers                                                                                                      0.0s
 => => writing image sha256:e8a9a33de2796f97731016b50f2c282ef20df1ebaed285516432c9b72b004cb8                                 0.0s
 => => naming to docker.io/library/my-golang-app 
```

运行我们打的镜像：

```
docker run --rm -it my-golang-app sh
```
```
# ls
bin  hello.go  myapp  pkg  src
# ./myapp
Hello, World!
# 
```