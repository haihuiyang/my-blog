> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

虚拟机如何加载 Class 文件？Class 文件中的信息进入到虚拟机后会发生什么变化？这些是本文要讨论的内容。

---

### 1、什么是虚拟机的类加载机制？

虚拟机把描述类的数据从 Class 文件加载到内存，并对数据进行校验、转换解析和初始化，最终形成可以被虚拟机直接使用的 Java 类型。这就是虚拟机的类加载机制（通俗一点讲就是把 Class 转成虚拟机可以使用的 Java 类型，转换过程中会有校验、解析和初始化的操作）。

### 2、类的生命周期：

类从被加载到虚拟机内存开始，到卸载出内存为止，它的生命周期包括：加载（Loading）、验证（Verification）、准备（Preparation）、解析（Resolution）、初始化（Initialization）、使用（Using）和卸载（Unloading）七个阶段。其中，验证、准备、解析三个部分统称为连接（Linking）。如下图所示：


![类的生命周期](https://img-blog.csdn.net/2018052016513247?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

图中需要注意的地方：加载、验证、准备、初始化和卸载这五个阶段具有确定的顺序。这个确定的顺序是指"开始"，即验证阶段必须等加载开始之后才能开始，准备阶段开始必须在验证开始之后。而 "进行" 和 "完成" 的顺序则不一定，这些阶段通常都是可以互相交叉地混合式进行的，通常会在一个阶段执行的过程中调用、激活另外一个阶段。

### 3、触发类初始化的条件（有且只有五种情况）：

>- new 一个对象的时候、读取或设置一个类的静态字段（放入常量池的静态字段除外：被 final 修饰的 static 变量）的时候，以及调用一个类的静态方法的时候。
>
>- 反射调用的时候。
>
>- 子类初始化触发父类初始化。
>
>- 执行的主类（包含 main() 方法的那个类）。
>
>- 当使用 JDK 1.7 的动态语言支持时，如果一个 java.lang.invoke.MethodHandle 实例最后的解析结果是 REF_getStatic、REF_putStatic、REF_invokeStatic 的方法句柄的时候。

下面几个例子是类的被动引用，不会触发类的初始化：

（1）通过子类引用父类的静态字段，不会导致子类初始化

```java
public class SuperClass {

    static {
        System.out.println("SuperClass init!");
    }

    public static int value = 123;

}

public class SubClass extends SuperClass {

    static {
        System.out.println("SubClass init!");
    }

}

public class NotInitialization {

    public static void main(String[] args) {
        System.out.println(SubClass.value);//通过子类引用父类的静态字段，不会导致子类初始化
    }
}
```

（2）通过数组定义来引用类，不会触发此类的初始化

```java
public class NotInitialization {

    public static void main(String[] args) {
        SuperClass[] superClassArray = new SuperClass[10]; // 通过数组定义来引用类，不会触发此类的初始化
    }
    // 这段代码不会输出 "SuperClass init!"，即没有触发 SuperClass 的初始化
}
```

（3）常量在编译阶段会存入调用类的常量池中，本质上并没有直接引用到定义常量的类，因此不会触发定义常量的类的初始化

```java
public class ConstClass {

    static {
        System.out.println("ConstClass init!");
    }

    public static final String HELLO_WORLD = "hello world";

}

public class NotInitialization {

    public static void main(String[] args) {
        System.out.println(ConstClass.HELLO_WORLD); // 引用常量池的变量不会触发定义常量的类的初始化
    }
    // 不会输出 "ConstClass init!"
}
```

### 4、类加载的过程

 - #### 加载

	加载阶段，虚拟机通过一个类的全限定名来获取定义此类的二进制流，然后把二进制流的静态存储结构转化为方法区的运行时数据结构，最后在内存中生成一个对象，作为方法区这个类各种数据的访问入口。
	
 - #### 验证（非常重要但非必要）

  验证的目的在于确保 Class 文件的字节流中包含的信息符合当前虚拟机的要求，并且不会危害虚拟机自身的安全。（假如自己编写的及第三方库都已经被反复使用和验证过，那么，可以考虑使用 -Xverify:none 参数关闭大部分的类验证机制，以缩短虚拟机类加载的时间）

  验证阶段大致会完成以下四个验证动作：

  （1）文件格式验证

  （2）元数据验证

  （3）字节码验证

  （4）符号引用验证 

 - #### 准备

   准备阶段是给类成员变量设置初始值（数据类型的零值）。

   这里的类成员变量指被 static 修饰的变量；初始值指数据类型的零值；而常量（被 static final 修饰的变量）会初始化为具体的值。

   例如：

   ```java
   public static final int value = 123;
   // 虚拟机在准备阶段就会根据 ConstantValue 的设置将 value 赋值为 123。
   ```

   数据类型的零值：

   ![数据类型的零值](https://img-blog.csdn.net/20180525234107517?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

 - #### 解析

	解析阶段主要做的事情是虚拟机将常量池内的符号引用替换成直接引用。
	Java 中编译时 `java.lang.NoSuchFieldError`、`java.lang.NoSuchMethodError`、`java.lang.IllegalAccessError` 等异常就是在解析阶段抛出的。
	
 - #### 初始化
	
- 初始化阶段是类加载过程的最后一步。前面我们提到，准备阶段会给类变量设置初始零值，而在初始化阶段，则是给类变量执行代码里真正赋值的时候。
	
	 - 赋值操作由所有类变量的赋值动作和静态语句块中的语句共同产生，编译器收集的顺序是由语句在源文件中出现的顺序所决定的，静态语句块中只能访问到定义在静态语句块之前的变量，定义在它之后的变量，在前面的静态语句块可以赋值，但是不能访问，例如：
	
	```java
	public class Test {
	
	    static {
	        i = 0; // 静态语句块可以给后面定义的类变量赋值，但是不能访问（编译器会报 "非法向前引用" ）
	        // System.out.println(i); Illegal forward reference.
	    }
	
	    static int i = 1;
	
	}
	```
	
	
	>初始化阶段的注意事项：
	>
	>（1）静态成员变量初始化在静态方法之前（ `static {}` 中都是变量赋值）；
	>
	>（2）父类初始化在子类之前
	>
	>（3）执行接口的初始化的时候不需要先执行父接口的初始化，只有当父接口中定义的变量使用时，父接口才会初始化；
	>
	>（4）虚拟机会保证一个类的初始化方法在多线程环境中被正确地加锁、同步：保证了在同一个类加载器下，一个类型只会初始化一次。


参考资料：

（1）《深入理解 Java 虚拟机》周志明 著.