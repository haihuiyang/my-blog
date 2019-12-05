
### 你真的了解 String 吗？

前几天在某乎上面看到了一些关于 String 的讨论：String 能否能够被继承？底层的 `char array` 会不会被共享？以及字符串常量池的一些问题。仔细一想，对于平时频繁的用到 String，还真没有深入的去了解过。于是就开始查询资料，进行深入的学习。

不查不知道，一查吓一跳！原来 String 里面还大有学问！不得不承认，是我太孤陋寡闻了。

以下就是对查阅资料的一个整理，希望能够加深记忆。


#### 1、谈谈 String 的前世今生（Java 6、7/8、9）


![String 的前世今生](https://img-blog.csdnimg.cn/20191202233452340.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n,size_16,color_FFFFFF,t_70)


在 Java 6 及以前，`String` 主要有四个成员变量： `char[] value`、`int offset`、`int count`、`int hash`。 

- `value` 用于字符存储；
- `offset` 为偏移量；
- `count` 为字符数量；
- `hash` 为哈希值。

通过 `offset` 和 `count` 定位 `value` 数组，得到字符串；这种方式可以高效、快速的共享 `value` 数组对象，同时节省内存空间。但是这种方式存在一个潜在的风险：在调用 `substring` 的时候很有可能发生内存泄漏。

我们来看一下 Java 6 的 `substring` 的[实现](http://hg.openjdk.java.net/jdk6/jdk6/jdk/file/b2317f5542ce/src/share/classes/java/lang/String.java#l1941)：


```java
public String substring(int beginIndex, int endIndex) {
    if (beginIndex < 0) {
        throw new StringIndexOutOfBoundsException(beginIndex);
    }
    if (endIndex > count) {
        throw new StringIndexOutOfBoundsException(endIndex);
    }
    if (beginIndex > endIndex) {
        throw new StringIndexOutOfBoundsException(endIndex - beginIndex);
    }
    return ((beginIndex == 0) && (endIndex == count)) ? this :
        new String(offset + beginIndex, endIndex - beginIndex, value);
        //新创建的 String 共享原有对象的 value 引用
}

// Package private constructor which shares value array for speed.
String(int offset, int count, char value[]) {
    this.value = value;// value 直接拿过来用
    this.offset = offset;
    this.count = count;
}
```

我们可以看到，由 `substring` 新生成的 `String` 对象共享了原有对象的 `value` 引用。如果 `substring` 的对象一直被引用，且原有 `String` 对象非常大，就会导致原有 `String` 对象的字符串一直无法被 GC 释放，从而导致[内存泄漏](https://zh.wikipedia.org/wiki/%E5%86%85%E5%AD%98%E6%B3%84%E6%BC%8F)。

到了 Java 7/8，`String` 的成员变量变成了两个： `char[] value`、`int hash`；没错，`int offset`、`int count` 被去掉了，`substring` 的实现也做了一定的调整：


```java
public String substring(int beginIndex, int endIndex) {
    if (beginIndex < 0) {
        throw new StringIndexOutOfBoundsException(beginIndex);
    }
    if (endIndex > value.length) {
        throw new StringIndexOutOfBoundsException(endIndex);
    }
    int subLen = endIndex - beginIndex;
    if (subLen < 0) {
        throw new StringIndexOutOfBoundsException(subLen);
    }
    return ((beginIndex == 0) && (endIndex == value.length)) ? this
            : new String(value, beginIndex, subLen);
}

public String(char value[], int offset, int count) {
    if (offset < 0) {
        throw new StringIndexOutOfBoundsException(offset);
    }
    if (count < 0) {
        throw new StringIndexOutOfBoundsException(count);
    }
    // Note: offset or count might be near -1>>>1.
    if (offset > value.length - count) {
        throw new StringIndexOutOfBoundsException(offset + count);
    }
    // copy 了一份 value，而不是直接使用 value
    this.value = Arrays.copyOfRange(value, offset, offset+count);
}

```

在调用 `substring` 的时候，不是共享原有的 `value` 数组，而是 `copy` 了一份。这样就解决了可能发生的内存泄漏问题。


在 Java 9 发布后，`String` 的成员变量又做了一次调整：`char[] value`、`byte coder`、`int hash` ；

为什么要这样子改呢？因为 oracle 公司觉得，用两个字节长度的 `char` 来存一个字节长度的 `byte` 有点过于浪费，为了节省空间，采用 `byte[]` 来存储字符串。除此之外，Java 9 还维护了一个新的属性 `coder`，作为编码格式的标志，在计算字符串长度和比较字符串的时候会用到它。


既然节省了空间，那我们就来看一下 `"Hello World"` 在 Java 8 和 9 下的内存大小分别是多少，看看能节省多少空间。（均在 64 位系统、开启指针压缩前提下计算。对象内存大小计算可参考：[深入理解Java虚拟机之----对象的内存布局](https://blog.csdn.net/haihui_yang/article/details/81071693)）

**Java 8 下大小为：64 bytes**

 （1）String 对象本身：24 bytes
 
 - 对象头：Mark Word(8) + 类型指针(4)
 - hash(4)
 - value[] 引用(4)
 - 对齐填充(4)

 （2）value[] 字符串：40 bytes
 
 - 对象头：Mark Word(8) + 类型指针(4) + 数组长度(4)
 - "Hello World"：**`char length(2)`** * array length(11)
 - 对齐填充(2) 


**Java 9 下的大小为：56 bytes**

 （1）String 对象本身：24 bytes
 
 - 对象头：Mark Word(8) + 类型指针(4)
 - hash(4)
 - **`coder(1)`**
 - 对齐填充(3)
 - value[] 引用(4)

 （2）value[] 字符串：32 bytes
 
 - 对象头：Mark Word(8) + 类型指针(4) + 数组长度(4)
 - "Hello World"：**`byte length(1)`** * array length(11)
 - 对齐填充(5) 

我们可以看到，Java 9 存储 String 对象本身和 Java 8 是一样的，虽然多了一个 `byte coder`，实际上占用的是对齐填充的一个字节，没有额外的存储开销；不过对于存储字符串的长度是大大减少了。`byte` 只需要一个字节存储，而 `char` 需要两个字节来存储，这样一来，`value[]` 数组的这一部分实例数据长度减半，大大减小了内存开销，并且字符串长度越长，节省的就越多。

没想到吧？JDK 在升级，String 也一直在改变，这些变化你都知道吗？

还没有升级的小伙伴们是不是也可以考虑一下要不要升级 JDK 的版本（坏笑😏）。

好了，我们缓一缓，歇口气。接下来我们进入下一个环节：**String 真的是 immutable 的吗？**

#### 2、String 真的是 immutable 的吗？

刚开始看到这个问题的时候，我就在思考：到底怎么才算 `immutable` 呢？

String 文档上写有这么一句话（[JDK 8#String](http://hg.openjdk.java.net/jdk8/jdk8/jdk/file/687fd7c7986d/src/share/classes/java/lang/String.java#l47)）：

```
 Strings are constant; their values cannot be changed after they are created.
```
`String 对象一旦被创建，它们的值就无法改变。` 

Why？为什么是这样子的呢？我带着疑问继续看了下去。紧接着我就看到 String 是一个 `final` 类----这代表了它不可被继承；另外，String 有两个成员变量：

```java
/** The value is used for character storage. */
private final char value[];

/** Cache the hash code for the string */
private int hash; // Default to 0
```

一个被 `final` 修饰的 `value[]` 数组，用于存储字符串；和一个 `int` 型的 `hash`，字符串的哈希值。看完 String 源码之后发现，这两个值在 String 被创建的时候初始化，并且没有对外提供任何修改它们的方法。所以我们可以看出 String 的不可变性体现在：

- **类不可被继承**
- **没有对外提供任何修改内部成员变量的方法**

即：对象一旦被创建，即是不可变对象。

因为没办法通过常规的手段对 String 做修改。那么，是否真的就无法修改 String 对象了呢？

结果很显然：既然常规的手段不行，那就用非常规的手段嘛（手动滑稽）。

可能大家已经想到非常规的手段是什么了：反射。没错，就是反射！反射就是这么的强大！这里贴一段来自 `stackoverflow` 上的代码：

```java
String s1 = "Hello World";  
String s2 = "Hello World";  
String s3 = s1.substring(6);  
System.out.println(s1); // Hello World  
System.out.println(s2); // Hello World  
System.out.println(s3); // World  

Field field = String.class.getDeclaredField("value");  
field.setAccessible(true);  
char[] value = (char[])field.get(s1);  
value[6] = 'J';  
value[7] = 'a';  
value[8] = 'v';  
value[9] = 'a';  
value[10] = '!';  

System.out.println(s1); // Hello Java!  
System.out.println(s2); // Hello Java!  
// 注意：Java 7 及之后输出为 World，Java 6 及之前版本为 Java! 具体原因请读者自己思考，参考 substring 的具体实现。
System.out.println(s3); // World
```

从上面的代码可以看出，String 还是可以被修改的。

由此可见，从其提供的公用接口来看，String 是 `immutable` 的。但是如果使用一些非常规手段，也是可以修改 String 对象的。


#### 3、String 为什么要设计成 `immutable` ？

上一节我们知道了在不使用非常规的前提下： **String 是 `immutable` 的**。那么，为什么要这样设计呢？

可以参考这篇文章：[Why String is Immutable in Java?](https://www.baeldung.com/java-string-immutable)

主要有以下几个原因：

- **满足常量池的特性**


String 是使用最广泛的数据结构。常量池的存在可以节省很多内存，因为值一样的不同 String 变量在常量池中只保存了一份，它们指向的是同一个对象。如果 String 是 `mutable` 的，那么如果其中一个 String 变量发生了改变，势必会影响到所有其他指向这个对象的 String 变量，很显然很不合理。

举个栗子：

```java
String s1 = "Hello World";
String s2 = "Hello World"
```

因为常量池的存在，没办法做到只修改 `s1` 变量而不影响 `s2` 变量。

所以，如果想把值一样的不同 String 变量在常量池中只保存一份，String 就必须是 `immutable` 的。

- **出于安全性上的考虑**

String 被广泛用于存储敏感信息，例如：`usernames`, `passwords`, `connection URLs`, `network connections` 等等，以及 JVM 类加载器也广泛使用了 String。

如果 String 是 `mutable` 的，很可能造成不可控的安全问题。比如看下面的代码：

```java
void criticalMethod(String username) {
    // perform security checks
    if (!isAlphaNumeric(username)) {
        throw new SecurityException(); 
    }
     
    // do some secondary tasks
    initializeDatabase();
     
    // critical task
    connection.executeUpdate("UPDATE Customers SET Status = 'Active' " +
      " WHERE Username = '" + username + "'");
}
```

因为在方法的外部持有 `username` 的引用，即使在验证了 `username` 以后，我们也没办法保证后面执行 `executeUpdate` 就一定是安全的，因为没法保证在执行安全检查之后 `username` 没有发生改变。


- **线程安全**

不可变，所以先天线程安全；

- **缓存 hash 值**

String 的使用实在是是太广泛了，各种各样的数据结构都会用到 String，对于依赖于 `hash` 值的 `HashMap`, `HashTable`, `HashSet` 这种数据结构，会频繁的调用 `hashCode()` 方法，由于 String 类不可变，所以 String 类重写了 `hashCode()` 方法，在第一次调用 `hashCode()` 计算 `hash` 值之后就把 `hash` 值缓存了起来，下次调用时不需要再进行计算，极大的提高了效率。

总体来说, String 不可变的原因包括**常量池的设计**、**性能**以及**安全性**这三大方面。


#### 4、String#intern() ：经典的面试题----你能答对吗？

下面这些是在搜索了众多资料之后整理的面试题。

在没有深入研究 String 之前，有好多都答不上来(= =)。

往下看之前需要了解的知识点：`==` 在比较引用类型时，比较的是引用地址。


**Case 1**

```java
	String s1 = new String("hello");
```

问：创建了几个 String 对象？

答：参考 R大的回答：[请别再拿“String s = new String("xyz");创建了多少个String实例”来面试了吧](https://www.iteye.com/blog/rednaxelafx-774673)

**Case 2**

```java
	String s1 = "hello";
	String s2 = "hello";
	System.out.println(s1 == s2);
```

答：输出 `true`，`s1`、`s2` 均指向常量池中 `"hello"` 的地址。

**Case 3**

```java
	String s1 = "hello";
	String s2 = new String("hello");
	System.out.println(s1 == s2);
```

答：输出 `false`，`s1` 为常量池中的地址，而 `s2` 为堆上 `new` 出来的对象。

**Case 4**

```java
	String s1 = "hello";
	String s2 = "he";
	String s3 = "llo";
	String s4 = s2 + s3;
	System.out.println(s1 == s4);
```

答：输出 `false`，上述代码等价于：


```java
	String s1 = "hello";
	String s2 = "he";
	String s3 = "llo";
	String s4 = (new StringBuilder()).append(s2).append(s3).toString();
	System.out.println(s1 == s4);
```

`s4` 是 `StringBuilder#toString()` 方法 `new` 出来的对象。

**Case 5**

```java
	String s1 = "hello";
	final String s2 = "he";
	final String s3 = "llo";
	String s4 = s2 + s3;
	System.out.println(s1 == s4);
```

答：输出 `true`，由于 `s2`、`s3` 是被 `final` 修饰的 String 变量，编译器在编译的时候就能推断出 `s4 = 'hello'`，所以上述代码等价于：

```java
	String s1 = "hello";
	String s4 = "hello";
	System.out.println(s1 == s4);
```

**Case 6**

```java
	String s1 = "hello";
	String s2 = new String("hello");
	System.out.println(s1 == s2);
	System.out.println(s1 == s2.intern());
```

答：输出 `false true`，`s1` 为常量池中地址，`s2` 为堆上 `new` 出来的对象，`s2.intern()` 为常量池中地址。


**Case 7**

```java
	String s1 = new String("hello");//(1)
	s1.intern();//(2)
	String s2 = "hello";//(3)
	System.out.println(s1 == s2);//(4)
	
	String s3 = new String("wo") + new String("rld");//(5)
	s3.intern();//(6)
	String s4 = "world";//(7)
	System.out.println(s3 == s4);//(8)
```

答：输出：

- `false false` (JDK 1.6 及以下)

- `false true`  (JDK 1.7 及以上) 

可以先思考以下为什么会是这种结果，然后我们再来看一看到底发生了什么：

- (1) 执行时会在常量池创建一个值为 `"hello"` 的字符串对象，同时在堆上也创建一个值为 `"hello"` String 对象；

- (2) 执行时会首先去常量池中查看是否存在一个值为 `"hello"` 的常量，发现 `"hello"` 存在于常量池，所以直接返回常量池中 `"hello"` 的引用；

- (3) 执行时发现 `"hello"` 已经存在于常量池，因此直接返回常量池中的引用；

- (4) 由于 `s1` 指向的是堆上 `new` 出来的 String 对象引用，而 `s2` 为常量池中的引用，所以输出为 `false`。

- (5) 执行时会在常量池创建两个字符串对象，一个是 `"wo"`，另一个是 `"rld"`，同时在堆上创建了三个 String 对象，分别为两个 `new` 关键字创建的 `"wo"` 、 `"rld"`，和 `StringBuilder` 将两个 `new` 出来的 String 对象 `append` 之后调用 `toString()` 方法创建的 `"world"` 对象，注意，此时 `"world"` 并未在常量池中；

- (6) 执行时会首先去常量池中查看是否存在值为 `"world"` 的常量，发现不存在，则把 `"world"` 放入常量池，并返回其引用；

	- 在 JDK 1.6 及之前的版本，常量池是放在 PermGen 区的，所以放入常量池的操作为：在 PermGen 区创建一个值为 `"world"` 的对象，将其引用放入常量池并返回。

	- 而 在 JDK 1.7 及之后，常量池被移至 Heap 区，放入常量池的操作就变成了：直接将堆中 `s3` 对象的引用放入常量池并返回。

	- 这也是为什么 **case 7** 在不同的 JDK 版本下输出结果不一样的原因。

- (7) 执行时发现 `"world"` 已经存在于常量池，因此直接返回常量池中的引用；

- (8) 对比 `s3` 与 `s4` 的值，并将结果打印出来。由于在 JDK 1.6 中，`s3` 与 `s4` 为两个不同的对象，因此输出 `false`；而在 JDK 1.7 里，二者是同一个对象，所以输出为 `true`。


**Case 8**

```java
	String s1 = new String("hello");
	String s2 = "hello";
	s1.intern();
	System.out.println(s1 == s2);
	
	String s3 = new String("wo") + new String("rld");
	String s4 = "world";
	s3.intern();
	System.out.println(s3 == s4);
```

答：输出：

- `false false` (JDK 1.6 及以下)

- `false false` (JDK 1.7 及以上) 

**Case 8** 留给大家分析，可以参考 **Case 7**


#### 5、关于运行时如何将 String 变量放入常量池中的思考

最后，还有一个问题困扰了我很久：不在常量池的 String 变量在调用 `intern()` 方法时，是如何放入常量池的？对于 `""` 这种方式创建的变量会自动放入常量池，那对于

```java 	
	String s3 = new String("wo") + new String("rld");
	s3.intern();
```

这种方式又是怎么放入常量池的呢？（假设调用 `intern()` 时 `"world"` 没有存在于常量池）

比如 `new String("hello world");` 这一行代码我通过反编译得到字节码可以看到每一步都在做什么：

```
  stack=3, locals=1, args_size=1
     0: new           #2                  // class java/lang/String
     3: dup
     4: ldc           #23                 // String hello world
     6: invokespecial #24                 // Method java/lang/String."<init>":(Ljava/lang/String;)V
     9: pop
    10: return

```

而对于 `intern()` 方法来说，只有一行


```
	11: invokevirtual #25                 // Method java/lang/String.intern:()Ljava/lang/String;
```

这个时候我在想，既然 `ldc` 是从常量池中变量推送至栈顶，那么为什么没有相应的将变量放入常量池的指令呢？

其实这个时候我已经跑偏了，这应该属于 JVM 是如何实现常量池的范畴了。

其实通过 `""` 这种方式创建的 String 对象会放入常量池，也没有相应的指令，在 Java 字节码层次我们只能看到 `ldc` 指令，即如何将常量池中的变量推送至栈顶。而对于 `native` 的 `intern()` 方法，是 C++ 写的，也不清楚当中到底做了什么操作，这个时候就恨不得自己能快速看懂 C++ 源码。虽然从大学毕业后几乎就没接触过 C++，想吃透 C++ 中 `intern()` 的实现，可不是一件简单的事情；不过看了一下其中的实现：[jvm.cpp#l3639](http://hg.openjdk.java.net/jdk7/jdk7/hotspot/file/tip/src/share/vm/prims/jvm.cpp#l3639) 和 [symbolTable.cpp#l543](http://hg.openjdk.java.net/jdk7/jdk7/hotspot/file/tip/src/share/vm/classfile/symbolTable.cpp#l543)，还是能了解一些大概：

```c++
oop StringTable::intern(Handle string_or_null, jchar* name,  
                        int len, TRAPS) {  
  unsigned int hashValue = java_lang_String::hash_string(name, len);  
  int index = the_table()->hash_to_index(hashValue);  
  oop string = the_table()->lookup(index, name, len, hashValue);  
  // Found  
  if (string != NULL) return string;  
  // Otherwise, add to symbol to table  
  return the_table()->basic_add(index, string_or_null, name, len,  
                                hashValue, CHECK_NULL);  
}   
```

调用 `intern()` 方法时，会先去 `the_table()` 中找，如果找到就直接返回；否则将其加至 `the_table()` 中并返回。


##### 结语：原本以为写一个 String 相关的博客会很简单，不会有太多的文字，谁知道写着写着居然写了这么多，每次快要停笔的时候突然又发现新的知识点。写的时候，可能是因为自己是处女座的吧，写了改，改了删，删了写，想尽自己最大的努力用最简单的语言把想说的表达出来，可是总感觉有些地方不到位。其实在刚开始写的时候很多地方都下不了笔，因为理解不够透彻，很多问题都答不上来，没办法下笔；于是就开始搜索资料，看各位大佬分享的关于 String 的心得和体会，找到的知识点也多了起来，虽然说这些不一定是最全的关于 String 的只是，但比起写之前对于 String 的理解是要强太多了。

最后，送一句话给自己，也送给大家：**每天再忙也应该给自己留点成长的时间！**


参考链接：

（1）[java String的intern方法](https://m.xp.cn/b.php/76117.html)

（2）[Java8内存模型—永久代(PermGen)和元空间(Metaspace)](https://www.cnblogs.com/paddix/p/5309550.html)(标题其实有误，应该是 Java8 运行时数据区，这里参考链接展示原标题)

（3）[深入解析String#intern](https://tech.meituan.com/2014/03/06/in-depth-understanding-string-intern.html)

（4）[Save Memory by Using String Intern in Java](https://blog.codecentric.de/en/2012/03/save-memory-by-using-string-intern-in-java/)

（5）[Is a Java string really immutable?](https://stackoverflow.com/questions/20945049/is-a-java-string-really-immutable)

（6）[Why is String immutable in Java?](https://stackoverflow.com/questions/22397861/why-is-string-immutable-in-java)