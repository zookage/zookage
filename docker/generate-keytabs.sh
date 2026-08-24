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

readonly base_dir=$(cd "$(dirname "$0")"; pwd)
readonly repo_dir=$(cd "${base_dir}/.."; pwd)
readonly secret_dir="${repo_dir}/kubernetes/base/common/secret"
readonly principals_file="${repo_dir}/kubernetes/base/common/config/openldap/bootstrap.ldif"

keytab_principals() {
  local dn_pattern=$1

  awk -v dn_pattern="${dn_pattern}" '
    function emit() {
      if (dn ~ dn_pattern && principal != "" && password != "") {
        print principal "\t" password
      }
    }

    /^dn: / {
      emit()
      dn = $0
      sub(/^dn: /, "", dn)
      principal = ""
      password = ""
      next
    }
    /^userPassword: / {
      password = $0
      sub(/^userPassword: /, "", password)
      next
    }
    /^krbPrincipalName: / {
      principal = $0
      sub(/^krbPrincipalName: /, "", principal)
      next
    }
    END {
      emit()
    }
  ' "${principals_file}"
}

generate_keytab() {
  local keytab_file=$1
  local dn_pattern=$2

  rm -f "${keytab_file}"
  while IFS=$'\t' read -r principal password; do
    ktutil -k "${keytab_file}" add \
      -p "${principal}" \
      -w "${password}" \
      -e aes256-cts-hmac-sha1-96 \
      -V 1
  done < <(keytab_principals "${dn_pattern}")
}

generate_tls_stores() {
  local hdfs_secret_dir="${secret_dir}/hdfs"
  local keystore_file="${hdfs_secret_dir}/hdfs-keystore.jks"
  local truststore_file="${hdfs_secret_dir}/hdfs-truststore.jks"
  local certificate_file
  certificate_file=$(mktemp)
  trap 'rm -f "${certificate_file}"' RETURN

  rm -f "${keystore_file}" "${truststore_file}"
  keytool -genkeypair -noprompt \
    -alias hdfs \
    -dname "CN=hdfs.zookage.svc.cluster.local, OU=Zookage, O=Zookage, L=Tokyo, C=JP" \
    -ext "SAN=DNS:hdfs-namenode-0.hdfs-namenode,DNS:hdfs-namenode-0.hdfs-namenode.zookage.svc.cluster.local,DNS:hdfs-namenode-1.hdfs-namenode,DNS:hdfs-namenode-1.hdfs-namenode.zookage.svc.cluster.local,DNS:hdfs-datanode-0.hdfs-datanode.zookage.svc.cluster.local,DNS:hdfs-datanode-1.hdfs-datanode.zookage.svc.cluster.local,DNS:hdfs-datanode-2.hdfs-datanode.zookage.svc.cluster.local,DNS:hdfs-journalnode-0.hdfs-journalnode.zookage.svc.cluster.local,DNS:hdfs-journalnode-1.hdfs-journalnode.zookage.svc.cluster.local,DNS:hdfs-journalnode-2.hdfs-journalnode.zookage.svc.cluster.local" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 3650 \
    -keystore "${keystore_file}" \
    -storetype JKS \
    -storepass zookage \
    -keypass zookage
  keytool -exportcert -noprompt \
    -alias hdfs \
    -keystore "${keystore_file}" \
    -storepass zookage \
    -file "${certificate_file}"
  keytool -importcert -noprompt \
    -alias hdfs \
    -keystore "${truststore_file}" \
    -storetype JKS \
    -storepass zookage \
    -file "${certificate_file}"
}

generate_service_keytabs() {
  generate_keytab \
    "${secret_dir}/yarn/yarn.keytab" \
    '^uid=.*ou=yarn,ou=kerberos,dc=example,dc=com$'
  generate_keytab \
    "${secret_dir}/mapreduce/mapreduce.keytab" \
    '^uid=.*ou=mapreduce,ou=kerberos,dc=example,dc=com$'
  generate_keytab \
    "${secret_dir}/spark/spark.keytab" \
    '^uid=.*ou=spark,ou=kerberos,dc=example,dc=com$'
  generate_keytab \
    "${secret_dir}/hbase/hbase.keytab" \
    '^uid=.*ou=hbase,ou=kerberos,dc=example,dc=com$'
  generate_keytab \
    "${secret_dir}/hive/hive.keytab" \
    '^uid=.*ou=hive,ou=kerberos,dc=example,dc=com$'
  generate_keytab \
    "${secret_dir}/trino/trino.keytab" \
    '^uid=.*ou=trino,ou=kerberos,dc=example,dc=com$'
  generate_keytab \
    "${secret_dir}/tez/tez.keytab" \
    '^uid=.*ou=tez,ou=kerberos,dc=example,dc=com$'
}

case "${1:-all}" in
  all|keytabs)
    generate_keytab \
      "${secret_dir}/client/client.keytab" \
      '^uid=zookage,ou=users,dc=example,dc=com$'
    generate_keytab \
      "${secret_dir}/hdfs/hdfs.keytab" \
      '(^uid=hdfs,ou=users,dc=example,dc=com$|^uid=.*ou=hdfs,ou=kerberos,dc=example,dc=com$)'
    generate_keytab \
      "${secret_dir}/ranger/ranger.keytab" \
      '^uid=.*ou=ranger,ou=kerberos,dc=example,dc=com$'
    generate_service_keytabs
    ;;
  services)
    generate_service_keytabs
    ;;
  tls)
    ;;
  *)
    echo "Usage: $0 [all|keytabs|services|tls]" >&2
    exit 2
    ;;
esac

if [[ "${1:-all}" == all || ${1:-all} == tls ]]; then
  generate_tls_stores
fi
