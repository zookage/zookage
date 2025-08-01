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
ARG tez_build_image
ARG jdk_image

# hadolint ignore=DL3006
FROM ${tez_build_image} AS builder

ARG clean

WORKDIR /root/tez
COPY . .
RUN \
  --mount=type=cache,target=/root/.cache/bower \
  --mount=type=cache,target=/root/.cache/yarn \
  --mount=type=cache,target=/root/.config \
  --mount=type=cache,target=/root/.local \
  --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn ${clean} package \
    -Ptools \
    -Dallow.root.build \
    -DskipTests \
    -Dmaven.javadoc.skip=true \
  && mkdir apache-tez-bin \
  && tar -C apache-tez-bin \
    -zxvf "/root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-minimal.tar.gz" \
  && mkdir tmp-tez-full \
  && tar -C tmp-tez-full \
    -zxvf "/root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).tar.gz" \
  && cp tmp-tez-full/LICENSE* apache-tez-bin/ \
  && cp tmp-tez-full/NOTICE* apache-tez-bin/ \
  && rm -rf tmp-tez-full \
  && mkdir apache-tez-bin/share \
  && cp "/root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)-minimal.tar.gz" \
    apache-tez-bin/share/tez-minimal.tar.gz \
  && cp "/root/tez/tez-dist/target/tez-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).tar.gz" \
    apache-tez-bin/share/tez.tar.gz \
  && cp "tez-ui/target/tez-ui-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).war" \
    apache-tez-bin/share/tez-ui.war \
  && cp \
    "/root/tez/tez-plugins/tez-aux-services/target/tez-aux-services-$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout).jar" \
    apache-tez-bin/share/tez-aux-services.jar

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/tez/apache-tez-bin /opt/tez
RUN groupadd --gid 1030 tez \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1030 --gid tez tez
USER tez:tez
