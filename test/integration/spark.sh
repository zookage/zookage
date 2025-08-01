#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu

readonly integration_dir=$(cd "$(dirname "$0")"; pwd)

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
