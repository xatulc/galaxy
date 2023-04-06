## 5. docker网络
Docker网络是一个由多个容器组成的虚拟网络。在Docker网络中，每个容器都有一个唯一的IP地址，并可以相互通信。Docker提供了多种网络类型，包括：

* Bridge网络：这是Docker的默认网络类型。通过Bridge网络，容器可以相互通信，并可以访问主机上的Internet。
* Host网络：通过Host网络，Docker容器可以与主机共享IP地址。这意味着容器可以访问主机上的所有网络服务。
* Overlay网络：Overlay网络是用于跨主机容器通信的网络。它使用Overlay协议，该协议可以在各个节点之间传输网络数据包。

Docker网络是一个虚拟网络，每个Docker容器都有自己独立的IP地址。这个IP地址不是在宿主机上分配的，而是在Docker网络中分配的，这些IP地址是在Docker守护进程中维护的一张表中分配的，每个Docker容器都有自己的唯一的IP地址。这意味着容器之间可以通过其IP地址相互通信，而不需要暴露它们的端口到宿主机上。

当容器加入同一个 Docker 网络时，它们可以使用容器名称或 Docker DNS 名对彼此进行访问，不必使用单个容器的 IP 地址。
### 5.1 创建一个docker网络
```
docker network create my_test_network
```
### 5.2 查看网络详情
```
 docker network inspect 25201a47bf5b98480cb820b05f7e2792ca5d45a5fd3fa551f7a967b549a2c16e
```
```
[
    {
        "Name": "my_test_network",
        "Id": "25201a47bf5b98480cb820b05f7e2792ca5d45a5fd3fa551f7a967b549a2c16e",
        "Created": "2023-03-24T10:00:15.609965759Z",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {},
        "Options": {},
        "Labels": {}
    }
]
```
### 5.3 查看Docker网络
```
docker network ls
```
### 5.4 删除网络
```
docker network rm mynetwork
```
### 5.5 容器网络互联
```
docker run -it --rm --name busybox1 --network my_test_network arm64v8/busybox:1.35 sh
```
```
docker run -it --rm --name busybox2 --network my_test_network arm64v8/busybox:1.35 sh
```
在容器命令框 执行ping命令
```
PING busybox1 (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.400 ms
64 bytes from 172.18.0.2: seq=1 ttl=64 time=0.381 ms
```
```
ping busybox2
PING busybox2 (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: seq=0 ttl=64 time=0.129 ms
64 bytes from 172.18.0.3: seq=1 ttl=64 time=0.577 ms
64 bytes from 172.18.0.3: seq=2 ttl=64 time=0.706 ms
```
busybox1 容器和 busybox2 容器建立了互联关系。








