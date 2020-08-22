# syntax=docker/dockerfile:experimental
ARG tez_build_image
FROM ${tez_build_image} AS builder

WORKDIR /root/tez
COPY . .
RUN --mount=type=cache,target=/root/.m2 \
  mvn clean package \
    -Ptools \
    -Dallow.root.build \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
  && mkdir apache-tez-bin \
  && tar -C apache-tez-bin \
    -zxvf /root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-minimal.tar.gz \
  && mkdir tmp-tez-full \
  && tar -C tmp-tez-full \
    -zxvf /root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).tar.gz \
  && cp tmp-tez-full/LICENSE* apache-tez-bin/ \
  && cp tmp-tez-full/NOTICE* apache-tez-bin/ \
  && rm -rf tmp-tez-full \
  && mkdir apache-tez-bin/share \
  && cp /root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-minimal.tar.gz \
    apache-tez-bin/share/tez-minimal.tar.gz \
  && cp /root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).tar.gz \
    apache-tez-bin/share/tez.tar.gz \
  && cp apache-tez-bin/tez-ui-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).war \
    apache-tez-bin/share/tez-ui.war \
  && cp \
    /root/tez/tez-plugins/tez-aux-services/target/tez-aux-services-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).jar \
    apache-tez-bin/share/tez-aux-services.jar

FROM openjdk:8

COPY --from=builder /root/tez/apache-tez-bin /opt/tez
