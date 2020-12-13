# syntax=docker/dockerfile:experimental
ARG hadoop_build_image
ARG openjdk_image

FROM ${hadoop_build_image} AS builder

ARG clean
ARG active_profiles

# YARN-UI v2 build requires a non-root user.
RUN groupadd --gid 999 hadoop-build \
  && useradd --create-home --uid 999 --gid hadoop-build hadoop-build

USER hadoop-build:hadoop-build
WORKDIR /home/hadoop-build/hadoop

COPY --chown=hadoop-build:hadoop-build . .
RUN --mount=type=cache,target=/home/hadoop-build/.m2,uid=999,gid=999 \
  mvn ${clean} package \
    -P${active_profiles} \
    -DskipTests \
    -Dtar \
    -Dmaven.javadoc.skip=true \
  && mv \
    ./hadoop-dist/target/hadoop-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout) \
    ./hadoop-dist/target/hadoop

FROM ${openjdk_image}

COPY --chown=root:root --from=builder /home/hadoop-build/hadoop/hadoop-dist/target/hadoop /opt/hadoop
