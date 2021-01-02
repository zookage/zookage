#!/bin/bash
set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

"${integration_dir}/divider.sh" "Start running a MR job"

"${integration_dir}/run.sh" gohdfs rm -rf /user/zookage/mr-wordcount-input
"${integration_dir}/run.sh" gohdfs rm -rf /user/zookage/mr-wordcount-output
"${integration_dir}/run.sh" gohdfs put /etc/hosts /user/zookage/mr-wordcount-input

"${integration_dir}/run.sh" bash -c "
  hadoop \
  jar \
  /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-*.jar \
  wordcount \
  /user/zookage/mr-wordcount-input \
  /user/zookage/mr-wordcount-output
"
"${integration_dir}/run.sh" gohdfs cat /user/zookage/mr-wordcount-output/part-r-00000

"${integration_dir}/divider.sh" "Finished running a MR job"
echo "The test job succeeded."
echo

"${integration_dir}/mr_log.sh"
