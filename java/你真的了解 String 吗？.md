### 你真的了解 String 吗？

前几天在某乎上面看到了一些关于 String 的讨论：String 能否能够被继承？底层的 char array 会不会共享？以及字符串常量池的一些问题。仔细一想，对于平时频繁的用到 String，还真没有深入的去了解过它。于是就开始查询资料，进行学习，不查不知道，一查吓一跳！原来 String 里面还有这么大的学问！以下就是对查阅到的资料的一个整理，希望能够加深记忆：

#### 1、String 的前世今生（Java 6、7/8、9）



#### 2、String 真的是 immutable 的吗？

#### 3、String 为什么要设计成 immutable ？

#### 4、String#intern() 


参考链接：

（1）[java String的intern方法](https://m.xp.cn/b.php/76117.html)

（2）[Java8内存模型—永久代(PermGen)和元空间(Metaspace)](https://www.cnblogs.com/paddix/p/5309550.html)(标题其实有误，应该是 Java8 运行时数据区，这里参考链接还是展示原标题)

（3）[深入解析String#intern](https://tech.meituan.com/2014/03/06/in-depth-understanding-string-intern.html)

（4）[Save Memory by Using String Intern in Java](https://blog.codecentric.de/en/2012/03/save-memory-by-using-string-intern-in-java/)

（5）[Is a Java string really immutable?](https://stackoverflow.com/questions/20945049/is-a-java-string-really-immutable)

（6）[Why is String immutable in Java?](https://stackoverflow.com/questions/22397861/why-is-string-immutable-in-java)