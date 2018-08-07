在 HotSpot 虚拟机中，对象在内存中存储的布局分为 3 块区域：对象头 ( Header ) 、实例数据 ( InstanceData ) 和对齐填充 (Padding) 。

##### 对象头 ( Header )
HotSpot 虚拟机的对象头包括以下信息：

###### "Mark Word"：
存储对象自身的运行时数据，如：哈希码 ( HashCode ) 、GC 分代年龄、锁状态标志、线程持有的锁、偏向线程 ID 、偏向时间戳等。这部分数据的长度在 32 位和 64 位的虚拟机中分别为 32 bit 和 64 bit 。

###### "Klass"：
类型指针，指向该对象的类元数据 ( 方法区 ) 的指针，虚拟机通过该指针来确定这个对象属于哪个类。这部分数据的长度在 32 位和 64 位的虚拟机中分别为 32 bit 和 64 bit ( 如果开启了指针压缩则为 4 bytes )。

###### "Array Length"：如果对象是一个 Java 数组，那么对象头中还有一块用于记录数组长度的数据
用于确定数组的大小，int 类型，大小为 4 bytes。

##### 实例数据 ( InstanceData )
![数据类型的长度](https://img-blog.csdn.net/20180805231910612?watermark/2/text/aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L2hhaWh1aV95YW5n/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70)
reference : 在 32 位和 64 位虚拟机中分别为 4 bytes 和 8 bytes ( 如果开启了指针压缩则为 4 bytes )。

##### 对齐填充 (Padding) 
不是必然存在，无特殊含义，仅仅是占位符的作用。因为 HotSpot VM 的自动内存管理系统要求对象起始地址必须是 8 字节的整数倍，当对象大小没有对齐时，需要通过对齐填充来补全。

```
/**
 * environment:
 *     java version "1.8.0_101"
 *     Java(TM) SE Runtime Environment (build 1.8.0_101-b13)
 *     Java HotSpot(TM) 64-Bit Server VM (build 25.101-b13, mixed mode)
 * VM options: -XX:+UseCompressedOops 使用指针压缩
 */
public class MemoryUseTest {

    public static void main(String[] args) {

        System.out.println(MemoryUtil.memoryUsageOf(new ObjectUse1()));
        System.out.println(MemoryUtil.memoryUsageOf(new ObjectUse2()));
        System.out.println(MemoryUtil.memoryUsageOf(new ObjectUse3()));
        System.out.println(MemoryUtil.memoryUsageOf(new ObjectUse4()));
        System.out.println(MemoryUtil.memoryUsageOf(new ObjectUse5[10]));
    }

    static class ObjectUse1 {
        short a;
    }

    static class ObjectUse2 {
        int a;
    }

    static class ObjectUse3 {
        long a;
    }

    static class ObjectUse4 {
        Object a;
    }

    static class ObjectUse5 {
        long a;
    }

}
```

```
output:
		16 // header(8) + klass(4) + short(2) + padding(2) = 16
		16 // header(8) + klass(4) + int(4) = 16
		24 // header(8) + klass(4) + long(8) + padding(4) = 24
		16 // header(8) + klass(4) + reference(4) = 16
		56 // header(8) + klass(4) + array length(4) + reference(4) * 10 = 56
```
掌握对象在内存中的布局可以让我们知道虚拟机中的内存到底是如何被使用的，以及如何调整代码以减少内存的开销。

参考资料：
（1）《深入理解java虚拟机》周志明 著.
（2）[Primitive Data Types](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/datatypes.html)