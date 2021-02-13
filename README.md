# ZooKage

ZooKage provides a sandbox environment to launch a set of components inhabiting the Hadoop ecosystem on top of Kubernetes.

## Supported components

* Apache Hadoop(HDFS, YARN, MapReduce)
* Apache Hive
* Apache Spark
* Apache Tez
* Apache ZooKeeper

## Requirements

* macOS is supported
* [Docker Desktop](https://www.docker.com/products/docker-desktop)
* [Enough RAM](https://docs.docker.com/docker-for-mac/)
    * e.g. 8GB for HDFS, YARN, Hive, and Tez
* [Kubernetes is enabled](https://docs.docker.com/get-started/orchestration/)

## Getting Started

### Launch a Hadoop cluster

Just run the following command.

```
$ git clone --branch v0.2.0 git@github.com:zookage/zookage.git
$ cd zookage
$ ./bin/up
namespace/zookage created
job.batch/package-hadoop created
job.batch/package-hive created
job.batch/package-tez created
...
All resources are ready!
```

### Log in to a client container

With `./bin/ssh`, you can ssh into `client-node`, which has command-line tools such as `hdfs`, `yarn`, `beeline`, and so on.

```
$ ./bin/ssh
zookage@client-node-0:~$
```

### Submit a job

On the container, you can run any commands.

```
zookage@client-node-0:~$ beeline
...
0: jdbc:hive2://hive-hiveserver2:10000/defaul> SELECT 1;
...
+------+
| _c0  |
+------+
| 1    |
+------+
1 row selected (6.432 seconds)
```

## Configuration

### Components and versions

Changing [kustomization.yaml](https://github.com/zookage/zookage/blob/main/kubernetes/kustomization.yaml), you can include/exclude any components in `bases` and specify their versions in `images`.

You should also check [Compatibility](https://github.com/zookage/zookage#compatibility) and pick up a valid combination.

### Configuration files

Configuration files such as `hdfs-site.xml` are located in [./config](https://github.com/zookage/zookage/tree/main/kubernetes/base/common/config).

## Helper commands

Several utilities are available.

* `./bin/up`
    * Launch components
* `./bin/down`
    * Delete resources created by ZooKage
* `./bin/ssh`
    * Log in to the given pod
    * Without any arguments, you will ssh into `client-node`
* `./bin/logs`
    * View logs of the given pod
    * Without any arguments, you can fetch all logs of all containers
* `./bin/kubectl`
    * Alias of `kubectl --namespace zookage`

## Web UI

You can access web UIs via `localhost`. Note that this feature is unstable and you may sometimes have to restart a Kubernetes cluster to recover access.

* [HDFS](http://localhost:9870/)
* [YARN ResourceManager](http://localhost:8088/cluster)
* [YARN-UI V2](http://localhost:8088/ui2/)
* [YARN Timeline Server](http://localhost:8188/applicationhistory)
* [MapReduce History Server](http://localhost:19888/jobhistory)
* [Spark History Server](http://localhost:18080/)
* [Tez UI](http://localhost:9999/tez-ui/)
* [HiveServer2](http://localhost:10002/)

## Build your image

### Configure locations of your repositories

You have to put `./docker/build.env` and configure paths where your repositories exist before building a Docker image.

You can refer to [sample-build.env](https://github.com/zookage/zookage/blob/main/docker/sample-build.env).

### Build a Docker image

`./docker/build-{component name}.sh` are the scripts to build a ZooKage compatible Docker image.

### Update kustomization.yaml

Please put the image tag in [kustomization.yaml](https://github.com/zookage/zookage/blob/main/kubernetes/kustomization.yaml) and run `./bin/up`.

## Compatibility

ZooKage provides the following images. Every image has the postfix `-zookage-0.2`, e.g. `3.2.2-zookage-0.2`.

| Hadoop | Hive | Tez | Spark | ZooKeeper |
|-|-|-|-|-|
| 2.10.1 | 2.3.8 | 0.9.2 | 3.0.1 | 3.6.2 |
| 3.1.4 | 3.1.2-guava-27.0-jre | 0.9.2-guava-27.0-jre-jersey-1.19-servlet-api-3.1.0-without-jetty | 3.0.1 | 3.6.2 |
| 3.2.2 | 3.1.2-guava-27.0-jre | 0.9.2-guava-27.0-jre-jersey-1.19-servlet-api-3.1.0-without-jetty | 3.0.1 | 3.6.2 |

## Tips

### Check containers' status

You can list all containers' status with `./bin/kubectl get pods`.

```
$ ./bin/kubectl get pods
NAME                                READY   STATUS      RESTARTS   AGE
hdfs-datanode-0                     1/1     Running     0          7m19s
hdfs-datanode-1                     1/1     Running     0          7m19s
hdfs-datanode-2                     1/1     Running     0          7m19s
...
```

### Attach a remote debugger to a container

`./bin/kubectl port-forward {pod name} {local port}:{container port}` enables a local process to connect to a container.

For example, you can access port 8000 on `client-node-0` via port 5005 on your local machine.

```
$ ./bin/kubectl port-forward client-node-0 5005:8000
Forwarding from 127.0.0.1:5005 -> 8000
Forwarding from [::1]:5005 -> 8000
```

### HA Setup

You can apply HA configurations with a few changes.

Note that this feature is NOT designed to deploy a production-ready cluster. This is for a developer who wants to test HA features on a local machine.

First, enable `patches/ha/{component}.yaml` in [kustomization.yaml](https://github.com/zookage/zookage/blob/main/kubernetes/kustomization.yaml).

```
patchesStrategicMerge:
### High Availability ###
- patches/ha/hdfs.yaml
- patches/ha/yarn.yaml
```

Second, edit the configuration files for components which need HA setup.

You should comment out non-HA configurations and introduce HA configurations.

```
<configuration>
  <!-- ### For non-HA ###
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>yarn-resourcemanager-0.yarn-resourcemanager</value>
  </property>
  ### For non-HA ### -->

  <!-- ### For HA ### -->
  <property>
    <name>yarn.resourcemanager.ha.enabled</name>
    <value>true</value>
  </property>
  ...
  <property>
    <name>yarn.resourcemanager.webapp.address.resourcemanager-1</name>
    <value>yarn-resourcemanager-1.yarn-resourcemanager:8088</value>
  </property>
  <!-- ### For HA ### -->
```
