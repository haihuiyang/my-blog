#### 1、Map

`Map` 是一个接口，代表的是 `key-value` 键值对，`Map` 中不能包含重复的 `key` ，一个 `key` 最多对应一个值。有一些 `Map` 的实现允许 `null` 值，一些则不允许 `null` 值。

#### 2、HashMap

基于哈希表的 `Map` 接口实现。除了未实现同步并允许 `null` 值，`HashMap` 和 `HashTable` 大致一样，不过 `HashTable` 基本上已经废弃了，如果需要同步，可以使用 `CurrentHashMap` 作为更好的代替。

下面来看一些 `HashMap` 中核心代码

```
/**
 * Returns a power of two size for the given target capacity.
 */
/*这个方法是基于给定的 size 计算一个不小于 size 的 2^n，实际上相当于把 cap - 1 的
最高位及其后面所有的低位都置为 1，得到 2^n - 1，最后结果 +1 得到 tableSize.
*/
static final int tableSizeFor(int cap) {
    int n = cap - 1;
    n |= n >>> 1;
    n |= n >>> 2;
    n |= n >>> 4;
    n |= n >>> 8;
    n |= n >>> 16;
    return (n < 0) ? 1 : (n >= MAXIMUM_CAPACITY) ? MAXIMUM_CAPACITY : n + 1;
}
```
`HashMap` 底层哈希表的 size 的大小总是 2 的倍数，这是 `HashMap` 在效率上的一个优化：**当底层数组的 `length` 为 `2^n` 时， `h & (length - 1)` 就相当于对 `length` 取模，其效率要比直接取模高得多。**

```
//查找哈希值为 hash，key 为 key 的节点
final Node<K,V> getNode(int hash, Object key) {
    Node<K,V>[] tab; Node<K,V> first, e; int n; K k;
	/*
	第一步，判断表是否为空，如果为空，直接返回null值
    若不为空，通过 hash 值对 table.length 取模（ (n - 1) & hash ）得到该节点在 table 中的下标
    */
    if ((tab = table) != null && (n = tab.length) > 0 &&
        (first = tab[(n - 1) & hash]) != null) {
        //若该下标处有值，比较该位置的第一个元素的 hash 和 key 是否相等
        if (first.hash == hash && // always check first node
            ((k = first.key) == key || (key != null && key.equals(k))))
            return first;
        //这之后的代码就是解决哈希冲突了，不过一般来说不大会走下面的代码
        if ((e = first.next) != null) {
	        /*
	        如果有哈希冲突，就接着往后面找
	        如果哈希冲突较多，使用的是红黑树处理哈希冲突，进行红黑树查找
	        */
            if (first instanceof TreeNode)
                return ((TreeNode<K,V>)first).getTreeNode(hash, key);
            //否则就是简单的链表查找
            do {
                if (e.hash == hash &&
                    ((k = e.key) == key || (key != null && key.equals(k))))
                    return e;
            } while ((e = e.next) != null);
            //遍历完也没找到，说明确实不存在，返回null值
        }
    }
    return null;
}
```

```
//往 HashMap 中存放哈希值为 hash，key 为 key 的节点
final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                   boolean evict) {
        Node<K,V>[] tab; Node<K,V> p; int n, i;
        if ((tab = table) == null || (n = tab.length) == 0)
	        //如果哈希表是空的，就初始化（这里的 resize 其实就是初始化的作用）
            n = (tab = resize()).length;
        if ((p = tab[i = (n - 1) & hash]) == null)
	        //如果该位置没有值，直接放在改位置上
            tab[i] = newNode(hash, key, value, null);
        else {
            Node<K,V> e; K k;
            if (p.hash == hash &&
                ((k = p.key) == key || (key != null && key.equals(k))))
                //如果该位置有值并且 key 一样，把 p 的引用赋给 e
                e = p;
            else if (p instanceof TreeNode)
	            //如果该节点是 TreeNode（说明哈希冲突较多），则执行树的插入算法
                e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
            else {
                for (int binCount = 0; ; ++binCount) {
	                //否则就是从链表里继续找，直到找到相同的 key 或者链表的最后
                    if ((e = p.next) == null) {
                        p.next = newNode(hash, key, value, null);
                        if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
	                        //当链表的元素超过一个阀值是时，将链表转换为红黑树
                            treeifyBin(tab, hash);
                        break;
                    }
                    if (e.hash == hash &&
                        ((k = e.key) == key || (key != null && key.equals(k))))
                        break;
                    p = e;
                }
            }
            if (e != null) { // existing mapping for key
	            //如果不是 putIfAbsent ，则替换原来的值，并且返回原来的值
                V oldValue = e.value;
                if (!onlyIfAbsent || oldValue == null)
                    e.value = value;
                afterNodeAccess(e);
                return oldValue;
            }
        }
        ++modCount;
        if (++size > threshold)
            resize();
        afterNodeInsertion(evict);
        return null;
    }
```
另一个值得注意的是 `HashMap` 的 `resize` 方法，这个方法会在初始化和扩展容量的时候使用。当扩展容量时，`HashMap` 的容量会扩充为原来的 `2` 倍，同时，原来的所有元素需要重新计算哈希值，位置也会发生相应的变化，这是比较耗性能的，如果事先知道 `Map` 的 `size` ，可以在一开始就创建大小适用的 `Map` 以减去 `resize` 的开销。

从上面的代码可以看出来： `HashMap` 是基于散列表，并且用拉链法来解决哈希冲突的。所以 `HashMap` 的底层数据结构是 "数组 + 链表"，即元素是链表的数组。不过当链表的元素个数超过一个阀值( `static final int TREEIFY_THRESHOLD = 8;` )的时候，会将链表转换为红黑树，所以如果哈希冲突多的话，数组的元素将会是红黑树。

拉链法解决哈希冲突示意图：
![拉链法](https://img-blog.csdn.net/20180612223028370?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

#### 4、LinkedHashMap

`LinkedHashMap` 拥有 `HashMap` 的所有特性，它比 `HashMap` 多维护了一个双向链表，因此可以按照插入的顺序从头部或者从尾部迭代，是有序的，不过因为比 `HashMap` 多维护了一个双向链表，它的内存相比而言要比 `HashMap` 大，并且性能会差一些，但是如果需要考虑到元素插入的顺序的话， `LinkedHashMap` 不失为一种好的选择。

#### 5、SortedMap

`SortedMap` 是一个有序的 `Map` 接口，按照自然排序，也可以按照传入的 `comparator` 进行排序，与 `Map` 相比，`SortedMap` 提供了 `subMap(K fromKey, K toKey)，headMap(K toKey)，tailMap(K fromKey)` 等额外的方法，用于获取与元素顺序相关的值。

####  6、TreeMap

`SortedMap ` 的一种实现，与 `HashMap` 不同， `TreeMap` 的底层就是一颗红黑树，它的 `containsKey , get , put and remove` 方法的时间复杂度是 log(n) ，并且它是按照 `key` 的自然顺序（或者指定排序）排列，与 `LinkedHashMap` 不同， `LinkedHashMap` 保证了元素是按照插入的顺序排列。


最后，参考 stackoverflow 上面的一张图片总结一下 `HashMap` ，`LinkedHashMap` ，`TreeMap` 之间的区别：
![HashMap、LinkedHashMap和TreeMap之间的对比](https://img-blog.csdn.net/20180615234647486?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

参考资料：
（1）[Difference between HashMap, LinkedHashMap and TreeMap](https://stackoverflow.com/questions/2889777/difference-between-hashmap-linkedhashmap-and-treemap)
（2）[JDK 1.8 文档](https://docs.oracle.com/javase/8/docs/api/java/util/Map.html)