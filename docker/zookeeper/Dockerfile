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
