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

### Client tools

`client-node` always includes Hadoop and the tools in `zookage-util`.
Enable additional client distributions with `patches/client/<component>.yaml`
entries in the `patches` section of `kubernetes/kustomization.yaml`, independently
of the server `resources`. The default configuration enables Hive and Tez clients.
For example, uncomment `patches/client/trino.yaml` to make the Trino CLI available
in `./bin/ssh`.

Each enabled client pulls its component's image on the client node. Selecting
only the clients you use reduces the downloads required before the client starts.
The `all`, `auth`, and `ha` test profiles enable every client; the LLAP profiles
enable Hive, Ozone, Tez, and ZooKeeper, including Ozone for the S3 tests.
