# syntax=docker/dockerfile:experimental
ARG maven_image
ARG jdk_image

# hadolint ignore=DL3006
FROM ${maven_image} AS builder

ARG clean

WORKDIR /root/zookeeper
COPY . .
# hadolint ignore=DL3008,DL3015
RUN \
  apt-get update \
  && apt-get install -y \
    g++ \
    cmake \
    autoconf \
    pkg-config \
    libcppunit-dev \
    libtool \
    openssl \
    libssl-dev \
    libsasl2-modules-gssapi-mit \
    libsasl2-modules \
    libsasl2-dev \
  && rm -rf /var/lib/apt/lists/*

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn ${clean} install -DskipTests -Dmaven.javadoc.skip=true \
  && tar -zxvf \
    "./zookeeper-assembly/target/apache-zookeeper-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin.tar.gz" \
  && mv \
    "./apache-zookeeper-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin" \
    ./apache-zookeeper-bin

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/zookeeper/apache-zookeeper-bin /opt/zookeeper
RUN groupadd --gid 1050 zookeeper \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1050 --gid zookeeper zookeeper
USER zookeeper:zookeeper
