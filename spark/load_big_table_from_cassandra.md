 - spark cassandra

	spark通过cassandra表创建view。
	当cassandra表中数据很大的时候，用全表创建view是一个很不好的行为；有一种优化的方案：使用rdd创建view的方式，导入所需数据(避免全表加载到内存，节省开销)。
	
  
	```
	loadNeededData(spark:SparkSession, cql:String, viewName:String): DataFrame ={
	    import spark.implicits._
	    import com.datastax.spark.connector._
	
	    val rdd = spark.sparkContext
	      .cassandraTable("keyspace","table")
	      .where(cql).filter(filterCondition).map(
			row=>{(row.getString("colName1"),row.getString("colName2"),row.getString("colName3"),row.get[Double]("colName4"))
	    })

	    val df = rdd.toDF("colName1","colName2","colName3","colName4")
	    df.createOrReplaceTempView(viewName)
	    df
	  }
	```