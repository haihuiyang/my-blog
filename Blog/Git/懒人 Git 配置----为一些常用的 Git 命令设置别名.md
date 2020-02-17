> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

---

#### 懒人 Git 配置

我这个人比较懒，考虑到 `Git` 是日常开发会经常用到的工具，所以想到为 `Git` 命令设置一些简短的别名，以便于在日常工作提交代码的时候能够少敲一点键盘，达到偷懒的目的～

下面就是我自己的别名配置：

```zsh
# git alias 配置
# 提交代码相关
alias ga='git add '
alias gci='git commit -m '
alias gst='git status'
alias gpl='git pull'
alias gps='git push'

# 查看提交记录
alias glg="git log --color --graph --pretty=format:'%Cred%h%Creset %Cgreen%ad -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>' --date=format:'%F %T' --decorate=short"

# 切换分支相关
alias gcb='git checkout -b '
alias gco='git checkout '
alias gcm='git checkout master'

# 获取、删除分支
alias gfa='git fetch --all'
alias gfp='git fetch --prune'
alias gbr='git branch '
alias gba='git branch -a'
alias gbd='git branch -d'
alias gbD='git branch -D'

# stash 相关
alias gsts='git stash save '
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'

# 加强版的 glg （实际上只是把 commit id 全部显示出来而已）
alias glga="git log --color --graph --pretty=format:'%Cred%H%Creset %Cgreen%ad -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>' --date=format:'%F %T' --decorate=short"
```

配置起来也是非常的简单（我使用的是 `zsh`，强烈推荐使用 `zsh`；事实上这些别名配置也就是 `zsh` 的别名配置），将上面的内容添加至 `~/.zshrc` 合适的位置（配置别名的地方），然后执行 `source ~/.zshrc` 命令即可。

不仅仅是 `Git` 命令可以配置别名，也可以为其他任何脚本配置别名，例如：为查看 `docker` 日志的命令配置别名，就不用每次都敲好长一段命令了，以提高查看 `docker` 日志的效率等。

上面的别名配置仅作参考，每个人都可以生成自己的一套命令的别名配置，找到适合自己的就好。

> 近来由于换到上海上班，来来回回的折腾，再加上上海这边比之前上班的地儿要忙得多，也就没有多少时间来更新自己的博客，暂时想着更新一些自己平时经常使用的一些配置、搭建环境之类的文章，因为这些文章写起来相对来说花的时间要少一些，等在上海这边更稳定一些之后继续按照之前的计划来吧；
> 这也是希望自己不要因为忙而把写博客的事给丢掉了。

