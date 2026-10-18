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

## Data access

The `hadoop` group is reserved for `hdfs`, `yarn`, and `mapred`. Hive and Trino access
`/apps/hive-warehouse` through the `warehouse` group; the `zookage` user has no direct
access to that shared warehouse.

Direct Spark SQL jobs use `/user/zookage/warehouse` for new databases. The
`/user/zookage` home remains private with mode `700`; Hive and Trino do not receive
direct access. The metastore uses the client's user identity for filesystem
operations in this simple-authentication setup. Create and select a separate
database before creating tables; the metastore's `default` database remains in
the shared warehouse.

These settings initialize new clusters. Existing databases retain their stored
locations, and existing clusters require migration of group membership and HDFS
permissions.
