**2020，对自己好一点。**

MBP 是在 PDD 上买的，要问为什么，因为便宜！

买的时候犹豫了挺久的，因为害怕买到翻新机或者不是正版的。但是又眼馋 PDD 的价格，最终还是狠下心来，决定上车。

拼单成功之后，过了一天多才发的货，走的顺丰。大概过了三四天到的，取的时候，当面验货，主要检查了包装有没有损坏。

到手之后，慎重起见，又在网上搜了一下应该如何检查 Mac 电脑有没有问题。三码合一、通过序列号在官网查询保修期、电池循环计数等等，里里外外都检查了一遍，貌似也没发现什么问题。算是成功下车了吧？真香，其实内心是慌得一批。。。

---

其实自己平时工作用的也是 MBP，不过那是公司配的。这个才算是真正的属于自己的 MBP，激动、开森。^_^

新电脑，除了系统自带的一些软件之外，什么都没有。不过自己工作也是一直用的 Mac，所以需要哪些软件及环境，还是比较明了的。对照着现有的电脑，弄了一下环境，不得不说，还是花了不少时间的。

为了方便以后新电脑环境的安装，所以就整理了一下。主要分为两类：

- 普通软件
- 开发环境
- 其他的一些设置

### 一、普通软件

#### 1、[Chrome 浏览器](https://www.google.cn/chrome/index.html)

第一个安装的就是 Chrome 浏览器，有了它，下载其他的软件就都没有问题了。虽然 Mac 自带的 Safari 也不错，但是 Chrome 有很多好用的插件。比如：Chrome 神器 [Vimium](https://github.com/philc/vimium)，有了它，浏览网页几乎可以做到脱离鼠标。

#### 2、微信、QQ 和 钉钉

聊天工具，平时主要用微信和钉钉，QQ 很少用，不过也给安装上了。

#### 3、网易云音乐 和 QQ音乐

听歌软件，这两个我都有在用，有些时候想听一些电台，比较适合在 QQ 音乐听。

#### 4、腾讯视频

因为有腾讯视频会员。。。也可以把爱奇艺、优酷视频也装上。

#### 5、[百度网盘](https://www.maczd.com/post/7.html) 和 [迅雷](http://mac.xunlei.com/)

#### 6、[TeamView](https://www.teamviewer.cn/cn/)

用于远程桌面控制，也可以考虑一下向日葵。

#### 7、[Sublime Text 3](https://www.sublimetext.com/3) 和 [Visual Studio Code](https://code.visualstudio.com/)

两款好用的编辑器，其实我只用过 Sublime Text 3，确实挺不错的；不过听说 Visual Studio Code 也不错，所以也下下来尝试一下。

#### 8、[Typora](https://www.typora.io/)

一款好用的 Markdown 编辑器，主要用于写博客的。之前一直用的 MacDown，不过自从知道了 Typora 之后，就抛弃了 MacDown。。。还可以看下 iPic，一个图床工具，可以直接在 App Store 上安装即可。

#### 9、[calibre](https://calibre-ebook.com/download_osx)

一个文件格式转换工具，个人觉得非常好用，支持各种格式相互转换。

#### 10、[WPS Office](wps.com/phone-mac/)

也是听说 WPS Office 目前功能也挺强大的，像脑图、流程图之类的都支持，也准备尝试一下。

#### 11、[Tencent Lemon](https://lemon.qq.com/)

一款文件清理和状态监控软件，包括系统/应用垃圾清理、网络检测、CPU 温度和风扇转速显示。效果如图（从左至右依次为：logo，内存占用，磁盘占用，CPU 温度，风扇转速和网速）：

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau7clup62j30d401cjra.jpg" alt="腾讯柠檬状态栏" style="zoom: 200%;" />

### 二、开发环境

#### 1、[iTerm2](https://iterm2.com/)、Git、[zsh](https://ohmyz.sh/) 和 [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md)

Git 安装：直接在 iTerm2 中执行 `git --version` 会提示，选择安装就好了。

（1）安装顺序为：**iTerm2 => Git => zsh => zsh-autosuggestions**

（2）iTerm2 ，Mac 上的 shell 终端神器，配合 zsh 真的特别好用，然后 zsh-autosuggestions 是代码提示自动补全，安装好 iTerm2 之后，配置一下滚屏的行数。

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau5ygjt6pj31970u043h.jpg" alt="设置滚屏的行数" style="zoom:50%;" />

（3）通过 `ssh-keygen` 命令生成 `~/.ssh`，然后配置到 GitHub 或 GitLab 上，然后就可以 pull、push 代码了。


```bash
ssh-keygen -t rsa -C "happyfeet"
```

（4）配置心跳文件 `~/.ssh/config`，可以保持和远程服务器的 ssh 连接。


```bash
Host dev
        HostName                ip
        User                    username
        ServerAliveInterval     60
```

#### 2、[IntelliJ IDEA](https://www.jetbrains.com/idea/)、[PyCharm](https://www.jetbrains.com/pycharm/download/#section=mac) 和 [WebStorm](https://www.jetbrains.com/webstorm/download/#section=mac)

- IntelliJ IDEA：Java、Scala 等

  几款实用的插件：

  - Alibaba Java Coding Guidelines：阿里规范提示，可做参考
  - CodeGlance
  - Grep Console：给输出日志添加颜色
  - JProfiler：JVM 调试工具
  - Key promoter X：提示快捷键相关
  - Lombok：@Data、@Getter 等注解相关
  - Presentation Assistant ：提示快捷键相关
  - SonarLint：代码质量检查工具
  - String Manipulation：字符串转换工具
  - Python
  - Scala

- PyCharm：Python

- WebStorm：前端

[万能破解方法](https://zhile.io/2018/08/17/jetbrains-license-server-crack.html)

#### 3、[Java](https://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)、[Python](https://www.python.org/downloads/release/python-381/)、[Mysql](https://dev.mysql.com/downloads/mysql/) 和 [nodejs](https://nodejs.org/en/download/)


这几个都是安装包，下下来之间安装就可以了。好像现在下载 Java 安装包需要登录 Oracle 了，稍微麻烦了一点点。

Mysql 安装完成之后，需要 initial database 才能用。操作：

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau665ybo5j30u50u0whq.jpg" alt="打开 MySQL" style="zoom:50%;" />

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau689wmsmj310k0u00v0.jpg" alt="初始化 Database" style="zoom:50%;" />

Java 需要配置环境变量，待会和 Gradle 、Maven 一起。

#### 4、[Gradle](https://gradle.org/releases/) 和 [Maven](http://maven.apache.org/download.cgi)

（1）Gradle

```bash
Unzip -d ~/tools/gradle gradle-5.0-bin.zip
```

（2）Maven

```bash
tar -zxvf apache-maven-3.6.3-bin.tar.gz -C ~/tools/maven/
```

Gradle 和 Maven 统一放在 ~/tools 目录下，便于管理，减压之后需要配置环境变量，修改 ~/.zshrc 文件，大致是下面这个样子的，也包含了 JAVA_HOME 的配置：

```bash
JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_231.jdk/Contents/Home
GRADLE_HOME=/Users/happyfeet/tools/gradle/gradle-5.0
#GRADLE_HOME=/Users/happyfeet/tools/gradle/gradle-6.0.1
MAVEN_HOME=/Users/happyfeet/tools/maven/apache-maven-3.6.3
MYSQL_HOME=/usr/local/mysql

export PATH=$HOME/bin:/usr/local/bin:$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin:$MAVEN_HOME/bin:$MYSQL_HOME/bin

export JAVA_HOME
export GRADLE_HOME
export MAVEN_HOME
export MYSQL_HOME
```

#### 5、zsh 的一些别名配置，平时提交代码会简单一些。

```bash
alias ll="ls -al -h"
alias lt="ls -alt -h"
alias ltr="ls -altr -h"


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

# ssh alias
alias s160='ssh 160'
alias s169='ssh 169'
alias so160='ssh out160'
alias s167='ssh 167'
alias so167='ssh out167'

# others
alias ip="ifconfig en0 | grep 'inet ' | sed 's/inet //g' | sed 's/ netmask.*//g'"
```

### 三、其他的一些设置

#### 1、时钟屏保 [fliqlo](https://fliqlo.com/)

#### 2、光标移动速度设置

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau6iq2nc5j30yi0u041r.jpg" alt="设置光标移动速度" style="zoom:50%;" />

#### 3、三指拖动设置

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau6k3ezg2j30u50u0tbr.jpg" alt="三指拖动-1" style="zoom: 50%;" />

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau6lx8oryj310u0q2tbn.jpg" alt="三指拖动-2" style="zoom:50%;" />

#### 4、键盘的 option 和 command 键位设置

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau6q6qrlej30yh0u0djk.jpg" alt="option 和 command 键位设置" style="zoom:50%;" />

#### 5、Dock 图标设置

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau6s6l2naj31140maac8.jpg" alt="Dock 图标设置" style="zoom:50%;" />

#### 6、IDEA 设置：File Header，todo 设置

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau6va1qngj318e0u0gpf.jpg" alt="IDEA File Header 设置" style="zoom:50%;" />

<img src="https://tva1.sinaimg.cn/large/006tNbRwgy1gau735fcfkj318e0u078c.jpg" alt="IDEA 设置 todo 模板" style="zoom:50%;" />



**2020，对自己好一点！加油啊！骚年！**