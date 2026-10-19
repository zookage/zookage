# ZooKage

ZooKage helps you run big data animals in a sandbox environment.

## Supported components

You can launch the following components on Kubernetes on Docker Desktop with a single command.

* Apache Hadoop(HDFS, YARN, MapReduce)
* Apache HBase
* Apache Hive
* Apache Ozone
* Apache Spark
* Apache Tez
* Apache ZooKeeper
* Trino

## How to use

See the [document](https://zookage.org/) and [Quick Start](https://zookage.org/docs/quick-start).

The `auth` integration profile enables Kerberos for HDFS, including HTTPFS,
block transfer authentication, and delegation tokens. Run `./test/integration.sh auth`
to recreate the sandbox with this profile and test it. DataNodes remain non-root
and use SASL with HTTPS. The NameNode web endpoint uses HTTPS on port 9871 and
SPNEGO; the development certificate is
`kubernetes/base/common/config/hdfs/hdfs-ca.crt`. The checked-in keytabs and TLS
key are sample credentials for this sandbox. Regenerate them with
`./docker/generate-keytabs.sh` and `./docker/generate-hdfs-tls.sh` respectively.
