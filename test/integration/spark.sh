#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

readonly spark_version=$1
echo "Spark version = ${spark_version}"
"${integration_dir}/divider.sh" "Start running a Spark job"

"${integration_dir}/run.sh" gohdfs rm -rf /user/zookage/spark-wordcount-input
"${integration_dir}/run.sh" gohdfs put /etc/hosts /user/zookage/spark-wordcount-input
"${integration_dir}/run.sh" bash -c "
  spark-submit \
  --class org.apache.spark.examples.JavaWordCount \
  "/opt/spark/examples/jars/spark-examples_2.12-*.jar" \
  /user/zookage/spark-wordcount-input
"
"${integration_dir}/divider.sh" "Finished running a Spark job"
echo "The test job succeeded."
echo

"${integration_dir}/spark_log.sh"
