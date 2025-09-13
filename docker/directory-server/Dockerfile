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

WORKDIR /root/directory-server

COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} install \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
    -Pinstallers \
  && mv \
    "./installers/target/installers/apacheds-archive-tar.gz/apacheds-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)" \
    ./installers/target/installers/directory-server

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/directory-server/installers/target/installers/directory-server /opt/directory-server
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends ldap-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --gid 1090 directory-server \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1090 --gid directory-server directory-server
USER directory-server:directory-server
