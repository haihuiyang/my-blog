谈到类文件结构，就要从 `Java` 虚拟机说起。

#### 一、Java虚拟机是一个与语言无关的平台

实现语言无关性的基础是虚拟机和字节码存储格式。 Java 虚拟机不与任何语言绑定，它只与 "Class 文件" 这种特定的二进制文件格式所关联。

任意一门语言都可以按照 Java 虚拟机规范把程序代码编译成 Class 文件，然后在虚拟机上运行。例如：使用 Java 编译器可以把 Java 代码编译成存储字节码的 Class 文件，使用 JRuby等其他语言的编译器一样可以把程序代码编译成 Class 文件，虚拟机并不关心 Class 的来源是何种语言，如下图所示：
![Java虚拟机提供的语言无关性](https://img-blog.csdn.net/20180606215353383?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

#### 二、什么是 Class 类文件结构？

**任意一个有效的类或接口所应当满足的格式称为 "Class 文件格式"，实际上它不一定以磁盘文件的形式存在。**

Class 文件是一组以 8 位字节为基础单位的二进制流，各项数据项目严格按照顺序紧凑地排列在 Class 文件之中。当遇到需要占用 8 位字节以上空间的数据项时，则会按照高位在前（Big–Endian）的方式分割成若干个 8 位字节进行存储。

"Class 文件"说白了就是程序代码编码解码的中间结果。将程序代码编译成 Class 文件的过程就是编码，而虚拟机加载 Class 文件的过程就是解码的过程，编码和解码需要严格虚拟机规范。

下面开始详细的介绍 Class 文件格式（这个过程比较枯燥，但这是了解虚拟机的重要基础之一）：

根据 Java 虚拟机规范的规定，Class 文件格式采用一种类似于 C 语言结构体的伪结构来存储数据，这种伪结构只有两种数据类型：无符号数和表。所以这里先介绍无符号数和表这两个概念：

（1）无符号数
 
- 无符号数属于基本的数据类型，以 `u1、u2、u4、u8` 来分别表示 1 个字节、2 个字节、4 个字节和 8 个字节的无符号数，无符号数可以用来描述数字、索引引用、数量值或者按照 UTF-8 编码构成字符串值。

（2）表

- 表是有多个无符号数或者其他表作为数据项构成的符合数据类型，所有表都习惯性地以 "_info" 结尾。表用于描述有层次关系的复合结构的数据。

Class 文件本质上就是一张表：
![Class文件格式](https://img-blog.csdn.net/20180606231010265?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

由于表中存在一些不定项，所以采取了 "size + size 个数据项" 的形式来描述，如上图中的 `fields_count` 表示 `field_info` 的个数，其后跟了 `fields_count` 个 `field_info`。

**注：由于这个地方是用 `u2` 即 2 个字节的无符号数来表示个数，那么，假如一个类的 `field` 的个数超过了 2 个字节所能表示的最大值，则该类会编译失败，不过这种情况基本上不可能出现**

接下来逐个理解上表中各个数据项的具体含义：

我们以最简单的一个 Java 代码为例：
```
package com.yhh.example;

public class TestClass {
    private int index;

    public Integer inc() {
        return index++;
    }
}

```
首先通过 `javac TestClass.java` 得到编译后的 `TestClass.class` 文件。

然后通过 `hexdump -C ClassName.class` 命令查看文件 TestClass.class 的内容（稍后会以这个为基础进行举例）：
```
➜  example git:(master) ✗ hexdump -C TestClass.class
00000000  ca fe ba be 00 00 00 34  00 19 0a 00 05 00 10 09  |.......4........|
00000010  00 04 00 11 0a 00 12 00  13 07 00 14 07 00 15 01  |................|
00000020  00 05 69 6e 64 65 78 01  00 01 49 01 00 06 3c 69  |..index...I...<i|
00000030  6e 69 74 3e 01 00 03 28  29 56 01 00 04 43 6f 64  |nit>...()V...Cod|
00000040  65 01 00 0f 4c 69 6e 65  4e 75 6d 62 65 72 54 61  |e...LineNumberTa|
00000050  62 6c 65 01 00 03 69 6e  63 01 00 15 28 29 4c 6a  |ble...inc...()Lj|
00000060  61 76 61 2f 6c 61 6e 67  2f 49 6e 74 65 67 65 72  |ava/lang/Integer|
00000070  3b 01 00 0a 53 6f 75 72  63 65 46 69 6c 65 01 00  |;...SourceFile..|
00000080  0e 54 65 73 74 43 6c 61  73 73 2e 6a 61 76 61 0c  |.TestClass.java.|
00000090  00 08 00 09 0c 00 06 00  07 07 00 16 0c 00 17 00  |................|
000000a0  18 01 00 19 63 6f 6d 2f  79 68 68 2f 65 78 61 6d  |....com/yhh/exam|
000000b0  70 6c 65 2f 54 65 73 74  43 6c 61 73 73 01 00 10  |ple/TestClass...|
000000c0  6a 61 76 61 2f 6c 61 6e  67 2f 4f 62 6a 65 63 74  |java/lang/Object|
000000d0  01 00 11 6a 61 76 61 2f  6c 61 6e 67 2f 49 6e 74  |...java/lang/Int|
000000e0  65 67 65 72 01 00 07 76  61 6c 75 65 4f 66 01 00  |eger...valueOf..|
000000f0  16 28 49 29 4c 6a 61 76  61 2f 6c 61 6e 67 2f 49  |.(I)Ljava/lang/I|
00000100  6e 74 65 67 65 72 3b 00  21 00 04 00 05 00 00 00  |nteger;.!.......|
00000110  01 00 02 00 06 00 07 00  00 00 02 00 01 00 08 00  |................|
00000120  09 00 01 00 0a 00 00 00  1d 00 01 00 01 00 00 00  |................|
00000130  05 2a b7 00 01 b1 00 00  00 01 00 0b 00 00 00 06  |.*..............|
00000140  00 01 00 00 00 03 00 01  00 0c 00 0d 00 01 00 0a  |................|
00000150  00 00 00 27 00 04 00 01  00 00 00 0f 2a 59 b4 00  |...'........*Y..|
00000160  02 5a 04 60 b5 00 02 b8  00 03 b0 00 00 00 01 00  |.Z.`............|
00000170  0b 00 00 00 06 00 01 00  00 00 07 00 01 00 0e 00  |................|
00000180  00 00 02 00 0f                                    |.....|
00000185
```

###### 1. 魔数和 Class 文件的版本

每个 Class 文件的头 4 个字节称为**魔数**（Magic Number），它的唯一作用是确定这个文件是否为一个能被虚拟机接受的 Class 文件。使用魔数而不是拓展名来进行识别主要是基于安全方面的考虑，因为文件拓展名可以随意更改。

魔数的值为 `0xCAFEBABE`

紧接着魔数的 4 个字节是 Class 文件的版本号：第 5 和第 6 个字节是次版本号（Minor Version），第  7 和第 8 个字节是主版本号（Major Version）。Java 的版本号是从 45 开始的，JDK 1.1 之后的每个 JDK 大版本发布主版本号向上加 1（JDK 1.0 ~ 1.1 使用了 45.0 ~ 45.3 的版本号），高版本的 JDK 能向下兼容以前版本的 Class 文件，但不能运行以后版本的 Class 文件，即使文件格式并未发生任何变化，虚拟机也必须拒绝执行超过其版本号的 Class 文件。

以 `TestClass.class` 为例：
```
00000000  ca fe ba be 00 00 00 34
```
可以看到，头 4 个字节为 `0xcafebabe` ，然后是次版本号 `0x0000` ，而主版本号为 `0x0034`，即十进制的52，即 Class 文件的十进制版本号为：52.0，说明该文件是使用 `JDK 1.8` 编译的 Class 文件。

###### 2. 常量池

紧接着主次版本号之后的是常量池入口，常量池可以理解为 Class 文件之中的资源仓库，它是 Class 文件结构中与其他项目关联最多的数据类型，也是占用 Class 文件空间最大的数据项目之一。

由于常量池中常量的数量是不固定的，所以需要有一个 `u2` 类型的数据来表示常量池容量计数值（ `constant_pool_count` ）。这里需要注意的是，常量池容量计数值是从 1 而不是 0 开始的，这是因为第 0 项常量空出来是有特殊考虑的，这样做的目的在于满足在特定情况下表达 "不引用任何一个常量池项目" 的含义，这种情况可以把索引值置为 0 来表示。 Class 文件结构中只有常量池的容量计数是从 1 开始，对于其他集合类型，都是从 0 开始的。

常量池中主要存放两大类常量：字面量（Literal）和符号引用（Symbolic References）。字面量比较接近于 Java 语言层面的常量概念，如文本字符串、声明为 `final` 的常量值等。而符号引用则属于编译原理方面的概念，包括了下面三类常量：

 1）类和接口的全限定名
 2）字段的名称和描述符
 3）方法的名称和描述符

常量池中每一项常量都是一个表，它们有一个共同点：就是表开始的第一位是一个 `u2` 类型的标志位，代表当前这个常量属于哪种类型。常量类型所代表的具体含义见下图：
![常量池的项目类型](https://img-blog.csdn.net/20180607223606867?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

`CONSTANT_Class_info` 的结构比较简单，见下图：
![CONSTANT_Class_info型常量结构1](https://img-blog.csdn.net/20180607224005141?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

`tag` 是标志位，代表它是属于哪种常量类型；`name_index` 是一个索引值，它指向常量池中一个 `CONSTANT_Utf8_info` 类型常量。

CONSTANT_Utf8_info型常量的结构如下：
![CONSTANT_Utf8_info型常量的结构](https://img-blog.csdn.net/20180608231440241?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

`tag` 同上；`length` 代表这个 UTF-8 编码的字符串长度是多少字节，后面紧跟着的长度为 `length` 字节的连续数据是一个使用 UTF-8 缩略编码表示的字符串。

由于 Class 文件中方法、字段等都需要引用 `CONSTANT_Utf8_info` 型常量来描述名称，所以 `CONSTANT_Utf8_info` 型常量的最大长度也就是 Java 中方法、字段名的最大长度。如果 Java 程序中如果定义了超过这个最大长度的变量名或方法名，将会无法编译。

下图是常量池中所有常量项的结构总表：
![常量池中所有常量项的结构总表2](https://img-blog.csdn.net/20180607224808573?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)
![常量池中所有常量项的结构总表2](https://img-blog.csdn.net/20180607224822134?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

以 `TestClass.class` 为例：

```
								   00 19 0a 00 05 00 10 09  |.......4........|
00000010  00 04 00 11 0a 00 12 00  13 07 00 14 07 00 15 01  |................|
00000020  00 05 69 6e 64 65 78 01  00 01 49 01 00 06 3c 69  |..index...I...<i|
00000030  6e 69 74 3e 01 00 03 28  29 56 01 00 04 43 6f 64  |nit>...()V...Cod|
00000040  65 01 00 0f 4c 69 6e 65  4e 75 6d 62 65 72 54 61  |e...LineNumberTa|
00000050  62 6c 65 01 00 03 69 6e  63 01 00 15 28 29 4c 6a  |ble...inc...()Lj|
00000060  61 76 61 2f 6c 61 6e 67  2f 49 6e 74 65 67 65 72  |ava/lang/Integer|
00000070  3b 01 00 0a 53 6f 75 72  63 65 46 69 6c 65 01 00  |;...SourceFile..|
00000080  0e 54 65 73 74 43 6c 61  73 73 2e 6a 61 76 61 0c  |.TestClass.java.|
00000090  00 08 00 09 0c 00 06 00  07 07 00 16 0c 00 17 00  |................|
000000a0  18 01 00 19 63 6f 6d 2f  79 68 68 2f 65 78 61 6d  |....com/yhh/exam|
000000b0  70 6c 65 2f 54 65 73 74  43 6c 61 73 73 01 00 10  |ple/TestClass...|
000000c0  6a 61 76 61 2f 6c 61 6e  67 2f 4f 62 6a 65 63 74  |java/lang/Object|
000000d0  01 00 11 6a 61 76 61 2f  6c 61 6e 67 2f 49 6e 74  |...java/lang/Int|
000000e0  65 67 65 72 01 00 07 76  61 6c 75 65 4f 66 01 00  |eger...valueOf..|
000000f0  16 28 49 29 4c 6a 61 76  61 2f 6c 61 6e 67 2f 49  |.(I)Ljava/lang/I|
00000100  6e 74 65 67 65 72 3b
```
第一项 `u2` 类型 `0x0019` 为常量池的容量，即十进制的 25 ，代表一共有 24（第 0 项空出来有特殊用途）项常量。然后是一位 `u1` 类型为 tag， `0x0a`，代表是类中方法的符号引用（ `CONSTANT_Class_info` ），然后是 `u2` 类型，`index` ，`0x0005` ，表示声明方法的类描述符的为常量池第 5 项常量。接下来还是 `u2` 类型， `index` ， `0x0010` ，表示名称即类型描述符为常量池第 16 项常量。然后第一项常量就结束了，继续第二个常量。tag， `0x09` ，代表类中字段的符号引用（ `CONSTANT_Fieldref_info` ），然后 `u2` 类型， `index` ， `0x0004` ，表示声明字段的类或接口描述符为常量池第 4 项常量。 `0x0011` ， 表示字段的描述符为常量池中第 17 项常量，第二项常量结束。然后继续按照此方法，可以得到剩下的 22 项常量。

###### 3. 访问标志

在常量池结束之后，紧接着的两个字节代表访问标志（`access_flags`），这个标志用于识别一些类或者接口层次的访问信息，包括：这个 Class 是类还是接口；是否定义为 `public` 类型；是否定义为 `abstract` 类型；如果是类的话，是否被声明为 `final` 等。具体标志及含义如下图：

![访问标志](https://img-blog.csdn.net/2018060722541552?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

以 `TestClass.class` 为例：
```
00000108  00  21
```
通过分析代码，只有 `0x0001` 和 `0x0020` 两个标志位为真，即它的 `access_flags` 的值应为 `0x0021` ，通过前面的计算，可以知道 `access_flags` 标志（偏移地址： `0x00000108` ）的确为 `0x0021` 。

###### 4. 类索引、父类索引和接口索引集合

类索引（this_class）和父类索引（super_class）都是一个 `u2` 类型的数据，而接口索引集合（interfaces）是一组 `u2` 类型的数据的集合，Class 文件通过这三项数据来确定这个类的继承关系。

类索引、父类索引和接口索引集合都按照顺序排列在访问标志之后，类索引和父类索引引用两个 `u2` 类型的索引值表示，它们各自指向一个类型为 `CONSTANT_Class_info` 的类描述符常量，从而得到全限定名字符串。

而接口索引集合，第一项为接口计数器，表示索引表的容量。如果该类没有实现任何接口，则该计数器值为 0。

以 `TestClass.class` 为例：
```
0000010a  00 04 00 05 00 00
```
第一项 `u2` 类型 `0x0004` ，表示该类的全限定名为常量池中第 4 项常量（ `com/yhh/example/TestClass` ），第二项 `u2` 类型 `0x0005` ，表示该类的父类全限定名为常量池中第 5 项常量（ `java/lang/Object` ），紧接着一项 `u2` 类型 `0x0000` 表示接口索引集合大小为 0 。

###### 5. 字段表集合

字段表（field_info）用于描述接口或者类中声明的变量。字段（field）包括类级变量以及实例级变量，但不包括在方法内部声明的局部变量。

字段表结构如下：
![字段表结构](https://img-blog.csdn.net/2018060722571474?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

字段修饰符放在 access_flags 项目中，可以设置的标志位及含义如下：、
![字段访问标志](https://img-blog.csdn.net/20180607225738433?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

跟随 access_flags 标志的是两个索引值：name_index 和 descriptor_index。它们都是对常量池的引用，分别代表着字段的简单名称以及字段和方法的描述符。

关于字段和方法的描述符的标识字符及含义如下：
![描述符标识字符含义](https://img-blog.csdn.net/20180607231636605?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

对于数组类型，每一维度将使用一个前置的 "[" 字符来描述，如一个定义为 "java.lang.String[][]" 类型的二维数组表示为："[[Ljava/lang/String"，一个整型数组 "int[]" 将被记录为 "[I"。

描述方法时，按照先参数列表，后返回值的顺序描述，参数列表按照参数的严格顺序放在一组小括号 "()" 之内。如方法 `void inc()` 的描述符为 "()V"，方法 `java.lang.String toString()` 的描述符为 "()Ljava/lang/String;"。

以 `TestClass.class` 为例：

```
0000010a						   						00  |nteger;.!.......|
00000110  01 00 02 00 06 00 07 00  00 
```

第一项 `u2` 类型值为 `0x0001` ，代表集合中只有一个方法，第二项 `u2` 类型为 `access_flags` ，值为 `0x0002` ，表示方法是 `private` 的，第三项 `u2` 类型为 `name_index` ，值为 `0x0006` ，即字段的简单名称指向常量池中第六项常量，第三项 `u2` 类型为 `descriptor_index` ，值为 `0x0007` ，即字段和方法的描述符指向常量池第七项常量。接下来一个 `u2` 类型值为 `0x0000` ，说明没有需要额外描述的内容。

###### 6. 方法表集合

方法表（method_info）结构和字段表结构是一模一样的，除了访问标志和属性表集合的可选项有所区别。
![方法表结构](https://img-blog.csdn.net/20180607232006908?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

因为 `volatile` 关键字和 `transient` 关键字不能修饰方法，所以方法表的访问标志中没有了 ACC_VLOLATILE 标志和 ACC_TRANSIENT 标志。与之对应的，新增了 `synchronized` 、`native` 、 `strictfp` 和 `abstract` 关键字的访问标志。具体标志位及其取值见下表：
![方法访问标志](https://img-blog.csdn.net/20180607232018966?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)

以 `TestClass.class` 为例：

```
0000011a 							  00 02 00 01 00 08 00  |................|
00000120  09 00 01 00 0a 00 00 00  1d 00 01 00 01 00 00 00  |................|
00000130  05 2a b7 00 01 b1 00 00  00 01 00 0b 00 00 00 06  |.*..............|
00000140  00 01 00 00 00 03 00 01  00 0c 00 0d 00 01 00 0a  |................|
00000150  00 00 00 27 00 04 00 01  00 00 00 0f 2a 59 b4 00  |...'........*Y..|
00000160  02 5a 04 60 b5 00 02 b8  00 03 b0 00 00 00 01 00  |.Z.`............|
00000170  0b 00 00 00 06 00 01 00  00 00 07
```

方法表和字段表没有太大区别， `0x0002` 代表有两个方法，第一个方法访问标志是 `0x0001` ，即是 `public` 的， `name_index` 为 `0x0008` ，指向常量池中第 8 项常量， `descriptor_index` 为 `0x0009` ，指向常量池中第 9 项常量； 下一个 `u2` 类型为 `attributes_count` ，值为 `0x0001` ，说明有一个属性值，紧接着是 `attribute_name_index` 为 `0x000a` ，即指向常量池中第 10 项常量，通过查找得到，第 10 项常量为 `Code` ，下一个 `u4` 类型为 `attribute_length` ，值为 `0x0000001d` ，即 29 ，下一个 `u2` 类型为 `max_stack` ，值为 `0x0001` ，表示操作数栈深度的最大值，下一个 `u2` 类型为 `max_locals` ，值为 `0x0001` ，代表了局部变量表所需的存储空间；接下来是 `code_length` 和 `code` ，用来存储 Java 源程序编译后生成的字节码指令，第一个 `u4` 类型为 `code_length` ，值为 `0x00000005` ，表示字节码区域共占 5 个字节，然后读入紧随的 5 个字节，并根据字节码指令表翻译出对应的字节码指令。

翻译 `2a b7 00 01 b1` 的过程为：
	1）读入 `2a` ，查表得 `0x2a` 对应的指令为 `aload_0` ，这个指令的含义是将第 0 个 `Slot` 中为 `reference` 类型的本地变量推送到操作数栈顶。
	2）读入 `b7` ，查表得 `0xb7` 对应的指令为 `invokespecial` ，其后有一个 `u2` 类型的参数说明调用哪一个方法。
	3）读入 `0001` ，是 `invokespecial` 指令的参数，指向常量池中第 1 个常量。
	4）读入 `b1` ，查表得 `0xb1` 对应的指令为 `return` ，含义是返回此方法，并且返回值为 `void` ，方法结束。

后面就都是根据类似的方法推出得到。

###### 7. 属性表集合

在 Class 文件、字段表、方法表都可以携带自己的属性表集合，以用于描述某些场景专有的信息。

以 `TestClass.class` 为例：

```
0000017b								    00 01 00 0e 00  |................|
00000180  00 00 02 00 0f                                    |.....|
00000185
```
包含一个 `SourceFile` 的属性，`sourcefile_index` 值为 `0x000f` ，指向常量池第 15 个常量。

至此，TestClass.class 文件字节码分析结束。

最后使用 `javap` 工具来得到一个完整的 TestClass.class 文件字节码内容如下：

```
➜  example git:(master) ✗ javap -verbose TestClass.class
Classfile /Users/yanghaihui/project/github/code/java/src/main/java/com/yhh/example/TestClass.class
  Last modified Jun 9, 2018; size 389 bytes
  MD5 checksum 510375b08360425cddc8b51216c5155d
  Compiled from "TestClass.java"
public class com.yhh.example.TestClass
  minor version: 0
  major version: 52
  flags: ACC_PUBLIC, ACC_SUPER
Constant pool:
   #1 = Methodref          #5.#16         // java/lang/Object."<init>":()V
   #2 = Fieldref           #4.#17         // com/yhh/example/TestClass.index:I
   #3 = Methodref          #18.#19        // java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
   #4 = Class              #20            // com/yhh/example/TestClass
   #5 = Class              #21            // java/lang/Object
   #6 = Utf8               index
   #7 = Utf8               I
   #8 = Utf8               <init>
   #9 = Utf8               ()V
  #10 = Utf8               Code
  #11 = Utf8               LineNumberTable
  #12 = Utf8               inc
  #13 = Utf8               ()Ljava/lang/Integer;
  #14 = Utf8               SourceFile
  #15 = Utf8               TestClass.java
  #16 = NameAndType        #8:#9          // "<init>":()V
  #17 = NameAndType        #6:#7          // index:I
  #18 = Class              #22            // java/lang/Integer
  #19 = NameAndType        #23:#24        // valueOf:(I)Ljava/lang/Integer;
  #20 = Utf8               com/yhh/example/TestClass
  #21 = Utf8               java/lang/Object
  #22 = Utf8               java/lang/Integer
  #23 = Utf8               valueOf
  #24 = Utf8               (I)Ljava/lang/Integer;
{
  public com.yhh.example.TestClass();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0

  public java.lang.Integer inc();
    descriptor: ()Ljava/lang/Integer;
    flags: ACC_PUBLIC
    Code:
      stack=4, locals=1, args_size=1
         0: aload_0
         1: dup
         2: getfield      #2                  // Field index:I
         5: dup_x1
         6: iconst_1
         7: iadd
         8: putfield      #2                  // Field index:I
        11: invokestatic  #3                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
        14: areturn
      LineNumberTable:
        line 7: 0
}
SourceFile: "TestClass.java"
```

参考文献：《深入理解java虚拟机》周志明 著.
