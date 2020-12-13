# syntax=docker/dockerfile:experimental
ARG openjdk_image

FROM ${openjdk_image}

RUN apt update \
  && apt install -y curl less netcat vim \
  && groupadd --gid 1000 hadoop \
  && groupadd --gid 1001 sandbox \
  && useradd --create-home --uid 1001 --gid sandbox sandbox \
  && groupadd --gid 1002 hdfs \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1002 --gid hdfs --groups hadoop hdfs \
  && groupadd --gid 1003 yarn \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1003 --gid yarn --groups hadoop yarn \
  && groupadd --gid 1004 mapred \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1004 --gid mapred --groups hadoop mapred \
  && groupadd --gid 1005 httpfs \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1005 --gid httpfs httpfs \
  && groupadd --gid 1006 hive \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1006 --gid hive hive \
  && groupadd --gid 1007 tez \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1007 --gid tez tez \
  && mkdir /var/log/hadoop \
  && chown root:hadoop /var/log/hadoop \
  && chmod 775 /var/log/hadoop \
  && mkdir /var/log/httpfs \
  && chown httpfs:httpfs /var/log/httpfs

RUN curl \
    --location \
    --output /usr/local/bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v1.19.2/bin/linux/amd64/kubectl \
  && chmod 755 /usr/local/bin/kubectl \
  && curl \
    --location \
    --output /opt/gohdfs-v2.1.1-linux-amd64.tar.gz \
    https://github.com/colinmarc/hdfs/releases/download/v2.1.1/gohdfs-v2.1.1-linux-amd64.tar.gz \
  && tar \
    --strip-components=1 \
    --directory=/usr/local/bin \
    -zxvf \
    /opt/gohdfs-v2.1.1-linux-amd64.tar.gz \
    gohdfs-v2.1.1-linux-amd64/hdfs \
  && mv /usr/local/bin/hdfs /usr/local/bin/gohdfs \
  && rm -rf /opt/gohdfs-v2.1.1-linux-amd64.tar.gz

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

USER sandbox
ENTRYPOINT ["entrypoint.sh"]
