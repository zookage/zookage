# syntax=docker/dockerfile:experimental
ARG maven_image
ARG jdk_image

# hadolint ignore=DL3006
FROM ${maven_image} AS builder

ARG clean

WORKDIR /root/hive
COPY . .
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --threads 1C ${clean} install \
    -Pdist,iceberg \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
  && mv \
    "./packaging/target/apache-hive-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin/apache-hive-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-bin" \
    ./packaging/target/hive \
  && mvn dependency:get "-Dartifact=org.postgresql:postgresql:$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout)" \
  && cp \
    "/root/.m2/repository/org/postgresql/postgresql/$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout)/postgresql-$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout).jar" \
    ./packaging/target/hive/lib \
  && unzip "./packaging/target/hive/lib/postgresql-$(mvn help:evaluate -Dexpression=postgres.version -q -DforceStdout).jar" "META-INF/LICENSE" "META-INF/licenses/**/LICENSE" -d /tmp/postgresql \
  && mkdir ./packaging/target/hive/licenses/postgresql \
  && mv /tmp/postgresql/META-INF/LICENSE ./packaging/target/hive/licenses/postgresql \
  && mv /tmp/postgresql/META-INF/licenses ./packaging/target/hive/licenses/postgresql

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/hive/packaging/target/hive /opt/hive
RUN groupadd --gid 1020 hive \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1020 --gid hive hive
USER hive:hive
