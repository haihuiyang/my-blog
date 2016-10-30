##***Java集合框架Collection:***

	一个独立元素的序列，这些元素都服从一条或多条规则；
	List必须按照插入的顺序保存元素，Set不能有重复元素。

### ***List(subInterface)***           
####*1.ArrayList*
	
- 实现了可变大小的数组（每次扩容后的*capacity*约为原*capacity*的1.5倍），允许**null**值，底层使用数组保存所有元素，所以随机访问很快，可以直接通过元素的下标值获取元素的值，但插入和删除较慢，因为需要移动*array*里的元素，未实现同步


- *ArrayList*默认的初始化容量非常小(10),底层实现为*array*，当对其添加大量数据时就必须改变*ArrayList*的*size*(一为原*size*的1.5倍)，而这种*resize*的*cost*是很大的，所以如果你知道你需要对*ArrayList*添加大量元素时最好给一个大一点的size


- *Create ArrayList from array*
				

```java
Object[] array = new Object[10];
List<Object> arrayList1 = new ArrayList<>(Arrays.asList(array));
List<Object> arrayList2 = Arrays.asList(array);
//Arrays.asList(array)返回的是一个fixed size array，如果不用new ArrayList<>(Arrays.asList(array))包装起来的话，对它进行add或remove操作就会报java.lang.UnsupportedOperationException
```

       
####*2.LinkedList*       

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
