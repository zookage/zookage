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

Direct Spark SQL jobs use `/apps/zookage-warehouse` for new databases. Create and
select a separate database before creating tables; the metastore's `default`
database remains in the shared warehouse. The dedicated warehouse uses inherited
ACLs so `zookage`, Hive, and Trino can access files created there by each other.

These settings initialize new clusters. Existing databases retain their stored
locations, and existing clusters require migration of group membership and HDFS
permissions. Rebuild the util image with `./docker/build-util.sh` before starting
a cluster with these changes.
