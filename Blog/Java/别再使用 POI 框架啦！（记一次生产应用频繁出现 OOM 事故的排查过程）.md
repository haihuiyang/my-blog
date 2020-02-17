> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

**真的不要再用 POI 了！！！**

---

#### 1、简要回顾

前段时间生产环境上的应用频繁 Crash。经过一番努力排查，我发现在使用 POI 框架读取 Excel 数据的时候产生了大量的 POI 对象，导致应用内存占用急剧增加，并且这些 POI 对象在处理完 Excel 之后也没有被正确回收，导致内存泄漏，最终应用因为 OOM 而 Crash 掉。

生产环境配置：

- 应用服务器内存大小：8G
- 使用 Docker 镜像运行的 Java 应用程序，Java 堆配置：`-Xms2G -Xmx6G`

解决方案：使用阿里开源的 [easyexcel](https://github.com/alibaba/easyexcel) 框架将 POI 替换掉。

#### 2、事情始末

##### （1）第一次交锋

在一个周五的下午，用户反馈说系统貌似挂了。。。

没错！就是周五的下午，就在我准备下班开始过快乐周末的时候，此时的心情：

![哭](https://img-blog.csdnimg.cn/20191224222532665.jpeg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

通过跳板机登录到应用服务器上确认应用状态：发现确实挂掉了。

将应用日志拎出来一看，发现在应用 Crash 的时候只有几个连接数据库的 WARN，并没有抛异常：

![系统 Crash - 1](https://img-blog.csdnimg.cn/20191224223853309.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

继续往上找，发现有一个 ERROR：

```java
ERROR | 2019-11-29 14:26:18:152 | [XNIO-3 task-27] api.LoggingExceptionHandler (LoggingExceptionHandler.java:80) - UT005023: Exception handling request to /someUrl
java.lang.IllegalStateException: io.undertow.server.RequestTooBigException: UT000020: Connection terminated as request was larger than 20971520
```
这是 servlet 在处理 HTTP 请求时报的错误，因为我们限制了上传文件的大小为 20M，所以这个地方是一个正常报错。

接着往上找，发现也有几个和上面日志一样的错误，所以这个地方应该是用户尝试上传了好几次，并且都上传失败了，所以也不是这个地方的问题。后面也没发现什么明显的 ERROR 或异常。同时我们运维人员发现在应用服务器上面的执行命令中存在 `kill -i` 的记录。

针对这样的情况，初步做了推测：

1. 有可能是人为因素将应用 `kill` 掉了；
2. 也有可能是内存溢出导致应用 Crash。

这里解释一下做出这样推断的原因：

- 应用日志突然没了，也没有任何报错，应用程序就挂掉了。我在本地进行了测试，在本地启动应用的过程中将对应的进程 `kill` 掉，其日志表现和应用日志极为相似；
- 猜测应用突然 Crash 有可能是 OOM，因为之前也出现过 OOM，但是具体报了 `OutOfMemoryError` 的错误。其实当时我比较困惑，一般 OOM 会有异常信息，例如像 `java.lang.OutOfMemoryError: Java heap space` 这种，而像什么都不报直接 Crash 还是比较少见，所以这也仅是我的一个猜测。因为也没有 GC 日志可看，这其实是我们本身配置上的一个失误：我们是用 Docker 起的应用，在启动的时候确实配了 GC 日志，问题在于没有把这个 GC 日志目录映射出来，所以在应用重启的时候 GC 日志也就没了。。。

根据上面初步推测的结果，做了两件事情：

1. 确认应用是否真的是人为 `kill` 掉的；（后面事实证明应用并不是被人为 `kill` 的）
2. 完善 GC 日志配置，并且多加了一些 JVM 的配置，使其能在 `OutOfMemoryError` 时把堆的内存快照 dump 下来。

添加的 JVM 参数如下：

```java
-XX:+UseG1GC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+PrintGCCause -Xloggc:/var/log/gc_%p_%t.log -XX:+UseGCLogFileRotation -XX:GCLogFileSize=2M -XX:ErrorFile=/tmp/jvm/hs_err_pid_%p.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dumpFilePath
```

##### （2）再次相遇

又一个周五的下午！用户来反馈说系统又挂了。。。

没错！你绝对没听错！又是周五。。。

![哭-2](https://img-blog.csdnimg.cn/2019122500080769.jpeg)

虽然挺委屈的，但事还是得做的嘛。而且心里想着上次加的 JVM 的配置，这次怎么着也得把这个问题找到！

然而结果挺让人意外的，应用日志表现和上次一模一样！一模一样！而且，新加的 `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dumpFilePath` 这个参数好像也没起作用，并没有在对应的目录找到堆的内存快照！（这里可以思考一下为什么会没有内存快照）

![服务 Crash-2](https://img-blog.csdnimg.cn/20191225001036982.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

不过好在这次是有 GC 日志的。

![GC 日志 - 1](https://img-blog.csdnimg.cn/20191225002410182.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

从这个 GC 日志来看，应该是有问题的，因为我们应用的堆大小配置为：`-Xms2G -Xmx6G`。

将 GC 日志检查了一遍，如图：

![频繁 GC](https://img-blog.csdnimg.cn/20191225222525915.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

很显然，这个 GC 有问题！不到 6s 钟，堆内存从 2376.0M 扩大到了 5358.0M，后续也没有降下来，直到程序 Crash。

所以猜测可能存在内存泄漏问题。

于是就让运维同事写了一个脚本，**定时监控应用的内存使用情况**。

同时我也开始**检查在 GC 时间点的用户行为**。根据每一次 GC 的时间，去应用日志里面找对应时间点的日志，看看这些时间点用户都做了些什么操作。

经过检查发现在每次 GC 附近用户都有上传 Excel，应用把 Excel 数据保存在服务器之后，会去读取 Excel 的数据。于是我就思考，会不会是这些 Excel 搞的鬼？

有了这个想法之后，立马让运维同事将其中的一个 Excel 下载下来，这个 Excel 大小为 17M 多。

拿到 Excel 之后，我在本地写了一个测试循环多次去读取这个 Excel 的数据，同时使用 JProfile 查看其内存使用情况，结果如下：

![GC 详情 - 1](https://img-blog.csdnimg.cn/20191225211656477.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)	

**仅读取一个 17M 的 Excel 内存直接就花去了将近 4 个 G！** 由于测试配置最大堆内存为 4 G，所以从上图也可以看出在不断的 GC。这是我起在本地的一个测试，除了读取 Excel 之外其他什么都没做。

这里对这个 Excel 的数据做一个说明：

- 大小：17M 多一点；
- 总共两个 Sheet；第一个 Sheet 大概 500 多行数据，列数大概在 30-40 之间；第二个 Sheet 的数据量和第一个 Sheet 差不多，但是里面存在公式；

其实代码里面只用到了第一个 Sheet 的数据。于是就想着把这些无用的数据删了试一试，然后现象比较诡异：

- 删除第二个 Sheet，Excel 大小变成了 11M 多，大概减小了 5M 多；（读这个删减版的 Excel 的内存比原来要小一点点，但是并没有减小太多）
- 接着把第一个 Sheet 的数据做了删减，发现将数据删减到只剩 2-3 行，Excel 的大小并没有变化，太奇怪了！

好吧，有点扯远了！回归正题。

前面讲到了猜测可能存在内存泄漏问题，并且定时监控应用的内存使用情况。这里我们采用的是比较简单的方式：**定时脚本，每半小时执行 `jmap -histo pid`，并将结果输出到指定文件中**。在检查文件的时候，发现了 POI 存在内存泄漏：

![内存泄漏 - 1](https://img-blog.csdnimg.cn/20191226221745519.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

![内存泄漏 - 2](https://img-blog.csdnimg.cn/20191226221825897.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

如图，第一张图是 13:30:26 时刻应用的内存使用情况，第二张图是 14:30:26 时刻应用的内存使用情况。同时，检查了应用的日志，发现用户在 13:03:22 上传了一个 Excel，在处理完 Excel 的数据之后，按理来说这些 POI 对象应该会被 GC 回收的，然而事实是这些 POI 对象一直到 14:30:26 都没有被回收，然后 14:42:08 的时候服务 Crash。

这就是导致应用频繁 Crash 的罪魁祸首。然后查了一下，结果一大堆：

![POI 内存泄漏？](https://img-blog.csdnimg.cn/20191226230150193.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

只是没明白的是：使用 POI 框架很容易内存溢出，为什么还会有这么多的人在用它？

![apache poi](https://img-blog.csdnimg.cn/20191226231651725.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

##### （3）终于解决

找到问题根源所在之后就好解决了，搜了一下读取 Excel 的工具，最终我们决定换成阿里开源的 [easyexcel](https://github.com/alibaba/easyexcel) 框架：

![alibaba easyexcel](https://img-blog.csdnimg.cn/20191226231404261.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

换成了 easyexcel 框架之后，使用 JProfile 测试了一下内存使用情况，同样处理上面提到的 17M 的 Excel ，结果如图：

![easyexcel 内存使用情况](https://img-blog.csdnimg.cn/20191226232228540.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

很明显，看上去比 POI 要好太多了，GC 频次明显降低，并且内存占用也大大降低。

最终，问题解决了。

![开心的像个三百斤的胖子](https://img-blog.csdnimg.cn/20191226232744738.jpeg)

#### 3、总结原因

文中还遗留了一些问题：

- 为什么配置了 `-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dumpFilePath` 却没有 dump 内存快照？
- 为什么程序 Crash 却没有任何异常日志？

这里可以从应用服务器的内存使用情况的方向进行思考，本文不再深入探讨。

下面来总结一下从这次经历中吸取到的教训：

1. 启动 Java 应用程序应该记录 GC 日志，并将其输出到指定目录；如果使用 Docker 执行，记得将日志目录映射到宿主机；例如：

	```java
	-XX:+UseG1GC -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps -XX:+PrintGCCause -Xloggc:/var/log/gc_%p_%t.log -XX:+UseGCLogFileRotation -XX:GCLogFileSize=2M -XX:ErrorFile=/tmp/jvm/hs_err_pid_%p.log -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/dumpFilePath
	```

2. 应在代码中的关键步骤打一些日志，便于线上问题的排查；
3. 不要以为大家都在使用的开源框架就是完美的，它们也有可能存在 BUG；
4. 书到用时方恨少，事非经过不知难；之前在 18 年年中的时候啃过《深入理解 Java 虚拟机》这本书，在解决这次 OOM 的问题时，还是有很多地方不太熟悉，尚需要翻看书籍做一些参考。

**最后，写给自己的话，也送给大家：每天再忙也应该给自己留点成长的时间！**

**全文完，希望能对大家有所帮助！**