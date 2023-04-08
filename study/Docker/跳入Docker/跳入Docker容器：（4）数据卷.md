## 4. 数据卷
> 容器中的文件可以通过挂载数据卷的方式共享到宿主机上，宿主机上的文件也可以通过挂载数据卷的方式共享到容器内。即容器内的数据与宿主机上的数据可以进行双向同步，并且容器被删除时数据卷不会随之删除。

### 4.1 创建 Docker 数据卷
#### 4.1.1 docker创建默认的本地数据卷
```
docker volume create data_vol
```
使用 docker volume inspect data_vol 我们可以看到data_vol数据卷实际被挂到了/var/lib/docker/volumes/data_vol/_data目录
```
[
    {
        "CreatedAt": "2023-03-24T09:06:27Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/data_vol/_data",
        "Name": "data_vol",
        "Options": {},
        "Scope": "local"
    }
]
```
#### 4.1.2 创建制定数据卷类型的数据卷
在创建数据卷时，可以使用 -d 选项来指定数据卷的类型,支持多种卷驱动程序
```
docker volume create -d <driver> <volume-name>
```

可以支持多种类型：
```
local - 默认驱动程序，可以在本地Docker主机上创建卷。

NFS - 支持将卷映射到支持NFS（网络文件系统）的主机上。

Convoy - 支持将卷映射到云存储提供商上，例如 Amazon EBS 和 NFS。

Flocker - 支持在 Docker 集群中共享卷。

GlusterFS - 支持将卷映射到 GlusterFS 文件系统上。

Ceph - 支持将卷映射到 Ceph 集群中的块设备和对象存储池。

Portworx - 支持在 Docker 集群中通过全局命名空间共享卷。
```

**创建一个名为 data_vol 的共享卷**
```
docker volume create -d local --name=data_vol
```
**创建使用NFS驱动程序的卷**
```
docker volume create -d nfs \
--name my_nfs_volume \
--opt device=:/path/on/host \
--opt o=addr=192.168.1.100,rw \
--opt type=nfs4
```

### 4.2 挂载 Docker 数据卷
#### 4.2.1 使用-v挂载
##### 4.2.1.1 使用创建的数据卷
```
docker run -d --name=web -v data_vol:/webapp nginx
```
##### 4.2.1.2 直接指定将宿主机某个目录挂载到容器内
```
docker run -d --name=web -v /home/test/webapp:/webapp nginx
```
#### 4.2.2 使用--mount参数进行挂载
```
docker run -d --name=web --mount source=data_vol,target=/webapp nginx
```
### 4.3 查看 Docker 数据卷
```
volume ls
```
### 4.4 查看数据卷详情
```
docker volume inspect data_vol
```
### 4.5 删除 Docker 数据卷
```
docker volume rm data_vol
```

### 4.6 总结来说会有这四种使用卷的情况：
#### 4.6.1 使用宿主机的卷
##### 4.6.1.1 具名卷
```
# 创建data_vol卷 并将它挂载到容器的/webapp目录
docker volume create data_vol
docker run -d --name=web -v data_vol:/webapp nginx
```
##### 4.6.1.2 匿名卷
```
# 未指定卷名称， Docker引擎会创建一个匿名卷，挂载到容器的/webapp
docker run -d --name myapp -v /webapp nginx
```
    
以上都会Docker宿主机器的/var/lib/docker/volumes目录下创建卷，这是卷的默认地址。
使用docker volume inspect 或者 docker inspect 容器都可以看到其生成卷的位置
#### 4.6.2 绑定挂载宿主机路径
```
docker run -d --name=webserver2 -v /dir/hellword/nginx:/webapp nginx
```
#### 4.6.3 使用tmpfs
```
# tmpfs 是一种临时文件系统，可用于将内存挂载到容器中，以进行轻量级临时存储。
# tmpfs 挂载是在容器启动期间创建的，并在容器被停止时自动删除。
# 创建 /mnt/my-tmp-volume 的 tmpfs 挂载点，用于存储临时文件。
docker run -it --mount type=tmpfs,destination=/mnt/my-tmp-volume busybox
```
#### 4.6.4 使用远程（云端）的存储卷
参考 支持多种卷驱动程序 的例子
