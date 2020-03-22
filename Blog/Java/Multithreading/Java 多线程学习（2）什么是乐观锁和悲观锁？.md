> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

乐观锁和悲观锁是并发情况下处理数据竞争的两种思想，它们的使用是非常广泛的，并不限于某种编程语言或数据库。

>乐观锁思想：先操作数据，提交时判断数据有没有被其他线程修改，如果没有，则提交更新；如果有，则不提交更新，采取补偿措施：一般是自旋重试，直到操作成功。（事后补救）
>
>悲观锁思想：必须将数据锁定之后才能操作数据。（事前预防）

---

### 一、先来看一个简单的例子

```java
public class Counter {

    private volatile int count;

    public static void main(String[] args) throws InterruptedException {

        Counter counter = new Counter();

        Thread thread1 = new Thread(() -> {
            for (int i = 0; i < 10000; i++) {
                counter.increase();
            }
        });

        Thread thread2 = new Thread(() -> {
            for (int i = 0; i < 10000; i++) {
                counter.increase();
            }
        });

        thread1.start();
        thread2.start();

        thread1.join();
        thread2.join();

        System.out.println("count is " + counter.getCount());
    }

    public int increase() {
        return count++;
    }

    public int getCount() {
        return count;
    }
}
```

很简单的一个计数器：定义了一个 `Counter` 类，维护一个 `count` 属性，并且提供一个自增方法 `increase()` ，每次将 `count` 的值加 1，然后发起两个线程 `thread1` 和 `thread2` 分别对 `count` 做 10000 次的自增操作。

如果这段代码能够正确并发的话，最后输出的值应该为 20000。然而运行这段代码，并不会得到预期的结果，得到的总是一个小于 20000 的值，并且每次运行的结果都不一样。

原因是 `count++` 这个操作不是原子操作，它会分为三步：

- （a）读 count
- （b）count + 1
- （c）将 count + 1 赋给 count

当两个线程同时调用 `counter.increase()`，假设它们的执行步骤是这样子：

-  `thread1` 执行步骤（a）读取 count 的值为 0；
-  `thread2` 也执行步骤（a）读取 count 值也是 0；
-  `thread1` 执行步骤（b）（c）将结果 1 赋给 count；
-  `thread2` 执行步骤（b）（c）将结果 1 赋给 count；

结果就有问题了，虽然两个线程都对 count 进行了加 1 操作，但是 count 的结果还是 1。问题就在于 `thread2` 在执行完步骤（b）准备执行步骤（c）将结果赋给 count 的时候，count 的值已经被 `thread1` 修改过了（此时 count = 1），而 `thread2` 还是基于 count 修改前的值（count = 0）来计算的。

那么怎么才能避免这种情况呢？

- （1）使用 AtomicInteger （CAS + 自旋）

	先执行（a）和（b），在执行（c）的时候判断是否有其他线程修改过 count；如果没有，执行（c）；如果 count 被其他线程修改过，则不执行（c），重新执行 `counter.increase()`；

```java
    private volatile AtomicInteger atomicCount = new AtomicInteger(0);

    public int atomicIncrease() {
        return atomicCount.incrementAndGet();
    }
```

- （2）使用 synchronized 加锁

	在调用 `counter.increase()` 之前先获取锁，将 count 锁住，不让别的线程操作 count，这样就能保证自己在操作 count 的时候不会有其他线程修改 count 了。

```java
	public synchronized int increase() {
	    return count++;
	}
```

方式（1）体现的就是乐观锁思想，而方式（2）体现的则是悲观锁思想。

### 二、什么是乐观锁和悲观锁？
#### 1、乐观锁

总是假设最好的情况，认为在自身操作数据的时候不会有其他线程操作该数据，**不加锁**，在提交的时候判断在这之前有没有其他线程操作该数据，如果没有，则执行提交，完成更新；否则，不执行提交。

乐观锁一般使用版本号机制或 CAS 操作实现。

- 版本号机制

	基本思路是在数据库中增加一个 version 字段，表示该数据的版本号；当数据更新时，版本号 + 1；当某线程操作该数据时，会将版本号和数据一起查询出来，在提交更新时，判断当前数据库中版本号与之前读取的版本号是否一致，如果一致才执行更新。
	
	用一条简易 SQL 可以表示为：
	
	```java
	update table set value = value + 1, version = version + 1 where id = #{id} and version = #{version};
	```
	当然这里的 version 可以是时间戳，也可以是其他的一些值，不过有一个前提，就是必须保证唯一性。
	
	我们把这条 SQL 做一点小改动，把 version 去掉，同时添加数据库中的值与之前读取的值是否一致的条件：
	
	```java
	update table set value = value + 1 where id = #{id} and value = #{value};
	```

	看着是不是很熟悉呢？上面这句 SQL 所体现出来的思想就是我们接下来要讲的 CAS。
	
- CAS（Compare And Swap）比较并交换操作
	
	CAS 有 3 个操作数，分别是内存位置 V、旧的预期值 A 和拟修改的新值 B。当且仅当 V 符合预期值 A 时，用新值 B 更新 V 的值，否则什么都不做。
	
	更多关于 CAS 的底层原理请移步：[Java 多线程学习（3） CAS 底层原理学习之我是如何从 Java 源码看到 openjdk 源码再到汇编码、intel 手册的](https://blog.csdn.net/haihui_yang/article/details/103739482)	

#### 2、悲观锁

总是假设最坏的情况，认为在自身操作数据的时候总会有其他线程操作该数据，所以在整个数据的处理过程中将该数据锁定，不允许其他线程操作该数据。

悲观锁的实现方式是加锁，例如：Java 中的 ReentrantLock、synchronized 关键字等。

### 三、优缺点及使用场景

1、功能限制

- 乐观锁的使用场景有限，无论是版本号机制还是 CAS。例如：CAS 只能保证单个变量的原子性，对于多个变量的更新无能为力；版本号机制也是如此，例如需要更新的数据涉及到多张表。而这些对于悲观锁来说都可以通过加锁来实现。

2、并发冲突程度

- 如果并发冲突程度低，乐观锁的效率要更高。因为悲观锁需要对数据进行加锁，而加锁和释放锁都需要消耗额外的资源；

- 如果并发冲突程度高，悲观锁优势要更大。因为并发冲突高，乐观锁很容易更新失败，进入自旋重试，浪费 CPU 资源。