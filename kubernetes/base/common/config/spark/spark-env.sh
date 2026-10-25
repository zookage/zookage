#!/usr/bin/env bash
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


SPARK_DIST_CLASSPATH=$("${HADOOP_HOME}/bin/hadoop" classpath)
export SPARK_DIST_CLASSPATH

if grep -Fxq 'spark.ui.filters org.apache.spark.ui.JWSFilter' "${SPARK_CONF_DIR}/spark-defaults.conf" &&
   ! grep -Fq 'spark.org.apache.spark.ui.JWSFilter.param.secretKey ' "${SPARK_CONF_DIR}/spark-defaults.conf"; then
  if [[ -z ${SPARK_JWS_SECRET_KEY:-} ]]; then
    echo "Spark JWS signing key is not set" >&2
    exit 1
  fi
  spark_jws_conf_dir=/dev/shm/zookage-spark-conf
  if [[ ! -d "${spark_jws_conf_dir}" ]]; then
    spark_jws_new_dir=$(mktemp -d /dev/shm/zookage-spark-conf.XXXXXXXX) || exit 1
    cp -LR "${SPARK_CONF_DIR}/." "${spark_jws_new_dir}/" || exit 1
    chmod 0600 "${spark_jws_new_dir}/spark-defaults.conf" || exit 1
    printf '\nspark.org.apache.spark.ui.JWSFilter.param.secretKey %s\n' "${SPARK_JWS_SECRET_KEY}" >> "${spark_jws_new_dir}/spark-defaults.conf" || exit 1
    mv -T "${spark_jws_new_dir}" "${spark_jws_conf_dir}" 2>/dev/null || rm -rf "${spark_jws_new_dir}"
  fi
  [[ -r "${spark_jws_conf_dir}/spark-defaults.conf" ]] || exit 1
  export SPARK_CONF_DIR="${spark_jws_conf_dir}"
fi
unset SPARK_JWS_SECRET_KEY
