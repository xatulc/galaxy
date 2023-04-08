```Dockerfile
# 指定基础镜像，这是分阶段构建的前期阶段
FROM openjdk:8-alpine as builder
# 执行工作目录
WORKDIR build
# 配置参数
ARG JAR_FILE=target/hello-docker-1.0.jar
# 将编译构建得到的jar文件复制到镜像空间中
COPY ${JAR_FILE} app.jar
# 通过工具spring-boot-jarmode-layertools从application.jar中提取拆分后的构建结果
RUN java -Djarmode=layertools -jar app.jar extract && rm app.jar

# 正式构建镜像
FROM openjdk:8-alpine

WORKDIR application

ENV TZ=Asia/Shanghai JAVA_OPTS="-Xms128m -Xmx256m -Djava.security.egd=file:/dev/./urandom"

# 配置时区
RUN apk add -U tzdata \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo '$TZ' > /etc/timezone

# 前一阶段从jar中提取除了多个文件，这里分别执行COPY命令复制到镜像空间中，每次COPY都是一个layer
COPY --from=builder /build/dependencies/ ./
COPY --from=builder /build/snapshot-dependencies/ ./
COPY --from=builder /build/spring-boot-loader/ ./
COPY --from=builder /build/application/ ./
COPY docker-entrypoint.sh docker-entrypoint.sh

ENTRYPOINT [ "/bin/sh", "docker-entrypoint.sh" ]
CMD ["run-hello-docker"]
```
使用的脚本：
```shell
#! /bin/bash
set -e

SERVICE_NAME="hello-docker"

if [ "$1" = "run-${SERVICE_NAME}" ]; then

    # skywalking 开关开启且 agent 目录存在
    if [[ "$SW_AGENT_ROOT" != "" ]] && [[ "$SW_ENABLE" == "true" ]]; then
        AGENT_PATH="$SW_AGENT_ROOT/skywalking-agent.jar"
        # skywalking-agent.jar agent jar 包存在
        if [ -f "$AGENT_PATH" ]; then
            echo "<<<<<<<<<<<<< run ${SERVICE_NAME} with skywalking agent >>>>>>>>>>>>>>>>>>>"
            java $JAVA_OPTS -javaagent:$AGENT_PATH org.springframework.boot.loader.JarLauncher
            exit
        fi
    fi

    echo "<<<<<<<<<<<< run default ${SERVICE_NAME} >>>>>>>>>>>>>>>>>>>>>"
    java $JAVA_OPTS org.springframework.boot.loader.JarLauncher
    exit
fi

echo "<<<<<<<<<<<< run overwrite command: $@ >>>>>>>>>>>>>>>>>>>>>"
exec "$@"
```

对Docker和脚本进行优化

对Dockerfile优化：减少了层数，缩小了docker镜像大小
```Dockerfile
# 指定基础镜像，这是分阶段构建的前期阶段
FROM openjdk:8-alpine as builder
# 执行工作目录
WORKDIR build
# 配置参数
ARG JAR_FILE=target/hello-docker-1.0.jar
# 将编译构建得到的jar文件复制到镜像空间中
COPY ${JAR_FILE} app.jar
# 通过工具spring-boot-jarmode-layertools从application.jar中提取拆分后的构建结果
RUN java -Djarmode=layertools -jar app.jar extract && rm app.jar

# 正式构建镜像
FROM openjdk:8-alpine

WORKDIR application

ENV TZ=Asia/Shanghai JAVA_OPTS="-Xms128m -Xmx256m -Djava.security.egd=file:/dev/./urandom"

# 配置时区
RUN apk add -U tzdata \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo '$TZ' > /etc/timezone

# 前一阶段从jar中提取除了多个文件，这里合并成单个COPY
COPY --from=builder /build/dependencies/ /build/snapshot-dependencies/ /build/spring-boot-loader/ /build/application/ ./
COPY docker-entrypoint.sh docker-entrypoint.sh

ENTRYPOINT [ "/bin/sh", "docker-entrypoint.sh" ]
CMD ["run-hello-docker"]
```

---
## 例子：
**在m1芯片上运行：**
对Dockerfile修改：
1.使用了架构为linux/arm64/v8的基础镜像
2.配置时区的指令进行了修改
```Dockerfile
# 指定基础镜像，这是分阶段构建的前期阶段
FROM eclipse-temurin:8-focal as builder
# 执行工作目录
WORKDIR build
# 配置参数
ARG JAR_FILE=target/hello-docker-1.0.jar
# 将编译构建得到的jar文件复制到镜像空间中
COPY ${JAR_FILE} app.jar
# 通过工具spring-boot-jarmode-layertools从application.jar中提取拆分后的构建结果
RUN java -Djarmode=layertools -jar app.jar extract && rm app.jar

# 正式构建镜像
FROM eclipse-temurin:8-focal

WORKDIR application

ENV TZ=Asia/Shanghai JAVA_OPTS="-Xms128m -Xmx256m -Djava.security.egd=file:/dev/./urandom"

# 配置时区
RUN apt-get update && apt-get install -y tzdata \
    && cp /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo '$TZ' > /etc/timezone

# 前一阶段从jar中提取除了多个文件，这里合并成单个COPY
COPY --from=builder /build/dependencies/ /build/snapshot-dependencies/ /build/spring-boot-loader/ /build/application/ ./
COPY docker-entrypoint.sh docker-entrypoint.sh

ENTRYPOINT [ "/bin/sh", "docker-entrypoint.sh" ]
CMD ["run-hello-docker"]
```
### 1. 打镜像
```
docker pull adoptopenjdk/openjdk8:aarch64-ubuntu-jre8u362-b09
docker build -t hello_springboot_docker .
```

### 2. 启动镜像
```
docker run -d -p 19098:9098 --name hello hello_springboot_docker 
```
### 3. 访问
``` 
http://localhost:19098/docker/hello
```

### 4. 其他告知：
代码：
```
@RestController
public class HelloController {
    @GetMapping("/docker/hello")
    public String hello(){
        SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");//设置日期格式
        String now = df.format(new Date());
        System.out.println(now + "-欢迎访问：将一个springboot打包一个docker镜像");
        return now + "   欢迎访问：将一个springboot打包一个docker镜像";
    }
}
```
容器运行日志：
```shell
<<<<<<<<<<<< run default hello-docker >>>>>>>>>>>>>>>>>>>>>
docker-entrypoint.sh: 9: [[: not found

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::                (v2.6.3)

2023-03-24 02:40:16.375  INFO 7 --- [           main] c.e.hellodocker.HelloDockerApplication   : Starting HelloDockerApplication v1.0 using Java 1.8.0_362 on 9aeb30d6aed5 with PID 7 (/application/BOOT-INF/classes started by root in /application)
2023-03-24 02:40:16.377  INFO 7 --- [           main] c.e.hellodocker.HelloDockerApplication   : No active profile set, falling back to default profiles: default
2023-03-24 02:40:16.840  INFO 7 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat initialized with port(s): 9098 (http)
2023-03-24 02:40:16.846  INFO 7 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2023-03-24 02:40:16.846  INFO 7 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet engine: [Apache Tomcat/9.0.56]
2023-03-24 02:40:16.874  INFO 7 --- [           main] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2023-03-24 02:40:16.874  INFO 7 --- [           main] w.s.c.ServletWebServerApplicationContext : Root WebApplicationContext: initialization completed in 474 ms
2023-03-24 02:40:17.083  INFO 7 --- [           main] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port(s): 9098 (http) with context path ''
2023-03-24 02:40:17.088  INFO 7 --- [           main] c.e.hellodocker.HelloDockerApplication   : Started HelloDockerApplication in 0.905 seconds (JVM running for 1.061)
2023-03-24 02:40:49.546  INFO 7 --- [nio-9098-exec-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring DispatcherServlet 'dispatcherServlet'
2023-03-24 02:40:49.546  INFO 7 --- [nio-9098-exec-1] o.s.web.servlet.DispatcherServlet        : Initializing Servlet 'dispatcherServlet'
2023-03-24 02:40:49.547  INFO 7 --- [nio-9098-exec-1] o.s.web.servlet.DispatcherServlet        : Completed initialization in 1 ms
2023-03-24 02:40:49-欢迎访问：将一个springboot打包一个docker镜像
2023-03-24 02:40:51-欢迎访问：将一个springboot打包一个docker镜像
2023-03-24 02:41:05-欢迎访问：将一个springboot打包一个docker镜像
```
