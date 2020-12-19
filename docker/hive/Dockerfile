# syntax=docker/dockerfile:experimental
ARG maven_image
ARG openjdk_image

# hadolint ignore=DL3006
FROM ${maven_image} AS builder

ARG clean

WORKDIR /root/hive
COPY . .
RUN --mount=type=cache,id=hadoop-sandbox-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} install \
    -Pdist \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
  && mv \
    "./packaging/target/apache-hive-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin/apache-hive-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin" \
    ./packaging/target/hive

# hadolint ignore=DL3006
FROM ${openjdk_image}

COPY --from=builder /root/hive/packaging/target/hive /opt/hive
