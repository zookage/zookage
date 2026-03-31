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
ARG maven_image

# hadolint ignore=DL3006
FROM ${maven_image} AS builder

WORKDIR /root/console
COPY console/pom.xml ./pom.xml
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --batch-mode dependency:go-offline

COPY console/src ./src
RUN --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  mvn --batch-mode -DskipTests package

# hadolint ignore=DL3006
FROM ${jdk_image}

RUN groupadd --gid 1001 zookage \
  && useradd --create-home --uid 1001 --gid zookage zookage

COPY --from=builder /root/console/target/quarkus-app /opt/zookage-console/quarkus-app

USER zookage:zookage
ENTRYPOINT ["java", "-jar", "/opt/zookage-console/quarkus-app/quarkus-run.jar"]
