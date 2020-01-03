本来是准备阅读 j.u.c 包下 ConcurrentHashMap 的底层源码，理解 ConcurrentHashMap 的实现原理的，看了一点点发现里面用到了很多 CAS。并且 atomic 和 locks 这两个包中也大量使用了 CAS，所以就先把 CAS 的原理搞清楚了之后再继续后面的内容。

看了一大堆文章，也是把它弄懂了。令我没想到的是，自己竟然从 Java 源码看到 openjdk 源码及汇编码，最后还看了一些 intel 手册的内容，最终不仅学会了 CAS，还学到了许多其他的知识。

慢慢发现，其实深入研究某一个知识点的实现，还是蛮有意思的，只是过程可能有点艰辛。

---


CAS 是乐观锁的一种实现方式，是一种轻量级锁，j.u.c 中很多工具类的实现就是基于 CAS 的。

#### 1、什么是 CAS？
CAS （Compare And Swap）比较并交换操作。

**CAS 有 3 个操作数，分别是内存位置 V、旧的预期值 A 和拟修改的新值 B。当且仅当 V 符合预期值 A 时，用新值 B 更新 V 的值，否则什么都不做。**

用一段伪代码来帮助理解 CAS：

```java
Object  A = getValueFromV();// 先读取内存位置 V 处的值 A
Object B = A + balaba;// 对 A 做一定处理，得到新值 B
	
// 下面这部分就是 CAS，通过硬件指令实现
if( A == actualValueAtV ) {// actualValueAtV 为执行当前原子操作时内存位置 V 处的值
	setNewValueToV(B);// 将新值 B 更新到内存位置 V 处
} else {
	doNothing();// 说明有其他线程改过内存位置 V 处的值了，A 已经不是最新值了，所以基于 A 处理得到的新值 B 是不对的
}
```

#### 2、CAS 的底层实现原理
CAS 的核心是 Unsafe 类。而当你去看 Unsafe 的源码的时候，发现里面调用的是 native 方法。而要看 native 方法的实现，确实需要花很大一番功夫，并且基本上都是 C++ 代码。

在经过一番折腾后，至少我大致知道了 Unsafe 类中的 native 方法的调用链及关键的 C++ 源码。

以  `compareAndSwapInt`  为例，这个本地方法在 openjdk 中依次调用的 C++ 代码为：

（1）`unsafe.cpp`：`openjdk/hotspot/src/share/vm/prims/unsafe.cpp`

```c++
UNSAFE_ENTRY(jboolean, Unsafe_CompareAndSwapInt(JNIEnv *env, jobject unsafe, jobject obj, jlong offset, jint e, jint x))
  UnsafeWrapper("Unsafe_CompareAndSwapInt");
  oop p = JNIHandles::resolve(obj);
  jint* addr = (jint *) index_oop_from_field_offset_long(p, offset);
  return (jint)(Atomic::cmpxchg(x, addr, e)) == e;
UNSAFE_END
```
[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/tip/src/share/vm/prims/unsafe.cpp#l1185)

（2）`atomic_****_****.inline.hpp`

- 如果是运行在 windows_x86（windows 系统，x86 处理器）下

`atomic_windows_x86.inline.hpp`：`openjdk/hotspot/src/os_cpu/windows_x86/vm/atomic_windows_x86.inline.hpp`

```c++
inline jint     Atomic::cmpxchg    (jint     exchange_value, volatile jint*     dest, jint     compare_value) {
  // alternative for InterlockedCompareExchange
  int mp = os::is_MP();
  __asm {
    mov edx, dest
    mov ecx, exchange_value
    mov eax, compare_value
    LOCK_IF_MP(mp)
    cmpxchg dword ptr [edx], ecx
  }
}
```
[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/os_cpu/windows_x86/vm/atomic_windows_x86.inline.hpp#l216)

- 如果是运行在 linux_x86 （linux 系统，x86 处理器）下

```c++
inline jint     Atomic::cmpxchg    (jint     exchange_value, volatile jint*     dest, jint     compare_value) {
  int mp = os::is_MP();
  __asm__ volatile (LOCK_IF_MP(%4) "cmpxchgl %1,(%3)"
                    : "=a" (exchange_value)
                    : "r" (exchange_value), "a" (compare_value), "r" (dest), "r" (mp)
                    : "cc", "memory");
  return exchange_value;
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/os_cpu/linux_x86/vm/atomic_linux_x86.inline.hpp#l93)

`__asm__` 表示汇编的开始

`volatile` 表示禁止编译器优化

`LOCK_IF_MP` 是个内联函数

```c++
#define LOCK_IF_MP(mp) "cmp $0, " #mp "; je 1f; lock; 1: "
```

以上几个参考自占小狼的[深入浅出 CAS](https://www.jianshu.com/p/fb6e91b013cc)。

`os::is_MP()` 这个函数是判断当前系统是否是多核处理器。

所以这个地方应该就是生成汇编码，我就只关注了这一行 `LOCK_IF_MP(%4) "cmpxchgl %1,(%3)"` ，毕竟后面的也看不懂。。。

这里相当于是如果当前系统是多核处理器则会在添加 lock 指令前缀，否则就不加。 

> 关于 `lock` 指令前缀说明：
>
> - 在《深入理解 Java 虚拟机》中，作者解释 volatile 的内存可见性原理时提到（371 页）：“关键在于 lock 前缀，查询 IA32 手册，它的作用是使得本 CPU 的 Cache 写入了内存，该写入动作也会引起别的 CPU 或者别的内核无效化（ Invalidate ）其 Cache，这种操作相当于对 Cache 中的变量做了一次前面介绍 Java 内存模式中所说的 ' store 和 write ' 操作。”
> - [intel IA32 手册](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.pdf) 中 8.1 LOCKED ATOMIC OPERATIONS 关于 lock 前缀的含义：
> 	- 保证原子操作
> 	- 总线锁定，通过使用 LOCK＃ 信号和 LOCK 指令前缀
> 	- 高速缓存一致性协议，确保可以对高速缓存的数据结构执行原子操作（缓存锁定）
> - lock 指令前缀也具有禁止指令重排序作用：可以通过阅读 [intel IA32 手册](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.pdf)中 8.2.2 Memory Ordering in P6 and More Recent Processor Families 和 8.2.3 Examples Illustrating the Memory-Ordering Principles 两节的内容得出。

看到这里，CAS 的底层实现原理也就很显然了，实际上就是：`lock cmpxchg`

其中，**`cmpxchg` 是硬件级别的原子操作指令，`lock` 前缀保证这个指令执行结果的内存可见性和禁止指令的重排序。**

> 关于 `lock cmpxchg` 的一些个人理解：由于 `lock` 指令前缀会锁定总线（或者是缓存锁定），所以在该 CPU 执行时总线是处于独占状态，该 CPU 通过总线广播一条 `read invalidate` 信息，通过高速缓存一致性协议（MESI），将其余 CPU 中该数据的 Cache 置为 `invalid` 状态（如果存在该数据的 Cache ），从而获得了对该数据的独占权，之后再执行 `cmpxchg` 原子操作指令修改该数据，完成对数据的修改。

#### 3、一些思考和疑问

##### （1）既然 CAS 具有 volatile 的读和写的内存语义，那为什么还需要把变量声明成 volatile 呢？

volatile 的读和写的内存语义其实是通过 lock 指令前缀实现的，如图：

![volatile putfield](https://user-gold-cdn.xitu.io/2020/1/1/16f5d0b6e60936c9?w=1436&h=878&f=png&s=330296)

而 CAS 在系统是多核处理器时也会添加 lock 指令前缀，这两个不就是重复了吗？

本来想通过工具查看 CAS 这一部分的汇编码的，不过 Java 代码的汇编码不包含这一部分，也就不知道这一部分的汇编码到底是啥样子的，因为这部分是由 C++ 实现的。

这个作如下猜测：

- 对于不走 CAS，单纯走 set 方法的，volatile 可以保证这些赋值操作的内存可见性；
- 对于单核处理器来说，CAS 是没有加 `lock` 指令的，这种情况仅靠 `cmpxchg` 能否保证各个线程的本地缓存失效呢？对 volatile 变量做 CAS 是否可以避免这个问题？

以上仅是我个人的一些理解，不一定正确，欢迎大家来一起讨论。

##### （2）总线锁定和多线程中获取锁是一个道理，只不过它的粒度要更小；CPU Cache 也可以类比到线程的本地工作内存。


#### 4、CAS 的优点
不加锁，在并发冲突程度不高的情况下，效率极高。（可以参考乐观锁的优点）

#### 5、CAS 存在哪些缺陷？
##### （1）CAS + 自旋 ==> 可能导致：循环时间长，CPU 开销大
大多数情况下，CAS 是配合自旋来实现对单个共享变量的更新的。

如果自旋 CAS 长时间不成功（说明并发冲突大），会给 CPU 带来非常大的执行开销。

##### （2）ABA 问题
首先明白一点：CAS 本身是一个原子操作，不存在 ABA 问题。

不过使用 CAS 更新数据一般需要三个步骤：

- 取数
- 处理数据
- CAS 更新数据

在这个过程中可能出现 ABA 问题。上面三个步骤不是一个原子操作，所以可能出现下面这种情况：

- 线程 thread1 查询 A 的值为 a，开始处理数据
- 线程 thread2 执行完三个步骤将 A 的值更新为 b
- 线程 thread3 执行完三个步骤将 A 的值从 b 又更新回 a
- 线程 thread1 处理完数据，得到 c ，这时它对比内存中的值 a，将 A 的值更新为 c

线程 thread1 在处理数据的过程中，实际上 A 的值已经经历了 `a -> b -> a` 的过程，但是对于线程 thread1 来说判断不出来，所以线程 thread1 还是可以将 A 的值更新为 c。这就是我们说的 ABA 问题。

这里我用 Java 代码模拟了一下 ABA 问题，有兴趣的可以去看一下：[CasABAProblem](https://github.com/haihuiyang/java/blob/master/sampleJava/src/main/java/com/yhh/example/concurrency/CasABAProblem.java)

ABA 问题可能带来的问题是什么呢？换句话说，`a -> b -> a` 这个过程可能会有哪些副作用？

思考了很久，没想到什么好的例子。。。等想到了之后再来更新。。。下面我们来看如何避免 ABA 问题。

其实避免 ABA 问题其实很简单，只需要给数据添加一个版本号。上面例子中的 `a -> b -> a` 的过程就会变成 `1a -> 2b -> 3a`，当线程 thread1 处理完数据，发现 `1a != 3a`，所以也就不会更新 A 的值了。可以参考 j.u.c atomic 包下 AtomicStampedReference 类，它就是添加了一个 stamp 字段作为数据的版本号。

>我还试了一下 compareAndSwapObject 方法，发现这个方法比较的是对象的引用，因为不管我怎么修改对象中的属性，compareAndSwapObject 都能执行成功。。。所以 Unsafe 中 compareAndSwap 的 compare 是否就可以用 == 来等价呢？看了一下，AtomicReference 中 compareAndSet(V expect, V update) 上的文档好像也确实是这么写的：
>
>```java
>* Atomically sets the value to the given updated value
>* if the current value {@code ==} the expected value.
>```
>
>我看到很多人的博客上面写了 ABA 问题，举了链表或栈的出栈入栈相关的例子。参考 wikipedia 上面的例子：[比较并交换](https://zh.wikipedia.org/wiki/%E6%AF%94%E8%BE%83%E5%B9%B6%E4%BA%A4%E6%8D%A2)
>
>里面是用 C 操作的堆，对堆进行了一系列的 pop 和 push 操作。并解释说：由于内存管理机制中广泛使用的内存重用机制，导致 NodeC 的地址与之前的 NodeA 一致。
>
>这种情况在 Java 中会出现吗？我觉得还是可以思考思考的。

##### （3）不支持多个共享变量的原子操作
从上面的介绍来看，CAS 本身就是针对单个共享变量的，对于多个共享变量，当然是不支持的。

当然，如果把多个共享变量合并成一个共享变量（放在一个对象里面），也是可以进行 CAS 操作。

这就看怎么理解多个共享变量了，如果说一个共享变量的多个属性可以被称之为多个共享变量，那么 CAS 也是可以支持的。



#### 6、结语


学 CAS ，最后学到的知识有：

- 能够粗浅阅读一些 openjdk 的 C++ 源码

- 加深对 volatile 的理解

- lock 指令的作用

- 内存屏障

- 如何反汇编 Java 字节码

- 以及一些工具的使用

收获颇丰！给自己点个赞！哈哈哈~


参考资料：

（1）[深入浅出CAS](https://www.jianshu.com/p/fb6e91b013cc)

（2）[JAVA CAS原理深度分析](https://www.iteye.com/blog/zl198751-1848575)

（3）[Why Memory Barriers？中文翻译（上）](http://www.wowotech.net/kernel_synchronization/Why-Memory-Barriers.html)

（4）[intel IA32 手册 8.1、8.2、8.3节](https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.pdf)https://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.pdf)