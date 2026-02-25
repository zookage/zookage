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
ARG native_option
ARG TARGETARCH

WORKDIR /root/ozone
COPY . .
# hadolint ignore=DL3008,DL3015
RUN \
  apt-get update \
  && apt-get install -y cmake g++ patch \
  && rm -rf /var/lib/apt/lists/*

# hadolint ignore=DL3003,DL3008,DL3015
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  if [ "$TARGETARCH" = "arm64" ]; then \
    apt-get update \
    && apt-get install -y autoconf libtool \
    && cd /tmp \
    && wget --quiet https://github.com/google/protobuf/releases/download/v2.5.0/protobuf-2.5.0.tar.gz \
    && wget --quiet https://raw.githubusercontent.com/apache/bigtop/refs/tags/rel/3.5.0/bigtop_toolchain/files/0001-Backport-atomic-operations-with-support-of-arm64-and.patch \
    && tar -xvzf protobuf-2.5.0.tar.gz \
    && cd /tmp/protobuf-2.5.0 \
    && patch -p1 < /tmp/0001-Backport-atomic-operations-with-support-of-arm64-and.patch \
    && ./autogen.sh \
    && ./configure --prefix=/usr/local/protobuf-2.5.0 --disable-shared --with-pic \
    && make install \
    && mv /usr/local/protobuf-2.5.0/bin/protoc /usr/local/protobuf-2.5.0/bin/protoc.exe \
    && mvn install:install-file \
      -DgroupId=com.google.protobuf \
      -DartifactId=protoc \
      -Dversion=2.5.0 \
      -Dclassifier=linux-aarch_64 \
      -Dpackaging=exe \
      -Dfile=/usr/local/protobuf-2.5.0/bin/protoc.exe \
    && rm -rf /var/lib/apt/lists/* \
    && cd /root/ozone; \
  fi \
  && mvn --threads 1C ${clean} install ${native_option} \
    -Dmaven.javadoc.skip=true \
    -DskipTests=true \
  && mv \
    "./hadoop-ozone/dist/target/ozone-$(mvn help:evaluate -Dexpression=ozone.version -q -DforceStdout)" \
    ./hadoop-ozone/dist/target/ozone

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/ozone/hadoop-ozone/dist/target/ozone /opt/ozone
RUN groupadd --gid 1070 ozone \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1070 --gid ozone ozone
USER ozone:ozone
