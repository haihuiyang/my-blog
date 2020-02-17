> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

---

#### 1、存在的原因

在 Java 中，float 和 double 的精度都是 16 位有效数字，当需要做比 16 位有效数字更精确的运算时，float 和 double 就显得无能为力。BigDecimal 就是为了这种情况而存在的。

#### 2、什么是 BigDecimal ？

BigDecimal 是一个不可变的，任意精度的有符号小数，主要用于对精度的有效位超过 16 位的数进行精确的运算。

#### 3、如何使用 BigDecimal

BigDecimal 之间的运算就和我们数学课上学的小数运算一样，所有的操作都是带精度的。

BigDecimal 提供了加（add）、减（subtract）、乘（multiply）、除（divide）和幂（pow）运算。

在未指定精度的前提下，加法和减法其结果的精度就是两个操作数中精度高的那一个精度 （例：2.00 -/+ 0.000 => 2.000）；乘法则是两个操作数的精度之和 （例：2.00 * 1.000 => 2.00000）；除法如果除的尽，那么结果的精度就是 `被除数的精度 - 除数的精度` ，如果除不尽，结果就是一个无限小数，这个时候如果没有指定结果的精度的话，就会抛出 ArithmeticException。就好像数学老师让你计算一个 1 / 3，你计算之后发现这个结果是 0.33333...，后面是无限个 3 ，没法算出一个准确的结果，所以就需要一个结果保留几位小数的约束。

既然要保留几位小数，那么在这几位小数之后的数是怎么处理的呢？这就是接下来要说的**舍入模式**。

舍入模式就是丢弃精度的舍入方式。课本上用的舍入模式基本上都是四舍五入。下面来看一下有哪些舍入模式：

- ROUND_UP：远离 0 方向进行舍入
- ROUND_DOWN：向 0 方向进行舍入
- ROUND_CEILING：向正无穷方向进行舍入
- ROUND_FLOOR：向负无穷方向进行舍入
- ROUND_HALF_UP：四舍五入
- ROUND_HALF_DOWN："五舍六入"
- ROUND_HALF_EVEN：银行家舍入（为了银行不亏钱引入的舍入方式）
- ROUND_UNNECESSARY：不需要舍入，如果结果中有不精确的值（指结果中存在小数），将抛出异常 ArithmeticException

#### 4、使用过程中的注意事项

##### （1）通过 double 创建 BigDecimal 的方式

BigDecimal 中有两种方式通过 double 创建 BigDecimal：

- `new BigDecimal(double val)` ：尽量不要使用，存在精度问题，下面的方式更好
- `BigDecimal.valueOf(Double val)`

这两种方式的区别在哪呢？我们来看一个例子：

```java
@Test
public void test_create_big_decimal() {
    BigDecimal useDoubleCreate = new BigDecimal(1.01);
    System.out.println("useDoubleCreate  : " + useDoubleCreate);

    BigDecimal useValueOfCreate = BigDecimal.valueOf(1.01);
    System.out.println("useValueOfCreate : " + useValueOfCreate);
}
```

如果你认为这两个结果是一样的，那么你就错了，实际结果是这样子的：
```java
/*
output:
	useDoubleCreate  : 1.0100000000000000088817841970012523233890533447265625
	useValueOfCreate : 1.01
*/
```
造成上述结果的原因在于我们的计算机是二进制的，浮点数没有办法用二进制进行精确表示。

其实使用 `BigDecimal.valueOf(double val)` ，实际上调用的是 `new BigDecimal(Double.toString(double val))`，即将 double 转成 String 然后通过 `new BigDecimal(String val)` 创建 BigDecimal，这种方式创建出来的 BigDecimal 是准确的。

##### （2）BigDecimal 对象是不可变的

BigDecimal 对象是不可变的，在 BigDecimal 上的所有操作返回的都不是原来的 BigDecimal，而是一个新的BigDecimal。

```java
@Test
public void test_big_decimal_is_final_object() {
    BigDecimal a = new BigDecimal("1.0");
    BigDecimal c = a.add(new BigDecimal("2.0"));
    System.out.println("after add a = " + a);
    System.out.println("c = " + c);
}
/*
output:
		after add a = 1.0
		c = 3.0
*/
```

##### （3）BigDecimal 的比较

- `compareTo` 方法： 只比较值相等。
- `equals` 方法：既比较值也比较精度。

```java
 @Test
 public void test_two_ways_compare_big_decimal() {
     BigDecimal two1 = new BigDecimal("2.0");
     BigDecimal two2 = new BigDecimal("2.00");

     System.out.println("two1 equals    two2 is " + two1.equals(two2));
     System.out.println("two1 compareTo two2 is " + two1.compareTo(two2));
 }
  /*
  output:
		two1 equals    two2 is false
		two1 compareTo two2 is 0
  */
```

参考资料：

（1）[ArithmeticException: “Non-terminating decimal expansion; no exact representable decimal result”](https://stackoverflow.com/questions/4591206/arithmeticexception-non-terminating-decimal-expansion-no-exact-representable)

（2）[JDK 1.8 文档](https://docs.oracle.com/javase/8/docs/api/java/math/BigDecimal.html)