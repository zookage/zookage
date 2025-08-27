# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# syntax=docker/dockerfile:experimental
ARG hadoop_build_image
ARG jdk_11_image
ARG jdk_17_image
ARG jdk_21_image
ARG ubuntu_image

# hadolint ignore=DL3006
FROM ${jdk_11_image} AS jdk_11
# hadolint ignore=DL3006
FROM ${jdk_17_image} AS jdk_17
# hadolint ignore=DL3006
FROM ${jdk_21_image} AS jdk_21

# hadolint ignore=DL3006
FROM ${hadoop_build_image} AS builder

ARG clean
ARG active_profiles

# YARN-UI v2 build requires a non-root user.
RUN groupadd --gid 999 hadoop-build \
  && useradd --create-home --uid 999 --gid hadoop-build hadoop-build

USER hadoop-build:hadoop-build
WORKDIR /home/hadoop-build/hadoop

COPY --chown=hadoop-build:hadoop-build . .
RUN \
  --mount=type=cache,target=/home/hadoop-build/.cache,uid=999,gid=999 \
  --mount=type=cache,target=/home/hadoop-build/.config,uid=999,gid=999 \
  --mount=type=cache,target=/home/hadoop-build/.local,uid=999,gid=999 \
  --mount=type=cache,target=/home/hadoop-build/.m2,uid=999,gid=999 \
  mvn ${clean} package \
    -P${active_profiles} \
    -DskipTests \
    -Dtar \
    -Dmaven.javadoc.skip=true \
  && mv \
    "./hadoop-dist/target/hadoop-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)" \
    ./hadoop-dist/target/hadoop

# hadolint ignore=DL3006
FROM ${ubuntu_image}

COPY --from=jdk_11 /opt/java/openjdk /opt/java/jdk11
COPY --from=jdk_17 /opt/java/openjdk /opt/java/jdk17
COPY --from=jdk_21 /opt/java/openjdk /opt/java/jdk21
ENV JAVA_HOME=/opt/java/jdk11

COPY --chown=root:root --from=builder /home/hadoop-build/hadoop/hadoop-dist/target/hadoop /opt/hadoop
RUN groupadd --gid 1010 hadoop \
  && groupadd --gid 1011 hdfs \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1011 --gid hdfs --groups hadoop hdfs \
  && groupadd --gid 1012 yarn \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1012 --gid yarn --groups hadoop yarn \
  && groupadd --gid 1013 mapred \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1013 --gid mapred --groups hadoop mapred \
  && groupadd --gid 1014 httpfs \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1014 --gid httpfs httpfs
