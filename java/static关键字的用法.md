
---
#####*static*：意为静态的.在*java*里面作为静态修饰符，可以理解为“全局”的意思，但是请注意：在*java*中是没有“全局”这一概念的。

 > ***static***不仅可以修饰成员变量，成员方法；还可以修饰代码块。
 
 1.  被***static***修饰的成员变量，在编译时由内存分配一块内存空间(只分配一块，为所有该类的实例所共享)，在程序结束时才会释放(也就是说gc回收对象时不会释放这一块空间，因为它不属于某个实例，它属于“**大家**”)，通过“***className.varName***”就可以访问静态成员变量（同一个类里的静态方法可以直接通过***varName***使用）
 
 **需要注意的两点**：
	 >a) 不能使用***this.staticVar***或者***this.staticMethod***，因为this关键字指的是调用方法的对象的引用，而***staticVar***并不属于某一个对象的引用！
	 >b) 不能在方法体内部声明静态变量！
	
 2. 	被***static***修饰的成员方法也是独立于该类的任何对象，被该类的所有实例共享。也可以不用实例化对象，直接通过和“***className.methodName***”就可以访问。***static***方法不允许使用非静态成员变量；当然，静态成员变量可以使用对象引用的实例化变量

	```java
	public class ExampleForStatic{
		public static int staticField = 1;
		public int instanceField;
		public static void main(String[] args){
			//通过***className.method***调用静态方法
			System.out.println(ExampleForStatic.getStaticField());
		}
	
		public static int getStaticField(){
			//static int staticFieldInMethod;错误，不能在方法体内部声明静态变量
			//同一个类的静态方法可以直接使用静态变量
			return staticField;	
			//return this.staticField;错误！不能使用this获取静态变量
		}
	}
	```

 3. 	被***static***修饰的代码块，会在类被初次加载的时候按照***static***块的顺序执行一遍，仅仅只加载一次(可提高性能，将一些创建对象实例时耗费资源较多的类的实例化放在一个***static｛｝***中可以提高程序运行效率)，一般用来初始化静态变量和调用静态方法。
 >a) 被***static***修饰的代码是类初始化器，剩下的代码是实例初始化，类初始化会在类被加载（[类在什么时候被加载？](localhost)）的时候按照定义的顺序执行初始化，而实例初始化在对象建立实例的时候执行，一个类最多被加载一次，即***static***修饰的代码最多执行一次，与建立对象的多少无关。
 >b) 在类第一次被加载时，首先会将所有的***static***域初始化为缺省值，然后再根据定义的顺序来执行赋值语句。

	```java
	public class ExampleForStatic {
	    private static String staticField;
	    private String instanceField;
	
	    static {
	        staticField = "this is my first blog.";
	        System.out.println(staticField);
	    }
	
	    {
	        System.out.println("instance has been created.");
	    }
	
	    public static void main(String[] args) {
	        DebugForStatic obj1 = new ExampleForStatic();
	        DebugForStatic obj2 = new ExampleForStatic();
	        DebugForStatic obj3 = new ExampleForStatic();
	    }
	}
	```
输出：
	```java
	this is my first blog.
	instance has been created.
	instance has been created.
	instance has been created.
	```

 4.    ***static***+***final*** ：类似于“全局常量”。
	 >对于变量，表示一旦给值便不可更改；
	 >对于方法，表示不可覆盖。

 5. 什么时候使用***static***呢？
     >One rule-of-thumb: ask yourself "does it make sense to call this method, even if no Obj has been constructed yet?"



 参考链接：			
1.[java中的static关键字解析](http://www.cnblogs.com/dolphin0520/p/3799052.html)              
2.[java中static作用详解](http://zhidao.baidu.com/link?url=h4CtRxVLXhIH4v5bCm8Ds2SJNTwWCzUGBXxt4B0pKYSdAStE_MmhqP76tGdEw6hBMsahiyr5WRjNlwkai3ee_q)											
3.[What does the 'static' keyword do in a class?](http://stackoverflow.com/questions/413898/what-does-the-static-keyword-do-in-a-class)                            
4.[java中静态代码块的用法 static用法详解](http://www.cnblogs.com/panjun-Donet/archive/2010/08/10/1796209.html)                                         
5.[Static initializer in Java](http://stackoverflow.com/questions/335311/static-initializer-in-java)  
6.[Java: when to use static methods](http://stackoverflow.com/questions/2671496/java-when-to-use-static-methods)
>#####ps：第一次写博文，看了很多篇文章，给自己做了一点总结，有说的不对的地方或不足的地方，欢迎大家指出，一起学习，谢谢！