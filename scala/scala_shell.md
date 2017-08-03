```
def multiply(str : String) : Long = {
	var mul : Long = 1
	for( i <- str) {
		mul *= i.toInt
	}
	mul
}


//递归实现

override def product(str : String) : Long = {
	if str.size == 0 product(str) = 1l else str.takeRight(1) * product(str.dropRight(1))
}
```
