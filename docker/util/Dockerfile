# syntax=docker/dockerfile:experimental
ARG openjdk_image

# hadolint ignore=DL3006
FROM ${openjdk_image}

# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl dnsutils less netcat vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --gid 1000 zookage \
  && useradd --create-home --uid 1000 --gid zookage zookage

RUN curl \
    --location \
    --output /usr/local/bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v1.19.3/bin/linux/amd64/kubectl \
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

COPY docker-entrypoint.sh /usr/local/bin/

USER zookage:zookage
ENTRYPOINT ["docker-entrypoint.sh"]
