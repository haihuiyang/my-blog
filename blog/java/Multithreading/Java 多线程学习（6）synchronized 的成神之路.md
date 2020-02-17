> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)



前段时间把 Object.await() 和 Object.notify()、LockSupport.park() 和 LockSupport.unpark() 差不多理解了，不过在跟踪 C++ 源码的时候看到了 ObjectMonitor.cpp 这个类（在 await() 释放锁和被 notify() 后重新获取锁的时候会调用这部分代码）；在看这里面的实现的时候，发现，咦？怎么它内部的逻辑和 synchronized 的特点如此之像！后来发现原来这里面就有 synchronized 底层实现。

以前通过文档学习了 synchronized 的用法及特点，但是并没有了解它的原理，如今终于知道了它为什么有这些特点了！

不仅如此，在这个过程中还把之前学到的一些知识点（对象的内存布局中的 Mark Word 那一部分）串了起来，有种恍然大悟的感觉！

下面就来对 synchronized 关键字做一个整理，加深记忆。

---

### 一、基础篇

#### 1、synchronized 怎么用？

```java
/**
 * @author happyfeet
 * @since Jan 19, 2020
 */
public class SynchronizedUsageExample {

    private static int staticCount;
    private final Object lock = new Object();
    private int count;

    public static synchronized int synchronizedOnStaticMethod() {
        return staticCount++;
    }

    public synchronized void synchronizedOnInstanceMethod() {
        count++;
    }

    public int synchronizedOnCodeBlock() {
        synchronized (lock) {
            return count++;
        }
    }
}
```

很简单的一个例子，不过涵盖了 synchronized 的所有用法：

- （1）作用于静态方法
- （2）作用于实例方法
- （3）作用于代码块

#### 2、synchronized 有哪些特点？

- ##### 总是需要一个对象作为锁

  - 作用于静态方法时锁是 class 对象

  - 作用于实例方法时锁是当前实例对象，即 this

  - 作用于代码块时锁是括号里的对象，即上例中的 lock 对象

- ##### 同一把锁同一时刻只能被一个线程所持有，不同锁之间互不影响

当多个线程访问同步代码块时，需要先获取锁，有且仅有一个线程可以获取到锁，没有获取到锁的线程会被阻塞，直到获取到锁；不同锁之间互不影响。

我们来看个例子：

```java
/**
 * @author happyfeet
 * @since Feb 03, 2020
 */
public class SynchronizedLockExample {

    private final Object lock = new Object();

    public static void main(String[] args) {

        SynchronizedLockExample lockExample = new SynchronizedLockExample();

        Thread thread1 = new Thread(() -> lockExample.synchronizedOnCodeBlock(), "thread-1");

        Thread thread2 = new Thread(() -> lockExample.synchronizedOnCodeBlock(), "thread-2");

        Thread thread3 = new Thread(() -> lockExample.synchronizedOnInstanceMethod(), "thread-3");

        Thread thread4 = new Thread(() -> lockExample.synchronizedOnInstanceMethod(), "thread-4");

        sleepOneSecond();
        thread1.start();
        sleepOneSecond();
        thread2.start();
        sleepOneSecond();
        thread3.start();
        sleepOneSecond();
        thread4.start();

        while (true) {

        }
    }

    private synchronized void synchronizedOnInstanceMethod() {
        println("I'm in synchronizedOnInstanceMethod, thread name is {}.", Thread.currentThread().getName());
        while (true) {
            // do something
        }
    }

    private void synchronizedOnCodeBlock() {
        synchronized (lock) {
            println("I'm in synchronizedOnCodeBlock, thread name is {}.", Thread.currentThread().getName());
            while (true) {
                // do something
            }
        }
    }

    private static void sleepOneSecond() {
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

执行 main 函数，程序输出如下：

```java
2020-02-03T10:19:12.993 thread thread-1 : I'm in synchronizedOnCodeBlock, thread name is thread-1.
2020-02-03T10:19:14.984 thread thread-3 : I'm in synchronizedOnInstanceMethod, thread name is thread-3.
```

Dump Threads，查看各个线程的运行状态，如图所示：

![synchronized 学习 - 图一](https://tva1.sinaimg.cn/large/006tNbRwgy1gbj13pt6eij32gm0lcajs.jpg)

**代码简介**

非常简单的一个例子，两个方法：synchronizedOnInstanceMethod 和 synchronizedOnCodeBlock（两个方法内部均为死循环，模拟正在处理业务逻辑，线程会一直持有锁）；

其中，synchronizedOnInstanceMethod 方法以 this 对象作为锁，synchronizedOnCodeBlock 以 lock 对象作为锁，然后启动了 4 个线程调用这两个方法：thread-1 和 thread-2 调用 synchronizedOnCodeBlock 方法，thread-3 和 thread-4 调用 synchronizedOnInstanceMethod 方法。

**结果分析**

从程序输出可以看到，thread-1 和 thread-3 都进入到了同步代码块内，处于 RUNNABLE 状态；由于 lock 和 this 锁分别被 thread-1 和 thread-3 所持有，thread-2 和 thread-4 无法获取到相应的锁，于是都处于 BLOCKED 状态。仔细看上面的截图可以发现，thread-4 正在等待获取 this 对象锁（同样的，thread-2 正在等待获取 lock 对象锁，不过截图中没有体现出来）：

```java
- waiting to lock <0x000000076acf00f0> (a com.yhh.example.concurrency.SynchronizedLockExample)
```

**一些拓展**

同一个类中，所有被 synchronized 修饰的静态方法使用的锁都是 class 对象；所有被 synchronized 修饰的实例方法使用的锁都是 this 对象；所以，对于这种：

```java
    private synchronized void method1() {
        // do something
    }

    private synchronized void method2() {
        // do something
    }

    private synchronized void method3() {
        // do something
    }
```

其实都是公用 this 对象这一把锁，如果 this 锁被线程 A 通过某个方法比如 method1() 将锁持有，那么，其他线程调用 method1()、method2()、method3() 时都会被阻塞；静态方法也是如此。

这里的核心点是：**同一把锁同一时刻只能被一个线程所持有。**

- ##### 可重入

synchronized 是**可重入锁**，可重入锁指的是在一个线程中可以多次获取同一把锁。

可重入锁最大的作用就是避免死锁。可以参考这里面的回答：[java的可重入锁用在哪些场合？](https://www.zhihu.com/question/23284564)

### 二、高级篇

#### 3、从字节码的角度看 synchronized

以 SynchronizedUsageExample 为例，反编译得到字节码如下（省略了一些不重要的字节码）：

```java
Classfile /Users/happyfeet/projects/java/sampleJava/src/main/java/com/yhh/example/concurrency/SynchronizedUsageExample.class
  ... 
{
  public static synchronized int synchronizedOnStaticMethod();
    descriptor: ()I
    flags: ACC_PUBLIC, ACC_STATIC, ACC_SYNCHRONIZED // 同步标记
    Code:
      stack=3, locals=0, args_size=0
         0: getstatic     #4                  // Field staticCount:I
         3: dup
         4: iconst_1
         5: iadd
         6: putstatic     #4                  // Field staticCount:I
         9: ireturn
      LineNumberTable:
        line 14: 0

  public synchronized void synchronizedOnInstanceMethod();
    descriptor: ()V
    flags: ACC_PUBLIC, ACC_SYNCHRONIZED // 同步标记
    Code:
      stack=3, locals=1, args_size=1
         0: aload_0
         1: dup
         2: getfield      #5                  // Field count:I
         5: iconst_1
         6: iadd
         7: putfield      #5                  // Field count:I
        10: return
      LineNumberTable:
        line 18: 0
        line 19: 10

  public int synchronizedOnCodeBlock();
    descriptor: ()I
    flags: ACC_PUBLIC
    Code:
      stack=4, locals=3, args_size=1
         0: aload_0
         1: getfield      #3                  // Field lock:Ljava/lang/Object;
         4: dup
         5: astore_1
         6: monitorenter // enter the monitor
         7: aload_0
         8: dup
         9: getfield      #5                  // Field count:I
        12: dup_x1
        13: iconst_1
        14: iadd
        15: putfield      #5                  // Field count:I
        18: aload_1
        19: monitorexit // exit the monitor（正常退出）
        20: ireturn
        21: astore_2
        22: aload_1
        23: monitorexit // exit the monitor（出现异常时走的逻辑）
        24: aload_2
        25: athrow
      Exception table:
         from    to  target type
             7    20    21   any
            21    24    21   any
      LineNumberTable:
        line 22: 0
					...
}
SourceFile: "SynchronizedUsageExample.java"
```

将有 synchronized 修饰的方法与普通方法对比，可以得到：

- 有 synchronized 修饰的方法的 flags 中多了一个同步标记：ACC_SYNCHRONIZED

- 有 synchronized 修饰的代码块中出现了成对的 monitorenter 和 monitorexit（注意：上面字节码中第二个 monitorexit 是处理异常，说明在执行第一个 monitorexit 之前程序出现了异常）

#### 4、ACC_SYNCHRONIZED、monitorenter 和 monitorexit

这几个的作用，需要从 [JVM 规范](https://docs.oracle.com/javase/specs/jvms/se8/html/index.html)中去找，主要是这几个地方：

- [2.11.10. Synchronization](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-2.html#jvms-2.11.10)

- [3.14. Synchronization](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-3.html#jvms-3.14)

- [monitorenter](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorenter)

- [monitorexit](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorexit)

JVM 的同步机制是通过 *monitor* （监视器锁）的进入和退出实现的。这里是 JVM 所定义的规范，不仅仅是 Java 语言，其他可以运行于 JVM 上的语言同样适用，例如：Scala。

对于 Java 语言来说，比较常用的同步实现就是使用 synchronized 关键字，作用于方法和代码块上。

##### （1）同步标记：ACC_SYNCHRONIZED

当 synchronized 作用于方法上时，反编译成字节码之后会发现方法的 flags 中会有一个同步标记：ACC_SYNCHRONIZED。

对于有 [ACC_SYNCHRONIZED](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-3.html#jvms-3.14) 标记的方法，线程在执行方法时的步骤是这样的：

- enters the monitor
- invokes the method itself
- exits the monitor whether the method invocation completes normally or abruptly

##### （2）monitorenter 和 monitorexit 指令

当 synchronized 作用于代码块时，可以发现字节码中出现了成对的 monitorenter 和 monitorexit 指令。

我们来看看 JVM 规范中是怎么描述这两个指令的：

- [**monitorenter**](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorenter)

**作用**

> 获取对象的 monitor

**参数**

> *objectref*，必须是对象引用，如果为 null 则抛出 NPE

**描述**

> 每个对象与一个 monitor 关联，monitor 只有在拥有 owner 的情况下才被锁定。当一个线程执行到 monitorenter 指令时会尝试获取对象锁所关联的 monitor，获取规则如下：
> - 如果 monitor 的 entry count 为0，则该线程可以进入 monitor，并将 monitor 的 entry count 的值设为 1，该线程成为 monitor 的 owner；
> - 如果当前线程已经拥有该 monitor，只是重新进入（reenter），则将 monitor 的 entry count 的值加 1；
> - 如果 monitor 的 owner 是其他线程，则当前线程进入阻塞状态，直到 monitor 的 entry count 为 0 之后再次尝试获取 monitor。

- [**monitorexit**](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorexit)

**作用**

> 释放对象的 monitor

**参数**

> *objectref*，必须是对象引用，如果为 null 则抛出 NPE

**描述**

> 执行 monitorexit 的线程必须是 *objectref* 关联的 monitor 的 owner，如果不是则抛出 IllegalMonitorStateException；
>
> 执行 monitorexit 的效果就是将 *objectref* 关联的 monitor 的 entry count 的值减 1，当 entry count 的值变为 0 时，当前线程将释放对象的 monitor，不再是该 monitor 的 owner。

到了这，对于 synchronized 的使用基本上是没有什么问题了；不过对于 synchronized 的执行过程还没有一个完整的认识，下面我们来看一看 synchronized 在 HotSpot 中是如何执行的？

### 三、成神篇

#### 5、偏向锁、轻量级锁和重量级锁？

我们先来看看什么是偏向锁、轻量级锁和重量级锁？后续讲 synchronized 在 HotSpot 中的执行过程中会讲到这些锁是如何获取的。

##### （1）偏向锁

偏向锁是 JDK 1.6 加入的，其目的是消除数据在无竞争情况下的同步原语，进一步提高程序的性能。

如果开启了偏向锁，锁会偏向于第一个获得它的线程，如果后续的执行过程该锁没有被其他线程获取，则持有偏向锁的线程将永远不需要再进行同步；

而一旦出现多个线程竞争同一把锁，就必须撤销偏向锁，撤销完之后再执行轻量级锁的同步操作，此时就会带来额外的锁撤销的消耗。

偏向锁可以提高带有同步但无竞争的程序性能，但如果程序中大多数锁总是被多个不同的线程访问，那偏向模式就是多余的；

JDK 1.6 默认开启，可以通过参数 -XX:-UseBiasedLocking 禁用偏向锁。

偏向锁是直接修改 Mark Word 中的 lock（标志位）和 biased_lock（是否偏向锁），偏向线程 ID 也直接存储于锁对象的 Mark Word 中。 

##### （2）轻量级锁

轻量级锁也是 JDK 1.6 加入的，其目的是在线程交替执行的情况下，减少传统的重量级锁使用操作系统互斥量产生的性能消耗。

轻量级锁会在当前线程的栈帧中建立一个名为 Lock Record 的空间，用于存储锁对象目前的 Mark Word 的拷贝，然后通过 CAS 尝试将对象的 Mark Word 更新为指向 Lock Record 的指针。如果更新成功，说明这个线程拥有了该对象锁，同时对象 Mark Word 的锁标志位转变为 “00”，表明此对象处于轻量级锁定状态。

当两个以上线程竞争同一个锁，那么轻量级锁不再有效，需要膨胀为重量级锁。此时除了互斥量的开销外，还有额外的轻量级锁的加锁和解锁操作，因此，在有竞争的情况下，轻量级锁会比传统的重量级锁更慢。

既然如此，那为什么还需要有轻量级锁呢？因为 “**对于绝大部分锁，在整个同步周期内都是不存在竞争的**”，这是一个经验数据。

##### （3）重量级锁

重量级锁是通过对象内部的监视器（monitor）实现，锁对象的 Mark Word 指向一个类型为 ObjectMonitor 的对象指针；monitor 的本质是依赖于底层操作系统的 Mutex Lock 实现，操作系统实现线程同步时，需要进行系统调用，需要从用户态（User Mode）到内核态（Kernel Mode）的切换，代价相对较高。

>三种锁的适用场景如下：
>
>- 偏向锁：适用于只有一个线程获取锁
>- 轻量级锁：适用于多个线程交替获取锁，不存在竞争
>- 重量级锁：适用于多个线程竞争同一个锁

#### 6、synchronized 在 HotSpot 中的执行过程

这里主要目的是对 synchronized 的执行过程有一个大概的认识，所以省略了很多代码及注释（注释其实很重要，不过为了篇幅起见，都去掉了），只保留了一些关键的 C++ 源码，如需查看完整 C++ 源码可以点击代码片段后面的链接查看。

synchronized 的 HotSpot 实现依赖于对象头的 Mark Word，关于 Mark Word 可以参考：[深入理解Java虚拟机之----对象的内存布局](https://blog.csdn.net/haihui_yang/article/details/81071693) 中的 Mark Word 模块，这是其中一张关于 64 位系统的 Mark Word 示例图片：

![HotSpot 虚拟机对象头 Mark Word](https://tva1.sinaimg.cn/large/0082zybpgy1gbp8gsq0n9j30xg0jktd0.jpg)


> 对于 synchronized 方法会多一个 ACC_SYNCHRONIZED 同步标记，线程在执行方法时的步骤为：
>
> `enters the monitor` => `invoke method` => `exits the monitor`
>
> 这里对于 `enters the monitor` 具体做了啥不是很清楚，不过我猜想应该是和 monitorenter 指令的行为是一致的；同样的，`exits the monitor` 与 monitorexit 指令一致。
>
> 可以参考：[Java synchronized是否有对应的字节码指令实现？](https://hllvm-group.iteye.com/group/topic/39067) 和 R 大的读书笔记 [第146页 Threads and Synchronization - The Java bytecode implementation](https://book.douban.com/annotation/29492994/)

以下为自己的一些理解（可能会有不对的地方），仅作参考。

##### （1）`templateTable_x86_64.cpp#monitorenter`：`openjdk/hotspot/src/cpu/x86/vm/templateTable_x86_64.cpp`

synchronized 代码块的字节码会出现成对的 monitorenter 和 monitorexit 指令，那么这两个指令是如何发挥作用的呢？

参考 R 大读书笔记 [第 232 页 7.2.1 Interpreter 模块](https://book.douban.com/annotation/31407691/) 及 [JVM 之模板解释器](https://zhuanlan.zhihu.com/p/33886967)

JVM 在执行 monitorenter 指令的入口为：

```c++
void TemplateTable::monitorenter() {
  
	...
    
  // store object
  __ movptr(Address(c_rarg1, BasicObjectLock::obj_offset_in_bytes()), rax);
  __ lock_object(c_rarg1);
  
  ...
    
  // The bcp has already been incremented. Just need to dispatch to
  // next instruction.
  __ dispatch_next(vtos);
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/cpu/x86/vm/templateTable_x86_64.cpp#l3596)

这一段主要是汇编代码，很晦涩，太难懂。

实话实说，我是没看懂这一段代码在干嘛，一脸懵逼，直接进入下一个方法：lock_object。

##### （2）`interp_masm_x86_64.cpp#lock_object`：`openjdk/hotspot/src/cpu/x86/vm/interp_masm_x86_64.cpp`

 ```c++
void InterpreterMacroAssembler::lock_object(Register lock_reg) {
  assert(lock_reg == c_rarg1, "The argument is only for looks. It must be c_rarg1");

  if (UseHeavyMonitors) {
    call_VM(noreg,
            CAST_FROM_FN_PTR(address, InterpreterRuntime::monitorenter),
            lock_reg);
  } else {
    Label done;

    ...

    if (UseBiasedLocking) {
      biased_locking_enter(lock_reg, obj_reg, swap_reg, rscratch1, false, done, &slow_case);
    }

    ...

    // Call the runtime routine for slow case
    call_VM(noreg,
            CAST_FROM_FN_PTR(address, InterpreterRuntime::monitorenter),
            lock_reg);

    bind(done);
  }
}
 ```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/cpu/x86/vm/interp_masm_x86_64.cpp#l688)

这里也同样基本上没看懂，有几个关键字眼可以推敲一番：UseHeavyMonitors、UseBiasedLocking，进入下一个方法：InterpreterRuntime::monitorenter

##### （3）`interpreterRuntime.cpp#monitorenter`：`openjdk/hotspot/src/share/vm/interpreter/interpreterRuntime.cpp`

```c++
IRT_ENTRY_NO_ASYNC(void, InterpreterRuntime::monitorenter(JavaThread* thread, BasicObjectLock* elem))
	...
  Handle h_obj(thread, elem->obj());
  if (UseBiasedLocking) {
    // Retry fast entry if bias is revoked to avoid unnecessary inflation
    ObjectSynchronizer::fast_enter(h_obj, elem->lock(), true, CHECK);
  } else {
    ObjectSynchronizer::slow_enter(h_obj, elem->lock(), CHECK);
  }
	...
IRT_END
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/interpreter/interpreterRuntime.cpp#l561)

**BasicObjectLock 类型的 elem 对象包含一个 BasicLock 类型的 _lock 对象和一个指向 Object 对象的指针 _obj；**

```c++
class BasicObjectLock VALUE_OBJ_CLASS_SPEC {
  friend class VMStructs;
 private:
  BasicLock _lock;                                    // the lock, must be double word aligned
  oop       _obj;                                     // object holds the lock;

 public:
  // Manipulation
  oop      obj() const                                { return _obj;  }
  void set_obj(oop obj)                               { _obj = obj; }
  BasicLock* lock()                                   { return &_lock; }

  ...
};
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/basicLock.hpp#l57)

- 这里的 Object 对象就是作为锁的对象；
- BasicLock 类型 _lock 对象主要用来保存 _obj 指向的 Object 对象的对象头数据；

```c++
class BasicLock VALUE_OBJ_CLASS_SPEC {
  friend class VMStructs;
 private:
  volatile markOop _displaced_header;
 public:
  markOop      displaced_header() const               { return _displaced_header; }
  void         set_displaced_header(markOop header)   { _displaced_header = header; }

  ...
};
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/basicLock.hpp#l32)

**UseBiasedLocking：标识 JVM 是否开启偏向锁功能，如果开启则执行 fast_enter 逻辑，否则执行 slow_enter；**

##### （4）`synchronizer.cpp#fast_enter`：`openjdk/hotspot/src/share/vm/runtime/synchronizer.cpp`

```c++
void ObjectSynchronizer::fast_enter(Handle obj, BasicLock* lock, bool attempt_rebias, TRAPS) {
 if (UseBiasedLocking) {
    if (!SafepointSynchronize::is_at_safepoint()) {
      BiasedLocking::Condition cond = BiasedLocking::revoke_and_rebias(obj, attempt_rebias, THREAD);
      if (cond == BiasedLocking::BIAS_REVOKED_AND_REBIASED) {
        return;
      }
    } else {
      assert(!attempt_rebias, "can not rebias toward VM thread");
      BiasedLocking::revoke_at_safepoint(obj);
    }
    assert(!obj->mark()->has_bias_pattern(), "biases should be revoked by now");
 }

 slow_enter (obj, lock, THREAD) ;
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l166)

**偏向锁的获取**

`BiasedLocking::Condition cond = BiasedLocking::revoke_and_rebias(obj, attempt_rebias, THREAD);`

这个方法做的事情就是获取偏向锁。点进去一看，又是一大块代码。。。而且还不是很容易理解。。。

参考 《深入理解 JVM 虚拟机》这本书和战小狼的这篇博客 [JVM源码分析之synchronized实现](https://www.jianshu.com/p/c5058b6fe8e5) 加以理解，大致逻辑为：

（a）获取锁对象的对象头中的 Mark Word，判断是不是可偏向状态；

> 假设当前虚拟机启用了偏向锁（启用参数：-XX:+UseBiasedLocking，这是 JDK 1.6 的默认值），那么，当锁对象第一次被线程获取的时候，虚拟机就会把对象头中的标志位设为 “01”，即可偏向状态。

（b）判断 Mark Word 中的偏向线程 ID：如果为空，则进入步骤（c）；如果指向当前线程，说明当前线程是偏向锁的持有者，可以不需要同步，直接执行同步块代码；如果指向其它线程，进入步骤（d）；

（c）通过 CAS 设置 Mark Word 中的偏向线程 ID 为当前线程 ID，如果设置成功，当前线程成为了偏向锁的持有者，可以直接执行同步块代码；否则进入步骤（d）；

（d）如果是从第（b）步直接进入步骤（d），说明当前线程尝试获取一个已经处于偏向模式的锁；而从第（c）步进入的步骤（d），说明当前还有其他线程在竞争锁，且当前线程竞争失败了；这两种情况都会使得锁的偏向模式宣告结束。当到达全局安全点（safepoint），获得偏向锁的线程被挂起，并撤销偏向锁，执行 slow_enter 将锁升级；升级完成后被阻塞在安全点的线程尝试获取升级之后的锁。

>这里撤销偏向锁并将锁升级，会根据锁对象目前是否处于被锁定的状态分为两种情况：未锁定（标志位为 “01”）和轻量级锁定（标志位为 “00”）。

##### （5）`synchronizer.cpp#slow_enter`：`openjdk/hotspot/src/share/vm/runtime/synchronizer.cpp`

fast_enter 获取偏向锁失败，就会进入到 slow_enter 方法中，而这里包含了获取轻量级锁的实现。

```c++
void ObjectSynchronizer::slow_enter(Handle obj, BasicLock* lock, TRAPS) {
  markOop mark = obj->mark();

  if (mark->is_neutral()) {
    // Anticipate successful CAS -- the ST of the displaced mark must
    // be visible <= the ST performed by the CAS.
    lock->set_displaced_header(mark);
    if (mark == (markOop) Atomic::cmpxchg_ptr(lock, obj()->mark_addr(), mark)) {
      TEVENT (slow_enter: release stacklock) ;
      return ;
    }
    // Fall through to inflate() ...
  } else
  if (mark->has_locker() && THREAD->is_lock_owned((address)mark->locker())) {
    lock->set_displaced_header(NULL);
    return;
  }

	...
  lock->set_displaced_header(markOopDesc::unused_mark());
  ObjectSynchronizer::inflate(THREAD, obj())->enter(THREAD);
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l224)

**轻量级锁的获取**

（a）`mark->is_neutral()` 判断 Mark Word 是否处于未锁定状态，如果是，进入第（c）步，否则进入第（b）步；

（b）如果当前线程是轻量级锁的持有者，可以不需要同步，直接执行同步块代码；否则，进入步骤（d）；

（c）通过 CAS 设置锁对象的 Mark Word 为 lock，如果设置成功，当前线程成为了轻量级锁的持有者，可以直接执行同步块代码；否则进入步骤（d）；

（d）如果是从第（b）步直接进入步骤（d），说明当前线程与一个已经处于轻量级锁的线程争用同一个锁；而从第（c）步进入的步骤（d），说明当前还有其他线程在竞争锁，且当前线程竞争失败了；如果有两个以上的线程争用同一个锁，那轻量级锁也不再有效，需要执行 inflate 将锁膨胀为重量级锁，同时将锁标志的状态值变为 “10”。

##### （6）`synchronizer.cpp#inflate`：`openjdk/hotspot/src/share/vm/runtime/synchronizer.cpp`

```c++
ObjectMonitor * ATTR ObjectSynchronizer::inflate (Thread * Self, oop object) {
			...
  for (;;) {
      const markOop mark = object->mark() ;

      // The mark can be in one of the following states:
      // *  Inflated     - just return
      // *  Stack-locked - coerce it to inflated
      // *  INFLATING    - busy wait for conversion to complete
      // *  Neutral      - aggressively inflate the object.
      // *  BIASED       - Illegal.  We should never see this

      // CASE: inflated
      if (mark->has_monitor()) {
          ObjectMonitor * inf = mark->monitor() ;
        	...
          return inf ;
      }

      // CASE: inflation in progress - inflating over a stack-lock.
      // Some other thread is converting from stack-locked to inflated.
				...
      if (mark == markOopDesc::INFLATING()) {
         TEVENT (Inflate: spin while INFLATING) ;
         ReadStableMark(object) ;
         continue ;
      }

      // CASE: stack-locked
				...
      if (mark->has_locker()) {
          ObjectMonitor * m = omAlloc (Self) ;
          m->Recycle();
          m->_Responsible  = NULL ;
          m->OwnerIsThread = 0 ;
          m->_recursions   = 0 ;
          m->_SpinDuration = ObjectMonitor::Knob_SpinLimit ;   // Consider: maintain by type/class

          markOop cmp = (markOop) Atomic::cmpxchg_ptr (markOopDesc::INFLATING(), object->mark_addr(), mark) ;
          if (cmp != mark) {
             omRelease (Self, m, true) ;
             continue ;       // Interference -- just retry
          }

          ...
          markOop dmw = mark->displaced_mark_helper() ;
          assert (dmw->is_neutral(), "invariant") ;
          m->set_header(dmw) ;
          m->set_owner(mark->locker());
          m->set_object(object);

          object->release_set_mark(markOopDesc::encode(m));

          // Hopefully the performance counters are allocated on distinct cache lines
          // to avoid false sharing on MP systems ...
          if (ObjectMonitor::_sync_Inflations != NULL) ObjectMonitor::_sync_Inflations->inc() ;
          TEVENT(Inflate: overwrite stacklock) ;
          if (TraceMonitorInflation) {
            if (object->is_instance()) {
              ResourceMark rm;
              tty->print_cr("Inflating object " INTPTR_FORMAT " , mark " INTPTR_FORMAT " , type %s",
                (void *) object, (intptr_t) object->mark(),
                object->klass()->external_name());
            }
          }
          return m ;
      }

      // CASE: neutral
      ObjectMonitor * m = omAlloc (Self) ;
      // prepare m for installation - set monitor to initial state
      m->Recycle();
      m->set_header(mark);
      m->set_owner(NULL);
      m->set_object(object);
      m->OwnerIsThread = 1 ;
      m->_recursions   = 0 ;
      m->_Responsible  = NULL ;
      m->_SpinDuration = ObjectMonitor::Knob_SpinLimit ;       // consider: keep metastats by type/class

      if (Atomic::cmpxchg_ptr (markOopDesc::encode(m), object->mark_addr(), mark) != mark) {
          m->set_object (NULL) ;
          m->set_owner  (NULL) ;
          m->OwnerIsThread = 0 ;
          m->Recycle() ;
          omRelease (Self, m, true) ;
          m = NULL ;
          continue ;
          // interference - the markword changed - just retry.
          // The state-transitions are one-way, so there's no chance of
          // live-lock -- "Inflated" is an absorbing state.
      }

      // Hopefully the performance counters are allocated on distinct
      // cache lines to avoid false sharing on MP systems ...
      if (ObjectMonitor::_sync_Inflations != NULL) ObjectMonitor::_sync_Inflations->inc() ;
      TEVENT(Inflate: overwrite neutral) ;
      if (TraceMonitorInflation) {
        if (object->is_instance()) {
          ResourceMark rm;
          tty->print_cr("Inflating object " INTPTR_FORMAT " , mark " INTPTR_FORMAT " , type %s",
            (void *) object, (intptr_t) object->mark(),
            object->klass()->external_name());
        }
      }
      return m ;
  }
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l1192)

**锁的膨胀过程**

这一段代码乍一看很长，真的很长，不过上面已经是删减了很多代码之后的版本了。细看之后发现其实这一段代码很容易理解：

（a）首先，这个代码最终是要得到一个 ObjectMonitor 对象，后续会调用其 enter 方法。

（b）并且它是一个自旋方法： `  for (;;) {}`

（c）接着它列举了 mark  的五种状态以及在这五种状态下的操作（实际上第五种是不可达状态）：

```
      // The mark can be in one of the following states:
      // *  Inflated     - just return
      // *  Stack-locked - coerce it to inflated
      // *  INFLATING    - busy wait for conversion to complete
      // *  Neutral      - aggressively inflate the object.
      // *  BIASED       - Illegal.  We should never see this
```

- Inflated：说明已经膨胀完成了，直接返回。
- Stack-locked：前面在讲轻量级锁的获取时讲到了当两个以上的线程争用同一个锁，要膨胀为重量级锁。此时的 mark 是处于轻量级锁定的状态，即 Stack-locked，需要执行膨胀操作膨胀为重量级锁。这里需要注意的是每个竞争锁的线程都会通过 CAS 尝试膨胀锁（CAS 设置 mark 状态为 INFLATING），CAS 成功的线程将继续执行膨胀操作，CAS 失败的线程则撤销之前的准备操作，并进入自旋等待膨胀完成。
- INFLATING：说明其他线程正在进行膨胀过程，当前线程进入自旋等待膨胀完成；这里的自旋不会一直占用 CPU 资源，它每隔一段时间会通过 os::NakedYield() 放弃 CPU 资源，或者调用 park() 挂起自己（[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l469)）；当其他线程完成锁的膨胀操作，退出自旋并返回。
- Neutral：这个状态说明 mark 尚处于未锁定状态，所以这个分支是将 mark 从未锁定状态直接膨胀成为重量级锁；我们回退到 slow_enter 方法，查看其调用过程，可以分析得到 mark 是不会在 Netural 状态进行膨胀操作的；所以如果上游方法是 slow_enter 是不会走这个分支的，这个分支应该是为了支持其他地方的调用；大致看了一下，这里的思路和 Stack-locked 类似，都是通过 CAS + 自旋执行膨胀操作，有兴趣可以了解一下。
- BIASED：不可达状态。

（d）当锁膨胀完成，返回对应的 ObjectMonitor 对象之后，并不表示该线程竞争到了锁，真正的锁竞争发生在 ObjectMonitor::enter 方法中。

##### （7）`objectMonitor.cpp#enter`：`openjdk/hotspot/src/share/vm/runtime/objectMonitor.cpp`

```c++
void ATTR ObjectMonitor::enter(TRAPS) {
  Thread * const Self = THREAD ;
  void * cur ;

  cur = Atomic::cmpxchg_ptr (Self, &_owner, NULL) ;
  if (cur == NULL) {
     // Either ASSERT _recursions == 0 or explicitly set _recursions = 0.
     assert (_recursions == 0   , "invariant") ;
     assert (_owner      == Self, "invariant") ;
     // CONSIDER: set or assert OwnerIsThread == 1
     return ;
  }

  if (cur == Self) {
     // TODO-FIXME: check for integer overflow!  BUGID 6557169.
     _recursions ++ ;
     return ;
  }

  if (Self->is_lock_owned ((address)cur)) {
    assert (_recursions == 0, "internal state error");
    _recursions = 1 ;
    // Commute owner from a thread-specific on-stack BasicLockObject address to
    // a full-fledged "Thread *".
    _owner = Self ;
    OwnerIsThread = 1 ;
    return ;
  }

		...
    // TODO-FIXME: change the following for(;;) loop to straight-line code.
    for (;;) {
      jt->set_suspend_equivalent();
      // cleared by handle_special_suspend_equivalent_condition()
      // or java_suspend_self()

      EnterI (THREAD) ;

      if (!ExitSuspendEquivalent(jt)) break ;

      //
      // We have acquired the contended monitor, but while we were
      // waiting another thread suspended us. We don't want to enter
      // the monitor while suspended because that would surprise the
      // thread that suspended us.
      //
          _recursions = 0 ;
      _succ = NULL ;
      exit (false, Self) ;

      jt->java_suspend_self();
    }
    ...
  }
		...
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l316)

`  cur = Atomic::cmpxchg_ptr (Self, &_owner, NULL) ;` 

首先我们要明白，这里返回的 cur 是 &_owner 的实际原值；

（a）如果 cur == NULL，说明该线程执行 cmpxchg_ptr 成功，成功获取到锁，直接返回；

（b）如果 cur == Self，即之前持有锁的线程就是自己，说明这是一个重入操作，只需要将 _recursions 加 1 之后返回即可；

（c）如果 Self->is_lock_owned ((address)cur)，这里，我觉得可以这样理解：首先明白一点，这也是一个重入操作，但是它是一个特殊的重入操作；因为之前持有锁的 &_owner 其实也是当前线程，但是这个 cur 和 Self 没办法通过 == 判断出来，需要用另一种方式才可以判断，即 Self->is_lock_owned ((address)cur)；这种方式判断出来如果为真，那么 _recursions 的值也一定为 0，然后将 Self 赋给 _owner，同时， _recursions 设置为 1，然后返回；

（d）如果上面三种情况都不满足，那就说明真正遇到了竞争；紧接着一个自旋操作竞争锁：先通过 EnterI 方法竞争锁，然后判断在获取锁的这段时间内，如果没有其他线程挂起自己，那么获取锁成功，返回；否则将锁释放，同时执行 jt->java_suspend_self() 等待挂起自己的线程将自己唤醒。

我们接下来看 EnterI 这个方法，EnterI 方法才是真正实现竞争锁的地方。

##### （8）`objectMonitor.cpp#EnterI`：`openjdk/hotspot/src/share/vm/runtime/objectMonitor.cpp`

```c++
void ATTR ObjectMonitor::EnterI (TRAPS) {
    Thread * Self = THREAD ;

    // Try the lock - TATAS
    if (TryLock (Self) > 0) {
        assert (_succ != Self              , "invariant") ;
        assert (_owner == Self             , "invariant") ;
        assert (_Responsible != Self       , "invariant") ;
        return ;
    }
		...
    if (TrySpin (Self) > 0) {
        assert (_owner == Self        , "invariant") ;
        assert (_succ != Self         , "invariant") ;
        assert (_Responsible != Self  , "invariant") ;
        return ;
    }

    // The Spin failed -- Enqueue and park the thread ...
    ObjectWaiter node(Self) ;
    Self->_ParkEvent->reset() ;
    node._prev   = (ObjectWaiter *) 0xBAD ;
    node.TState  = ObjectWaiter::TS_CXQ ;

    // Push "Self" onto the front of the _cxq.
    // Once on cxq/EntryList, Self stays on-queue until it acquires the lock.
    // Note that spinning tends to reduce the rate at which threads
    // enqueue and dequeue on EntryList|cxq.
    ObjectWaiter * nxt ;
    for (;;) {
        node._next = nxt = _cxq ;
        if (Atomic::cmpxchg_ptr (&node, &_cxq, nxt) == nxt) break ;

        // Interference - the CAS failed because _cxq changed.  Just retry.
        // As an optional optimization we retry the lock.
        if (TryLock (Self) > 0) {
            assert (_succ != Self         , "invariant") ;
            assert (_owner == Self        , "invariant") ;
            assert (_Responsible != Self  , "invariant") ;
            return ;
        }
    }
		...
    for (;;) {

        if (TryLock (Self) > 0) break ;

        // park self
        if (_Responsible == Self || (SyncFlags & 1)) {
            TEVENT (Inflated enter - park TIMED) ;
            Self->_ParkEvent->park ((jlong) RecheckInterval) ;
            // Increase the RecheckInterval, but clamp the value.
            RecheckInterval *= 8 ;
            if (RecheckInterval > 1000) RecheckInterval = 1000 ;
        } else {
            TEVENT (Inflated enter - park UNTIMED) ;
            Self->_ParkEvent->park() ;
        }

        if (TryLock(Self) > 0) break ;
				...
    }

    UnlinkAfterAcquire (Self, &node) ;
    if (_succ == Self) _succ = NULL ;

    assert (_succ != Self, "invariant") ;
    if (_Responsible == Self) {
        _Responsible = NULL ;
        OrderAccess::fence(); // Dekker pivot-point
    }

    if (SyncFlags & 8) {
       OrderAccess::fence() ;
    }
    return ;
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l479)

如果看过 AQS 的源码的人来看这一段代码，会发现这段代码和 AQS 的 ConditionObject 的行为很相似。下面我们来看 EnterI 是怎么去竞争锁的：

（a）TryLock (Self) 尝试一下获取锁，如果返回值 > 0，说明获取锁成功，返回；

（b）TrySpin (Self) 在入队之前自旋一小段时间尝试获取锁，如果返回值 > 0，说明获取锁成功，返回；

（c）如果前面两个操作都没成功，就创建一个 ObjectWaiter 类型的 node，加入到 cxq/EntryList 的队首；入队是一个自旋操作，如果入队失败，再次尝试获取锁，如果获取成功，直接返回；否则继续执行入队操作；

（d）执行到这，说明 Self 已经在队列里面了，这里又是一个自旋操作：TryLock + park()；尝试获取锁，如果获取成功，进入（e）；否则挂起自己，等待被唤醒（当持有锁的线程释放锁时，会唤醒最早进入等待队列的节点）。当该线程唤醒之后，会从挂起的点继续执行。

（e）获取到锁，将自己从队列中移除，返回。

至此，关于 monitorenter 的执行过程基本上就结束了；而 monitorexit 的执行过程和 monitorenter 基本类似，可以参考 monitorenter 的执行过程自行理解，这里不再进行讲述。这里有一点需要注意，执行 monitorexit 时，会在代码的最后最后调用 unpark 用于唤醒阻塞于 EnterI 方法中的线程。

**遗留的问题**

- 偏向锁和轻量级锁是如何记录重入次数的？

### 四、结语

看过了 synchronized 底层源码之后再来回看《深入理解 Java 虚拟机》中关于 synchronized 的部分，发现原来自己的这些理解书本上本来就有，而且详细的很，不免想到之前看到的口天师兄的这个回答：[你的编程能力从什么时候开始突飞猛进？](https://www.zhihu.com/question/356351510)，真的非常精辟。

写这篇文章花了挺长时间的，不过收获也确实蛮多的，说说自己的感受吧：

- 最开始看的时候其实是最难受的，基本上遇到的所有东西都是问题，不过慢慢的看多了之后就会发现有很多地方是相似的（例如 EnterI 方法和 AQS 的 ConditionObject）
- [Java Language and Virtual Machine Specifications](http://webcache.googleusercontent.com/search?q=cache:https://docs.oracle.com/javase/specs/) 中的内容非常好，一定要找时间把它看完
- 《深入理解 Java 虚拟机》第二版： 这本书也写的特别好，值得反复阅读，深入阅读；这本书最近出第三版了，正在考虑要不要入手一本
- 书上总结的内容确实是精华，不过如果能够自己实践一番，效果更佳

参考资料：

（1）[17.1. Synchronization](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html#jls-17.1)

（2）[3.14. Synchronization](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-3.html#jvms-3.14)

（3）[2.11.10. Synchronization](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-2.html#jvms-2.11.10)

（4）[monitorenter](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorenter)

（5）[monitorexit](https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#jvms-6.5.monitorenter)

（6）《深入理解 Java 虚拟机》第二版 周志明 著.

（7）[JVM源码分析之synchronized实现](https://www.jianshu.com/p/c5058b6fe8e5)