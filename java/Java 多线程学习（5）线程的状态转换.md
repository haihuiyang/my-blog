最开始的打算是只写线程的状态及转换的（即下文中的 1、2 点），因为在看了 Thread 源码和别人写的关于线程状态转换的博客之后，心里挺明了的，觉得自己应该理解了。。。

不过在学 AQS 的时候发现用到了很多 LockSupport.park() 和 LockSupport.unpark()，涉及到挂起线程与唤醒线程，这个时候才意识到自己对于这一块其实并不是太熟，并不太清楚 LockSupport.park() 和 LockSupport.unpark() 是怎么用的（只知道一个会挂起线程，另一个会唤醒线程，但是其中的原理并不清楚），于是又跑去看 LockSupport 的源码、学习 Object.wait() 和 Object.notify() 的使用及原理，此时才觉得对线程状态的转换才算是入门了。

切实体会到了纸上谈兵是多么的可笑！好了，进入正题。

---

线程都有哪些状态呢？它们之间是如何转换的呢？如何通过代码来完成这些转换呢？这就是这篇文章要解决的问题。

其实之前对线程的状态还是了解过的，不过没有系统的整理过，有些知识点还是略微模糊的。例如：

- 在哪些情况下线程会进入等待状态？（又分为限期等待和无限期等待两种）
- 阻塞状态和等待状态的区别？
- Object.wait() 和 Object.notify()、LockSupport.park() 和 LockSupport.unpark() 如何使用？
- ...



### 1、线程的 6 种状态

Java 线程（为什么说是 Java 线程呢？因为操作系统线程状态和这 6 个状态还有些许差异）一共有 6 种状态，Thread 类中专门定义了一个枚举类 State 来表示这 6 种状态。

#### （1）NEW（新建）

创建了一个 Thread 实例，还没有调用其 start() 方法，此时线程处于新建状态。

#### （2）RUNNABLE（运行）

运行状态包含了 Ready 和 Running 两种状态。什么意思呢？

Ready 状态的意思就是我已经准备好一切，只要让我用 CPU 我就能 Running，即正在等待 CPU 分配执行时间；

Running 状态就是得到了 CPU 的执行时间，正在运行。

#### （3）BLOCKED（阻塞）

线程 A 进入同步区域的时候，需要获取一个排他锁，若此时排他锁正在被另一个线程 B 占有，线程 A 将进入阻塞状态。

#### （4）WAITING（无限期等待）

处于这种状态的线程不会被分配 CPU 执行时间，它们要等待被其他线程显式地唤醒。以下方法会让线程陷入无限期的等待状态：	

- 没有设置 Timeout 参数的 Object.wait() 方法；
- 没有设置 Timeout 参数的 Thread.join() 方法；
- LockSupport.park() 方法。

#### （5）TIMED_WAITING（限期等待）

处于这种状态的线程也不会被分配 CPU 执行时间，不过无须等待被其他线程显式地唤醒，在一定时间之后它们会由系统自动唤醒。以下方法会让线程进入限期等待状态：

- Thread.sleep() 方法；
- 设置了 Timeout 参数的 Object.wait() 方法；
- 设置了 Timeout 参数的 Thread.join() 方法；
- LockSupport.parkNanos() 方法；
- LockSupport.parkUntil() 方法。

#### （6）TERMINATED（结束）

run() 方法执行完成，线程结束执行，此时的线程状态。

### 2、线程的状态转换图

上一节讲了线程的 6 个状态以及线程进入这 6 个状态的场景，其实不是很直观；下面的这幅图很直观的展示了线程状态的转换，也没有什么可说的，直接上图（建议自己去画一遍这个图，如果能不借助外物就能画出来的话，基本上线程状态转换也就没什么问题了）。

![线程的状态转换](https://tva1.sinaimg.cn/large/006tNbRwgy1gaxmvaut9wj30wn0u0jvt.jpg)

我个人觉得这图还挺好看的！不知你们觉得如何？

### 3、如何通过代码展示上述几个状态？

#### （1）NEW（新建）

```java
    private static void newState() {
        Thread newThread = new Thread("00-newThread");
        System.out.println(newThread.getState());
    }
```

![线程-新建-1](https://tva1.sinaimg.cn/large/006tNbRwgy1gayrhtaw7jj31qq0potdh.jpg)

![线程-新建-2](https://tva1.sinaimg.cn/large/006tNbRwgy1gayr6vd3iej31wn0u07ck.jpg)



#### （2）RUNNABLE（运行）

```java
    private static void runnableState() {
        Thread runnableThread = new Thread(() -> {
            while (true) {

            }
        }, "01-runnableThread");

        runnableThread.start();

        System.out.println(runnableThread.getState());
    }
```

![线程-运行](https://tva1.sinaimg.cn/large/006tNbRwgy1gayrdjs6qvj31pb0u0q94.jpg)

#### （3）BLOCKED（阻塞）

```java
    private static void blockedState() {

        Thread holdLockThread = new Thread(() -> {
            synchronized (lock) {
                while (true) {

                }
            }
        }, "holdLockThread");

        holdLockThread.start();

        Thread blockedThread = new Thread(() -> {
            synchronized (lock) {
                while (true) {

                }
            }
        }, "04-blockedThread");

        blockedThread.start();

        System.out.println(blockedThread.getState());
    }
```

![线程-阻塞](https://tva1.sinaimg.cn/large/006tNbRwgy1gayrpadh01j31j70u0q9b.jpg)

#### （4）WAITING（无限期等待）

```java
    private static void waitingState() {
        Thread waitingThread = new Thread(() -> {
            LockSupport.park();
        }, "02-waitingThread");

        waitingThread.start();

        System.out.println(waitingThread.getState());
    }
```

![线程-无限期等待](https://tva1.sinaimg.cn/large/006tNbRwgy1gayrtgfpnsj322n0u0gu3.jpg)

#### （5）TIMED_WAITING（限期等待）

```java
    private static void timeWaitingState() {
        Thread timeWaitingThread = new Thread(() -> {
            LockSupport.parkUntil(LocalDateTime.now().plusDays(1).toEpochSecond(ZoneOffset.of("+8")) * 1000);
        }, "03-timeWaitingThread");

        timeWaitingThread.start();

        System.out.println(timeWaitingThread.getState());
    }
```

![线程-限期等待](https://tva1.sinaimg.cn/large/006tNbRwgy1gayrxb57gcj324y0u0wny.jpg)

#### （6）TERMINATED（结束）

```java
    private static void terminatedState() {
        Thread terminatedThread = new Thread("05-terminatedThread");
        terminatedThread.start();
        try {
            terminatedThread.join();// 等待 terminatedThread 执行完成
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println(terminatedThread.getState());
    }
```

![线程-结束](https://tva1.sinaimg.cn/large/006tNbRwgy1gays3h4wqkj31jm0u00yp.jpg)

### 4、Object.wait() 和 Object.notify()

```java
    private static void waitAndNotify() {

        Thread waitThread = new Thread(() -> {
            synchronized (waitAndNotify) {
                System.out.println("I'm wait thread.");
                try {
                    System.out.println("waiting...");
                    waitAndNotify.wait();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("notified.");
            }
        }, "waitThread");

        Thread notifyThread = new Thread(() -> {
            synchronized (waitAndNotify) {
                System.out.println("I'm notified thread.");
                waitAndNotify.notify();
                System.out.println("notify wait thread.");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println("after sleep 1 second.");
            }
        }, "notifyThread");

        waitThread.start();
        try {
            Thread.sleep(20);// 确保 waitThread 在 notifyThread 之前执行
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        notifyThread.start();
    }
```

输出：

```java
I'm wait thread.
waiting...
I'm notified thread.
notify wait thread.
after sleep 1 second.
notified.
```

关于 Object.wait() 和 Object.notify() 补充几点：

（1）当前线程必须是 waitAndNotify monitor 的持有者，如果不是会抛 IllegalMonitorStateException；

（2）调用 waitAndNotify.wait() 方法会将当前线程放入 waitAndNotify 对象的 `wait set` 中等待被唤醒；并且释放其持有的所有锁；

（3）调用 waitAndNotify.notify() 方法会从 waitAndNotify 对象的 `wait set` 中唤醒一个线程（此例中的 waitThread），不过 waitThread 不会马上执行，它必须等待 notifyThread 释放 waitAndNotify 锁；当 waitThread 再次获得 waitAndNotify 锁，才可以再次执行。也就解释了为什么 `notified.` 会在最后输出。

### 5、LockSupport.park() 和 LockSupport.unpark()

```java
    private static void parkAndUnpark() {

        Thread parkThread = new Thread(() -> {
            System.out.println("park.");
            LockSupport.park();
            System.out.println("unpark.");
        }, "parkThread");

        parkThread.start();

        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        System.out.println("after sleep 1 second");

        LockSupport.unpark(parkThread);
    }
```

输出：

```java
park.
after sleep 1 second
unpark.
```

### 6、结语

本文差不多结束了，完整代码可在[这里](https://github.com/haihuiyang/java/blob/master/sampleJava/src/main/java/com/yhh/example/concurrency/ThreadStateChangeTest.java)找到。不过遗留的问题其实还有很多：

- 线程的中断？
- Thread 中的 native 方法的底层实现（C++源码）
- Object.wait() 和 Object.notify() 的底层原理（C++源码）
- LockSupport.park() 和 LockSupport.unpark() 的底层原理（C++源码）

遗留的这些问题基本上都是一些 native 方法，需要跟踪 C++ 源码；或者查看官方文档，比如： [Threads and Locks](https://docs.oracle.com/javase/specs/jls/se8/html/jls-17.html)。

经过查阅资料以及对 C++ 源码的摸索，对于上面几个问题背后的原理我也正在理解中，后续我会将自己的一些理解整理出来。

**我一直坚信，钻研技术要做到：知其然，知其所以然！**

参考资料：

（1）[Thread.java 源码](http://hg.openjdk.java.net/jdk8/jdk8/jdk/file/tip/src/share/classes/java/lang/Thread.java)

（2）《深入理解 Java 虚拟机》第二版.