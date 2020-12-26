# syntax=docker/dockerfile:experimental
ARG maven_image
ARG openjdk_image

# hadolint ignore=DL3006
FROM ${maven_image} AS builder

ARG clean

WORKDIR /root/ozone
COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} install -Dmaven.javadoc.skip=true -DskipTests -Pdist -Dtar \
  && mv \
    "./hadoop-ozone/dist/target/ozone-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)" \
    ./hadoop-ozone/dist/target/ozone

# hadolint ignore=DL3006
FROM ${openjdk_image}

COPY --from=builder /root/ozone/hadoop-ozone/dist/target/ozone /opt/ozone
RUN groupadd --gid 1040 ozone \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1040 --gid ozone ozone
USER ozone
