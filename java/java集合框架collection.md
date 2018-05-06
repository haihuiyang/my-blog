##***Java集合框架Collection:***

	一个独立元素的序列，这些元素都服从一条或多条规则；
	List必须按照插入的顺序保存元素，Set不能有重复元素。

### ***List(subInterface)***           
####*1.ArrayList*(基于索引的动态数组)
	
- 实现了**可变大小**的数组，允许所有元素，包括**null**值，底层使用数组(**array**)保存所有元素，所以随机访问很快，可以直接通过元素的下标值获取元素的值（***size, isEmpty, get, set, iterator, listIterator***这些方法的时间复杂度均为**O(1)**），但插入和删除较慢，因为需要移动*array*里的元素(即***add, remove***的时间复杂度为**O(n)**)，未实现同步


- 每一个*ArrayList*实例都有一个容量(***capacity***)，使用**Lists.newArrayList()**创建的是一个**capacity为0**的List，当在添加第一个元素的时候会扩展到默认的初始化容量(**10**)，当对其添加的数据大于它的***capacity***就必须改变*ArrayList*的***capacity***(一般是原来大小的1.5倍)，而这种***resize***操作是有开销的，所以如果你知道数组的大小为actualSize，可以按照下面的方式初始化一个大小固定的ArrayList，以减去resaze的开销：

	```java
	int actualSize = 100;
	List<Object> objectArrayList = Lists.newArrayListWithCapacity(actualSize);
	```

- ***iterator()和listIterator(int)***返回的迭代器是快速失败(**fail-fast**)的：

	如果在迭代器创建之后，原始的List被修改了，迭代器会抛一个`ConcurrentModificationException`，原因是Iterator里的`expectedModCount`和List的`modCount`不一致导致的。在迭代的时候如果需要修改List，只能通过Iterator的remove方法修改


- *Create ArrayList from array*
				

	```java
	Object[] array = new Object[10];
	List<Object> arrayList1 = Lists.newArrayList(Arrays.asList(array));
	List<Object> arrayList2 = Arrays.asList(array);
	//需要注意的是：Arrays.asList(array)返回的是一个fixed size array(上面的arrayList2)，如果不用Lists.newArrayList(Arrays.asList(array))(上面的arrayList2)包装起来的话，对它进行add或remove操作就会报java.lang.UnsupportedOperationException
	```

       
####*2.LinkedList*(双链表数据结构)  

   - 实现了*List*接口，允许**null**值，底层使用链表保存所有元素(除了要存数据外，还需存**next**和**pre**两个*pointer*，因此占用的内存比*ArrayList*多)，因此，向*LinkedList*里面插入或移除元素时会特别快，但是对于随机访问方面相对较慢（需要遍历链表），无同步，想要实现同步可以这样：

	```java
	List list = Collections.synchronizedList(new LinkedList(...)); 
	```

   - *LinkedList*还添加了可以使其用作栈，队列或者双向队列的方法（待理解）  
   
####	*3.Vector*         

##### 和*ArrayList*几乎一样，由于实现了同步，所以较*ArrayList*有轻微的性能上的差距（一般不用它，而是使用*ArrayList*，在外部实现同步）

####	*4.Stack*    
##### 后进先出（LIFO），继承于Sector，新增了五个方法：push(E item)：将item压入栈；pop()：remove掉栈顶元素并返回remove掉的元素；peek()：返回栈顶的第一个元素（无remove操作）；empty()：判断栈是否为空；search()：返回查找到的离栈顶最近的元素的position;

#### **总结：**

	1.当集合内的元素需要频繁插入，删除操作时应使用LinkedList；当需要频繁查询时，使用ArrayList(大部分情况是使用ArrayList)
	
	2.ArrayList和LinkedList都未实现同步，Vector是在ArrayList的基础上实现了同步，是线程安全的
	
	3.相比而言，LinkedList所占的内存要比ArrayList大
   
###***Set(subInterface)***

####	*1.HashSet*         
####	*2.LinkedHashSet*         
####	*3.TreeSet*         
####	*4.SortedSet*       

##***Map:***
	
	一组成对的“键值对”对象，允许用键来查找值。

####***1.HashMap***		
	
####***2.HashTable***		
	
####***3.WeakHashMap***		
	
####***4.SortedMap***			

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

参考链接：			
1.[Create ArrayList from array](http://stackoverflow.com/questions/157944/create-arraylist-from-array)			
2.[When to use LinkedList over ArrayList?](http://stackoverflow.com/questions/322715/when-to-use-linkedlist-over-arraylist#comment22926624_7671021)			
3.[java中的容器讲解](http://blog.csdn.net/wwww1988600/article/details/8646191)    
4.[Java ArrayList resize costs](https://codinginthetrenches.com/2014/09/10/java-arraylist-resize-costs/)
