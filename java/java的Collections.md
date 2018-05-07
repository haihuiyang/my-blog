##***Collections:***

##***Arrays:***
- Arrays:提供了多个操作***array***的方法
	- sort()：排序

	```java
	Integer[] integers = {2, 4, 52, 6, 24, 72, 23, 22, 11};
	
	Arrays.sort(integers);//sort
	
	Arrays.stream(integers).forEach(i -> System.out.print(i + " "));
	```
		输出：2 4 6 11 22 23 24 52 72 
	- binarySearch()：二分查找

	```java
	  List<String> list = Arrays.asList("aaa", "bbb", "ccc", "ddd", "eee", "fff", "ggg");

      String[] str = (String[]) list.toArray();

      System.out.println(Arrays.binarySearch(str, "ddd"));//binarySearch
	```
		输出：3
	- copyOf()：复制数组

	```java
	String[] newStr = Arrays.copyOf(str, 4);//copyArray
	```
		输出：aaa bbb ccc ddd
	- equals()：判断数组是否相等

		//不仅元素要想等，顺序也要相同
	- fill()：向数组里面填充元素（用一个元素填充数组）

	
	```java
	Character[] chars = {'a', 'b', 'c'};
	
	Arrays.fill(chars, 'd');//fill
	
	Arrays.stream(chars).forEach(c -> System.out.print(c + " "));
	```
		输出：d d d
	- stream()：java 1.8已经实现了stream方法

	
	```java
	String[] newStr = Arrays.copyOf(str, 4);//copyArray
	
	Arrays.stream(newStr).forEach(s -> System.out.print(s + " "));//stream
	```
	- toString()：转换为String
	- ...
