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

WORKDIR /root/ozone
COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} package -DskipTests=true \
  && mv \
    "./hadoop-ozone/dist/target/ozone-$(mvn help:evaluate -Dexpression=ozone.version -q -DforceStdout)" \
    ./hadoop-ozone/dist/target/ozone

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/ozone/hadoop-ozone/dist/target/ozone /opt/ozone
RUN groupadd --gid 1070 ozone \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1070 --gid ozone ozone
USER ozone:ozone
