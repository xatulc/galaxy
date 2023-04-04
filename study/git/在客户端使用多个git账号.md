ssh 密钥存位置
```shell
~/.ssh
```

查看git全局配置
```
git config --global
```
实质是查询 ~/.gitconfig 文件

生成密钥对的命令
```shell
ssh-keygen -t rsa -C "new email"
```
平时我们都是直接回车，默认生成id_rsa和id_rsa.pub。这里特别需要注意，出现提示输入文件名的时候(Enter file in which to save the key (~/.ssh/id_rsa): id_rsa_new)要输入与默认配置不一样的文件名，比如：我这里填的是 id_rsa_github

生成了如下的密钥对
```
config				id_rsa_github			id_rsa_xatu_lc@163.com.pub
id_rsa				id_rsa_github.pub		known_hosts
id_rsa.pub			id_rsa_xatu_lc@163.com		known_hosts.old
```

 执行ssh-agent让ssh识别新的私钥
ssh-add ~/.ssh/id_rsa_github

创建一个config文件
touch config

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

Host github：这是一个自定义的别名，表示你要连接的远程主机
HostName github.com：这是 GitHub 的真实域名，在 SSH 连接时会将该域名解析为相应的 IP 地址。
User xatulc：这是你在 GitHub 上的用户名，也就是你的身份标识。
IdentityFile ~/.ssh/id_rsa_github：这是 SSH 密钥文件的路径，其中 id_rsa_github 是一个针对 GitHub 的密钥文件名。使用密钥可以增加 SSH 连接的安全性。
PreferredAuthentications publickey：这是认证方式的首选项，指定了 SSH 连接时优先采用公钥认证方式。

原来使用默认（全部用户）使用该命令：  git@github.com:xatulc/galaxy.git
现在就要使用 github:xatulc/galaxy.git


将对应的公钥复制到github上
 
使用 ssh -T git@github.com 进行测试 (命令是：ssh -T git@HostName)输出：
Hi xatulc! You've successfully authenticated, but GitHub does not provide shell access.

最后在不同的本地仓库记得使用命令设置当前的用户，不然就是全局的默认用户
git config --local user.name xxx
git config --local user.email xxx@xxx.com
