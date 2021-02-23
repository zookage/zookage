# syntax=docker/dockerfile:experimental
ARG maven_image
ARG openjdk_image

# hadolint ignore=DL3006
FROM ${maven_image} AS builder

ARG clean

WORKDIR /root/hbase
COPY . .
RUN \
  --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn ${clean} install -DskipTests \
  && mvn install assembly:single -DskipTests -Dcheckstyle.skip=true -Prelease \
  && tar -zxvf \
    "./hbase-assembly/target/hbase-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin.tar.gz" \
    --directory=./hbase-assembly/target \
  && mv \
    "./hbase-assembly/target/hbase-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)" \
    "./hbase-assembly/target/hbase" \
  && tar -zxvf \
    "./hbase-assembly/target/hbase-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-client-bin.tar.gz" \
    --directory=./hbase-assembly/target \
  && mv \
    "./hbase-assembly/target/hbase-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-client" \
    "./hbase-assembly/target/hbase-client"

# hadolint ignore=DL3006
FROM ${openjdk_image}

COPY --from=builder /root/hbase/hbase-assembly/target/hbase /opt/hbase
COPY --from=builder /root/hbase/hbase-assembly/target/hbase-client /opt/hbase-client
RUN groupadd --gid 1060 hbase \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1060 --gid hbase hbase
USER hbase:hbase
