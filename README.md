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
SPNEGO.

ZooKage uses a shared private CA to sign service certificates. TLS clients trust
`kubernetes/base/common/config/tls/zookage-ca.crt` or the Java truststore
`kubernetes/base/common/config/tls/zookage-truststore.jks`. Both contain only
public certificates and are available in the `tls-conf` ConfigMap for any
service. Hadoop configuration ConfigMaps also include them, so existing Hadoop
clients can use `/etc/hadoop/conf/zookage-ca.crt` and
`/etc/hadoop/conf/zookage-truststore.jks`.

The CA signing key is in `docker/tls/zookage-ca.jks` and is not deployed to
Kubernetes. Each service gets its own private key and a certificate chain signed
by this CA. Run `./docker/generate-tls.sh hdfs` to reissue the HDFS certificate
using the hostnames in `docker/tls/hdfs.san`, without changing the CA or client
truststore. To issue a certificate for another service, add
`docker/tls/<service>.san` with one SAN per line, or supply SANs directly:

```sh
./docker/generate-tls.sh example 'dns:example.zookage.svc.cluster.local,dns:localhost'
```

This writes the service keystore to
`kubernetes/base/common/secret/<service>/<service>.jks` and its public certificate
to `kubernetes/base/common/config/tls/<service>.crt`. Mount the service keystore
only in its server and distribute the shared CA certificate or truststore to
clients. The sample keystore password is `zookage`.

`./docker/generate-tls-ca.sh` initializes a new CA and refuses to overwrite
existing CA files. Replacing the CA requires reissuing all service certificates
and redistributing the client trust files. The checked-in CA key, service keys,
and keytabs are sample credentials for this sandbox. Regenerate keytabs with
`./docker/generate-keytabs.sh`.
