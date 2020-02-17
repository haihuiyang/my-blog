> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

在平时写代码的过程中集合会经常被用到，类似于 Map、List、Set 等等，相应的，集合工具类也会被频繁的使用，下面我们来瞅一瞅 java.util 包下的 Collections 类提供了哪些有用的方法。

---

### 1、Collections 类介绍


```java
    // Suppresses default constructor, ensuring non-instantiability.
    private Collections() {
    }
```

首先，Collections 类将自己的构造函数私有化，保证不会创建 Collections 的实例（自己项目中写的工具类也应该是这样）。

```java
    private static final int BINARYSEARCH_THRESHOLD   = 5000;
    private static final int REVERSE_THRESHOLD        =   18;
    private static final int SHUFFLE_THRESHOLD        =    5;
    private static final int FILL_THRESHOLD           =   25;
    private static final int ROTATE_THRESHOLD         =  100;
    private static final int COPY_THRESHOLD           =   10;
    private static final int REPLACEALL_THRESHOLD     =   11;
    private static final int INDEXOFSUBLIST_THRESHOLD =   35;
```

紧接着，声明了许多阀值，这些阀值是做啥用的呢？稍安勿躁，人家在文档里面说明了， 许多 List 算法有两种实现，其中一种适用于 RandomAccess 列表，而另一种则适用于 sequential 列表；通常来说，随机存取列表和数量不大的顺序列表使用 RandomAccess 算法拥有更好的性能，所以上面的阀值就是为顺序列表挑选算法用的。而为什么 BINARYSEARCH_THRESHOLD=5000 而不是 3000 呢？因为这是由性能测试工作人员不断的验证之后得到的结果，而不是随随便便写上去的，其他的阀值亦是如此。

好的，接下来就是具体的工具方法了。

以下几个方法都是针对于 List 的：

#### （1）sort：排序，要求 List 中的所有元素可比较，Collections 中提供了两个方法排序。

- `void sort(List<T> list)` ：直接传一个 List ，按照自然顺序排序；

- `void sort(List<T> list, Comparator<? super T> c)` ：传入一个 List 和一个 Comparator，根据 Comparator 排序。

#### （2）binarySearch：二分查找，要求 List 中元素有序。

- `int binarySearch(List<? extends Comparable<? super T>> list, T key)` ： List 必须是有序的，且按照自然顺序排序；

- `int binarySearch(List<? extends T> list, T key, Comparator<? super T> c)` ： List 和一个 Comparator，List 必须有序，且根据 Comparator 排序。

#### （3）reverse：反转。

- `void reverse(List<?> list)` ：将 List 反转

#### （4）shuffle：洗牌，打乱顺序。

- `void shuffle(List<?> list)`：按照系统自动生成的随机数将 List 顺序打乱；

- `void shuffle(List<?> list, Random rnd)`：按照指定的随机数将 List 顺序打乱。

下面的方法是针对于 Collection 的：

#### （5）min/max：求极值，求集合的最大值和最小值，均提供了两种方式，自然排序及指定排序规则。

- `T min(Collection<? extends T> coll)`

- `T max(Collection<? extends T> coll)`

- `T min(Collection<? extends T> coll, Comparator<? super T> comp)`

- `T max(Collection<? extends T> coll, Comparator<? super T> comp)`

#### （6）unmodifiable**：返回 ** 的一个不可变的 view，例如 unmodifiableMap 就是返回一个不可变的 Map 的 view。

- `**<T> unmodifiable**(**<? extends T> c)`

#### （7）synchronized**：返回一个实现了同步的 ** ，例如 synchronizedMap 就是返回一个实现同步的 Map 。

- `**<T> synchronized**(**<? extends T> c)`

> 备注：6 和 7 都是通过静态内部类实现的，在传入的集合外封装了一层，添加了 unmodifiable 或 synchronized 属性，从而实现不可变及同步的。

#### （8）empty** ：返回一个单例的、不可变的空集合，例如 emptyMap 就是返回一个 static final 的、不可变的空 Map 。

- `**<T> empty**()`

- 和返回 Optional.empty() 代表没有一样，很多情况下，我们返回空的集合来代表没有或者避免返回 null 值，如果我们能确定在程序后面不会对该集合做修改，那么返回 Collections.empty**() 会省去新建对象的开销，因为它是 static final 的。

#### （9）以上列出了 Collections 中绝大部分的工具方法，还有些许没列出来的，基本上也很少用到，有兴趣的同学可以去看一下源码了解一下。

### 2、总结

- 实际应用中用的最多的方法应该是 sort、binarySearch、min/max 及empty** 。 
- 当需要对 List 排序时，可以直接调用 Collections.sort() 方法；
- 当要查找 List 中的元素且 List 是有序时，可以使用 Collections.binarySearch；
- 当需要查找集合中的极值时，调用 Collections.min()/Collections.max()；
- 而需要返回一个空的不可修改的集合时，可以调用 Collections.empty**()。



> #### 不积跬步无以至千里，不积小流无以成江河！
> #### 不积跬步无以至千里，不积小流无以成江河！
> #### 不积跬步无以至千里，不积小流无以成江河！
> #### 重要的事说三遍！

参考资料：

（1）[https://docs.oracle.com/javase/7/docs/api/java/util/Collections.html](https://docs.oracle.com/javase/7/docs/api/java/util/Collections.html)