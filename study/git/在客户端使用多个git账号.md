mac上 ssh密钥的存位置
```shell
cd ~/.ssh
```
查看git全局配置
```
git config --global
```
实质是查询 ~/.gitconfig 文件

### 1. 生成密钥对的命令
```shell
ssh-keygen -t rsa -C "new email"
```
如果只使用一个git账号我们都是直接回车，默认生成id_rsa和id_rsa.pub。
这里特别需要注意，出现提示输入文件名的时候(Enter file in which to save the key (~/.ssh/id_rsa): id_rsa_new)要输入与默认配置不一样的文件名，比如：我这里填的是 id_rsa_github

### 2. 查看生成的密钥对
```
config				id_rsa_github			
id_rsa				id_rsa_github.pub
id_rsa.pub		    known_hosts
```

### 3. 执行ssh-agent让ssh识别新的私钥

```shell
ssh-add ~/.ssh/id_rsa_github
```

### 4. 写一个config配置文件
```shell
touch config
```
内容：
```
# 配置xatu_lc@163.com
Host my_coding
HostName e.coding.net
IdentityFile ~/.ssh/id_rsa_xatu_lc@163.com
PreferredAuthentications publickey
User xatu_lc@163.com

# 配置gitHub
Host github
HostName github.com
User xatulc
IdentityFile ~/.ssh/id_rsa_github
PreferredAuthentications publickey
```

拿配置gitHub的例子来解释下：
```shell
Host github：这是一个自定义的别名，表示你要连接的远程主机

HostName github.com：这是 GitHub 的真实域名，在 SSH 连接时会将该域名解析为相应的 IP 地址。

User xatulc：这是你在 GitHub 上的用户名，也就是你的身份标识。

IdentityFile ~/.ssh/id_rsa_github：这是 SSH 密钥文件的路径，其中 id_rsa_github 是一个针对 GitHub 的密钥文件名。使用密钥可以增加 SSH 连接的安全性。

PreferredAuthentications publickey：这是认证方式的首选项，指定了 SSH 连接时优先采用公钥认证方式。
```

### 5. 将对应的公钥复制到github上

选择Settings然后选择SSH填入公钥

![](images/1.png ':size=500x500')

![](images/2.png ':size=500x500')

### 6. 进行测试
```shell
# ssh -T git@HostName
ssh -T git@github.com
```
输出为下：
```shell
Hi xatulc! You've successfully authenticated, but GitHub does not provide shell access.
```
### 7. 如何使用&需要注意

最后在不同的本地仓库记得使用命令设置当前的用户，不然就是使用的全局的默认用户

使用那个用户既得在当前本地仓库进行初始化
```shell
git config --local user.name xatulc
git config --local user.email xatu_lc@163.com
```

**另外的密钥也参照上述步骤进行**
