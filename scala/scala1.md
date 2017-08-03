# scala基础：

* `val`和`var`的区别：

	- `val`声明的值是一个不可变的常
	- `var`声明的是一个可变的变量
	- 声明`val`（值）或`var`（变量）不初始化会报错
	
* `Unit`与`void`相似


## [trait](http://docs.scala-lang.org/tutorials/tour/mixin-class-composition.html)

* 直译为 特性，特点
* 与java的接口类似(除了可以有实现外－－具有更大的灵活性，基本上相同)，但是可以实现部分方法
* 被trait修饰的对象可作为混入类(mixin-class)加到其他类中，使用with关键字 
* trait可以继承于类，也可以继承其他trait
* 不能从trait直接创建实例对象

```scala
	abstract class AbsIterator {
	  type T
	  def hasNext: Boolean
	  def next: T	
	}
```


```scala
	trait RichIterator extends AbsIterator {
	  def foreach(f: T => Unit) { while (hasNext) f(next) }
	}
```


```scala
	class StringIterator(s: String) extends AbsIterator {
	  type T = Char
	  private var i = 0
	  def hasNext = i < s.length()
	  def next = { val ch = s charAt i; i += 1; ch }
	}
```

```scala
	object StringIteratorTest {
	  def main(args: Array[String]) {
	    class Iter extends StringIterator(args(0)) with RichIterator
	    val iter = new Iter
	    iter foreach println
	  }
	}
```

* all new definitions that are not inherited

* RichIterator和StringIterator都继承自AbsIterator，而且RichIterator是被trait修饰的，即实现了AbsIterator的一个特性，而且可以作为混入类加入到其他实现了AbsIterator的类里面，使用with关键字，这样，其他实现AbsIterator的子类也就拥有了trait的特性。
