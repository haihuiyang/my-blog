### 老生常谈：StringBuilder 和 StringBuffer 的那些事儿

---

> 作为一个老生常谈的话题，相信大家对于 StringBuilder 和 StringBuffer 一定不陌生，因为它们经常出现在面试的题目当中。下面我们就来聊一聊关于 StringBuilder 和 StringBuffer 的那些事儿。

#### 1、为什么会有 StringBuilder 和 StringBuffer ？

首先，我们来看一个字符串拼接的例子：

```java
String result = new String("Hello, ")
        + new String("I ")
        + new String("am ")
        + new String("HappyFeet!");
```

对 JVM 编译优化有过研究的人应该知道，这段代码在编译之后就等价于：

```java
String result = new StringBuilder()
        .append(new String("Hello, "))
        .append(new String("I "))
        .append(new String("am "))
        .append(new String("HappyFeet!"))
        .toString();
```
这是 JVM 的早期编译优化。这样做的目的是什么呢？我们来做一个假设：如果没有 StringBuilder 和 StringBuffer 这两个字符串变量类。

那么，由于 String 对象的不可变性，如果要将两个 String 对象拼接起来应该怎么做呢？我们来看一下 String 类中实现的 `concat` 方法是怎么拼接两个字符串的：

```java
public String concat(String str) {
    int otherLen = str.length();
    if (otherLen == 0) {
        return this;
    }
    int len = value.length;
    char buf[] = Arrays.copyOf(value, len + otherLen);
    str.getChars(buf, len);
    return new String(buf, true);
}
```
我们主要看最后三行：新生成了一个 `buf[]` 数组，然后将两个 String 对象的内容拷贝，最后 `new` 了一个 String 对象。所以，如果想要实现将上面四个 String 对象连接，那么步骤应该是这样子的：

- 第一步：拼接前两个字符串，得到 `middleResult1 = "Hello, I "`；
- 第二步：拼接 `middleResult1` 和下一个字符串，得到 `middleResult2 = "Hello, I am "`；
- 第三步：拼接 `middleResult2` 和 最后一个字符串，得到最终的结果 `"Hello, I am HappyFeet!"`。

看出问题了吗？没错，问题就出在 `middleResult1` 和 `middleResult2` 上。除了最终需要的结果以外，还生成了两个中间结果，在得到了最终结果后它们就变成了无用的垃圾对象；而当这种对象超过一定数量，就会触发 GC，从而对程序性能造成一定的影响。

而 StringBuilder 和 StringBuffer 与 String 的实现不一样，它们是字符串变量，可以直接对内部的字符数组做修改且不产生新的对象，从而有效的避免了上面的问题。

#### 2、它们有什么区别 ？

它们之间最大的区别就是：

- StringBuffer 是**线程安全**的；
- StringBuilder 是**非线程安全**的。

仔细看了一下二者的源码实现，它们都继承自 `AbstractStringBuilder` 这个抽象类，提供的方法也完全相同；与 StringBuilder 相比， StringBuffer 几乎在每个方法签名上都加了 `synchronized` 关键字，做了同步。

如果我们看的再仔细一点，就会发现，其实除了 `synchronized` 关键字之外，还有一个地方也有区别：StringBuffer 中多了一个 `toStringCache` 变量，我们来看看它的作用是什么：

```java
/**
 * A cache of the last value returned by toString. Cleared
 * whenever the StringBuffer is modified.
 */
private transient char[] toStringCache;

@Override
public synchronized StringBuffer append(String str) {
    toStringCache = null;
    super.append(str);
    return this;
}

@Override
public synchronized String toString() {
    if (toStringCache == null) {
        toStringCache = Arrays.copyOfRange(value, 0, count);
    }
    return new String(toStringCache, true);
}
```

从上面这段截取自 StringBuffer 中的代码和注释可以看出，`toStringCache` 是 `toString()` 方法内部的一个缓存，只要一修改 StringBuffer 该值就会被清空。

其实这里我有点不太明白这个变量的用处，为什么不和 StringBuilder 一样通过 `value` 直接 `new` 一个 String 对象出来。下面是 StringBuilder 中的 `toString()` 方法：

```java
@Override
public String toString() {
    // Create a copy, don't share the array
    return new String(value, 0, count);
}
```
假如我们理解这个变量是对调用 `toString()` 方法的一种性能优化，那么大家可以思考一下，这种场景在什么情况下才会出现呢？

我这里暂且先这么理解：为了 StringBuffer 中的 `value` 不被 `new` 出来的 String 所共享，所以将其拷贝一份，即 `toStringCache` ，再将其传给 String 的构造函数。

```java
String(char[] value, boolean share) {
    // assert share : "unshared not supported";
    this.value = value;
}
```

不知这样理解是否正确，欢迎知道的小伙伴们留言讨论。

#### 3、StringBuilder 和 StringBuffer 的适用场景
关于这个问题，可以参考 [JAVA 中的 StringBuilder 和 StringBuffer 适用的场景是什么？](https://www.zhihu.com/question/20101840) 这篇回答，结论是：

**StringBuffer 几乎没有使用场景。**

至于为什么会有 StringBuffer 存在，他也提到了，以下内容摘自上面这篇回答，只是更新了一下排版：

>因为最早是没有 StringBuilder 的，Sun 的人不知处于何种愚蠢的考虑，决定让 StringBuffer 是线程安全的，然后大约 10 年之后，人们终于意识到这是一个多么愚蠢的决定，意识到在这 10 年之中这个愚蠢的决定为 Java 运行速度慢这样的流言贡献了多大的力量，于是，在 JDK 1.5 的时候，终于决定提供一个非线程安全的 StringBuffer 实现，并命名为 StringBuilder。顺便，javac 好像大概也是从这个版本开始，把所有用加号连接的 String 运算都隐式的改写成 StringBuilder，也就是说，从 JDK 1.5 开始，用加号拼接字符串已经没有任何性能损失了。

这里注明一下，`从 JDK 1.5 开始，用加号拼接字符串已经没有任何性能损失了` 仅指在没有循环的情况下。那在有循环的情况下会怎样呢？

在 `阿里巴巴 Java 开发手册.pdf`（2017.2.9 版）中 OOP 规约第 17 点有提到：

```
【推荐】循环体内，字符串的联接方式，使用 StringBuilder 的 append 方法进行扩展。
反例:
        String str = "start";
        for (int i = 0; i < 100; i++) {
            str = str + "hello";
        }
说明：反编译出的字节码文件显示每次循环都会 new 出一个 StringBuilder 对象，然后进行 append 操作，最后通过 toString 方法返回 String 对象，造成内存资源浪费。
```

所以总结起来就是：

- 循环体内，字符串的联接方式，使用 StringBuilder 的 `append` 方法进行扩展。
- **放心的使用 StringBuilder 吧！**
- 如果真的遇到了需要考虑线程安全的情况（几乎不可能出现），就只能用 StringBuffer；

#### 4、一些关于 StringBuilder 和 StringBuffer 的 JMH 测试

这里主要是想通过 JMH 的测试结果来验证一些疑惑。

上一篇（[JMH----微基准测试框架学习笔记](https://blog.csdn.net/haihui_yang/article/details/103467185)）学到的 JMH 终于派上用场了`(*￣︶￣)`。

这里直接展示测试结果，如果需要查看代码，请点击： [StringBuilderVsStringBufferBenchmark](https://github.com/haihuiyang/jmh-study/blob/master/src/main/java/org/openjdk/jmh/custom/StringBuilderVsStringBufferBenchmark.java) 。

##### （1）StringBuilder 和 StringBuffer 对比
```java
# JMH version: 1.22
# VM version: JDK 1.8.0_101, Java HotSpot(TM) 64-Bit Server VM, 25.101-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_101.jdk/Contents/Home/jre/bin/java
# VM options: -Xms1G -Xmx1G
# Warmup: 3 iterations, 10 s each
# Measurement: 5 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Average time, time/op

Benchmark                                           (iterations)  Mode  Cnt       Score       Error  Units
StringBuilderVsStringBufferBenchmark.stringBuffer             10  avgt    5     228.282 ±    85.761  ns/op
StringBuilderVsStringBufferBenchmark.stringBuffer            100  avgt    5    1565.257 ±   416.230  ns/op
StringBuilderVsStringBufferBenchmark.stringBuffer           1000  avgt    5   17355.895 ±  1895.037  ns/op
StringBuilderVsStringBufferBenchmark.stringBuffer          10000  avgt    5  178058.107 ±  9831.287  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder            10  avgt    5     190.816 ±    42.750  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder           100  avgt    5    1494.362 ±   146.519  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder          1000  avgt    5   16635.693 ±  5831.893  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder         10000  avgt    5  164570.802 ± 22688.891  ns/op
```

结论：StringBuilder 是要比 StringBuffer 要快一些的；

原因：很明显，StringBuffer 需要做同步，有额外开销。

##### （2）StringBuilder 初始化大小设置与否对比

```java
# JMH version: 1.22
# VM version: JDK 1.8.0_101, Java HotSpot(TM) 64-Bit Server VM, 25.101-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_101.jdk/Contents/Home/jre/bin/java
# VM options: -Xms1G -Xmx1G
# Warmup: 3 iterations, 10 s each
# Measurement: 5 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Average time, time/op

Benchmark                                                       (iterations)  Mode  Cnt       Score       Error  Units
StringBuilderVsStringBufferBenchmark.stringBuilder                        10  avgt    5     190.188 ±    14.964  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder                       100  avgt    5    1541.160 ±   235.143  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder                      1000  avgt    5   18450.736 ±  8682.940  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder                     10000  avgt    5  196029.270 ± 16398.131  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilderWithCapacity            10  avgt    5     149.941 ±    38.031  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilderWithCapacity           100  avgt    5    1434.880 ±   116.324  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilderWithCapacity          1000  avgt    5   12799.943 ±  2182.352  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilderWithCapacity         10000  avgt    5  127860.395 ±  3243.272  ns/op
```

结论：指定了初始化的大小比未指定要快；

原因：可类比于 ArrayList 中的扩容。

##### （3）StringBuilder  与循环中使用 `"+"` 拼接字符串对比

```java
# JMH version: 1.22
# VM version: JDK 1.8.0_101, Java HotSpot(TM) 64-Bit Server VM, 25.101-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_101.jdk/Contents/Home/jre/bin/java
# VM options: -Xms1G -Xmx1G
# Warmup: 3 iterations, 10 s each
# Measurement: 5 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Average time, time/op

Benchmark                                           (iterations)  Mode  Cnt         Score         Error  Units
StringBuilderVsStringBufferBenchmark.plusInLoop               10  avgt    5       208.727 ±      28.654  ns/op
StringBuilderVsStringBufferBenchmark.plusInLoop              100  avgt    5      7672.408 ±    3089.043  ns/op
StringBuilderVsStringBufferBenchmark.plusInLoop             1000  avgt    5    636063.685 ±   82982.381  ns/op
StringBuilderVsStringBufferBenchmark.plusInLoop            10000  avgt    5  64356519.012 ± 1113442.160  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder            10  avgt    5       203.204 ±      63.713  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder           100  avgt    5      1561.139 ±     770.216  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder          1000  avgt    5     14866.678 ±     378.993  ns/op
StringBuilderVsStringBufferBenchmark.stringBuilder         10000  avgt    5    145933.117 ±    5708.812  ns/op
```

结论：StringBuilder 比循环中使用 `"+"` 要快；且随着数量的增大，优势也愈明显；

原因：反编译出的字节码文件显示每次循环都会 `new` 出一个 StringBuilder 对象，然后进行 `append` 操作，最后通过 `toString` 方法返回 String 对象，造成内存资源浪费。

**知其然知其所以然！**

**不积跬步无以至千里，不积小流无以成江海！加油！**

参考资料：

（1）[StringBuilder and StringBuffer in Java](https://www.baeldung.com/java-string-builder-string-buffer)

（2）[StringBuffer and StringBuilder performance with JMH](http://alblue.bandlem.com/2016/04/jmh-stringbuffer-stringbuilder.html)