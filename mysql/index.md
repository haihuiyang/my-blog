- _mysql_ **_index_** 创建：
 
1. 优点：创建 **_index_** 之后， _select_ 会很快，相对的， _insert_ 会慢。一般来说，最好创建索引，提升的 _select_ 速度比降低的 _insert_ ，  _update_ or _delete_ 的要多。

2. 缺点： **_index_** 会占磁盘空间；降低写的速度（_insert_，_update_，_delete_）
