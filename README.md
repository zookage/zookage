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

## Spark History Server in the auth profile

The auth profile protects the Spark History Server with Spark's `JWSFilter`.
Requests need an HS256 JWT in an `Authorization: Bearer` header. The development
signing key is in `kubernetes/base/common/secret/spark/spark-jws.key`; the Web
integration test shows how to sign a short-lived token and call the server.

`JWSFilter` does not provide a browser login or identify users for Spark's
per-application ACLs. Anyone holding a valid token can view all history. This
repository's key and the HTTP endpoint are intended for the local sandbox;
use a private signing key and TLS before exposing the service elsewhere.
