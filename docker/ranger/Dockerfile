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

WORKDIR /root/ranger

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends python3 unzip

COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} install \
    -Pall \
    -DskipTests \
    -DskipJSTests \
    -Dmaven.javadoc.skip=true
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  ranger_version=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout) \
  && mkdir ./tmp \
  && find ./target -type f -name "ranger-${ranger_version}-*.tar.gz" \
    -not -name "ranger-${ranger_version}-src.tar.gz" \
    -exec tar -zxvf {} --directory=./tmp \; \
  && find ./tmp -type d -name "ranger-${ranger_version}-*" \
    -exec bash -c 'for f; do mv "$f" "${f//-$0/}"; done' "$ranger_version" {} + \
  && ln -s ./conf.dist ./tmp/ranger-admin/ews/webapp/WEB-INF/classes/conf \
  && mkdir ./zookage \
  && mv ./tmp/ranger-* ./zookage
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mkdir ./zookage/lib \
  && postgres_version=42.7.8 \
  && mvn dependency:get "-Dartifact=org.postgresql:postgresql:$postgres_version" \
  && cp \
    "/root/.m2/repository/org/postgresql/postgresql/$postgres_version/postgresql-$postgres_version.jar" \
    ./zookage/lib/postgresql.jar \
  && unzip ./zookage/lib/postgresql.jar "META-INF/LICENSE" "META-INF/licenses/**/LICENSE" -d /tmp/postgresql \
  && mkdir -p ./zookage/licenses/postgresql \
  && cp /tmp/postgresql/META-INF/LICENSE ./zookage/licenses/postgresql \
  && cp -R /tmp/postgresql/META-INF/licenses ./zookage/licenses/postgresql

# hadolint ignore=DL3006
FROM ${jdk_image}

# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=builder /root/ranger/zookage /opt/ranger
RUN groupadd --gid 1100 ranger \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1100 --gid ranger ranger
USER ranger:ranger
