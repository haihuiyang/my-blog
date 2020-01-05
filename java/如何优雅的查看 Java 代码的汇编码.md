

汇编码这种东西还是在上编译原理这门课的时候接触的比较多，工作之后几乎就没接触过了。

最近一次接触汇编码是阅读《深入理解 Java 虚拟机》这本书，书中在讲 `volatile` 实现原理的时候提到了汇编码中的 `lock` 指令前缀。

然后这一次在学习 CAS 底层的实现原理也碰到了 `lock` 指令前缀，于是就产生了一个想法： **Java 代码生成的汇编码是什么样子的？如何将 Java 代码与汇编码相对应？**

比如这个类：

```java
package com.yhh.example;

public class VolatileTest {

    private volatile int volatileCount = 0;
    private int count = 0;

    public static void main(String[] args) {

        VolatileTest volatileTest = new VolatileTest();

        volatileTest.increase();
        volatileTest.decrease();

    }

    private void decrease() {
        count--;
    }

    private void increase() {
        volatileCount++;
    }

}
```

它的汇编码是什么样子的呢？（这里仅指这个类或某个方法的汇编码，而不是 JIT 的汇编码，如果需要看 JIT 的汇编码，需要考虑触发 JIT 编译的条件）

下面我们就来学习一下：如何优雅的查看 Java 代码的汇编码

---

### 一、使用 hsdis + IntelliJ IDEA 获取汇编日志

hsdis（HotSpot disassembly） 是 Sun 官方推荐的 HotSpot VM JIT 编译代码的反汇编插件。

#### 1、下载 hsdis-amd64.dylib

下载 [hsdis-amd64.dylib](https://github.com/haihuiyang/summaries/tree/master/lib/hsdis)，将其放在本地的一个目录，例如：`/Users/HappyFeet/tools/hsdis`

#### 2、配置 IntelliJ IDEA 运行参数，获取汇编日志

下面会用到的 `java` 命令参数的解释，参考 [Java Platform, Standard Edition Tools Reference#java](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html)：

- `-XX:+UnlockDiagnosticVMOptions`：解锁用于 JVM 诊断的选项。

- `-XX:+PrintAssembly`：配合反汇编插件（例如 `hsdis-amd64.dylib`）可以打印出字节码和本地方法的汇编码；必须和 `-XX:+UnlockDiagnosticVMOptions` 一起使用。

- `-Xcomp`：在第一次调用时强制编译方法。默认情况下，无论是 `-client` 模式还是 `-server` 模式，都需要执行一定次数解释方法的调用才会触发方法的编译。（如果需要 JIT 日志，则不指定该参数）

- `-XX:CompileCommand=compileonly,*ClassName.methodName`：只编译类名为 `ClassName` 中的 `methodName` 方法，支持使用 `*` 作为通配符。可以多次指定 `-XX:CompileCommand` 添加多条命令。（建议只指定需要的方法，否则将会产生大量的无关日志）

- `-XX:+LogCompilation`：允许将编译活动记录到当前工作目录中名为 `hotspot.log` 的文件中。可以通过 `-XX:LogFile` 指定文件的路径和名字。

- `-XX:LogFile=path`：指定日志的路径和文件名。例如：`-XX:LogFile=/var/log/hotspot.log`

所以，如果只需要编译 `*VolatileTest.increase` 和 `*VolatileTest.decrease` 这两个方法，并且将日志输出到 `/var/log/hotspot.log` 文件中，`VM options` 参数是这样子的：

```java
-XX:+UnlockDiagnosticVMOptions -XX:+PrintAssembly -Xcomp -XX:CompileCommand=compileonly,*VolatileTest.increase -XX:CompileCommand=compileonly,*VolatileTest.decrease -XX:+LogCompilation -XX:LogFile=/var/log/hotspot.log
```

同时需要在 `Environment variables` 添加

```
LD_LIBRARY_PATH=/Users/HappyFeet/tools/hsdis
```

配置如下图所示：

![IEDA 配置](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b69e9cbbb4?w=1992&h=898&f=jpeg&s=235819)

执行 `VolatileTest#main` 函数，然后就可以在 `/var/log` 得到 `hotspot.log` 文件，里面就是汇编日志，包含了代码的汇编码。

```bash
➜  ~ ll /var/log | grep hotspot.log
-rw-r--r--   1 HappyFeet       staff             133K Dec 31 22:32 hotspot.log
➜  ~
```

使用 sublime text 2 打开，大致是这样子的，分别对应于 `increase` 和 `decrease` 方法：

![increase](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b69e980ba3?w=1610&h=368&f=jpeg&s=161490)

![decrease](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6a674ffe9?w=1614&h=384&f=jpeg&s=163676)

直接用 sublime text 2 打开上面的 `hotspot.log` 文件查看汇编码还是挺难受的，那么有没有更优雅的方式呢？

答案当然是有的！这个时候就是 jitwatch 大展神通的时候了。

### 二、通过 jitwatch 工具优雅的查看汇编日志

jitwatch 是 GitHub 上的一个开源项目：[AdoptOpenJDK/jitwatch](https://github.com/AdoptOpenJDK/jitwatch)

一个用于分析汇编日志的图形界面工具，还是挺好用的。

#### 1、jitwatch 安装

（1）clone 项目

`git clone https://github.com/AdoptOpenJDK/jitwatch.git`

（2）编译

- `ant clean compile test run`
- `mvn clean compile test exec:java`
- `gradlew clean build run` 

三种方式任选其一，我第一次用 `gradle` 的方式，然后报了个错。

报错如下：（从报错信息来看，好像是 `gradle` 的版本低了？）

```bash
➜  jitwatch git:(master) gradle clean build run

FAILURE: Build failed with an exception.

* Where:
Script '/Users/HappyFeet/project/jitwatch/ui/build-jdk7.gradle' line: 60

* What went wrong:
A problem occurred evaluating script.
> Cannot change dependencies of configuration ':ui:system' after it has been resolved.

* Try:
Run with --stacktrace option to get the stack trace. Run with --info or --debug option to get more log output. Run with --scan to get full insights.

* Get more help at https://help.gradle.org

Deprecated Gradle features were used in this build, making it incompatible with Gradle 5.0.
Use '--warning-mode all' to show the individual deprecation warnings.
See https://docs.gradle.org/4.10.3/userguide/command_line_interface.html#sec:command_line_warnings

BUILD FAILED in 1m 42s
```

后来我换成了 `mvn` 的方式，就成功了，所以也就没有去解决这个错误。。。

成功之后会自动弹出这样一个界面，恭喜你，可以开始耍 jitwatch 了。

![jitwatch-1](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6a36dd76f?w=2046&h=1154&f=jpeg&s=192696)

（3）启动

之后每次在 jitwatch 项目下直接执行 `sh launchUI.sh` 启动 jitwatch。

#### 2、配置 jitwatch 分析 `hotspot.log` 文件

（1）配置生成 `hotspot.log` 日志的 java 文件所在的 `src` 文件目录和 `class` 文件目录

![jitwatch 配置](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6a130e194?w=2048&h=1144&f=jpeg&s=384421)

（2）配置完成之后，点击 Open Log 按钮，选中 `hotspot.log` 文件，然后点击 Start 按钮，如果配置正确的话，会得到如下结果：

![jitwatch 成功-1](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6a73d5752?w=2048&h=1144&f=jpeg&s=342198)

点击 increase() ，就可以看到

![jitwatch 成功-2](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6da8a0b85?w=2048&h=1144&f=jpeg&s=534910)

 左边是 Java 代码，中间是字节码，最右边是汇编码，这样看起来就方便多了。

#### 3、使用 jitwatch Sandbox 分析 JIT 汇编码

Sandbox 里面有一个样例：`SimpleInliningTest`，可以直接点击 Run 运行。

Sandbox 的作用呢就是直接运行代码里面的 main 函数，然后根据代码的执行情况会生成 JIT 日志，执行完成之后可以分析这个过程中的 JIT 日志。需要注意的是：这里必须达到了 JIT 的条件才会生成 JIT compile log，例如达到一定的调用次数。

我个人觉得 Sandbox 不是很好用。有以下几个原因：

- VM options 不可配（或许是我没找到配置的地方）
- 有时候存在问题：`Assembly not found. Was -XX:+PrintAssembly option used?`
- 必须满足 JIT 的条件才会有 JIT compile log

其实最主要的问题是第二点。

而使用 IntelliJ IDEA 生成的汇编日志可以完美避过上面这几个问题。

##### 结语：学个 CAS 底层实现原理（[CAS 底层原理学习之我是如何从 Java 源码看到 openjdk 源码再到汇编码、intel 手册的](https://blog.csdn.net/haihui_yang/article/details/103739482)），竟然还能扯到汇编，我也是挺佩服自己的！

##### 最后放两张图，展示有 volatile 修饰和普通变量赋值的区别：

![volatile putfield](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6e60936c9?w=1436&h=878&f=png&s=330296)

![non volatile putfield](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6e04e3e62?w=1436&h=878&f=png&s=318338)

```
0x000000010fea8c14: lock addl $0x0,(%rsp)  ;*putfield volatileCount
                                           ; - com.yhh.example.VolatileTest::increase@7 (line 22)
```

可以对比得出，volatile 修饰的变量确实会多一个 `lock addl $0x0,(%rsp)` 指令。

参考资料：

（1）[Java Platform, Standard Edition Tools Reference#java](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/java.html)

（2）[mac下使用JITWatch查看JDK1.8汇编代码](https://www.iteye.com/blog/yunjiechao-163-com-2386423)

（3）[学会一个JVM插件：使用HSDIS反汇编JIT生成的代码](https://cloud.tencent.com/developer/article/1082675)

（4）[利用hsdis和JITWatch查看分析HotSpot JIT compiler生成的汇编代码](https://blog.csdn.net/hengyunabc/article/details/26898657)

（5）[HotSpot profiling with JITWatch](https://www.chrisnewland.com/images/jitwatch/HotSpot_Profiling_Using_JITWatch.pdf)