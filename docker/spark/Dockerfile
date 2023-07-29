# syntax=docker/dockerfile:experimental
ARG spark_rm_image
ARG jdk_image

# hadolint ignore=DL3006
FROM ${spark_rm_image} AS builder

# hadolint ignore=DL3002
USER root:root
WORKDIR /root/spark
COPY . .
RUN \
  --mount=type=cache,id=zookage-cache,target=/root/.cache \
  --mount=type=cache,id=zookage-gem,target=/root/.gem \
  --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  --mount=type=cache,id=zookage-sbt,target=/root/.sbt \
  ZINC_OPTS="-Xmx4g -XX:ReservedCodeCacheSize=2g" \
  ./dev/make-distribution.sh \
    --name zookage-spark \
    --mvn /root/spark/build/mvn \
    -B \
    -Pmesos \
    -Pyarn \
    -Pkubernetes \
    -Psparkr \
    -Pscala-2.12 \
    -Phadoop-provided \
    -Phive \
    -Phive-thriftserver \
    -Pconnect

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/spark/dist /opt/spark
RUN groupadd --gid 1040 spark \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1040 --gid spark spark
USER spark:spark
