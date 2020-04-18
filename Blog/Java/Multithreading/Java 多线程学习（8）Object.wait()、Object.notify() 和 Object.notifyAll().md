> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

wait、notify 和 notifyAll 是 Object 对象所提供的几个方法，想必大家都见过，因为 Java 中的每个对象都有；不过在平时的工作中基本上不会用到，我是没遇到过。

这次想要深入的去学习这几个方法也是因为阅读 AQS 源码的缘故。

AQS 中实现了 Condition 这个接口，它提供的方法和 Object 的这几个方法极其相似，所以决定先把 Object 的这几个方法吃透。

---

### 一、基本用法

我们先来看看总共有哪几个方法吧。

```java
Object.wait()

Object.wait(long timeout)

Object.wait(long timeout, int nanos)

Object.notify()

Object.notifyAll()
```

一共有这五个方法，其实我们只需要关注下面这三个方法就行了，因为剩下两个 wait 方法都是 Object.wait(long timeout)  的变形。

```java
Object.wait(long timeout)

Object.notify()

Object.notifyAll()
```

这三个是 native 方法，是 C++ 实现的，我们先从 Javadoc 中看看这些方法的的用法和特点，然后再去源码中看为什么会是这样。

结合方法名及 Javadoc 来看，这几个方法有如下特点：

- wait（等待）

  （1）使当前线程进入 WAITING（无限期等待）或 TIMED_WAITING（限期等待）状态，取决于 timeout 的值；

  （2）当前线程必须是这个对象 monitor 的持有者，即需要先持有这个对象的锁方可调用 wait 方法，否则会抛出 IllegalMonitorStateException 异常；

  （3）线程 T 退出 wait 状态的方式。

  - 其他线程调用了 notify 方法，并且 T 线程被选中

  - 其他线程调用了 notifyAll 方法

  - 其他线程中断了 T 线程

  - The call spuriously (that is, for no reason) returns.（虚假唤醒）

  - 经过了 wait 指定的时间

    >和 park 挂起的线程的恢复方式差不多，可参考 [Java 多线程学习（7）聊聊 LockSupport.park() 和 LockSupport.unpark()](https://blog.csdn.net/haihui_yang/article/details/105029673)

- notify（通知）

  （1）唤醒一个正在等待当前对象的 monitor 的线程

  （2）当前线程必须是该对象 monitor 的持有者

- notifyAll（通知所有）

  （1）唤醒正在等待当前对象的 monitor 的所有线程

  （2）当前线程必须是该对象 monitor 的持有者

**举个栗子**

```java
public class WaitNotifyExample {

    private static final Object LOCK = new Object();

    public static void main(String[] args) {

        Thread waitThread = new Thread(() -> {
            synchronized (LOCK) {
                try {
                    PrintUtils.println("before wait");
                    LOCK.wait();
                    PrintUtils.println("after wait");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });

        Thread notifyThread = new Thread(() -> {
            synchronized (LOCK) {
                PrintUtils.println("before notify");
                LOCK.notify();
                PrintUtils.println("after notify");
            }
        });

        waitThread.start();
        notifyThread.start();
    }

}
```

**输出**

```java
before wait
before notify
after notify
after wait
```

**分析**

- waitThread 获取到 LOCK 锁，输出 "before wait"，然后调用 LOCK 对象的 wait 方法，进入等待状态；注意，此时 waitThread 会将 LOCK 锁释放
- notifyThread 获取到 LOCK 锁，输出 "before notify"，然后调用 LOCK 对象的 notify 方法，由于此时等待 LOCK 对象 monitor 的线程只有一个，即 waitThread，所以 waitThread 被唤醒；但是此时 notifyThread 还没有释放 LOCK 锁，所以 waitThread 只有继续等待获取 LOCK 锁
- notifyThread 输出 "after notify" 并且同步块执行完，释放 LOCK 锁
- waitThread 获取到 LOCK 锁，继续执行同步块代码，输出 "after wait"，程序结束

**需要注意的点**

- 如果直接调用 LOCK 的 wait 或 notify 方法，将会抛出 IllegalMonitorStateException 异常；
- notifyAll 方法会将等待 LOCK 对象 monitor 的所有线程都唤醒，当 LOCK 锁处于可用状态时，被唤醒的这些线程将会去尝试获取锁，有且只有一个线程能获取到锁； 没获取到锁的线程只有等待锁被释放后继续尝试获取锁。

### 二、源码分析

native 方法，那就需要看它的 C++ 源码了。

#### 1、native 方法的入口

`Object.c`：`openjdk/jdk/src/share/native/java/lang/Object.c`

```c++
static JNINativeMethod methods[] = {
    {"hashCode",    "()I",                    (void *)&JVM_IHashCode},
    {"wait",        "(J)V",                   (void *)&JVM_MonitorWait},
    {"notify",      "()V",                    (void *)&JVM_MonitorNotify},
    {"notifyAll",   "()V",                    (void *)&JVM_MonitorNotifyAll},
    {"clone",       "()Ljava/lang/Object;",   (void *)&JVM_Clone},
};
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/jdk/file/687fd7c7986d/src/share/native/java/lang/Object.c#l44)

这就是这三个 native 方法的入口。

#### 2、Object.wait(long timeout)

##### （1）`jvm.cpp#JVM_MonitorWait`：`openjdk/hotspot/src/share/vm/prims/jvm.cpp`

```c++
JVM_ENTRY(void, JVM_MonitorWait(JNIEnv* env, jobject handle, jlong ms))
  JVMWrapper("JVM_MonitorWait");
  Handle obj(THREAD, JNIHandles::resolve_non_null(handle));
  JavaThreadInObjectWaitState jtiows(thread, ms != 0);
  if (JvmtiExport::should_post_monitor_wait()) {
    JvmtiExport::post_monitor_wait((JavaThread *)THREAD, (oop)obj(), ms);

    // The current thread already owns the monitor and it has not yet
    // been added to the wait queue so the current thread cannot be
    // made the successor. This means that the JVMTI_EVENT_MONITOR_WAIT
    // event handler cannot accidentally consume an unpark() meant for
    // the ParkEvent associated with this ObjectMonitor.
  }
  ObjectSynchronizer::wait(obj, ms, CHECK);
JVM_END
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/prims/jvm.cpp#l515)

直接进入 ObjectSynchronizer::wait 方法，因为前面也比较难看懂。

##### （2）`synchronizer.cpp#ObjectSynchronizer::wait`：`openjdk/hotspot/src/share/vm/runtime/synchronizer.cpp`

```c++
void ObjectSynchronizer::wait(Handle obj, jlong millis, TRAPS) {
  if (UseBiasedLocking) {
    BiasedLocking::revoke_and_rebias(obj, false, THREAD);
    assert(!obj->mark()->has_bias_pattern(), "biases should be revoked by now");
  }
  if (millis < 0) {
    TEVENT (wait - throw IAX) ;
    THROW_MSG(vmSymbols::java_lang_IllegalArgumentException(), "timeout value is negative");
  }
  ObjectMonitor* monitor = ObjectSynchronizer::inflate(THREAD, obj());
  DTRACE_MONITOR_WAIT_PROBE(monitor, obj(), THREAD, millis);
  monitor->wait(millis, true, THREAD);

  /* This dummy call is in place to get around dtrace bug 6254741.  Once
     that's fixed we can uncomment the following line and remove the call */
  // DTRACE_MONITOR_PROBE(waited, monitor, obj(), THREAD);
  dtrace_waited_probe(monitor, obj, THREAD);
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l376)

- 首先判断了一下是否是偏向锁，如果是的话会做一些操作（没有去细看做了啥）；
- 然后判断传入参数 millis，如果小于 0 则抛出异常；
- 最后将锁膨胀，并且调用其 wait 方法。

##### （3）`objectMonitor.cpp#wait`：`openjdk/hotspot/src/share/vm/runtime/objectMonitor.cpp`

```c++
void ObjectMonitor::wait(jlong millis, bool interruptible, TRAPS) {
  	...
   // Throw IMSX or IEX.
   CHECK_OWNER();

   EventJavaMonitorWait event;

   // check for a pending interrupt
   if (interruptible && Thread::is_interrupted(Self, true) && !HAS_PENDING_EXCEPTION) {
     // post monitor waited event.  Note that this is past-tense, we are done waiting.
     if (JvmtiExport::should_post_monitor_waited()) {
        JvmtiExport::post_monitor_waited(jt, this, false);
     }
     if (event.should_commit()) {
       post_monitor_wait_event(&event, 0, millis, false);
     }
     TEVENT (Wait - Throw IEX) ;
     THROW(vmSymbols::java_lang_InterruptedException());
     return ;
   }

   TEVENT (Wait) ;

   assert (Self->_Stalled == 0, "invariant") ;
   Self->_Stalled = intptr_t(this) ;
   jt->set_current_waiting_monitor(this);

   // create a node to be put into the queue
   // Critically, after we reset() the event but prior to park(), we must check
   // for a pending interrupt.
   ObjectWaiter node(Self);
   node.TState = ObjectWaiter::TS_WAIT ;
   Self->_ParkEvent->reset() ;
   OrderAccess::fence();          // ST into Event; membar ; LD interrupted-flag

   // Enter the waiting queue, which is a circular doubly linked list in this case
   // but it could be a priority queue or any data structure.
   // _WaitSetLock protects the wait queue.  Normally the wait queue is accessed only
   // by the the owner of the monitor *except* in the case where park()
   // returns because of a timeout of interrupt.  Contention is exceptionally rare
   // so we use a simple spin-lock instead of a heavier-weight blocking lock.

   Thread::SpinAcquire (&_WaitSetLock, "WaitSet - add") ;
   AddWaiter (&node) ;
   Thread::SpinRelease (&_WaitSetLock) ;

   if ((SyncFlags & 4) == 0) {
      _Responsible = NULL ;
   }
   intptr_t save = _recursions; // record the old recursion count
   _waiters++;                  // increment the number of waiters
   _recursions = 0;             // set the recursion level to be 1
   exit (true, Self) ;                    // exit the monitor
   guarantee (_owner != Self, "invariant") ;

   // The thread is on the WaitSet list - now park() it.
   // On MP systems it's conceivable that a brief spin before we park
   // could be profitable.
   //
   // TODO-FIXME: change the following logic to a loop of the form
   //   while (!timeout && !interrupted && _notified == 0) park()

   int ret = OS_OK ;
   int WasNotified = 0 ;
   { // State transition wrappers
     OSThread* osthread = Self->osthread();
     OSThreadWaitState osts(osthread, true);
     {
       ThreadBlockInVM tbivm(jt);
       // Thread is in thread_blocked state and oop access is unsafe.
       jt->set_suspend_equivalent();

       if (interruptible && (Thread::is_interrupted(THREAD, false) || HAS_PENDING_EXCEPTION)) {
           // Intentionally empty
       } else
       if (node._notified == 0) {
         if (millis <= 0) {
            Self->_ParkEvent->park () ;
         } else {
            ret = Self->_ParkEvent->park (millis) ;
         }
       }

       // were we externally suspended while we were waiting?
       if (ExitSuspendEquivalent (jt)) {
          // TODO-FIXME: add -- if succ == Self then succ = null.
          jt->java_suspend_self();
       }

     } // Exit thread safepoint: transition _thread_blocked -> _thread_in_vm


     // Node may be on the WaitSet, the EntryList (or cxq), or in transition
     // from the WaitSet to the EntryList.
     // See if we need to remove Node from the WaitSet.
     // We use double-checked locking to avoid grabbing _WaitSetLock
     // if the thread is not on the wait queue.
     //
     // Note that we don't need a fence before the fetch of TState.
     // In the worst case we'll fetch a old-stale value of TS_WAIT previously
     // written by the is thread. (perhaps the fetch might even be satisfied
     // by a look-aside into the processor's own store buffer, although given
     // the length of the code path between the prior ST and this load that's
     // highly unlikely).  If the following LD fetches a stale TS_WAIT value
     // then we'll acquire the lock and then re-fetch a fresh TState value.
     // That is, we fail toward safety.

     if (node.TState == ObjectWaiter::TS_WAIT) {
         Thread::SpinAcquire (&_WaitSetLock, "WaitSet - unlink") ;
         if (node.TState == ObjectWaiter::TS_WAIT) {
            DequeueSpecificWaiter (&node) ;       // unlink from WaitSet
            assert(node._notified == 0, "invariant");
            node.TState = ObjectWaiter::TS_RUN ;
         }
         Thread::SpinRelease (&_WaitSetLock) ;
     }

     // The thread is now either on off-list (TS_RUN),
     // on the EntryList (TS_ENTER), or on the cxq (TS_CXQ).
     // The Node's TState variable is stable from the perspective of this thread.
     // No other threads will asynchronously modify TState.
     guarantee (node.TState != ObjectWaiter::TS_WAIT, "invariant") ;
     OrderAccess::loadload() ;
     if (_succ == Self) _succ = NULL ;
     WasNotified = node._notified ;
			
     ...
       
     assert (_owner != Self, "invariant") ;
     ObjectWaiter::TStates v = node.TState ;
     if (v == ObjectWaiter::TS_RUN) {
         enter (Self) ;
     } else {
         guarantee (v == ObjectWaiter::TS_ENTER || v == ObjectWaiter::TS_CXQ, "invariant") ;
         ReenterI (Self, &node) ;
         node.wait_reenter_end(this);
     }

     // Self has reacquired the lock.
     // Lifecycle - the node representing Self must not appear on any queues.
     // Node is about to go out-of-scope, but even if it were immortal we wouldn't
     // want residual elements associated with this thread left on any lists.
     guarantee (node.TState == ObjectWaiter::TS_RUN, "invariant") ;
     assert    (_owner == Self, "invariant") ;
     assert    (_succ != Self , "invariant") ;
   } // OSThreadWaitState()

   jt->set_current_waiting_monitor(NULL);

   guarantee (_recursions == 0, "invariant") ;
   _recursions = save;     // restore the old recursion count
   _waiters--;             // decrement the number of waiters

   // Verify a few postconditions
   assert (_owner == Self       , "invariant") ;
   assert (_succ  != Self       , "invariant") ;
   assert (((oop)(object()))->mark() == markOopDesc::encode(this), "invariant") ;

   if (SyncFlags & 32) {
      OrderAccess::fence() ;
   }

   // check if the notification happened
   if (!WasNotified) {
     // no, it could be timeout or Thread.interrupt() or both
     // check for interrupt event, otherwise it is timeout
     if (interruptible && Thread::is_interrupted(Self, true) && !HAS_PENDING_EXCEPTION) {
       TEVENT (Wait - throw IEX from epilog) ;
       THROW(vmSymbols::java_lang_InterruptedException());
     }
   }

   // NOTE: Spurious wake up will be consider as timeout.
   // Monitor notify has precedence over thread interrupt.
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l1440)

```c++
#define CHECK_OWNER()                                                             \
  do {                                                                            \
    if (THREAD != _owner) {                                                       \
      if (THREAD->is_lock_owned((address) _owner)) {                              \
        _owner = THREAD ;  /* Convert from basiclock addr to Thread addr */       \
        _recursions = 0;                                                          \
        OwnerIsThread = 1 ;                                                       \
      } else {                                                                    \
        TEVENT (Throw IMSX) ;                                                     \
        THROW(vmSymbols::java_lang_IllegalMonitorStateException());               \
      }                                                                           \
    }                                                                             \
  } while (false)
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l1393)

```c++
inline void ObjectMonitor::AddWaiter(ObjectWaiter* node) {
  assert(node != NULL, "should not dequeue NULL node");
  assert(node->_prev == NULL, "node already in list");
  assert(node->_next == NULL, "node already in list");
  // put node at end of queue (circular doubly linked list)
  if (_WaitSet == NULL) {
    _WaitSet = node;
    node->_prev = node;
    node->_next = node;
  } else {
    ObjectWaiter* head = _WaitSet ;
    ObjectWaiter* tail = head->_prev;
    assert(tail->_next == head, "invariant check");
    tail->_next = node;
    head->_prev = node;
    node->_next = head;
    node->_prev = tail;
  }
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l2292)

- 首先 CHECK_OWNER()，判断当前线程是不是 monitor 的所有者，如果不是，将抛出 IllegalMonitorStateException；

- 判断线程是否有未处理的中断，如果存在，则会抛出 InterruptedException 异常；

- jt->set_current_waiting_monitor(this) 将线程的 currentWaitingMonitor 对象设置为当前对象，waiters 数量 +1；

- 创建一个 node，并且通过 AddWaiter (&node) 方法将其加入到 _WaitSet 中（WaitSet 实际上是一个链表）；

- 通过 exit (true, Self) 方法将持有的 monitor 释放掉；

- 通过调用 park (millis) 挂起自己；

- 后续的代码是线程从挂起状态恢复，如果 node 还在 _WaitSet 中，则将其从中去除，同时将 node.TState 的值设置为 ObjectWaiter::TS_RUN；

- 通过 enter (Self) 方法重新获取 monitor；

- jt->set_current_waiting_monitor(NULL) 将线程的 currentWaitingMonitor 对象设置为 NULL，waiters 数量 -1；

- 最后一个就是响应中断。

  > 这里的 enter (Self) 和 exit (true, Self) 可以参考这篇文章中的分析： [Java 多线程学习（6）synchronized 的成神之路](https://blog.csdn.net/haihui_yang/article/details/104259409) ，这里就不再赘述。
  >
  > 其实这里还有很多细节，有些地方我也没看太懂，但是整个代码大致的流程基本上理清楚了；然后从这里也可以知道会抛出 IllegalMonitorStateException 异常的原因，以及线程在 wait 的过程中是会将其 monitor 释放的，在恢复时会去重新获取它；另外，wait 挂起线程使用的底层方法和 LockSupport.park() 方法是一致的，所以这也是为什么这两个方法的 Javadoc 非常相像。

#### 3、Object.notify()

##### （1）`jvm.cpp#JVM_MonitorNotify`：`openjdk/hotspot/src/share/vm/prims/jvm.cpp`

```c++
JVM_ENTRY(void, JVM_MonitorNotify(JNIEnv* env, jobject handle))
  JVMWrapper("JVM_MonitorNotify");
  Handle obj(THREAD, JNIHandles::resolve_non_null(handle));
  ObjectSynchronizer::notify(obj, CHECK);
JVM_END
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/prims/jvm.cpp#l526)

对应到 ObjectSynchronizer::notify 方法。

##### （2）`synchronizer.cpp#ObjectSynchronizer::notify`：`openjdk/hotspot/src/share/vm/runtime/synchronizer.cpp`

```c++
void ObjectSynchronizer::notify(Handle obj, TRAPS) {
 if (UseBiasedLocking) {
    BiasedLocking::revoke_and_rebias(obj, false, THREAD);
    assert(!obj->mark()->has_bias_pattern(), "biases should be revoked by now");
  }

  markOop mark = obj->mark();
  if (mark->has_locker() && THREAD->is_lock_owned((address)mark->locker())) {
    return;
  }
  ObjectSynchronizer::inflate(THREAD, obj())->notify(THREAD);
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l407)

##### （3）`objectMonitor.cpp#notify`：`openjdk/hotspot/src/share/vm/runtime/objectMonitor.cpp`

```c++
void ObjectMonitor::notify(TRAPS) {
  CHECK_OWNER();
  if (_WaitSet == NULL) {
     TEVENT (Empty-Notify) ;
     return ;
  }
  DTRACE_MONITOR_PROBE(notify, this, object(), THREAD);

  int Policy = Knob_MoveNotifyee ;

  Thread::SpinAcquire (&_WaitSetLock, "WaitSet - notify") ;
  ObjectWaiter * iterator = DequeueWaiter() ;
  if (iterator != NULL) {
     TEVENT (Notify1 - Transfer) ;
     guarantee (iterator->TState == ObjectWaiter::TS_WAIT, "invariant") ;
     guarantee (iterator->_notified == 0, "invariant") ;
     if (Policy != 4) {
        iterator->TState = ObjectWaiter::TS_ENTER ;
     }
     iterator->_notified = 1 ;
     Thread * Self = THREAD;
     iterator->_notifier_tid = Self->osthread()->thread_id();

     ObjectWaiter * List = _EntryList ;
     if (List != NULL) {
        assert (List->_prev == NULL, "invariant") ;
        assert (List->TState == ObjectWaiter::TS_ENTER, "invariant") ;
        assert (List != iterator, "invariant") ;
     }

     if (Policy == 0) {       // prepend to EntryList
         if (List == NULL) {
             iterator->_next = iterator->_prev = NULL ;
             _EntryList = iterator ;
         } else {
             List->_prev = iterator ;
             iterator->_next = List ;
             iterator->_prev = NULL ;
             _EntryList = iterator ;
        }
     } else
     if (Policy == 1) {      // append to EntryList
         if (List == NULL) {
             iterator->_next = iterator->_prev = NULL ;
             _EntryList = iterator ;
         } else {
            // CONSIDER:  finding the tail currently requires a linear-time walk of
            // the EntryList.  We can make tail access constant-time by converting to
            // a CDLL instead of using our current DLL.
            ObjectWaiter * Tail ;
            for (Tail = List ; Tail->_next != NULL ; Tail = Tail->_next) ;
            assert (Tail != NULL && Tail->_next == NULL, "invariant") ;
            Tail->_next = iterator ;
            iterator->_prev = Tail ;
            iterator->_next = NULL ;
        }
     } else
     if (Policy == 2) {      // prepend to cxq
         // prepend to cxq
         if (List == NULL) {
             iterator->_next = iterator->_prev = NULL ;
             _EntryList = iterator ;
         } else {
            iterator->TState = ObjectWaiter::TS_CXQ ;
            for (;;) {
                ObjectWaiter * Front = _cxq ;
                iterator->_next = Front ;
                if (Atomic::cmpxchg_ptr (iterator, &_cxq, Front) == Front) {
                    break ;
                }
            }
         }
     } else
     if (Policy == 3) {      // append to cxq
        iterator->TState = ObjectWaiter::TS_CXQ ;
        for (;;) {
            ObjectWaiter * Tail ;
            Tail = _cxq ;
            if (Tail == NULL) {
                iterator->_next = NULL ;
                if (Atomic::cmpxchg_ptr (iterator, &_cxq, NULL) == NULL) {
                   break ;
                }
            } else {
                while (Tail->_next != NULL) Tail = Tail->_next ;
                Tail->_next = iterator ;
                iterator->_prev = Tail ;
                iterator->_next = NULL ;
                break ;
            }
        }
     } else {
        ParkEvent * ev = iterator->_event ;
        iterator->TState = ObjectWaiter::TS_RUN ;
        OrderAccess::fence() ;
        ev->unpark() ;
     }

     if (Policy < 4) {
       iterator->wait_reenter_begin(this);
     }

     // _WaitSetLock protects the wait queue, not the EntryList.  We could
     // move the add-to-EntryList operation, above, outside the critical section
     // protected by _WaitSetLock.  In practice that's not useful.  With the
     // exception of  wait() timeouts and interrupts the monitor owner
     // is the only thread that grabs _WaitSetLock.  There's almost no contention
     // on _WaitSetLock so it's not profitable to reduce the length of the
     // critical section.
  }

  Thread::SpinRelease (&_WaitSetLock) ;

  if (iterator != NULL && ObjectMonitor::_sync_Notifications != NULL) {
     ObjectMonitor::_sync_Notifications->inc() ;
  }
}
```

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l1663)

- 首先调用 CHECK_OWNER()；
- 判断 _WaitSet 是否为空，如果为空，则直接返回；
- 通过 DequeueWaiter() 方法从 _WaitSet 中获取第一个节点 iterator；
- 根据 Policy 的值选择不同的策略
  - Policy = 0，将 iterator 加到 EntryList 的头部；
  - Policy = 1，将 iterator 加到 EntryList 的尾部；
  - Policy = 2，将 iterator 加到 cxq 的头部；
  - Policy = 3，将 iterator 加到 cxq 的尾部；
  - Policy = 4，直接调用 unpark 方法。

可以看到，这里除了 Policy = 4 会调用 unpark 方法外，其他都是将节点加到 EntryList 或者 cxq 中。

> _WaitSet 中的线程是所有调用了 wait 方法的线程，就算锁是处于可用状态，这些线程也不能获取到锁；
>
> 而 EntryList 或者 cxq 中的线程则是已经从 wait 状态中恢复，只是锁不可用，正在等待获取锁。如图所示：
>
> <img src="https://tva1.sinaimg.cn/large/007S8ZIlgy1gdx3u3y7gbj30qw0oen23.jpg" alt="ObjectMonitor 对象示意图" style="zoom: 67%;" />

notify 方法将一个 _WaitSet 的线程移到 EntryList 或者 cxq 中，将其从 wait 状态恢复，等待获取锁。

在当前线程将锁释放后，EntryList 或者 cxq 中的某一个线程会获取到锁，继续执行 wait 方法之后的代码。

释放锁是当前线程执行完同步代码块后，通过 monitorexit 指令实现的。

#### 4、Object.notifyAll()

notifyAll 和 notify 基本上是一样的，区别在于 notify 作用 _WaitSet 中的一个线程，而 notifyAll 是作用于 _WaitSet 中的所有线程；代码上表现为 notify 直接从 _WaitSet 取一个元素，而 notifyAll 则遍历 _WaitSet。

这里就不贴代码了，留下了相应源码的传送门，有兴趣的可以点进去看看。

##### （1）`jvm.cpp#JVM_MonitorNotifyAll`：`openjdk/hotspot/src/share/vm/prims/jvm.cpp`

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/prims/jvm.cpp#l533)

##### （2）`synchronizer.cpp#ObjectSynchronizer::notifyAll`：`openjdk/hotspot/src/share/vm/runtime/synchronizer.cpp`

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/synchronizer.cpp#l421)

##### （3）`objectMonitor.cpp#notifyAll`：`openjdk/hotspot/src/share/vm/runtime/objectMonitor.cpp`

[点击查看源码](http://hg.openjdk.java.net/jdk8/jdk8/hotspot/file/87ee5ee27509/src/share/vm/runtime/objectMonitor.cpp#l1782)

### 三、结语

到这里本文基本上就结束了，文中贴了许多 C++ 源码，极其枯燥无味，能看到这里的人少之又少，下面再啰嗦几句话。

其实 ObjectMonitor::exit 中有些地方没有看懂，因为里面用到了 TEVENT，不知道这个地方怎么去阅读；

又一次暴露了我的 C++ 是多么的菜！哈哈哈！而且可以看到，其实有很多细节都被我直接跳过了。

不过还好，我主要也是了解一下整体的流程、思路，这些应该是对的。当然，如果有不对的地方，欢迎大家指正！

最后看下来，wait 和 notify 挂起和唤醒线程用到的还是 C++ 中的 park 和 unpark 方法，

> 关于 C++ 中的 park 和 unpark 可以看一下这篇文章： 
>
> [Java 多线程学习（7）聊聊 LockSupport.park() 和 LockSupport.unpark()](https://blog.csdn.net/haihui_yang/article/details/105029673)
>
> 里面有详细的分析。

对应到更下层的方法应该就是 pthread_cond_wait()、pthread_cond_signal() 和 pthread_cond_broadcast() 这几个方法，而这几个方法就没有再继续深入研究了，估计在研究下去就要到操作系统级别了，宝宝心里苦呀。

最后再鼓励鼓励自己，这几天不用上班，不过也没花太多时间在写博客上面；希望上班以后，在新的工作环境下，也能够坚持更新自己的博客！

Come On！

