- $SPARK_HOME/bin/spark-shell --packages datastax:spark-cassandra-connector:1.6.0-s_2.10

- $SPARK_HOME/bin/spark-submit --packages datastax:spark-cassandra-connector:1.6.0-s_2.10


***运行spark-shell:***

```spark
/Users/yanghaihui/tools/spark-2.0.1-bin-hadoop2.7/bin/spark-shell --conf spark.cassandra.connection.host=127.0.0.1 \
--packages datastax:spark-cassandra-connector:2.0.0-M2-s_2.11
```

- spark-shell 示例shell

```scala
import org.apache.spark.sql._
import org.apache.spark.sql.cassandra._
import com.datastax.spark.connector._
import com.datastax.spark.connector.cql._

val sqlContext = new SQLContext(sc)

val df = sqlContext.read.format("org.apache.spark.sql.cassandra").options(Map( "table" -> "idx_weight", "keyspace" -> "gta")).load()

df.createOrReplaceTempView("idx_weight")

val sql = spark.sql("select tradingdate,weight from idx_weight where symbol = '000906'");

val df_filter = df.filter("tradingdate >= '2016-08-01' and symbol <= '000010'")

val df_filter10 = df_filter.head(10)

df_filter10.show

df_filter10.printSchema()
```

var csi800_weight = idx_weight_df.filter("select date_format(tradingdate,'%Y-%m-%d'), weight from gta.idx_weight where symbol = '000906';")

var csi800_weight = idx_weight_df.filter("select tradingdate,weight from gta.idx_weight where symbol = '000906';")

DATE_FORMAT(TRADINGDATE,'%Y-%m-%d')




/Users/yanghaihui/tools/spark-2.0.1-bin-hadoop2.7/bin/spark-submit --class com.yhh.spark.App \
    --master local \
    /Users/yanghaihui/IdeaProjects/sparkTest/target/sparkTest-1.0-SNAPSHOT-jar-with-dependencies.jar