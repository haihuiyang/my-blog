# 初学scala

[学习链接](http://www.scala-lang.org/documentation/getting-started.html)

* 使用下面命令运行scala程序，scala编译原理与java类似，通过scalac command编译一个或多个scala源文件，然后产生可以在任何标准JVM上执行的bytecode。

```scala
scalac HelloWorld.scala
```

* scalac将产生的class files放在当前目录（默认），你也可以通过 `-d` 参数指定不同的输出目录，如：

```scala
scalac -d classes HelloWorld.scala
```

* 执行编译后的bytecode：

```scala
scala HelloWorld
```

* 也可以通过`-classpath`（别名为：`-cp`）指定bytecode所在目录

```scala
scala -cp(-classpath) classes HelloWorld
```

