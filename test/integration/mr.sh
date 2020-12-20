#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

readonly hadoop_version=$1
echo "Hadoop version = ${hadoop_version}"
"${integration_dir}/divider.sh" "Start running a MR job"

"${integration_dir}/run.sh" gohdfs rm -rf /user/sandbox/mr-wordcount-input
"${integration_dir}/run.sh" gohdfs rm -rf /user/sandbox/mr-wordcount-output
"${integration_dir}/run.sh" gohdfs put /etc/hosts /user/sandbox/mr-wordcount-input

"${integration_dir}/run.sh" \
  hadoop \
  jar \
  "/opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-${hadoop_version}.jar" \
  wordcount \
  /user/sandbox/mr-wordcount-input \
  /user/sandbox/mr-wordcount-output
"${integration_dir}/run.sh" gohdfs cat /user/sandbox/mr-wordcount-output/part-r-00000

"${integration_dir}/divider.sh" "Finished running a MR job"
echo "The test job succeeded."
echo

"${integration_dir}/mr_log.sh"
