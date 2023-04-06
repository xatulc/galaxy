## 回退 git add 操作
1. 查看当前 git 仓库的状态
```shell
git status
```

    显示：
    ```shell
    On branch master
    Your branch is up to date with 'origin/master'.
    
    Changes to be committed:
      (use "git restore --staged <file>..." to unstage)
            modified:   .DS_Store
            new file:   .idea/.gitignore
            new file:   .idea/galaxy.iml
            new file:   .idea/misc.xml
            new file:   .idea/modules.xml
            new file:   .idea/vcs.xml
            modified:   _media/.DS_Store
            new file:   images/.DS_Store
    ```

2. 撤销所有暂存的更改
```shell
git reset
```

3. 回退选定的文件
```shell
git reset <file>
```