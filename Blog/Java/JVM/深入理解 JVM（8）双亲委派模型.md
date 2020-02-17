> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

双亲委派模型（至于为什么叫这个请看参考资料第二点）

![双亲委派模型](https://img-blog.csdn.net/20180922202553893?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

上图即是类加载器的双亲委派模型。

**通俗一点来说，对于任意层次的类加载器接到了类加载的请求，它首先不会自己去尝试加载这个类，而是把这个请求委派给上一层的父类加载器去完成，当父类加载器无法完成加载请求时，子加载器才会尝试自己去加载。**

---

### 一、类加载器种类

#### 1、从虚拟机角度来看讲，只存在两种不同的类加载器：

- 启动类加载器（Bootstrap ClassLoader）

	这个类加载器使用 C++ 语言实现，是虚拟机自身的一部分

- 其他所有类加载器

	除开启动类加载器的所有其他类加载器，这些类加载器均由 Java 语言实现，并且全部继承于抽象类 `java.lang.ClassLoader` 。

#### 2、从 Java 开发人员的角度来看，类加载器可以按照以下类型进行划分：

- 启动类加载器（Bootstrap ClassLoader）

	前面已经介绍过，这个类加载器负责将存放在 `<JAVA_HOME>/lib`  目录中的，或者被 `-Xbootclasspath` 参数指定的路径中的，并且是虚拟机识别的类库加载到虚拟机内存中。启动类加载器无法被 Java 程序直接引用，用户在编写自定义类加载器时，如果需要把加载请求委派为引导类加载器，那直接使用 `null` 替代即可。

- 扩展类加载器（Extension ClassLoader）

	由 `sun.misc.Launcher$ExtClassLoader` 实现，它负责加载 `<JAVA_HOME>/lib/ext` 目录中的，或者被 `java.ext.dirs` 系统变量所指定的路径中的所有类库，开发者可以直接使用。

- 应用程序类加载器（Application ClassLoader）

	由 `sun.misc.Launcher$AppClassLoader` 实现，由于它是 `ClassLoader` 中的
`getSystemClassLoader()` 方法的返回值，所以一般也称它为系统类加载器。它负责用户类路径（ClassPath）上所指定的类库，开发者可以直接使用。如果用户没有自定义类加载器，那么它就是程序中默认的类加载器。

- 自定义类加载器（User ClassLoader）

	用户自定义的类加载器，也是继承自 `ClassLoader` 。

>类加载器之间的层级关系：启动类加载器位于类加载器的最顶层，它本身之上没有 `parent` ，由于它是由 C++ 实现，所以它也不是一个对象，在 Java 中一般用 `parent=null` 来表示；然后依次为扩展类加载器，应用程序类加载器和自定义类加载器，即：自定义类加载器的 `parent` 为应用程序类加载器，应用程序类加载器的 `parent` 为扩展类加载器，扩展类加载器的 `parent=null` 即为启动类加载器；当然这属于一般情况，其实，自定义类加载器的 `parent` 也可以为启动类加载器，只需将自定义类加载器的 `parent` 设置为 `null` 即可。

### 二、双亲委派模型

双亲委派模型实现很简单，就是 `ClassLoader#loadClass` 方法，请看 `loadClass` 方法中的代码：

```java
protected Class<?> loadClass(String name, boolean resolve)
    throws ClassNotFoundException
{
    synchronized (getClassLoadingLock(name)) {
        // First, check if the class has already been loaded
        Class<?> c = findLoadedClass(name);
        if (c == null) {
            long t0 = System.nanoTime();
            try {
                if (parent != null) {
                    c = parent.loadClass(name, false);
                } else {
                    c = findBootstrapClassOrNull(name);
                }
            } catch (ClassNotFoundException e) {
                // ClassNotFoundException thrown if class not found
                // from the non-null parent class loader
            }

            if (c == null) {
                // If still not found, then invoke findClass in order
                // to find the class.
                long t1 = System.nanoTime();
                c = findClass(name);

                // this is the defining class loader; record the stats
                sun.misc.PerfCounter.getParentDelegationTime().addTime(t1 - t0);
                sun.misc.PerfCounter.getFindClassTime().addElapsedTimeFrom(t1);
                sun.misc.PerfCounter.getFindClasses().increment();
            }
        }
        if (resolve) {
            resolveClass(c);
        }
        return c;
    }
}
```

首先，类加载肯定得是一个同步操作，在加载前先检查类是否已经被加载过，防止一个类被加载多次。接着就是我们要说的双亲委派模型了：**首先判断这个类是否存在 `parent` ，如果存在，则委派给 `parent` 去加载（这是一个向上递归调用的过程），如果不存在则委派给启动类加载器去加载；当这两者都无法加载时，才调用自身的 `findClass` 方法去加载，这就是我们所说的双亲委派模型。**

双亲委派模型有一个显而易见的好处：就是 Java 类随着它的类加载器一起具备了一种带有优先级的层次关系。例如类 `java.lang.Object` ，它存放在 `rt.jar` 之中，无论哪一个类加载器要加载这个类，最终都是委派给处于模型最顶端的启动类加载器进行加载，因此 `Object` 类在程序的各种类加载器环境中都是同一个类。相反，如果没有使用双亲委派模型，由各个类加载器自行去加载的话，如果用户自己编写了一个称为 `java.lang.Object` 的类，并放在程序的 `ClassPath` 中，那系统中将会出现多个不同的 `Object` 类， Java 类型体系中最基础的行为也就无法保证，应用程序也将会变得一片混乱。

参考资料：

（1）《深入理解 Java 虚拟机》周志明 著.

（2）[哪些专有名词翻译得特别烂？](https://www.zhihu.com/question/27192923/answer/35664179)