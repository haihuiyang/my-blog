CREATE KEYSPACE test WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1 };
CREATE TABLE test.kv(key text PRIMARY KEY, value int);

INSERT INTO test.kv(key, value) VALUES ('key1', 1);
INSERT INTO test.kv(key, value) VALUES ('key2', 2);

//run spark-shell
$SPARK_HOME/bin/spark-shell --conf spark.cassandra.connection.host=127.0.0.1 \
                            --packages datastax:spark-cassandra-connector:2.0.0-M2-s_2.11


//Loading and analyzing data from Cassandra
import com.datastax.spark.connector._

val rdd = sc.cassandraTable("test", "kv")
println(rdd.count)
println(rdd.first)
println(rdd.map(_.getInt("value")).sum)        

//Saving data from RDD to Cassandra
val collection = sc.parallelize(Seq(("key3", 3), ("key4", 4)))
collection.saveToCassandra("test", "kv", SomeColumns("key", "value"))       



//Preparing SparkContext to work with Cassandra
val conf = new SparkConf(true)
        .set("spark.cassandra.connection.host", "192.168.123.10")
        .set("spark.cassandra.auth.username", "cassandra")            
        .set("spark.cassandra.auth.password", "cassandra")

val sc = new SparkContext("spark://192.168.123.10:7077", "test", conf)




//Mapping rows to tuples
sc.cassandraTable[(String, Int)]("test", "words").select("word", "count").toArray
// Array((bar,20), (foo,10))

sc.cassandraTable[(Int, String)]("test", "words").select("count", "word").toArray
// Array((20,bar), (10,foo))

//Example Mapping a Cassandra Row to a Scala Case Class

case class WordCount(word: String, count: Int)
sc.cassandraTable[WordCount]("test", "words").toArray
// Array(WordCount(bar,20), WordCount(foo,10))

//Example of reading from one cluster and writing to another
import com.datastax.spark.connector._
import com.datastax.spark.connector.cql._

import org.apache.spark.SparkContext


def twoClusterExample ( sc: SparkContext) = {
  val connectorToClusterOne = CassandraConnector(sc.getConf.set("spark.cassandra.connection.host", "127.0.0.1"))
  val connectorToClusterTwo = CassandraConnector(sc.getConf.set("spark.cassandra.connection.host", "127.0.0.2"))

  val rddFromClusterOne = {
    // Sets connectorToClusterOne as default connection for everything in this code block
    implicit val c = connectorToClusterOne
    sc.cassandraTable("ks","tab")
  }

  {
    //Sets connectorToClusterTwo as the default connection for everything in this code block
    implicit val c = connectorToClusterTwo
    rddFromClusterOne.saveToCassandra("ks","tab")
  }

}



//Obtaining a Cassandra table as an RDD
import com.datastax.spark.connector._ //Loads implicit functions
sc.cassandraTable("keyspace name", "table name")

val rdd = sc.cassandraTable("test", "words")
// rdd: com.datastax.spark.connector.rdd.CassandraRDD[com.datastax.spark.connector.rdd.reader.CassandraRow] = CassandraRDD[0] at RDD at CassandraRDD.scala:41

rdd.toArray.foreach(println)
// CassandraRow{word: bar, count: 20}
// CassandraRow{word: foo, count: 20}   


//Example of using an EmptyCassandraRDD

// validation is deferred, so it is not triggered during rdd creation
val rdd = sc.cassandraTable[SomeType]("ks", "not_existing_table")
val emptyRDD = rdd.toEmptyCassandraRDD

val emptyRDD2 = sc.emptyCassandraTable[SomeType]("ks", "not_existing_table"))

//Example Accessing the values within a CassandraRow
val firstRow = rdd.first
// firstRow: com.datastax.spark.connector.rdd.reader.CassandraRow = CassandraRow{word: bar, count: 20}
firstRow.columnNames    // Stream(word, count) 
firstRow.size           // 2 

firstRow.getInt("count")       // 20       
firstRow.getLong("count")      // 20L 

firstRow.get[Int]("count")                   // 20       
firstRow.get[Long]("count")                  // 20L
firstRow.get[BigInt]("count")                // BigInt(20)
firstRow.get[java.math.BigInteger]("count")  // BigInteger(20)

//Example accessing values in a CassandraRow that may be null

firstRow.getIntOption("count")        // Some(20)
firstRow.get[Option[Int]]("count")    // Some(20)

//Reading collections

CREATE TABLE test.users (username text PRIMARY KEY, emails SET<text>);
INSERT INTO test.users (username, emails) 
     VALUES ('someone', {'someone@email.com', 's@email.com'});

val row = sc.cassandraTable("test", "users").first
// row: com.datastax.spark.connector.rdd.reader.CassandraRow = CassandraRow{username: someone, emails: [someone@email.com, s@email.com]}

row.getList[String]("emails")            // Vector(someone@email.com, s@email.com)
row.get[List[String]]("emails")          // List(someone@email.com, s@email.com)    
row.get[Seq[String]]("emails")           // List(someone@email.com, s@email.com)   :Seq[String]
row.get[IndexedSeq[String]]("emails")    // Vector(someone@email.com, s@email.com) :IndexedSeq[String]
row.get[Set[String]]("emails")           // Set(someone@email.com, s@email.com)

row.get[String]("emails")               // "[someone@email.com, s@email.com]"


//Reading columns of Cassandra User Defined Types from a CassandraRow
CREATE TYPE test.address (city text, street text, number int);
CREATE TABLE test.companies (name text PRIMARY KEY, address FROZEN<address>);

val address: UDTValue = row.getUDTValue("address")
val city = address.getString("city")
val street = address.getString("street")
val number = address.getInt("number")

//Example Using Implicits for Read Configuration
object ReadConfigurationOne {
  implicit val readConf = ReadConf(100,100)
}
import ReadConfigurationOne._
val rdd = sc.cassandraTable("write_test","collections")
rdd.readConf
//com.datastax.spark.connector.rdd.ReadConf = ReadConf(100,100,LOCAL_ONE,true)

implicit val anotherConf = ReadConf(200,200)
val rddWithADifferentConf = sc.cassandraTable("write_test","collections")
rddWithADifferentConf.readConf
//com.datastax.spark.connector.rdd.ReadConf = ReadConf(200,200,LOCAL_ONE,true)

//Example Using Select to Prune Cassandra Columns
sc.cassandraTable("test", "users").select("username").toArray.foreach(println)
// CassandraRow{username: noemail} 
// CassandraRow{username: someone}

//Example Using Select to Retreive TTL and Timestamp
val row = rdd.select("column", "column".ttl, "column".writeTime).first
val ttl = row.getLong("ttl(column)")
val timestamp = row.getLong("writetime(column)") 

//Example Using "as" to Rename a Column
rdd.select("column".ttl as "column_ttl").first
val ttl = row.getLong("column_ttl")

//Example Using Where to Filter Cassandra Data Server Side

sc.cassandraTable("test", "cars").select("id", "model").where("color = ?", "black").toArray.foreach(println)
// CassandraRow[id: KF-334L, model: Ford Mondeo]
// CassandraRow[id: MT-8787, model: Hyundai x35]

sc.cassandraTable("test", "cars").select("id", "model").where("color = ?", "silver").toArray.foreach(println)
// CassandraRow[id: WX-2234, model: Toyota Yaris]


//Mapping rows to tuples
sc.cassandraTable[(String, Int)]("test", "words").select("word", "count").toArray
// Array((bar,20), (foo,10))

sc.cassandraTable[(Int, String)]("test", "words").select("count", "word").toArray
// Array((20,bar), (10,foo))

// Example Mapping a Cassandra Row to a Scala Case Class
case class WordCount(word: String, count: Int)
sc.cassandraTable[WordCount]("test", "words").toArray
// Array(WordCount(bar,20), WordCount(foo,10))

// Example of Mappable Standard Scala Class
class WordCount extends Serializable {
  var word: String = ""
  var count: Int = 0    
}


// Example Mapping a Cassandra Column to a Differently Named Scala Class Property
case class WordCount(word: String, count: Int)
val result = sc.cassandraTable[WordCount]("test", "words").select("word", "num" as "count").collect()

sc.cassandraTable[SomeClass]("test", "table").select(
    "no_alias",
    "simple" as "simpleProp",
    "simple".ttl as "simplePropTTL",
    "simple".writeTime as "simpleWriteTime")

// Example using keyBy to Map a Cassandra Table to Pairs of Objects

import org.joda.time.DateTime
case class UserId(userName: String, domain: String)
case class UserData(passwordHash: String, lastVisit: DateTime)

sc.cassandraTable[UserData]("test", "users").keyBy[UserId]

sc.cassandraTable[UserData]("test", "users").keyBy[(String, String)]("user_name", "domain")

sc.cassandraTable[(String, DateTime)]("test", "users")
  .select("password_hash", "last_visit", "user_name", "domain")   
  .keyBy[(String, String)]("user_name", "domain")

// Mapping User Defined Types
case class Address(street: String, city: String, zip: Int)
case class ClassWithUDT(key: Int, name: String, addr: Address)

CREATE TYPE ks.address (street text, city text, zip int)
CREATE TABLE $ks.udts(key INT PRIMARY KEY, name text, addr frozen<address>)


// Example Saving an RDD of Tuples with Default Mapping

CREATE TABLE test.words (word text PRIMARY KEY, count int);

val collection = sc.parallelize(Seq(("cat", 30), ("fox", 40)))
collection.saveToCassandra("test", "words", SomeColumns("word", "count"))

/*
cqlsh:test> select * from words;

 word | count
------+-------
  bar |    20
  foo |    10
  cat |    30
  fox |    40

(4 rows)
*/

// Example Saving an RDD of Tuples with Custom Mapping

CREATE TABLE test.words (word text PRIMARY KEY, count int);

val collection = sc.parallelize(Seq((30, "cat"), (40, "fox")))
collection.saveToCassandra("test", "words", SomeColumns("word" as "_2", "count" as "_1"))

/*
cqlsh:test> select * from words;

 word | count
------+-------
  cat |    30
  fox |    40

(2 rows)
*/

// Example Saving an RDD of Scala Objects

case class WordCount(word: String, count: Long)
val collection = sc.parallelize(Seq(WordCount("dog", 50), WordCount("cow", 60)))
collection.saveToCassandra("test", "words", SomeColumns("word", "count"))

/*
cqlsh:test> select * from words;

 word | count
------+-------
  bar |    20
  foo |    10
  cat |    30
  fox |    40
  dog |    50
  cow |    60
*/

// Example Saving an RDD of Scala Objects with Custom Mapping

case class WordCount(word: String, count: Long)
val collection = sc.parallelize(Seq(WordCount("dog", 50), WordCount("cow", 60)))
collection.saveToCassandra("test", "words2", SomeColumns("word", "num" as "count"))

// Example Appending/Prepending To Cassandra Lists
CREATE TABLE ks.collections_mod (
      key int PRIMARY KEY,
      lcol list<text>,
      mcol map<text, text>,
      scol set<text>
  )

val listElements = sc.parallelize(Seq(
  (1,Vector("One")),
  (1,Vector("Two")),
  (1,Vector("Three"))))

val prependElements = sc.parallelize(Seq(
  (1,Vector("PrependOne")),
  (1,Vector("PrependTwo")),
  (1,Vector("PrependThree"))))

listElements.saveToCassandra("ks", "collections_mod", SomeColumns("key", "lcol" append))
prependElements.saveToCassandra("ks", "collections_mod", SomeColumns("key", "lcol" prepend))

/*
cqlsh> Select * from ks.collections_mod where key = 1
   ... ;

 key | lcol                                                                | mcol | scol
-----+---------------------------------------------------------------------+------+------
   1 | ['PrependThree', 'PrependTwo', 'PrependOne', 'One', 'Two', 'Three'] | null | null

(1 rows)
*/


// Example Using Case Classes to Insert into a Cassandra Row With UDTs
CREATE TYPE test.address (city text, street text, number int);
CREATE TABLE test.companies (name text PRIMARY KEY, address FROZEN<address>);

case class Address(street: String, city: String, zip: Int)
val address = Address(city = "Oakland", zip = 90210, street = "Broadway")
val col = Seq((1, "Joe", address))
sc.parallelize(col).saveToCassandra(ks, "udts", SomeColumns("key", "name", "addr"))	


// Example Using UDTValue.fromMap to Insert into a Cassandra Row With UDTs

import com.datastax.spark.connector.UDTValue
case class Company(name: String, address: UDTValue)
val address = UDTValue.fromMap(Map("city" -> "Santa Clara", "street" -> "Freedom Circle", "number" -> 3975))
val company = Company("DataStax", address)
sc.parallelize(Seq(company)).saveToCassandra("test", "companies")


// Example Copying a table without deletes

//cqlsh
CREATE TABLE doc_example.tab1 (key INT, col_1 INT, col_2 INT, PRIMARY KEY (key))
INSERT INTO doc_example.tab1 (key, col_1, col_2) VALUES (1, null, 1)
CREATE TABLE doc_example.tab2 (key INT, col_1 INT, col_2 INT, PRIMARY KEY (key))
INSERT INTO doc_example.tab2 (key, col_1, col_2) VALUES (1, 5, null)

//spark-shell
val ks = "doc_example"
//Copy the data from tab1 to tab2 but don't delete when we see a null in tab1
sc.cassandraTable[(Int, CassandraOption[Int], CassandraOption[Int])](ks, "tab1")
  .saveToCassandra(ks, "tab2")

sc.cassandraTable[(Int,Int,Int)](ks, "tab2").collect
//(1, 5, 1)

// Example of using different None behaviors

//Fill tab1 with (1, 1, 1) , (2, 2, 2) ... (6, 6, 6)
sc.parallelize(1 to 6).map(x => (x, x, x)).saveToCassandra(ks, "tab1")
//Delete the second column when x >= 5
//Delete the third column when x <= 2
//For other rows put in the value -1
sc.parallelize(1 to 6).map(x => x match {
  case x if (x >= 5) => (x, CassandraOption.Null, CassandraOption.Unset)
  case x if (x <= 2) => (x, CassandraOption.Unset, CassandraOption.Null)
  case x => (x, CassandraOption(-1), CassandraOption(-1))//add default value.
}).saveToCassandra(ks, "tab1")

val results = sc.cassandraTable[(Int, Option[Int], Option[Int])](ks, "tab1").collect
results 
/*
  (1, Some(1), None),
  (2, Some(2), None),
  (3, Some(-1), Some(-1)),
  (4, Some(-1), Some(-1)),
  (5, None, Some(5)),
  (6, None, Some(6)))
*/

//set default value
CREATE TABLE test.word2 (
	key text,
    word text,
    count int,
    primary key(key,word)
)

import com.datastax.spark.connector.types.CassandraOption

sc.parallelize(1 to 5).map( x=>( x ,CassandraOption("key") ,x*x) )
	.saveToCassandra("test","word2",SomeColumns( "word" , "key" , "count" ))

/*
 key | word | count
-----+------+-------
 key |    1 |     1
 key |    2 |     4
 key |    3 |     9
 key |    4 |    16
 key |    5 |    25
*/


//Example of converting Scala Options to Cassandra Options

import com.datastax.spark.connector.types.CassandraOption
//Setup original data (1, 1, 1) ... (6, 6, 6)
sc.parallelize(1 to 6).map(x => (x,x,x)).saveToCassandra(ks, "tab1")

//Setup options Rdd (1, None, None) (2, None, None) ... (6, None, None)
val optRdd = sc.parallelize(1 to 6)
  .map(x => (x, None, None))

//Delete the second column, but ignore the third column
optRdd
  .map{ case (x: Int, y: Option[Int], z: Option[Int]) =>
    (x, CassandraOption.deleteIfNone(y), CassandraOption.unsetIfNone(z))
  }.saveToCassandra(ks, "tab1")

val results = sc.cassandraTable[(Int, Option[Int], Option[Int])](ks, "tab1").collect
results
/*
    (1, None, Some(1)),
    (2, None, Some(2)),
    (3, None, Some(3)),
    (4, None, Some(4)),
    (5, None, Some(5)),
    (6, None, Some(6))
*/

// Example of using ignoreNulls to treat all nulls as Unset

//Setup original data (1, 1, 1) --> (6, 6, 6)
sc.parallelize(1 to 6).map(x => (x, x, x)).saveToCassandra(ks, "tab1")

val ignoreNullsWriteConf = WriteConf.fromSparkConf(sc.getConf).copy(ignoreNulls = true)
//These writes will not delete because we are ignoring nulls
val optRdd = sc.parallelize(1 to 6)
  .map(x => (x, None, None))
  .saveToCassandra(ks, "tab1", writeConf = ignoreNullsWriteConf)

val results = sc.cassandraTable[(Int, Int, Int)](ks, "tab1").collect

results
/**
  (1, 1, 1),
  (2, 2, 2),
  (3, 3, 3),
  (4, 4, 4),
  (5, 5, 5),
  (6, 6, 6)
**/

// Example Creating a New Table and Saving an RDD to it at the Same Time
case class WordCount(word: String, count: Long)
val collection = sc.parallelize(Seq(WordCount("dog", 50), WordCount("cow", 60)))
collection.saveAsCassandraTable("test", "words_new", SomeColumns("word", "count"))


// Example Creating a New Table Using the Definition of another Table
import com.datastax.spark.connector.cql.{ColumnDef, RegularColumn, TableDef}
import com.datastax.spark.connector.types.IntType
case class WordCount(word: String, count: Long)
val table1 = TableDef.fromType[WordCount]("test", "words_new")
val table2 = TableDef("test", "words_new_2", table1.partitionKey, table1.clusteringColumns,
  table1.regularColumns :+ ColumnDef("additional_column", RegularColumn, IntType))
val collection = sc.parallelize(Seq(WordCount("dog", 50), WordCount("cow", 60)))
collection.saveAsCassandraTableEx(table2, SomeColumns("word", "count"))


// Example Creating a New Table Using a Completely Custom Definition
Example Creating a New Table Using a Completely Custom Definition

import com.datastax.spark.connector.cql.{ColumnDef, RegularColumn, TableDef, ClusteringColumn, PartitionKeyColumn}
import com.datastax.spark.connector.types._

// Define structure for rdd data
case class outData(col1:UUID, col2:UUID, col3: Double, col4:Int)

// Define columns
val p1Col = new ColumnDef("col1",PartitionKeyColumn,UUIDType)
val c1Col = new ColumnDef("col2",ClusteringColumn(0),UUIDType)
val c2Col = new ColumnDef("col3",ClusteringColumn(1),DoubleType)
val rCol = new ColumnDef("col4",RegularColumn,IntType)

// Create table definition
val table = TableDef("test","words",Seq(p1Col),Seq(c1Col, c2Col),Seq(rCol))

// Map rdd into custom data structure and create table
val rddOut = rdd.map(s => outData(s._1, s._2(0), s._2(1), s._3))
rddOut.saveAsCassandraTableEx(table, SomeColumns("col1", "col2", "col3", "col4"))


//have some problems.
sc.cassandraTable("test","words").select("word","count").map(s => (s.getString("word"),s.getInt("count"))).saveAsCassandraTable("test","word5",SomeColumns("word_new","count_new"))


//Example of using a new implicit Column Mapper to map a JavaBean Like Class
import com.datastax.spark.connector.mapper.JavaBeanColumnMapper
class WordCount extends Serializable { 
    private var _word: String = ""
    private var _count: Int = 0
    def setWord(word: String) { _word = word }
    def setCount(count: Int) { _count = count }
    override def toString = _word + ":" + _count
}

object WordCount {
    implicit object Mapper extends JavaBeanColumnMapper[WordCount] 
}

sc.cassandraTable[WordCount]("test", "words").toArray
// Array(bar:20, foo:10)


// Example of Using a Custom DefaultColumnMapper
case class WordCount(w: String, c: Int)

object WordCount { 
    implicit object Mapper extends DefaultColumnMapper[WordCount](
        Map("w" -> "word", "c" -> "count")) 
}

sc.cassandraTable[WordCount]("test", "words").toArray
// Array(WordCount(bar,20), WordCount(foo,10))

sc.parallelize(Seq(WordCount("baz", 30), WordCount("foobar", 40)))
  .saveToCassandra("test", "words", SomeColumns("word", "count"))


















