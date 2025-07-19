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
ARG hadoop_three_version

WORKDIR /root/hbase
COPY . .
RUN \
  --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn -Dhadoop.profile=3.0 -Dhadoop-three.version=${hadoop_three_version} ${clean} install -DskipTests \
  && mvn -Dhadoop.profile=3.0 -Dhadoop-three.version=${hadoop_three_version} install assembly:single -DskipTests -Dcheckstyle.skip=true -Prelease \
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
FROM ${jdk_image}

COPY --from=builder /root/hbase/hbase-assembly/target/hbase /opt/hbase
COPY --from=builder /root/hbase/hbase-assembly/target/hbase-client /opt/hbase-client
RUN groupadd --gid 1060 hbase \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1060 --gid hbase hbase
USER hbase:hbase
