> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

LongAdder、LongAccumulator 和 Striped64，其实还有 DoubleAdder 和 DoubleAccumulator，这几个类是 j.u.c 包的作者 [Doug Lea](https://en.wikipedia.org/wiki/Doug_Lea) 在 JDK 1.8 版本的时候加进来的。

由于这几个类的实现几乎一模一样，所以这里仅以 LongAdder 为例，分析其底层实现原理。

---

#### 1、LongAdder 和 AtomicLong

AtomicLong 是通过 CAS 来对一个 value 做原子更新操作。在竞争程度较低的时候，它的效率很高。但是在竞争激烈的情况下，CAS 很容易失败。

LongAdder 可以理解为加强版的 AtomicLong，但是又有一点点区别。

在竞争程度低的时候，LongAdder 和 AtomicLong 的特点是一样的。但是在竞争激烈的情况下，它的性能会优于 AtomicLong，不过它不能保证 sum 返回值的准确性（具体原因后面会讲到）。

下面我们来看看 LongAdder 为什么在竞争激烈的情形下性能要优于 AtomicLong。

#### 2、LongAdder 的底层实现原理

```java
transient volatile long base;
transient volatile Cell[] cells;
```

首先 LongAdder 维护了一个 base 值，这个值和 AtomicLong 中的 value 的作用一样；除此之外，它还维护了一个 `Cell[] cells` 数组，初始值为 null，只有在对 base 执行 CAS 更新失败时（说明竞争激烈）才会用到 cells 这个数组。

> Cell 类很简单，里面就放了一个 value 和一个支持 CAS 更新 value 的 cas 方法。

并且如果看过 HashMap 底层实现的话，你会发现这个 cells 数组跟 HashMap 中的数组很像，特别像。它长度是 2 的 n 次幂，也是通过 `h & (length - 1)` 来获取数组的下标。

当 n 个线程同时执行 add 方法时，

- 对于 AtomicLong 来说只会有一个线程会执行成功，剩下的都会失败进入自旋，最终看起来就像是串行的在执行。

- 而对于 LongAdder，它会根据线程的 probe 值（ Thread 类中的 threadLocalRandomProbe 字段）求得一个 cells 的数组下标，获取到 cell 值。n 个线程被分散到不同的 cell 中，在执行 CAS 的时候也就不会失败了。

	>这里可以想一下如果出现哈希冲突，会是一个什么样的情况？

![LongAdder 在高并发情况下执行示意图](https://img-blog.csdnimg.cn/20200107201130164.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)

下面我们来看看 LongAdder 的核心实现逻辑：LongAdder 中的 add 方法和Striped64 中的 longAccumulate 方法。

（1）LongAdder 中的 add 方法

```java
public void add(long x) {
    Cell[] as; long b, v; int m; Cell a;
    if ((as = cells) != null || !casBase(b = base, b + x)) {
        boolean uncontended = true;
        if (as == null || (m = as.length - 1) < 0 ||
            (a = as[getProbe() & m]) == null ||
            !(uncontended = a.cas(v = a.value, v + x)))
            longAccumulate(x, null, uncontended);
    }
}
```

流程图大致是这样子的：

![LongAdder add 方法流程图](https://img-blog.csdnimg.cn/20200105224946503.jpg?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)



（2）Striped64 中的 longAccumulate 方法：

```java
final void longAccumulate(long x, LongBinaryOperator fn,
                          boolean wasUncontended)
```

longAccumulate 方法很多个逻辑分支，就不一一分析每个 if 代表什么含义了，这里主要讲一讲它的思路。

- （1）首先，它是一个死循环，只有在 x 的值成功加到 base 或者 cells 中才会跳出循环；

- （2）它通过 `probe & (length - 1)` 将多个线程分流，分散到不同的 cells 中，从而减小了 CAS 失败的概率；

- （3）cells 会随着竞争程度的升高而扩容，当达到最大值（大于等于 CPU 的数量）后不再扩容。

	>当超过 CPU 数量之后再扩容就没有意义了，可以思考一下为什么？

- （4）通过 CAS 和一个 int  变量（cellsBusy）实现了一个自旋锁，在初始化和扩容 cells 的时候同步。

如果想知道 longAccumulate 方法每一个 if 具体做了啥，可以参考文末参考资料的第一个链接。

#### 3、LongAdder 的特点及适用场景

从前面可以知道，LongAdder 把值加到了 base 和 cells 数组每个元素的 value 中，所以最终的结果应该是这些属性加起来。

我们来看它的 sum 方法实现：

```java
public long sum() {
    Cell[] as = cells; Cell a;
    long sum = base;
    if (as != null) {
        for (int i = 0; i < as.length; ++i) {
            if ((a = as[i]) != null)
                sum += a.value;
        }
    }
    return sum;
}
```

sum 方法是返回当前总和，但这个返回值并不是一个原子快照。什么意思呢？

假如在 sum 的过程中，没有线程调用 add 方法，这种情况下返回的值是准确的；但在这个过程中，cell[0] 已经被加过了，这时恰好有一个线程调用了 add 方法，对 cell[0] 作了更新，但这个时候 sum 方法已经统计不到了，所以这种值不会被加进来。

所以它的特点总结起来就是：

- 在高并发下有更好的性能表现；
- 但高并发下不能保证 sum 返回值的准确性；

所以对于高并发、且对于统计值的精确性不是特别高的场景比较适合使用 LongAdder。

例如一些网站上的实时在线人数统计、实时弹幕条数这种。而如果对准确性有严格要求的话，就只能使用 AtomicLong 了。

#### 4、一些思考

- LongAdder 体现了用空间换时间的思想
- 到底哪些情况下会用到 LongAdder 呢？（由于目前并没有在业务上遇到过需要使用 LongAdder 的情况，所以只能根据它的特点思考可能使用会使用 LongAdder 的场景。）

**最后写给自己的话：勤能补拙，有付出才会有回报！手动给自己点个赞~ (\*╹▽╹\*)**

参考资料：

（1）[LongAdder类学习笔记](https://www.cnblogs.com/boothsun/p/8979614.html)

（2）[深入剖析LongAdder是咋干活的](https://juejin.im/post/5d2eb113518825305f248079)