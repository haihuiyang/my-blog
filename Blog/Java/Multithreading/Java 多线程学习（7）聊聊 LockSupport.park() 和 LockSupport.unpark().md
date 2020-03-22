> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

最近在忙着找工作、找房子，事儿也挺多的，加上又换了个城市，也就没什么心思写博客了。如今工作已定，房子也租好了，是时候调整好自己的心态，开始写博客了。

说实话，这段时间面了不少公司，和很多面试官交流了许多，感触颇多，不过目前还没想好怎么写，我会尽快将这段时间辞职及面试的体会整理成一篇博客发表出来，还请大家耐心等待！

暂且把面试的事搁下，咱们今天来聊 LockSupport.park() 和 LockSupport.unpark() 的底层原理。

为什么会聊到这两个方法呢？原因是在阅读 AQS 的源码的时候发现这两个方法调用的次数非常多！所以在继续深入阅读 AQS 源码之前，先来熟悉一下 LockSupport.park() 和 LockSupport.unpark() 的底层实现，为后续 AQS 的学习打下基础。

---

### 一、LockSupport.park() 和 LockSupport.unpark()

#### 1、那些你应该知道的基础知识

park 翻译成中文是 "停放" 的意思，在代码中的该方法含义是 "挂起" 当前线程。

实际上，LockSupport 类中所提供的方法有许多，常用的有下面这几个： 

- park()：无限期挂起当前线程
- parkNanos(long nanos)：挂起当前线程一段时间
- parkUntil(long deadline)：在 deadline 之前一直挂起当前线程
- unpark(Thread thread)：唤醒 thread 线程

其中 unpark 用于唤醒线程，其他三个均用于挂起线程。

挂起线程又分为无限期和有限期挂起，对应到线程的状态是 WAITING（无限期等待）和 TIMED_WAITING（限期等待）。

一个被无限期挂起的线程恢复的方式有三种：

- 其他线程调用了 unpark 方法，参数为被挂起的线程

- 其他线程中断了被挂起的线程

- The call spuriously (that is, for no reason) returns.

  > 这里讲的是虚假唤醒，可以参考以下几篇资料：
  >
  > - [Why does pthread_cond_wait have spurious wakeups?](https://stackoverflow.com/questions/8594591/why-does-pthread-cond-wait-have-spurious-wakeups)
  > - [Do spurious wakeups in Java actually happen?](https://stackoverflow.com/questions/1050592/do-spurious-wakeups-in-java-actually-happen)
  >
  > 由于虚假唤醒的存在，在调用 park 时一般采用自旋的方式，伪代码如下：
  >
  > ```java
  >     while (!canProceed()) { 
  >         ...
  >         LockSupport.park(this);
  >     }
  > ```

而有限期挂起的除了上面三种之外，还有第四种方式：

- 经过了挂起的时间段或者是达到了指定的 deadline

#### 2、它们有何特点？

```
This class associates, with each thread that uses it, a permit.
```

[Java 文档](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/locks/LockSupport.html)里说到了，每个线程都关联一个许可（permit）。

当许可可用时，调用 park 会立即返回，否则可能（虚假唤醒则不会被挂起）被挂起；如果许可不可用时，调用 unpark 会使得许可变成可用，而如果许可本身是可用时，调用 unpark 不会有任何影响。

可能直接看文字不是那么的一目了然，我们来看几个例子：

- ##### 例一：park 挂起线程，unpark 唤醒被挂起的线程

```java
public static void exampleOne() {
    Thread thread = new Thread(() -> {
        while (flag) {

        }

        System.out.println("before first park");
        LockSupport.park();
        System.out.println("after first park");
        LockSupport.park();
        System.out.println("after second park");

    });

    thread.start();

    flag = false;

    sleep(20);

    System.out.println("before unpark.");
    LockSupport.unpark(thread);
}
```
**输出结果**

```java
before first park
before unpark
after first park
```

**分析**

首先，许可初始是不可用的；所以在调用 park 后 thread 被挂起，后续主线程调用了 unpark 方法唤醒了被挂起的 thread，输出 `after first park` ，紧接着 thread 调用 park 继续被挂起。

- ##### 例二：unpark 效果不会被累积

```java
private static void exampleTwo() {
    Thread thread = new Thread(() -> {
        while (flag) {

        }

        System.out.println("before first park");
        LockSupport.park();
        System.out.println("after first park");
        LockSupport.park();
        System.out.println("after second park");

    });

    thread.start();

    LockSupport.unpark(thread);
    LockSupport.unpark(thread);

    flag = false;
}
```

**输出结果**

```java
before first park
after first park
```

**分析**

主线程先对 thread 执行两次 unpark 操作，然后 thread 再连续调用两次 park 方法，结果发现，第二个 park 会挂起 thread；这里主要体现了 unpark 效果不会被累积，当许可可用时，调用 unpark 方法不会产生任何效果。

- ##### 例三：中断对 park 的影响

```java
private static void exampleThree() {
    Thread thread = new Thread(() -> {

        System.out.println("before first park");
        LockSupport.park();
        System.out.println("after first park");
        LockSupport.park();
        System.out.println("after second park");
        System.out.println("isInterrupted is " + Thread.interrupted());
        System.out.println("isInterrupted is " + Thread.interrupted());
        LockSupport.park();
        System.out.println("after third park");
    });

    thread.start();

    sleep(200);

    thread.interrupt();
}
```

**输出结果**

```java
before first park
after first park
after second park
isInterrupted is true
isInterrupted is false
```

**分析**

thread 先后共调用了三次 park，前两次调用没啥区别，在第三次调用之前调用了两次 Thread.interrupted()；从输出结果来看，发现前两次 park 并没有生效，只有第三次 park 将线程挂起了，Why？

我们先来看 Thread.interrupted() 的作用：**判断当前线程的中断状态，同时将中断状态清除。**实际上这里只需要调用一次 Thread.interrupted() 即可，调用了两次是为了查看线程中断状态的变化。

当线程的中断状态为 true 时，park 失去了效果，不会挂起线程；而当调用了 Thread.interrupted() 将中断状态清除之后，park 又恢复了效果。

所以这里可以得出的结论：**线程中断会使 park 失效**。

[完整示例代码传送门](https://github.com/haihuiyang/java/blob/master/sampleJava/src/main/java/com/yhh/example/concurrency/ParkTest.java)

### 二、源码跟踪

重头戏来啦！上面讲到了 park 和 unpark 的几个方法，其实它们最终对应于 UNSAFE.park(boolean isAbsolute, long time) 和 UNSAFE.unpark(Object thread) 这两个 native 方法。

下面我们就去看看这两个 native 方法是如何实现的。

#### 1、UNSAFE.park(boolean isAbsolute, long time)

##### （1）`unsafe.cpp#Unsafe_Park`：`openjdk/hotspot/src/share/vm/prims/unsafe.cpp`

```c++
UNSAFE_ENTRY(void, Unsafe_Park(JNIEnv *env, jobject unsafe, jboolean isAbsolute, jlong time))
  UnsafeWrapper("Unsafe_Park");
  EventThreadPark event;
#ifndef USDT2
  HS_DTRACE_PROBE3(hotspot, thread__park__begin, thread->parker(), (int) isAbsolute, time);
#else /* USDT2 */
   HOTSPOT_THREAD_PARK_BEGIN(
                             (uintptr_t) thread->parker(), (int) isAbsolute, time);
#endif /* USDT2 */
  JavaThreadParkedState jtps(thread, time != 0);
  thread->parker()->park(isAbsolute != 0, time);
#ifndef USDT2
  HS_DTRACE_PROBE1(hotspot, thread__park__end, thread->parker());
#else /* USDT2 */
  HOTSPOT_THREAD_PARK_END(
                          (uintptr_t) thread->parker());
#endif /* USDT2 */
  ...
UNSAFE_END
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/tip/src/share/vm/prims/unsafe.cpp#l1206)

这里有几个分支判断，不过可以看出无论是哪个分支，最终都会走 `park(bool isAbsolute, jlong time)` 这个方法。

##### （2）`os_linux.cpp#Parker::park`：`openjdk/hotspot/src/os/linux/vm/os_linux.cpp`

```c++
void Parker::park(bool isAbsolute, jlong time) {
			...
  if (Atomic::xchg(0, &_counter) > 0) return;

  Thread* thread = Thread::current();
  assert(thread->is_Java_thread(), "Must be JavaThread");
  JavaThread *jt = (JavaThread *)thread;

  		...
  if (Thread::is_interrupted(thread, false)) {
    return;
  }

  // Next, demultiplex/decode time arguments
  timespec absTime;
  if (time < 0 || (isAbsolute && time == 0) ) { // don't wait at all
    return;
  }
  if (time > 0) {
    unpackTime(&absTime, isAbsolute, time);
  }
			...
  if (Thread::is_interrupted(thread, false) || pthread_mutex_trylock(_mutex) != 0) {
    return;
  }
  
  int status ;
  if (_counter > 0)  { // no wait needed
    _counter = 0;
    status = pthread_mutex_unlock(_mutex);
    assert (status == 0, "invariant") ;
    // Paranoia to ensure our locked and lock-free paths interact
    // correctly with each other and Java-level accesses.
    OrderAccess::fence();
    return;
  }

  assert(_cur_index == -1, "invariant");
  if (time == 0) {
    _cur_index = REL_INDEX; // arbitrary choice when not timed
    status = pthread_cond_wait (&_cond[_cur_index], _mutex) ;
  } else {
    _cur_index = isAbsolute ? ABS_INDEX : REL_INDEX;
    status = os::Linux::safe_cond_timedwait (&_cond[_cur_index], _mutex, &absTime) ;
    if (status != 0 && WorkAroundNPTLTimedWaitHang) {
      pthread_cond_destroy (&_cond[_cur_index]) ;
      pthread_cond_init    (&_cond[_cur_index], isAbsolute ? NULL : os::Linux::condAttr());
    }
  }

  		...
  _counter = 0 ;
  status = pthread_mutex_unlock(_mutex) ;
  OrderAccess::fence();

  // If externally suspended while waiting, re-suspend
  if (jt->handle_special_suspend_equivalent_condition()) {
    jt->java_suspend_self();
  }
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/os/linux/vm/os_linux.cpp#l5862)

- 首先通过 Atomic::xchg(0, &_counter) 方法将 _counter 置 0，如果原来的 _counter > 0，说明原来的许可是可用的，直接返回；

- 如果当前线程的处于中断状态，直接返回；

> Thread::is_interrupted(thread, false) 只会判断线程的中断状态，不会重置其中断状态；Thread.interrupted() 调用的是 Thread::is_interrupted(thread, true)，判断线程的中断状态同时将其重置。

- 如果 time < 0 或者 isAbsolute 为 true 且 time = 0，说明不需要挂起线程，直接返回；否则将 time 换算成 absTime，后续有限期等待会用到。
- 再次判断 _counter 的值，如果大于 0，说明原来的许可是可用的，将其置 0，然后直接返回。这里应该是在Atomic::xchg 到获取锁的之间有 unpark 操作，使得 _counter 的值变为 1 了；
- 判断如果 time == 0，调用 pthread_cond_wait 方法，进入无限期等待；否则，调用 os::Linux::safe_cond_timedwait 方法，这个方法最终调用的是 pthread_cond_timedwait，从而进入有限期等待。

> 关于 pthread_cond_wait 可以看一下这篇文章： [pthread_cond_wait 详解](https://www.xuebuyuan.com/2173853.html)
>
> 感觉和 Object.wait、Object.notify、Object.notifyAll 的机制很类似。

#### 2、UNSAFE.unpark(Object thread)

##### （1）`unsafe.cpp#Unsafe_Unpark`：`openjdk/hotspot/src/share/vm/prims/unsafe.cpp`

```c++
UNSAFE_ENTRY(void, Unsafe_Unpark(JNIEnv *env, jobject unsafe, jobject jthread))
  UnsafeWrapper("Unsafe_Unpark");
  Parker* p = NULL;
  if (jthread != NULL) {
    oop java_thread = JNIHandles::resolve_non_null(jthread);
    if (java_thread != NULL) {
      jlong lp = java_lang_Thread::park_event(java_thread);
      if (lp != 0) {
        // This cast is OK even though the jlong might have been read
        // non-atomically on 32bit systems, since there, one word will
        // always be zero anyway and the value set is always the same
        p = (Parker*)addr_from_java(lp);
      } else {
        // Grab lock if apparently null or using older version of library
        MutexLocker mu(Threads_lock);
        java_thread = JNIHandles::resolve_non_null(jthread);
        if (java_thread != NULL) {
          JavaThread* thr = java_lang_Thread::thread(java_thread);
          if (thr != NULL) {
            p = thr->parker();
            if (p != NULL) { // Bind to Java thread for next time.
              java_lang_Thread::set_park_event(java_thread, addr_to_java(p));
            }
          }
        }
      }
    }
  }
  if (p != NULL) {
#ifndef USDT2
    HS_DTRACE_PROBE1(hotspot, thread__unpark, p);
#else /* USDT2 */
    HOTSPOT_THREAD_UNPARK(
                          (uintptr_t) p);
#endif /* USDT2 */
    p->unpark();
  }
UNSAFE_END
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/tip/src/share/vm/prims/unsafe.cpp#l1232)

前面一大段代码是在给 Parker* p 赋值，最终调用的是 p 的 unpark 方法：p->unpark()。

##### （2）`os_linux.cpp#Parker::unpark`：`openjdk/hotspot/src/os/linux/vm/os_linux.cpp`

```c++
void Parker::unpark() {
  int s, status ;
  status = pthread_mutex_lock(_mutex);
  assert (status == 0, "invariant") ;
  s = _counter;
  _counter = 1;
  if (s < 1) {
    // thread might be parked
    if (_cur_index != -1) {
      // thread is definitely parked
      if (WorkAroundNPTLTimedWaitHang) {
        status = pthread_cond_signal (&_cond[_cur_index]);
        assert (status == 0, "invariant");
        status = pthread_mutex_unlock(_mutex);
        assert (status == 0, "invariant");
      } else {
        status = pthread_mutex_unlock(_mutex);
        assert (status == 0, "invariant");
        status = pthread_cond_signal (&_cond[_cur_index]);
        assert (status == 0, "invariant");
      }
    } else {
      pthread_mutex_unlock(_mutex);
      assert (status == 0, "invariant") ;
    }
  } else {
    pthread_mutex_unlock(_mutex);
    assert (status == 0, "invariant") ;
  }
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/os/linux/vm/os_linux.cpp#l5963)

unpark 方法其实很简单，首先通过 pthread_mutex_lock 获取锁，然后将 _counter 置为 1，再判断当前是否有线程被挂起，如果有，则通过 pthread_cond_signal 唤醒被挂起的线程，然后释放锁。

### 三、结语

学习知识真是一环扣一环，学一个不会的知识点，很容易碰到新的不会的知识点，然后不断的接触新知识点，不断地学习新的内容；当你不断的学习，不断的把新知识点吃透，慢慢的又会发现其实很多知识点的思想又是相通的，学起来反而没那么费劲了。

就好比看到 pthread_cond_wait 的机制时，就会联想到 Object.wait，因为两者的实现有很多相像的地方，理解起来也就比较简单。

最后留一个问题，大家可以思考一下：LockSupport.park 和 Object.wait 两者有何区别？

参考资料：

（1）[由几个小例引发的对interrupt()、LockSupport.park()深入解析](https://cgiirw.github.io/2018/05/27/Interrupt_Ques/)

（2）[Class LockSupport](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/locks/LockSupport.html)