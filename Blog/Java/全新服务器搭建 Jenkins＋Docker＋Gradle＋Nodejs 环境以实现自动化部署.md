> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

在开发过程中，如果每次交付给测试时都需要手动的对代码进行构建和部署，这无疑是一件较为繁琐的过程，如果能够让其一键完成，无疑可以节省人力劳动并降低时间开销。这就是我们通常说的自动化部署。

最近接手了公司的一个新项目，所幸有机会自己独立搭建这样一套自动化部署环境。虽然有些地方不那么完美，但是已经能够一键部署了，也还是不错的。

下面就是搭建的大致步骤、搭建过程中遇到的问题及解决办法。

```zsh
注意：本文基于 `Red Hat` 环境，初始状态为：一个 `root` 用户，存在 `yum` 命令可以调用，`Red Hat` 版本信息如下：
	
Linux iZ9ni05eeu3wg5xwyjnt5gZ 3.10.0-514.6.2.el7.x86_64 #1 SMP Thu Feb 23 03:04:39 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
```

---

#### 一、新建用户和用户组（参考博文：[Linux学习-给普通用户加sudo权限](https://blog.csdn.net/Dream_angel_Z/article/details/45841109)）

首先需要添加一个新用户 `HappyFeet`，所有操作应该基于新用户来进行，而不是 `root` 用户，因为 `root` 权限太高，稍有不慎就可能出大问题。

##### 1、添加用户组

```zsh
groupadd HappyFeet
```

##### 2、添加用户，并指定用户组

```zsh
useradd -g HappyFeet HappyFeet
```

##### 3、给用户设置密码（输入密码2次）

```zsh
passwd HappyFeet
```


##### 4、给新用户添加 `sudo` 权限

切换至 `root` 帐号，执行 `visudo` ，找到 `root  ALL=(ALL)    ALL`，在其后面新增一行：`HappyFeet  ALL=(ALL)    ALL` 即可。

#### 二、zsh 配置

##### 1、安装 `git`

```zsh
sudo yum install git
```

##### 2、安装 `zsh`（参考文档：[Installing zsh – the easy way](https://gist.github.com/derhuerst/12a1558a4b408b3b2b6e)）

```zsh
sudo yum install zsh
```

##### 3、安装 `on my zsh`（参考官方文档：[Install oh-my-zsh now](https://ohmyz.sh/)）

##### 4、安装提示工具 `zsh-autosuggestions`（参考官方文档：[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md)，可装可不装，一款提示工具）

##### 5、通过 `ssh-keygen` 生成 `ssh key`，然后将自己的 public key 加至 `authorized_keys` 文件中，后面即可通过 `ssh username@host` 登录服务器，方便快捷。（这也是个可选项，如果不这样配置的话每次 `ssh` 时都需要输密码，就会很麻烦）

参考链接：[How to ssh to remote server using a private key?](https://unix.stackexchange.com/questions/23291/how-to-ssh-to-remote-server-using-a-private-key)

##### 6、.zshrc 添加别名（仅是别名配置，可以忽略不管）

在 `~/.zshrc` 文件中新增一行：`alias ll="ls -alh"`

#### 三、安装 Docker（参考官方文档：[Get Docker CE for CentOS](https://docs.docker.com/v17.12/install/linux/docker-ce/centos/#install-docker-ce-1)，服务器为 `Red Hat` 版本，按照 `centos` 版安装 `docker ce` 社区版本）

##### 1、Install required packages.

```zsh
sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2
```

##### 2、Use the following command to set up the stable repository.

```zsh
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

##### 3、Install the latest version of Docker CE.

```zsh
sudo yum install docker-ce
```

##### 4、启动.

```zsh
sudo systemctl start docker
```

##### 5、使用 `docker ps` 报如下错误

```zsh
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.39/containers/json: dial unix /var/run/docker.sock: connect: permission denied
```

**解决方案为：将当前用户加入 `docker` 用户组（参考链接：[docker.sock permission denied](https://stackoverflow.com/questions/48568172/docker-sock-permission-denied)）**

```zsh
➜  ~ echo $USER
HappyFeet
➜  ~ sudo usermod -aG docker $USER
```

#### 四、安装 openjdk（参考官方文档：[How to download and install prebuilt OpenJDK packages](https://openjdk.java.net/install/)）

##### 1、安装 openjdk

```zsh
su -c "yum install java-1.8.0-openjdk-devel"
```

**需要注意的是，需要安装 develop 版的，不带 devel 后缀的是 jre 环境。**

##### 2、添加 `JAVA_HOME、JRE_HOME` 环境变量（gradle 会用到）

```zsh
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.191.b12-1.el7_6.x86_64
export JRE_HOME=${JAVA_HOME}/jre

export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib

export PATH=$PATH:${JAVA_HOME}/bin
```

#### 五、安装 gradle

##### 1、下载 bin.zip（个人喜欢用.zip安装，知道安装在哪，所有都是由自己掌控，下载链接：[download gradle](https://gradle.org/install/)）

##### 2、解压至指定路径

```zsh
$ mkdir ~/tools/gradle
$ unzip -d ~/tools/gradle gradle-4.6-bin.zip
$ ls ~/tools/gradle/gradle-4.6
LICENSE  NOTICE  bin  getting-started.html  init.d  lib  media
```

##### 3、添加 GRADLE_HOME 至 .zshrc

```zsh
export GRADLE_HOME=/home/HappyFeet/tools/gradle/gradle-4.6
export PATH=$PATH:${GRADLE_HOME}/bin
```

##### 4、`gradle -v` 验证，输出如下：

```zsh
➜  ~ gradle -v

------------------------------------------------------------
Gradle 4.6
------------------------------------------------------------

Build time:   2018-02-28 13:36:36 UTC
Revision:     8fa6ce7945b640e6168488e4417f9bb96e4ab46c

Groovy:       2.4.12
Ant:          Apache Ant(TM) version 1.9.9 compiled on February 2 2017
JVM:          1.8.0_191 (Oracle Corporation 25.191-b12)
OS:           Linux 3.10.0-514.6.2.el7.x86_64 amd64
```

#### 六、安装 jenkins

##### 1、下载war包（[Getting started with Jenkins](https://jenkins.io/download/)，Generic Java package (.war)版本）

##### 2、编写 start_jenkins.sh 脚本

```zsh
#!/bin/sh
export JENKINS_HOME=/home/HappyFeet/tools/jenkins
export COPY_REFERENCE_FILE_LOG=$HOME/copy_reference_file.log
java -jar $JENKINS_HOME/jenkins.war --httpPort=8899 --logfile=$JENKINS_HOME/jenkins.log
```

##### 3、启动 jenkins

执行 `nohup /home/HappyFeet/scripts/start_jenkins.sh &`，使用 `nohup` 的原因是为了让它在后台一直运行

启动完之后可以打开 [http://serverHost:8899](http://serverHost:8899) 即可进入 jenkins 页面进入后续操作

#### 七、安装 htop，监控系统状态

```zsh
sudo yum install htop
```

#### 八、安装 nodejs 最新版本（参考链接：[How To Install Latest Nodejs on CentOS/RHEL 7/6](https://tecadmin.net/install-latest-nodejs-and-npm-on-centos/)、[Installing nodejs on Red Hat](https://stackoverflow.com/questions/27778593/installing-nodejs-on-red-hat)）

```zsh
curl -sL https://rpm.nodesource.com/setup | bash -
yum install -y nodejs
```

#### 九、登录 daocloud.io

```zsh
docker login daocloud.io
Username: HappyFeet（daocloud.io 的 username）
Password:
```

#### 十、在 jenkins 上添加自动化脚本

jenkins 集成了 git、gradle、nodejs 及 docker。

后端服务原本的部署步骤为：

（1）更新代码（需要将 server 上的 `~/.ssh/id_rsa.pub` key 加在 github 上）：`git pull master`

（2）将更新之后的代码编译，打成 jar 包：`gradle clean build`

（3）将更新的 jar 挂载在 docker 内部运行：`docker run balabala...`

前端服务也是类似。

通过 jenkins 工具，我们可以通过一个按钮就完成上面的所有操作，即自动化。在这个自动化中，jenkins 所扮演的角色就是一个 operator，它可以按顺序执行上面（1）、（2）、（3）的操作。而我们要做的就是将（1）、（2）、（3）脚本化。

至于如何编写脚本和 jenkins 配置则需要参考 jenkins 文档及 shell 脚本编写相关的知识了...在此不做详细讲解了。下面给出我自己编写的大致脚本仅作参考：

```zsh
#!/bin/zsh

source /home/HappyFeet/.zshrc #使之可以调用 gradle、docker 命令
gradle clean build
cp build/libs/**.jar /opt/jars/**.jar #将jar包复制到挂载目录
docker stop svc_name
docker rm svc_name
docker run --name svc_name -v /opt/jars/:/app/ ....
```

**搭建自动化部署环境所涉及的知识点还是比较多的，虽然我也想将搭建过程详尽道来，但其中细节颇多，很难将其全面覆盖到，所以很多地方我都将参考链接附上，有一些则是官方文档，通过这些链接基本可以完成，但不一定很轻松。当然，如果在搭建过程中遇到问题，可以在 stackoverflow 上搜寻答案，也欢迎大家提问！毕竟----我是一只爱瞎折腾的程序猿^_^～**