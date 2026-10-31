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

WORKDIR /root/hive

# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends unzip

COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} install \
    -Pdist \
    -DskipTests \
    -Dmaven.javadoc.skip=true

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mv \
    "./packaging/target/apache-hive-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin/apache-hive-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin" \
    ./packaging/target/hive

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mv \
    "./standalone-metastore/packaging/target/hive-standalone-metastore-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin/apache-hive-metastore-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin" \
    ./standalone-metastore/packaging/target/hive-metastore

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn dependency:get "-Dartifact=org.postgresql:postgresql:$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout)"

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  cp \
    "/root/.m2/repository/org/postgresql/postgresql/$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout)/postgresql-$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout).jar" \
    ./packaging/target/hive/lib

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  cp \
    "/root/.m2/repository/org/postgresql/postgresql/$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout)/postgresql-$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout).jar" \
    ./standalone-metastore/packaging/target/hive-metastore/lib

RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  unzip "./packaging/target/hive/lib/postgresql-$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout).jar" "META-INF/LICENSE" "META-INF/licenses/**/LICENSE" -d /tmp/postgresql

RUN mkdir ./packaging/target/hive/licenses/postgresql

# Keep builder steps separate; these layers are not included in the runtime image.
# hadolint ignore=DL3059
RUN mkdir ./standalone-metastore/packaging/target/hive-metastore/licenses/postgresql

# hadolint ignore=DL3059
RUN cp /tmp/postgresql/META-INF/LICENSE ./packaging/target/hive/licenses/postgresql

# hadolint ignore=DL3059
RUN cp /tmp/postgresql/META-INF/LICENSE ./standalone-metastore/packaging/target/hive-metastore/licenses/postgresql

# hadolint ignore=DL3059
RUN cp -R /tmp/postgresql/META-INF/licenses ./packaging/target/hive/licenses/postgresql

# hadolint ignore=DL3059
RUN cp -R /tmp/postgresql/META-INF/licenses ./standalone-metastore/packaging/target/hive-metastore/licenses/postgresql

# hadolint ignore=DL3006
FROM ${jdk_image} AS hive

COPY --from=builder /root/hive/packaging/target/hive /opt/hive
RUN groupadd --gid 1020 hive \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1020 --gid hive hive \
  && install -d -o hive -g hive -m 0700 /etc/secrets
USER hive:hive

# hadolint ignore=DL3006
FROM ${jdk_image} AS hive-metastore

COPY --from=builder /root/hive/standalone-metastore/packaging/target/hive-metastore /opt/hive-metastore
RUN groupadd --gid 1020 hive \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1020 --gid hive hive \
  && install -d -o hive -g hive -m 0700 /etc/secrets
USER hive:hive
