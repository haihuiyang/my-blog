dataFrame.withColumn("rate_of_return", ((last(dataFrame("close_price")).over(wSpec).divide(first(dataFrame("close_price")).over(wSpec)-1).multiply(last(dataFrame("weight")).over(wSpec))))).show(20)


val wSpec = Window.partitionBy("stock_code").orderBy("trading_date").rowsBetween(-1, 0)

dataFrame.withColumn("rate_of_return", calculateReturn(last(dataFrame("close_price")).over(wSpec), first(dataFrame("close_price")).over(wSpec), last(dataFrame("weight")).over(wSpec))).show(20)

dataFrame.createOrReplaceTempView("rate_of_return")
import session._
sql()


  def calculateReturn(close_price: Column, pre_close_price: Column, weight: Column): Column = {
    val return1 = close_price.divide(pre_close_price) - 1
    val val1 = return1.multiply(weight)
    val1
  }
  
  
scala> val buf = scala.collection.mutable.ArrayBuffer.empty[Int]
buf: scala.collection.mutable.ArrayBuffer[Int] = ArrayBuffer()

scala> val map = scala.collection.mutable.HashMap.empty[Int,String]
map: scala.collection.mutable.HashMap[Int,String] = Map()

