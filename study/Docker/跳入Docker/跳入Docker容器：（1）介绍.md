## 1. Docker简介
Docker 使用 Google 公司推出的 Go 语言 进行开发实现，基于 Linux 内核的 cgroup，namespace，以及 OverlayFS 类的 Union FS 等技术，对进程进行封装隔离，属于 操作系统层面的虚拟化技术。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。

容器是机器上的沙盒进程，与主机上的所有其他进程隔离。这种隔离利用了内核命名空间和 cgroups

当运行容器时，Docker 会为该容器创建一组命名空间。这些命名空间提供了一层隔离。容器的每个方面都在单独的命名空间中运行，并且它的访问权限仅限于该命名空间。


 ### 1.1 docker优点
 * 更高效的利用系统资源
容器不需要进行硬件虚拟以及运行完整操作系统等额外开销
* 更快速的启动时间
 传统的虚拟机技术启动应用服务往往需要数分钟，而 Docker 容器应用，由于直接运行于宿主内核，无需启动完整的操作系统
* 一致的运行环境
Docker 的镜像提供了除内核外完整的运行时环境，确保了应用运行环境一致性，从而不会再出现 「这段代码在我机器上没问题啊」 这类问题。
* 持续交付和部署

### 1.2 镜像

### 1.3 容器
镜像（Image）和容器（Container）的关系，就像是面向对象程序设计中的 类 和 实例 一样，镜像是静态的定义，容器是镜像运行时的实体。容器可以被创建、启动、停止、删除、暂停等。

容器的实质是进程，但与直接在宿主执行的进程不同，容器进程运行于属于自己的独立的 命名空间。因此容器可以拥有自己的 root 文件系统、自己的网络配置、自己的进程空间，甚至自己的用户 ID 空间。容器内的进程是运行在一个隔离的环境里，使用起来，就好像是在一个独立于宿主的系统下操作一样。这种特性使得容器封装的应用比直接在宿主运行更加安全。