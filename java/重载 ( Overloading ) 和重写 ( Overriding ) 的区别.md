##### 重载 ( Overloading )：同一个类中方法名称相同，方法特征签名不同

1、同一个类中
2、方法名称一样
3、方法特征签名不同

什么是**方法特征签名**?

Java 代码的方法特征签名只包括了方法名称、参数顺序及参数类型。不包括方法的返回值，因此不能通过方法的返回值不同实现方法的重载。

Note：虽然 java 语言中无法通过返回值不同来重载方法，但在 Class 文件格式中是可以的（ Class 文件中方法特征签名是包含了方法的返回值的），如果两个方法有相同的名称和特征签名，但返回值不同，那么也是可以合法共存于同一个 Class 文件中的。

##### 重写 ( Overriding )：在子类中更改给定方法的实现

1、不同类中（准确来说是父类和子类中）
2、方法特征签名一样

##### Overriding vs. Overloading
1、引用类型确定在编译时该使用哪个重载方法，而运行时的实际类型确定使用哪个重写方法。
2、重载是编译时概念，而重写是一个运行时概念。

```
public class OverloadTest {

    static abstract class Human {

    }

    static class Man extends Human {

    }

    static class Woman extends Human {

    }

    public void sayHello(Human guy) {
        System.out.println("hello, guy!");
    }

    public void sayHello(Man guy) {
        System.out.println("hello, gentleman!");
    }

    public void sayHello(Woman guy) {
        System.out.println("hello, lady!");
    }

    public static void main(String[] args) {
        OverloadTest overload = new OverloadTest();

        Human man = new Man();
        Human woman = new Woman();

        overload.sayHello(man);
        overload.sayHello(woman);
    }

}
```

```
output:
		hello, guy!
		hello, guy!
```


```
public class OverrideTest {

    static abstract class Human {
        abstract void sayHello();
    }

    static class Man extends Human {

        @Override
        void sayHello() {
            System.out.println("hello, man!");
        }
    }

    static class Woman extends Human {

        @Override
        void sayHello() {
            System.out.println("hello, woman!");
        }
    }

    public static void main(String[] args) {
        Human man = new Man();
        Human woman = new Woman();

        man.sayHello();
        woman.sayHello();
    }
}
```

```
output:
		hello, man!
		hello, woman!
```
参考资料：
（1）[Overriding vs. Overloading in Java](https://www.programcreek.com/2009/02/overriding-and-overloading-in-java-with-examples/)
（2）《深入理解java虚拟机》周志明 著.