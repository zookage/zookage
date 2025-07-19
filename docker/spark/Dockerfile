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
ARG spark_rm_image
ARG jdk_image

# hadolint ignore=DL3006
FROM ${spark_rm_image} AS builder

# hadolint ignore=DL3002
USER root:root
WORKDIR /root/spark
COPY . .
RUN \
  --mount=type=cache,id=zookage-cache,target=/root/.cache \
  --mount=type=cache,id=zookage-gem,target=/root/.gem \
  --mount=type=cache,id=zookage-m2,target=/root/.m2 \
  --mount=type=cache,id=zookage-sbt,target=/root/.sbt \
  ZINC_OPTS="-Xmx4g -XX:ReservedCodeCacheSize=2g" \
  ./dev/make-distribution.sh \
    --name zookage-spark \
    --mvn /root/spark/build/mvn \
    -B \
    -Pmesos \
    -Pyarn \
    -Pkubernetes \
    -Psparkr \
    -Pscala-2.12 \
    -Phadoop-provided \
    -Phive \
    -Phive-thriftserver \
    -Pconnect

# hadolint ignore=DL3006
FROM ${jdk_image}

COPY --from=builder /root/spark/dist /opt/spark
RUN groupadd --gid 1040 spark \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1040 --gid spark spark
USER spark:spark
