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

## ZooKeeper authentication

The `auth` Kubernetes profile requires Kerberos and a client certificate on the
ZooKeeper client port (2181). ZooKeeper peers authenticate with Kerberos. Its
AdminServer on port 8080 uses HTTPS with a client certificate for its
`/commands` management endpoint. The ZooKeeper CLI and HBase clients are
configured for the authenticated client port in this profile.

To access AdminServer in a browser, import
`kubernetes/base/common/secret/zookeeper-client/zookeeper-client.p12` with
password `zookage`, trust `kubernetes/base/common/config/tls/zookage-ca.crt`,
and make `zookeeper-server.zookage.svc.cluster.local` resolve to `127.0.0.1`
on your workstation. Then run
`./bin/kubectl port-forward svc/zookeeper-server 8080:8080` and open
`https://zookeeper-server.zookage.svc.cluster.local:8080/commands`.
