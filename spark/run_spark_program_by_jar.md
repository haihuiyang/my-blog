/Users/yanapple/dev/pkg/spark-2.0.0-bin-hadoop2.7/bin/spark-submit --class com.betalpha.ShowTimeSeriesApp --master local[4] --jars /Users/yanapple/dev/pkg/lib/spark-cassandra-connector-2.0.0-M2-s_2.11.jar --packages datastax:spark-cassandra-connector:2.0.0-M2-s_2.11,com.databricks:spark-csv_2.11:1.5.0 --conf spark.cassandra.connection.host=localhost /Users/yanapple/dev/projects/BetalphaData/SimpleScala/target/scala-2.11/simplescala_2.11-1.0.jar bar factor_exposures_by_date factorid LIQ,PBR 2013-10-13 2013-12-13




