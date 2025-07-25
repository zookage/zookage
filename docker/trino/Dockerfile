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
ARG jdk_image

# hadolint ignore=DL3006
FROM ${jdk_image} AS builder

ARG clean

WORKDIR /root/trino
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends git

COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  ./mvnw ${clean} install \
    -pl '!:trino-docs,!:trino-server-rpm' \
    -DskipTests \
  && mv \
    "./client/trino-cli/target/trino-cli-$(./mvnw --quiet help:evaluate -Dexpression=project.version -DforceStdout)-executable.jar" \
    "./client/trino-cli/target/trino-cli-executable.jar" \
  && mv \
    "./core/trino-server/target/trino-server-$(./mvnw --quiet help:evaluate -Dexpression=project.version -DforceStdout)" \
    "./core/trino-server/target/trino-server"

# hadolint ignore=DL3006
FROM ${jdk_image}

# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && groupadd --gid 1080 trino \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1080 --gid trino trino

COPY --from=builder --chmod=755 /root/trino/client/trino-cli/target/trino-cli-executable.jar /opt/trino/trino-cli/bin/trino
COPY --from=builder /root/trino/core/trino-server/target/trino-server /opt/trino/trino-server

USER trino:trino
