## 语法糖（Syntactic sugar） ##

----------
语法糖（Syntactic sugar），也译为糖衣语法，是由英国计算机科学家彼得·约翰·兰达（Peter J. Landin）发明的一个术语，指计算机语言中添加的某种语法，这种语法对语言的功能并没有影响，但是更方便程序员使用。通常来说使用语法糖能够增加程序的可读性，从而减少程序代码出错的机会。                   ------摘自百度百科

----------

Java 语言中主要的语法糖有：泛型、自动装箱、自动拆箱、遍历循环、变长参数、条件编译、内部类、和 try 语句中定义和关闭资源等。本文主要通过跟踪 javac 源码、反编译 Class 文件等方式去了解它们的本质实现。

##### 1、泛型和类型擦除

泛型是 JDK 1.5 的一项新增特性，它的本质是参数化类型（Prametersized Type）的应用，也就是说说操作的数据类型被指定为一个参数。这种参数类型可以用在类、接口和方法的创建中，分别称为泛型类、泛型接口和泛型方法。

Java 语言中泛型是一种伪泛型。怎么理解呢？它只在程序源码中存在，在编译之后的字节码文件中，就已经替换成原生类型了，并在相应的地方插入了强制转型代码。对于运行期的 Java 语言来说，`ArrayList<String>` 和 `ArrayList<Double>` 就是同一个类。

至于 Java 为什么要这样子实现，可以参考一下知乎里面 R大 的回答 [
Java不能实现真正泛型的原因？](https://www.zhihu.com/question/28665443/answer/118148143)

下面我们来看一个例子：

```
/* 编译前 Java 代码 */
public class GenericSyntacticSugar {

    public void test() {
        List<String> names = new ArrayList<>();

        names.add("a");

        String name = names.get(0);
    }
}
```
将上面这段代码编译成 Class 文件：

```
/* 编译后 Class 文件 */
public class GenericSyntacticSugar {
    public GenericSyntacticSugar() {
    }

    public void test() {
        ArrayList var1 = new ArrayList();//这里已经没有<String>类型了
        var1.add("a");
        String var2 = (String)var1.get(0);//使用的时候添加强制转型
    }
}
```
可以看到，在编译后的 Class 文件中，泛型不见了！！！并且在使用的地方加了强制转型。这也就是我们常说的**类型擦除**。


##### 2、自动装箱与自动拆箱

自动装箱是 Java 编译器在基本类型和相应的对象包装类之间进行的自动转换。例如，将 int 转换为 Integer ，将 double 转换为 Double ，等等。如果转换以另一种方式进行，例如，将 Integer 转换为 int，这称为自动拆箱。

自动装箱发生的条件：当一个原始类型变量

1）作为参数传递给期望对应包装器类的对象的方法。

2）分配给相应包装器类的变量。

相应的，自动拆箱触发于：当一个包装器类变量

1）作为参数传递给期望对应基元类型值的方法。

2）分配给相应基元类型的变量。

下面我们来看一个例子：

```
/* 编译前 Java 代码 */
public class Autoboxing {

    public static void main(String[] args) {
        Integer a = 1;
        Integer b = 2;
        Integer c = 3;
        Integer d = 3;
        Integer e = 321;
        Integer f = 321;
        Long g = 3L;
        System.out.println(c == d);
        System.out.println(e == f);

        System.out.println(c == (a + b));
        System.out.println(c.equals(a + b));
        System.out.println(g == (a + b));
        System.out.println(g.equals(a + b));

    }
}
```
至于这段代码的输出是什么？去掉语法糖之后代码是什么样子？读者可以带着这两个问题继续读下去。

首先通过 `javac Autoboxing.java` 得到 `Autoboxing.class` 文件（由于 Class 文件中并不能非常明显的看出自动装箱与拆箱，因此根据字节码来查看具体发生了什么。），
随后通过 `javap -c Autoboxing.class` 得到下列字节码。

```
/* 反编译 Java 字节码 */
public class com.yhh.example.syntactic.sugar.Autoboxing {
  public com.yhh.example.syntactic.sugar.Autoboxing();
    Code:
       0: aload_0
       // ----调用超类构造方法，即父类的构造函数
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V 
       4: return

  public static void main(java.lang.String[]);
    Code:
	   // ----将int型1推送至栈顶
       0: iconst_1 
       // ----调用静态方法 Integer.valueOf()
       1: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer; 
       // ----将栈顶引用型数值存入第二个本地变量
       4: astore_1 
       // ----0 - 4 步相当于代码中的 Integer a = 1; => Integer a = Integer.valueOf(1); 发生了自动装箱。
       5: iconst_2
       6: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
       9: astore_2
       // ----Integer b = 2; => Integer b = Integer.valueOf(2); 发生了自动装箱。
      10: iconst_3
      11: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
      14: astore_3
      // ----Integer c = 3; => Integer c = Integer.valueOf(3); 发生了自动装箱。
      15: iconst_3
      16: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
      19: astore        4
      // ----Integer d = 3; => Integer d = Integer.valueOf(3); 发生了自动装箱。
      21: sipush        321
      24: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
      27: astore        5
      // ----Integer e = 321; => Integer e = Integer.valueOf(321); 发生了自动装箱。
      29: sipush        321
      32: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
      35: astore        6
      // ----Integer f = 321; => Integer f = Integer.valueOf(321); 发生了自动装箱。
      37: ldc2_w        #3                  // long 3l
      40: invokestatic  #5                  // Method java/lang/Long.valueOf:(J)Ljava/lang/Long;
      43: astore        7
      // ----Long g = 3L; => Long g = Long.valueOf(3); 发生了自动装箱。
      45: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
      // ----将第四个引用类型本地变量推送至栈顶
      48: aload_3
      // ----将第五个引用类型本地变量推送至栈顶
      49: aload         4
      // ----比较栈顶两引用型数值，当结果不相等时跳转至 58
      51: if_acmpne     58
      // ----将int型1推送至栈顶
      54: iconst_1
      // ----无条件跳转至 59
      55: goto          59
      // ----将int型0推送至栈顶
      58: iconst_0
      // ----调用实例方法 System.out.println
      59: invokevirtual #7                  // Method java/io/PrintStream.println:(Z)V
      // ----45 - 59 步对应于：System.out.println(c == d);
      62: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
      65: aload         5
      67: aload         6
      69: if_acmpne     76
      72: iconst_1
      73: goto          77
      76: iconst_0
      77: invokevirtual #7                  // Method java/io/PrintStream.println:(Z)V
      // ----System.out.println(e == f);
      80: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
      83: aload_3
      // ----调用实例方法 Integer.intValue
      84: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
      87: aload_1
      // ----调用实例方法 Integer.intValue
      88: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
      91: aload_2
      92: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
      95: iadd
      96: if_icmpne     103
      99: iconst_1
     100: goto          104
     103: iconst_0
     104: invokevirtual #7                  // Method java/io/PrintStream.println:(Z)V
      // ----83 - 104 对应于 System.out.println(c == (a + b)); => System.out.println(c.intValue() == (a.intValue() + b.intValue())); 发生了自动拆箱
     107: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
     110: aload_3
     111: aload_1
     112: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
     115: aload_2
     116: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
     119: iadd
     120: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
     123: invokevirtual #9                  // Method java/lang/Integer.equals:(Ljava/lang/Object;)Z
     126: invokevirtual #7                  // Method java/io/PrintStream.println:(Z)V
      // ----107 - 126 对应于 System.out.println(c.equals(a + b)); => System.out.println(c.equals(Integer.valueOf(a.intValue() + b.intValue()))); 发生了自动拆箱与自动装箱
     129: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
     132: aload         7
     134: invokevirtual #10                 // Method java/lang/Long.longValue:()J
     137: aload_1
     138: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
     141: aload_2
     142: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
     145: iadd
      // ----将栈顶int型数值强制转换成long型数值并将结果压入栈顶
     146: i2l
     147: lcmp
     148: ifne          155
     151: iconst_1
     152: goto          156
     155: iconst_0
     156: invokevirtual #7                  // Method java/io/PrintStream.println:(Z)V
      // ----129 - 156 对应于 System.out.println(g == (a + b)); => System.out.println(g.longValue() == (a.intValue() + b.intValue())); 发生了自动拆箱和一次强制转型
     159: getstatic     #6                  // Field java/lang/System.out:Ljava/io/PrintStream;
     162: aload         7
     164: aload_1
     165: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
     168: aload_2
     169: invokevirtual #8                  // Method java/lang/Integer.intValue:()I
     172: iadd
     173: invokestatic  #2                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
     176: invokevirtual #11                 // Method java/lang/Long.equals:(Ljava/lang/Object;)Z
     179: invokevirtual #7                  // Method java/io/PrintStream.println:(Z)V
      // ----159 - 179 对应于 System.out.println(g.equals(a + b)); => System.out.println(g.equals(Integer.valueOf(a.intValue() + b.intValue())));
     182: return
}
```

所以解除语法糖之后的代码是这样子的：

```
/* 根据反编译后的字节码反推 Java 代码 */
public class Autoboxing {

    public static void main(String[] args) {

        Integer a = Integer.valueOf(1);                                            //  Integer a = 1;
        Integer b = Integer.valueOf(2);                                            //  Integer b = 2;
        Integer c = Integer.valueOf(3);                                            //  Integer c = 3;
        Integer d = Integer.valueOf(3);                                            //  Integer d = 3;
        Integer e = Integer.valueOf(321);                                          //  Integer e = 321;
        Integer f = Integer.valueOf(321);                                          //  Integer f = 321;
        Long g = Long.valueOf(3);                                                  //  Long g = 3L;
        System.out.println(c == d);                                                //  System.out.println(c == d);
        System.out.println(e == f);                                                //  System.out.println(e == f);

        System.out.println(c.intValue() == (a.intValue() + b.intValue()));         //  System.out.println(c == (a + b));
        System.out.println(c.equals(Integer.valueOf(a.intValue() + b.intValue())));//  System.out.println(c.equals(a + b));
        System.out.println(g.longValue() == (a.intValue() + b.intValue()));        //  System.out.println(g == (a + b));
        System.out.println(g.equals(Integer.valueOf(a.intValue() + b.intValue())));//  System.out.println(g.equals(a + b));

    }
}
```
输出结果为：

```
output:
		true
		false
		true
		true
		true
		false
```
咦？为什么 `c == d` 为 `true` 而 `e == f` 为 `false` 呢？

原因在这：

```
    static final int low = -128;
    static final int high;// 可通过 property 文件配置，默认值为 127
	    
public static Integer valueOf(int i) {
        if (i >= IntegerCache.low && i <= IntegerCache.high)
            return IntegerCache.cache[i + (-IntegerCache.low)];
        return new Integer(i);
    }
```
可以看到，Integer 类做了一个缓存，[-128, 127] 之间的值都被缓存起来了。所以 两个 `Integer.valueOf(3)` 表示的是同一个对象，而 `Integer.valueOf(321)` 是两个不同的对象，因此，一个是 `true` ，一个是 `false` 。

这里需要注意的是：包装器类型的 `"=="` 运算在不遇到算术运算的情况下不会自动拆箱，比较的是引用，并且 `equals()` 方法不会处理数据转型的问题。实际编码中应当尽量避免这些情况。

##### 3、遍历循环

遍历循环需要被遍历的对象实现 `Iterable` 接口，因为其本质是调用底层的迭代器。例如：

```
/* 编译前 Java 代码 */
public class ForeachSyntacticSugar {

    public static void main(String[] args) {
        List names = Arrays.asList(1, "sd");
        for (Object name : names) {
            System.out.println(name);
        }
    }
}
```

编译成 Class 文件为：

```
/* 编译后 Class 文件 */
public class ForeachSyntacticSugar {
    public ForeachSyntacticSugar() {
    }

    public static void main(String[] var0) {
        List var1 = Arrays.asList(1, "sd");
        Iterator var2 = var1.iterator();

        while(var2.hasNext()) {
            Object var3 = var2.next();
            System.out.println(var3);
        }

    }
}
```

##### 4、变长参数

变长，即参数的个数不定，可以是任意个。

```
/* 编译前 Java 代码 */
public class VariableParameter {

    public void variable_parameter_test(Object... args) {
        for (Object arg : args) {
            System.out.println(arg);
        }
    }

}
```

编译成 Class 文件：

```
/* 编译后 Class 文件 */
public class VariableParameter {
    public VariableParameter() {
    }

    public void variable_parameter_test(Object... var1) {
        Object[] var2 = var1;
        int var3 = var1.length;

        for(int var4 = 0; var4 < var3; ++var4) {
            Object var5 = var2[var4];
            System.out.println(var5);
        }

    }
}
```

可以看到，Java 中的变长参数底层其实是一个数组。

使用变长参数时的注意事项：

1）使用了变长参数的方法也可以重载，但重载可能导致歧义。

2）在JDK 5之前，可变长度参数可以用两种方式处理：一种是使用重载，而另一种是使用数组参数。

3）方法中只能有一个变量参数，且必须是最后一个参数。

##### 5、条件编译

首先，产生条件编译的情况是条件为常量的 If 语句，编译器会根据布尔常量值的真假将分支中不成立的代码块消除掉。例如：

```
/* 编译前 Java 代码 */
public class ConditionCompile {

    public static void main(String[] args) {
        if (true) {
            System.out.println("it's true!");
        } else {
            System.out.println("it's false!");
        }
    }

}
```
在编译后是这样子的：

```
/* 编译后 Class 文件 */
public class ConditionCompile {
    public ConditionCompile() {
    }

    public static void main(String[] var0) {
        System.out.println("it's true!");
    }
}
```

当然，正常情况下，我们是不会傻到写出这种代码的，知道有这回事就行了。

##### 6、枚举类

举一个最简单的枚举的例子：

```
/* 编译前 Java 代码 */
public enum HumanEnum {
    MAN, WOMAN
}
```
通过 `javac HumanEnum.java` 得到的是这样子的：

```
/* 编译后 Class 文件 */
public enum HumanEnum {
    MAN,
    WOMAN;

    private HumanEnum() {
    }
}
```

看不出来到底发生了什么，所以我们通过 `javap -c HumanEnum.class` 查看字节码：

```
/* 反编译 Java 字节码 */
public final class com.yhh.example.syntactic.sugar.HumanEnum extends java.lang.Enum<com.yhh.example.syntactic.sugar.HumanEnum> {
  public static final com.yhh.example.syntactic.sugar.HumanEnum MAN;

  public static final com.yhh.example.syntactic.sugar.HumanEnum WOMAN;

  public static com.yhh.example.syntactic.sugar.HumanEnum[] values();
    Code:
       0: getstatic     #1                  // Field $VALUES:[Lcom/yhh/example/syntactic/sugar/HumanEnum;
       3: invokevirtual #2                  // Method "[Lcom/yhh/example/syntactic/sugar/HumanEnum;".clone:()Ljava/lang/Object;
       6: checkcast     #3                  // class "[Lcom/yhh/example/syntactic/sugar/HumanEnum;"
       9: areturn

  public static com.yhh.example.syntactic.sugar.HumanEnum valueOf(java.lang.String);
    Code:
       0: ldc           #4                  // class com/yhh/example/syntactic/sugar/HumanEnum
       2: aload_0
       3: invokestatic  #5                  // Method java/lang/Enum.valueOf:(Ljava/lang/Class;Ljava/lang/String;)Ljava/lang/Enum;
       6: checkcast     #4                  // class com/yhh/example/syntactic/sugar/HumanEnum
       9: areturn

  static {};
    Code:
       0: new           #4                  // class com/yhh/example/syntactic/sugar/HumanEnum
       3: dup
       4: ldc           #7                  // String MAN
       6: iconst_0
       7: invokespecial #8                  // Method "<init>":(Ljava/lang/String;I)V
      10: putstatic     #9                  // Field MAN:Lcom/yhh/example/syntactic/sugar/HumanEnum;
      13: new           #4                  // class com/yhh/example/syntactic/sugar/HumanEnum
      16: dup
      17: ldc           #10                 // String WOMAN
      19: iconst_1
      20: invokespecial #8                  // Method "<init>":(Ljava/lang/String;I)V
      23: putstatic     #11                 // Field WOMAN:Lcom/yhh/example/syntactic/sugar/HumanEnum;
      26: iconst_2
      27: anewarray     #4                  // class com/yhh/example/syntactic/sugar/HumanEnum
      30: dup
      31: iconst_0
      32: getstatic     #9                  // Field MAN:Lcom/yhh/example/syntactic/sugar/HumanEnum;
      35: aastore
      36: dup
      37: iconst_1
      38: getstatic     #11                 // Field WOMAN:Lcom/yhh/example/syntactic/sugar/HumanEnum;
      41: aastore
      42: putstatic     #1                  // Field $VALUES:[Lcom/yhh/example/syntactic/sugar/HumanEnum;
      45: return
}
```
通过上述字节码，我们大致可以还原出 `HumanEnum` 的普通类：

```
/* 根据反编译后的字节码反推 Java 代码 */
public final class HumanEnum extends Enum<HumanEnum> {

    public static final HumanEnum MAN;
    public static final HumanEnum HUMAN;

    private static final HumanEnum $VALUES[];

    static {
        MAN = new HumanEnum("MAN", 0);
        HUMAN = new HumanEnum("HUMAN", 1);
        $VALUES = (new HumanEnum[]{
                MAN, HUMAN
        });
    }

    private HumanEnum(String name, int original) {
        super(name, original);
    }

    public static HumanEnum[] values() {
        return (HumanEnum[]) $VALUES.clone();
    }

    public static HumanEnum valueOf(String name) {
        return (HumanEnum) Enum.valueOf(HumanEnum.class, name);
    }
}
```

当然上面的那个类是无法被编译的，因为 Java 编译器限制了我们显式的继承自 `java.Lang.Enum` 类, 报错 `Classes cannot directly extends 'java.lang.Enum' `。

##### 7、内部类

```
/* 编译前 Java 代码 */
public class InnerClass {

    class Foo {
        private String name;

        public Foo(String name) {
            this.name = name;
        }
    }

}
```

这是最简单的一个成员内部类，编译之后发现新增了两个文件：`InnerClass.class` 和 `InnerClass$Foo.class` ，	

通过 `javap -c src/main/java/com/yhh/example/syntactic/sugar/InnerClass` 命令得到外部类的字节码如下：

```
/* 反编译 Java 字节码 */
public class com.yhh.example.syntactic.sugar.InnerClass {
  public com.yhh.example.syntactic.sugar.InnerClass();
    Code:
       0: aload_0
       1: invokespecial #1                  // Method java/lang/Object."<init>":()V
       4: return
}
```
咦，从这字节码来看，其内部类的信息全不见了。

然后我们再看 `InnerClass$Foo.class` 文件的字节码：
（这有一个需要注意的地方就是，需要在 `$` 符号前加一个转义字符，不然编译得到的还是 `InnerClass` 类的字节码。`javap -c src/main/java/com/yhh/example/syntactic/sugar/InnerClass\$Foo.class` ）

```
/* 反编译 Java 字节码 */
class com.yhh.example.syntactic.sugar.InnerClass$Foo {
  final com.yhh.example.syntactic.sugar.InnerClass this$0;

  public com.yhh.example.syntactic.sugar.InnerClass$Foo(com.yhh.example.syntactic.sugar.InnerClass, java.lang.String);
    Code:
       0: aload_0
       1: aload_1
       2: putfield      #1                  // Field this$0:Lcom/yhh/example/syntactic/sugar/InnerClass;
       5: aload_0
       6: invokespecial #2                  // Method java/lang/Object."<init>":()V
       9: aload_0
      10: aload_2
      11: putfield      #3                  // Field name:Ljava/lang/String;
      14: return
}
```

咦，发现内部类 Foo 中多了一个声明为 `final` 的外部类类型的引用 `this$0`，并且在 Foo 的构造函数中完成了初始化。看到这个，对于成员内部类为什么能访问其外部类所有属性（包括 `private` ）、并且依附其外部类而存在等特点也就统统想明白了。

编译之后外部类和内部类是完全独立的 Class 文件，外部类中不包含任何内部类的信息，而所有的内部类都拥有一个外部类对象的引用。

除了成员内部类之外，还有静态内部类、局部内部类和匿名内部类，不过它们的原理都是类似的。

##### 8、try 语句中定义和关闭资源

JDK 1.7 之后才支持。在 JDK 1.7 以前，去操作系统资源时，比如流、文件或者 Socket 连接等，需要手动的去关闭资源。而现在，只需要这样：

```
/* 编译前 Java 代码 */
public class WithResourse {

    public void with_resourse_test() {
        try (OutputStream os = new FileOutputStream("filePath")) {
            os.flush();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
```

然后就不用担心中途抛异常导致资源无法关闭，造成资源泄漏，编译器会帮我们做好关闭资源的操作，是不是简单多了？至于是怎么做的呢，请看 Class 文件：

```
/* 编译后 Class 文件 */
public class WithResourse {
    public WithResourse() {
    }

    public void with_resourse_test() {
        try {
            FileOutputStream var1 = new FileOutputStream("filePath");
            Throwable var2 = null;

            try {
                var1.flush();
            } catch (Throwable var12) {
                var2 = var12;
                throw var12;
            } finally {
                if (var1 != null) {
                    if (var2 != null) {
                        try {
                            var1.close();
                        } catch (Throwable var11) {
                            var2.addSuppressed(var11);
                        }
                    } else {
                        var1.close();
                    }
                }

            }
        } catch (IOException var14) {
            var14.printStackTrace();
        }

    }
}

```

仔细一看，咦，怎么和自己之前写 try ... catch ... finally 是如此的类似，不过好像还多了一个操作 `var2.addSuppressed(var11);` ，这儿稍微提一下，这个操作是为了避免异常屏蔽（具体可以看看 [Throwable#addSuppressed](https://docs.oracle.com/javase/7/docs/api/java/lang/Throwable.html#addSuppressed%28java.lang.Throwable%29) 的文档说明），在排查问题的时候会很有用。

###### 到此，Java 中常用的一些语法糖介绍完毕，总而言之，语法糖可以看做是编译器实现的一些 “小把戏“ ，这些 “小把戏“ 可能会使得效率 “大提升“ ，但我们也应该去了解这些 “小把戏“ 背后的真实世界，那样才能利用好它们，而不被它们所迷惑。

参考资料：

（1）《深入理解java虚拟机》周志明 著.

（2）[Autoboxing and Unboxing](https://docs.oracle.com/javase/tutorial/java/data/autoboxing.html)

（3）[Variable Arguments (Varargs) in Java](https://www.geeksforgeeks.org/variable-arguments-varargs-in-java/)