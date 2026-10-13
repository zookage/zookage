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

### Kerberos integration tests

The `auth` profile requires a locally built Hadoop image with SSSD and the native
LinuxContainerExecutor; the published `3.4.1-zookage-0.5` image does not include
these prerequisites. Configure `docker/build.env` from `docker/sample-build.env`
with your Hadoop 3.4.1 source directory, then run `./docker/build-hadoop.sh`.
Use the image tag `3.4.1-zookage-0.5-kerberos-native` and enable native libraries.
Make this image available to your Kubernetes runtime before running
`./test/integration.sh auth` (which recreates the ZooKage cluster).

For an existing auth cluster, `./test/integration.sh` detects Kerberos and obtains
the client ticket before running the normal integration checks. YARN and Hive
service keytabs are copied into private volumes at Pod initialization; restart
the affected Pods after changing those Secrets.
