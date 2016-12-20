###*[Launching Applications with spark-submit](https://spark.apache.org/docs/1.4.1/submitting-applications.html)*

```scala
./bin/spark-submit \
  --class <main-class>
  --master <master-url> \
  --deploy-mode <deploy-mode> \
  --conf <key>=<value> \
  ... # other options
  <application-jar> \
  [application-arguments]
```

Some of the commonly used options are:

- --class: The entry point for your application (e.g. org.apache.spark.examples.SparkPi)
- --master: The [master URL](https://spark.apache.org/docs/1.4.1/submitting-applications.html#master-urls) for the cluster (e.g. spark://23.195.26.187:7077)
- --deploy-mode: Whether to deploy your driver on the worker nodes (cluster) or locally as an external client (client) (default: client) †
- --conf: Arbitrary Spark configuration property in key=value format. For values that contain spaces wrap “key=value” in quotes (as shown).
- application-jar: Path to a bundled jar including your application and all dependencies. The URL must be globally visible inside of your cluster, for instance, an hdfs:// path or a file:// path that is present on all nodes.
- application-arguments: Arguments passed to the main method of your main class, if any