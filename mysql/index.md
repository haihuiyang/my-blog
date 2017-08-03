* mysql的`index`创建：
 
	* 优点：创建`index`之后，`select`会很快，相对的，`insert`会慢。一般来说，最好创建索引，提升的`select`速度比降低的`insert`，`update` or `delete`的要多。

	* 缺点：`index`会占磁盘空间；降低写的速度（`insert, update, delete`）
