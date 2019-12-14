




### JMH----微基准测试框架学习笔记

---

#### 一、学习背景

最近想对比一下 `StringBuilder` 和 `StringBuffer` 二者在性能上的差异。

如何对比呢，当然是看在相同的情况下，执行相同的操作，哪一个效率更高，然后就想到了使用 JMH 来做一个基准测试。

其实 oracle 早在 13 年就发布了 JMH 的第一个版本。那时我高中毕业，刚刚进入大学，很难接触到 JMH，真正开始接触 JMH 是在工作之后。

我记得当时的情况是：项目中的某一个功能需要查询大量的数据，并且数据存在一定的规律性；由于数据量比较大，查询耗时长，从而导致应用异常缓慢。后面公司招进来一位大佬，对这种情况进行了优化。大致就是将时间序列的数据经过编码存成文件，在启动时将文件数据加载进内存；为了减小内存消耗，所以加载进内存的不是 java 对象，而是 `byteArray`，在实际使用时才会解码成 java 对象。

那么问题来了，操作 `byteArray` 的 `Buffer` 类有很多，到底用哪一种好呢？（由于对性能的要求较高，所以这里需要选择性能最好的一个）

大佬给的答案是：实际测试一下，对比测试结果，选性能最好的。然后就用到了 JMH 。

看过同事写的 JMH 测试代码之后，才是我真正意义上接触 JMH。不过当时对 JMH 只是粗略的了解了一下，并没有深入的学习，仅仅停留在 “ JMH 是一个代码性能测试工具，它可以用来测量具有相同效果的不同方法之间的性能差异”。

趁着这次机会，准备对 JMH 做一个系统的学习。

#### 二、JMH 是什么？

[JMH](https://openjdk.java.net/projects/code-tools/jmh/)（Java Microbenchmark Harness） 是 oracle 官方开发的一个微基准测试框架，可以精确到毫秒级别。

#### 三、它能做什么？

可以对代码进行基准测试。

比如：

- java 中实现循环有多种方式：`for`、`while`、`foreach`、`iterator`，哪一种方式效率更高？
- `StringBuilder` 和 `StringBuffer` 哪一种性能更高？
- `for` 循环和 java 8 的 `stream()` 之间的性能比较

使用 JMH 一测便知。

当然，我们这里讨论的都是针对小的、方法级别上的性能测试，而对于接口、应用层面上来说，JMH 并不适合。

#### 四、如何执行？

运行 JMH 程序主要有两种方式：

1. **生成 jar 执行**

2. **通过 IDE 直接执行**

第一种方式只需要三步：

- 通过命令创建 `maven` 项目：

```maven
$ mvn archetype:generate \
          -DinteractiveMode=false \
          -DarchetypeGroupId=org.openjdk.jmh \
          -DarchetypeArtifactId=jmh-java-benchmark-archetype \
          -DgroupId=org.sample \
          -DartifactId=test \
          -Dversion=1.0
```

其中 `groupId` 和 `artifactId` 可以改成自己常用的，通过上面命令创建的 `maven` 项目依赖的版本有点老，可以通过修改 `pom.xml` 来调整 JMH 相关依赖以及 java 版本。

- 构建 jar 包

```bash
$ cd test/
$ mvn clean install
```

- 执行 jar 包：`benchmarks.jar` （根据第一步的命令创建的 `maven` 项目中的名字其实是这个：`microbenchmarks.jar` ）

```bash
$ java -jar target/benchmarks.jar
```
> 也可以通过执行 `java -jar target/benchmarks.jar -h` 查看帮助以及支持的一些配置参数；
> 
> 或者 `java -jar target/benchmarks.jar ClassName` 执行指定的类。


第二种方式：

- 在 IDE 创建一个用于测量的类（跟创建 JUnit Test 很像），编写基准测试代码，执行。


两种方式都很简单。

官方推荐使用第一种方式，原因是直接执行 jar 包可以确保正确初始化基准并产生可靠的结果。而在现有项目或 IDE 中执行会使得基准的初始化变得更加复杂，结果的可靠性也较低。

至于到底使用哪种方式，看情况（主要还是看你对**结果可靠性**的要求）：

> 对于只是想知道一个大概的性能比较，直接在 IDE 上跑没什么问题；但是如果是想要知道极为精确的性能比较，那么，构建一个 jar 包放到服务器上跑结果会更可靠。


#### 五、如何写 JMH 基准测试？

oracle 本身并没有提供一个 JMH 的使用手册，不过好在它有很多 JMH 的[样例代码](https://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)，列举了如何写好 JMH 代码。

我们来看一个最简单的 JMH 代码，该代码来自 JMH 的 [第一个样例代码](https://hg.openjdk.java.net/code-tools/jmh/file/c8f9f5b85cd9/jmh-samples/src/main/java/org/openjdk/jmh/samples/JMHSample_01_HelloWorld.java)：

```java
public class JMHSample_01_HelloWorld {

    @Benchmark
    public void wellHelloThere() {
        // this method was intentionally left blank.
    }

    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(JMHSample_01_HelloWorld.class.getSimpleName())
                .forks(1)
                .build();

        new Runner(opt).run();
    }

}
```

非常简单，在方法上面加一个 `@Benchmark` 注解即可，然后执行 `main` 函数，即可得到基准测试的结果。

看完了所有的样例代码之后，就能知道，其实 JMH 主要是通过注解的方式来配置参数的，非常便捷。熟悉了 JMH 注解的用法，也就学会了 JMH。不过，记得一定把样例代码看完，里面讲到了写 JMH 的时候需要注意的点。下面我们先来看一看 JMH 注解的用法。


#### 六、注解是怎么用的？

先来对所有的样例代码有一个概览：

![JMH 样例代码](https://img-blog.csdnimg.cn/20191213003121512.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

上面的这些代码是 JMH 官方提供的样例代码，我把它们导到本地还费了一番功夫。我用的是蛮力 `o(╥﹏╥)o`  ：由于不知道怎么把 JMH 的样例代码从 openJDK 上 fork 下来，所以就只有一个个的拷贝（ 厉害的 VC 大法 ），然后在拷贝的过程中发现 14 和 19 这两个文件没有，一开始还以为是我漏掉了，后来发现确实没有这两个文件，可能是中间某些版本的时候删除了吧。

前面的几个样例代码展示了 JMH 常用注解的用法。紧接着讲了在写基准测试时需要注意的一些地方，然后就是在不同情况下的用例。

这里先来看一下 JMH 的参数是如何配置的：

- 在 `class` 上添加注解；
- 在 `method` 上添加注解；
- 通过 `main` 函数中构建 `Options` 进行配置。

这三个地方配置的优先级为 `低 -> 到`，优先级低的会被优先级高的`覆盖`。其中方法上的注解只影响一个方法，其余两个都是影响测试类中的所有方法。我们来看一个例子：

```java
@BenchmarkMode(Mode.AverageTime)
public class JMHSample_01_HelloWorld {

    @Benchmark
    @BenchmarkMode(Mode.SampleTime)
    public void wellHelloThere() {
        // this method was intentionally left blank.
    }

    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(JMHSample_01_HelloWorld.class.getSimpleName())
                .forks(1)
                .mode(Mode.Throughput)
                .build();

        new Runner(opt).run();
    }

}
```

如上图，在类上面配置了 `@BenchmarkMode(Mode.AverageTime)`，在方法名上配置了 `@BenchmarkMode(Mode.SampleTime)`，最后在 `Options` 中也配置了 `.mode(Mode.Throughput)`，我们来看看输出是什么：

```java
# JMH version: 1.22
# VM version: JDK 1.8.0_101, Java HotSpot(TM) 64-Bit Server VM, 25.101-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_101.jdk/Contents/Home/jre/bin/java
# VM options: -javaagent:/Applications/IntelliJ IDEA.app/Contents/lib/idea_rt.jar=54436:/Applications/IntelliJ IDEA.app/Contents/bin -Dfile.encoding=UTF-8
# Warmup: 5 iterations, 10 s each
# Measurement: 5 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Throughput, ops/time
# Benchmark: org.openjdk.jmh.samples.JMHSample_01_HelloWorld.wellHelloThere
```

关键在这一句：`# Benchmark mode: Throughput, ops/time` 

可以看出，最终生效的是 `Options` 中配置的值。

知道了配置的优先级之后，我们先看一个完整的例子：

```java
@OutputTimeUnit(TimeUnit.MILLISECONDS)
@Fork(value = 1, jvmArgs = {"-Xms1G", "-Xmx1G"})
@Warmup(iterations = 3)
@Measurement(iterations = 5)
public class StringBuilderVsStringBufferBenchmark {

    public static void main(String[] args) throws RunnerException {
        Options opt = new OptionsBuilder()
                .include(StringBuilderVsStringBufferBenchmark.class.getSimpleName())
                .build();

        new Runner(opt).run();
    }

    @Benchmark
    public String stringBuilder(MyState state) {
        StringBuilder sb = new StringBuilder(state.initial);
        for (int i = 0; i < state.iterations; i++) {
            sb.append(state.suffix);
        }
        return sb.toString();
    }

    @Benchmark
    public String stringBuffer(MyState state) {
        StringBuffer sb = new StringBuffer(state.initial);
        for (int i = 0; i < state.iterations; i++) {
            sb.append(state.suffix);
        }
        return sb.toString();
    }

    @State(Scope.Benchmark)
    public static class MyState {
        int iterations = 10;
        String initial = "abc";
        String suffix = "def";
    }

}
```

这里面出现了很多注解，下面我们来看一看每个注解的作用（包含了没有出现在例子中的注解）：

##### 1、`@Benchmark`

只有被这个注解标记的方法才会参与基准测试，并且有一个前提，就是被 `@Benchmark` 标记的方法必须是 `public` 的。一旦被这个注解标注，JMH 就会在编译的时候生成一个与这个方法相对应的类，对应生成的类名格式为 `className_methodName_jmhTest`，可以在 `projectRelativePath/target/generated-sources/annotations` 目录下找到。

举个栗子，类名为 `BenchmarkTest` 下有一个方法 `measure` 上标注了 `@Benchmark` 注解，则其对应 JMH 生成的类名为 `BenchmarkTest_measure_jmhTest`。

#####  2、`@BenchmarkMode`

基准测试的模式，一般来说，根据测量的维度来选择模式：

- `Mode.Throughput`：吞吐量模式，固定时间内方法执行的次数 ( ops/time )；
- `Mode.AverageTime`：平均执行时间 ( time/op )，实际上就是吞吐量的倒数；
- `Mode.SampleTime`：对一段时间的调用结果做随机取样，输出取样结果的分布；
- `Mode.SingleShotTime`：单次执行时间；在这种模式下，迭代时间是没有意义的，因为测试方法执行结束后，迭代就结束了；往往同时把 `warmup` 的次数设为 0，用于冷启动性能测试；
- `{Mode.Throughput, Mode.AverageTime}`：多个模式同时进行；
- `Mode.All`：所有模式同时进行。

#####  3、`@Warmup`

`@Warmup` 用来配置预热的内容，可用于类或者方法上。一般配置 `warmup` 的参数有这些：

- iterations：预热的次数。iteration 是 JMH 进行测试的最小单位。在大部分模式下，一次 iteration 代表的是一秒。

- time：每次预热的时间。

- timeUnit：时间单位，默认是s。

- batchSize：批处理大小，每次操作调用几次方法

#####  4、`@OutputTimeUnit`

输出结果所使用的单位，值是 `j.u.c` 包下的 `TimeUnit` 类，可以支持 `TimeUnit.SECONDS`，`TimeUnit.MICROSECONDS` 等等。

#####  5、`@State`

很多时候我们需要维护一些具有状态的属性，比如在多线程的时候维护一个共享状态。这个状态可能在每个线程中都一样，也有可能是每个线程有自己的状态，JMH 为我们提供了这种支持。该注解只能用在类上面，因为类被作为了共享状态的载体。`@State` 的值状态值一共有以下几种：

- `Scope.Benchmark`：状态在所有的 benchmark 线程中所共享；
- `Scope.Thread`：线程独有状态；
- `Scope.Group`：状态在相同的 `group` 中共享。

#####  6、`@Setup`、`@TearDown`

执行基准测试前的准备工作和结束后的收尾工作（基准测试结果不包含这一部分时间）。这里总共有三种级别，可以按需使用：

* `Level.Trial`: 在整个基准测试（the entire benchmark）之前执行 `@Setup` 标注的代码，在基准测试执行完成之后执行 `@TearDown` 标注的代码；主要是数据的准备和资源的释放工作。
* `Level.Iteration`: 在每次迭代（the benchmark iteration）前后执行。
* `Level.Invocation`; 在每次方法调用（the benchmark method invocation）前后执行。注意，这里样例代码的注释中标出了 `WARNING`，提醒使用者在使用前先读一下 java 文档，确认测试方式是正确的。

	> WARNING: HERE BE DRAGONS! THIS IS A SHARP TOOL.
	MAKE SURE YOU UNDERSTAND THE REASONING AND THE IMPLICATIONS OF THE WARNINGS BELOW BEFORE EVEN CONSIDERING USING THIS LEVEL.

#####  7、`@Param`

在某些情况下，我们想测试一个方法在不同的参数下的性能对比（纵向对比），如果我们编写多个 benchmark 的方法，就会造成代码逻辑的冗余。而有了 `@Param` 注解后，就解决了这个问题。

`@Param` 只能用在非 `final` 的字段上，用以指定某项参数的多种情况，并且需要与 `@State` 配套使用。

```java
@Param(value = {"10", "1000", "10000"})
private int size;
```

的结果是这样子的：

```java
Benchmark                     (size)  Mode  Cnt   Score    Error  Units
Benchmark.stringBufferAppend      10  avgt    4  ≈ 10⁻⁴           ms/op
Benchmark.stringBufferAppend    1000  avgt    4   0.022 ±  0.043  ms/op
Benchmark.stringBufferAppend   10000  avgt    4   0.218 ±  0.009  ms/op
```


#####  8、`@Fork`

进行 fork 的次数。可用于类或者方法上，并且可以配置 fork 时的 jvm 参数，例如：如果 fork 数是 2 的话，则基准测试在两个 fork 上进行，每一个 fork 所配置的参数都是一样的，最后合并结果并统计。

#####  9、`@Measurement`

用于配置实际调用方法的一些基本测试参数。可用于类或者方法上。参数和 `@Warmup` 一样

#####  10、`@Threads`

用于类或方法上，代表执行基准测试的线程数量。

#####  11、`@Group`、`@GroupThreads`

`@Group` 注解可以将多个方法归为一组；而 `@GroupThreads` 则定义了组内有多少线程来运行基准方法。

#####  12、`@CompilerControl`

该注解用于控制方法的编译过程，总共有六种模式，有三种模式需要关注一下：

- EXCLUDE：禁止编译方法
- INLINE：强制使用内联
- DONT_INLINE：禁止使用内联

#####  13、`@OperationsPerInvocation`

这个注解的作用是，每调用一次方法算多少次操作（`一次方法调用 = n 次操作，n 可配置`）。例如：

```java
@Benchmark
@OperationsPerInvocation(10)
public void test() {
    for (int i = 0; i <= 10; i++) {
        // do something
    }
}
```
例如这样，调用一次 `test()` 方法，当成是 10 次操作。


#### 七、JMH 中存在的陷阱？

讲之前，我们先来回顾一下 JVM 的一些知识：

> 当虚拟机发现某个方法或代码块的运行特别频繁时，就会把这些代码认定为 “热点代码”（Hot Spot Code）。为了提高热点代码的执行效率，在运行时，虚拟机将会把这些代码编译成与本地平台相关的机器码，并进行各种层次的优化，这就是 JVM 的即时编译（JIT）。比如：常量折叠、循环展开、内联和无用代码消除等等。

没错，正是由于 JIT 的存在，使得有些基准测试结果不准确。原因是经过 JIT 优化之后，实际运行中的代码可能和之前编写的代码已经有了很大的区别。

除了 JIT 导致的一些陷阱之外，还有其他的一些因素，可以参考这边博文：[JMH 与 8 个测试陷阱](https://www.cnkirito.moe/java-jmh/)

#### 八、几个例子（均可在 [jmh-study](https://github.com/haihuiyang/jmh-study) 中找到源码）

##### 1、`ArrayList` 和 `HashSet` 的 `contains` 所花费的时间对比

代码中出现的 `ArrayList` 和 `HashSet` 为 1 ~ 10000 连续的自然数，将其乱序。然后从里面查找了 `"-1", "300", "3000", "9999", "111111"` 这几个值（随便选的几个数），结果如下：

```java
# JMH version: 1.22
# VM version: JDK 1.8.0_101, Java HotSpot(TM) 64-Bit Server VM, 25.101-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_101.jdk/Contents/Home/jre/bin/java
# VM options: -Xms1G -Xmx1G
# Warmup: 3 iterations, 10 s each
# Measurement: 8 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Average time, time/op

Benchmark                                              (value)  Mode  Cnt      Score     Error  Units
ArrayListVsHashSetContainsBenchmark.arrayListContains       -1  avgt    8  10795.501 ± 136.991  ns/op
ArrayListVsHashSetContainsBenchmark.arrayListContains      300  avgt    8   9422.179 ± 105.861  ns/op
ArrayListVsHashSetContainsBenchmark.arrayListContains     3000  avgt    8   6678.929 ±  83.924  ns/op
ArrayListVsHashSetContainsBenchmark.arrayListContains     9999  avgt    8   9228.611 ± 128.557  ns/op
ArrayListVsHashSetContainsBenchmark.arrayListContains   111111  avgt    8  10975.917 ± 741.760  ns/op
ArrayListVsHashSetContainsBenchmark.hashSetContains         -1  avgt    8      5.722 ±   0.052  ns/op
ArrayListVsHashSetContainsBenchmark.hashSetContains        300  avgt    8      8.043 ±   0.075  ns/op
ArrayListVsHashSetContainsBenchmark.hashSetContains       3000  avgt    8      8.113 ±   0.577  ns/op
ArrayListVsHashSetContainsBenchmark.hashSetContains       9999  avgt    8      8.018 ±   0.140  ns/op
ArrayListVsHashSetContainsBenchmark.hashSetContains     111111  avgt    8      6.611 ±   0.112  ns/op
```

解释一下为什么要做这个基准测试：这里对比的是长度 10000 的数量下 O(n) 和 O(1) 的时间复杂度的区别，其实不做基准测试也能知道，肯定是 O(1) 的快于 O(n) 的。不过我这里想知道的是到底快了多少，我这里对比的是 10000 的数量下两者的性能对比，我也可以对比 10、100、1000 或者 1000000 数量下会快多少。平时在做 `Code Review` 的时候，时不时就看到一些地方使用 `ArrayList` 这种数据结构，然而在只是拿它去做 `contains` 判断某个元素是否在集合里面。看到这种我一般会提出建议使用 `HashSet`，不过一些人觉得由于数量不大，所以使用或者不使用 `HashSet` 应该区别不大。这个测试就是为了验证一下这个说法。（这里只展示了长度为 10000 下的性能对比，实际上我按照各个不同的数量级都进行了测试）

##### 2、`StringBuilder` 和 `StringBuffer` 做字符串的连接，二者性能上的差异

```java
# JMH version: 1.22
# VM version: JDK 1.8.0_101, Java HotSpot(TM) 64-Bit Server VM, 25.101-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_101.jdk/Contents/Home/jre/bin/java
# VM options: -Xms1G -Xmx1G
# Warmup: 3 iterations, 10 s each
# Measurement: 5 iterations, 10 s each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Throughput, ops/time

Benchmark                                           (iterations)   Mode  Cnt     Score     Error   Units
StringBuilderVsStringBufferBenchmark.stringBuffer             10  thrpt    5  7234.182 ± 277.858  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuffer            100  thrpt    5   863.752 ±  31.024  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuffer           1000  thrpt    5    69.709 ±   0.952  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuffer          10000  thrpt    5     6.431 ±   0.082  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuilder            10  thrpt    5  8150.492 ± 252.214  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuilder           100  thrpt    5   768.255 ± 249.520  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuilder          1000  thrpt    5    67.138 ±   2.608  ops/ms
StringBuilderVsStringBufferBenchmark.stringBuilder         10000  thrpt    5     7.227 ±   0.192  ops/ms
```



##### 3、 for 循环和 Java 8 的 stream() 对比

参考 github 上的这篇文章：[Stream Performance](https://github.com/CarpenterLee/JavaLambdaInternals/blob/master/8-Stream%20Performance.md)

#### 九、总结

> 1、用数据说话（show me the data）：方法性能孰优孰劣，不是谁谁谁说了算，而是通过一系列的测试结果分析得到。
> 
> 2、具体情况具体分析：JMH 测试出来的结果仅仅只是提供一个参考，在实际生产环境运行中的性能可能会有所差异，因为实际的运行环境有太多不可控的因素，很难和测试的基准一样。
> 
> 3、**Be Attention**：在写 JMH 的时后注意避免出现[样例代码](https://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)中例举的错误方式。例如：Loop Optimizations，Dead Code Elimination，Constant Folding，还有一些缓存命中、分支预测等，包含但不限于这些。

写到最后发现，我去，居然写了这么长。平时上班基本没有太多的时间来写博客，只有在每天下班后的空余时间学一点点写一点点，就这样，花了将近一周多的时间，把它完成了。由于是学一点点，写一点点，遇到不懂的再去补学，然后在补充进来，所以可能有很多地方写的很死板，就像记笔记似的。

原本是想写 `StringBuilder` 和 `StringBuffer` 的区别，然后准备用 JMH 测试一下两者的性能上的差异来证实一个理论上的结果，然后就发现好像对于 JMH 不是很熟，所以就趁这个机会补一下 JMH 相关的知识，于是有了这篇文章。

写的过程中又温习了一下 JVM 的一些知识，另外一些关于性能上的疑惑也都解决了（例如：` parallelStream() 到底比 stream() 要快多少？`、`stream() 和 for 迭代之间性能如何如何？`、`做一次加法操作需要多少 ns？`），总体来说收获颇多。


**最后给自己点个赞，鼓励一下自己，能够放弃了看小说、看视频、玩游戏的时间来学习，嗯，你是最胖的！**


参考资料：

（1）[Code Tools: jmh](https://openjdk.java.net/projects/code-tools/jmh/)

（2）[JMH Samples](https://hg.openjdk.java.net/code-tools/jmh/file/tip/jmh-samples/src/main/java/org/openjdk/jmh/samples/)

（3）[Performance measurement with JMH – Java Microbenchmark Harness](https://blog.codecentric.de/en/2017/10/performance-measurement-with-jmh-java-microbenchmark-harness/)

（4）[JMH 与 8 个测试陷阱](https://www.cnkirito.moe/java-jmh/)