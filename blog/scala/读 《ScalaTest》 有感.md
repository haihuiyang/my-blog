> 转载请注明原创出处，谢谢！
>
> [HappyFeet的博客](https://blog.csdn.net/haihui_yang)

距离上一次发博客差不多有一年了。2018 年 10 月 至 2019 年 8 月，这一段时间待在上海负责公司的一个项目，整个人就忙了起来，在坚持写了两个月之后就觉得没那么多精力再去做其他事情了，于是就把写博客这件事情搁了下来。中途有好几次都是想写但最终都没有下定决心，然后就一直耽搁下来。回到成都后，事情没那么多了，是时候做一些笔记了。

---

其实呢，看这篇文档是因为工作上遇到的一个问题：Scala 单元测试如何优雅的去 assert 一个方法抛出指定异常呢？

对于 Java 来说，很简单：

```java
@Test(expected = YourExpectedException.class)
public void test_method() {

   // method body			
	
}
```

而在 Scala 里面没法这样写。在看这个文档之前，我想到的办法是这样子的：

```scala
try {
       // method body
} catch {
  case e: Throwable =>
    assert(e.isInstanceOf[YourExpectedException])
    assert(e.getMessage == "your expected message")
}
```

通过 ```try ... catch``` 的方式实现，写完了之后一看，写起来很麻烦，另外有点地方不对劲：如果方法不抛异常测试也一样能过，所以就去问了一下同事有什么方式可以做到这件事情，同事发了我一个链接：[`http://www.scalatest.org/user_guide/using_matchers`](http://www.scalatest.org/user_guide/using_matchers)。读完之后发现了以下几种方式都可以做到：

```scala
an [YourExpectedException] should be thrownBy {     // Ensure a particular exception type is thrown
       // method body
}

val caught = the [YourExpectedException] thrownBy { // Capturing an expected exception in a variable
       // method body
}

the [YourExpectedException] thrownBy {              // Inspecting an expected exception
       // method body
} should have message ("your expected message")
```
看了上面几种方式，瞬间觉得舒服多了，写测试就像写一句话一样，读起来非常流畅，也很明朗，极力推荐！！！

在优化了代码之后，这篇文档也就被我收藏了起来。why？因为这个文档写的很好，简洁易懂，并且都带有详细的举例说明，是我的菜(^_^)，没过多久我就把它看完了，现在就分享给大家。

ScalaTest 是一位名叫 Bill Venners 开发出来的 Scala 测试框架。主要目的是为了**提高程序员的生产力**。那么，它有哪些特点呢？

##### 1、提出了 suite 的概念

suite：0 ~ n 个测试的集合。

##### 2、支持多种测试样式

例如：FunSuite（BDD）样式:

```scala
import org.scalatest.FunSuite

class SetSuite extends FunSuite {

  test("An empty Set should have size 0") {
    assert(Set.empty.size == 0)
  }

  test("Invoking head on an empty Set should produce NoSuchElementException") {
    assertThrows[NoSuchElementException] {
      Set.empty.head
    }
  }
}
```

WordSpec（specs or specs2）样式:

```scala
import org.scalatest.WordSpec

class SetSpec extends WordSpec {

  "A Set" when {
    "empty" should {
      "have size 0" in {
        assert(Set.empty.size == 0)
      }

      "produce NoSuchElementException when head is invoked" in {
        assertThrows[NoSuchElementException] {
          Set.empty.head
        }
      }
    }
  }
}
```
...

还有验收测试样式等等，这里就不一一例举了，可以[点击这里](http://www.scalatest.org/user_guide/selecting_a_style)查看 ScalaTest 支持的所有样式。

ScalaTest 提供这些样式并不是为了让用户每一种样式都用，而是建议团队为单元测试选择一种主要样式，验收测试选择一种主要样式，不推荐混合使用。大家可以根据自己的团队选择合适的风格，最适合的才是最好的。

##### 3、集成了主流单元测试 mock 框架

例如 EasyMock、JMock、Mockito 等 Java 主流 mock 框架。并为这些框架提供了足够多的语法糖。例如只要引入了 trait：MockitoSugar 之后，mock 一个类就可以这样写: `val mockedClass = mock[YourClass]`，非常便捷。

##### 4、语言本身提供了各种各样的语法糖，方便编写测试

```scala
sevenDotOh should equal (6.9 +- 0.2)
sevenDotOh should === (6.9 +- 0.2)
sevenDotOh should be (6.9 +- 0.2)
sevenDotOh shouldEqual 6.9 +- 0.2
sevenDotOh shouldBe 6.9 +- 0.2
```

上面代码中出现的 `should`, `equal`, `+-`, `be`, `shouldEqual`, `shouldBe` 就是 `ScalaTest` 提供的语法糖的一部分。

##### 5、还有一些特性，不过平时一般用的比较少，如：异步测试、给测试方法打标签 (tag)、自定义 Match 类等...

从上面的这些特点来看，可以用两个字来形容 ScalaTest：灵活。

不同的样式、集成主流单元测试框架，各种各样的语法糖，使得编写 Scala Test 非常简单；一句话的风格读起来也很顺畅，而且浅显易懂。

文章提到的一个理念也很有道理，在日常开发的过程中应该要时刻遵守：**测试代码应该要 `简洁、明显，快速易懂`，使得团队中的不同开发人员能够通过查看彼此的测试代码就能快速知道代码在干什么。**

最后引用一句原文的话概括一下：

>The upshot is that ScalaTest is designed to facilitate productivity of teams by being:
>	easy to get into
>	easy to read, even by casual users
>	easy to remember how to write
>	easy to customize to address special needs

PS: 自我感觉新 Get 到了很多东西，不过学到了和用文字表达出来感觉有不是那么一回事儿，就跟做笔记一样，学到的肯定比写下来的多。看来，表达能力还有待提高呀，革命尚未成功，同志仍需努力！加油！！！

参考资料：

（1）[ScalaTest](http://www.scalatest.org/)