- 在spring的配置文件application.yml里面配置list：

	用逗号分隔的*string*表示
	
	*application.yml*
	
	`string: string1,string2,string3`
	
	```
	
	@Value("${string}")
	string[] stringList;
	```
	
	`stringList:{"string1","string2","string3"}`