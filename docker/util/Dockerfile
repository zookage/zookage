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
ARG kubectl_version=v1.35.1

# hadolint ignore=DL3006
FROM ${jdk_image}
ARG kubectl_version

# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl dnsutils ldap-utils less unzip vim \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --gid 1001 zookage \
  && useradd --create-home --uid 1001 --gid zookage zookage

RUN curl \
    --location \
    --output /usr/local/bin/kubectl \
    https://dl.k8s.io/release/${kubectl_version}/bin/linux/amd64/kubectl \
  && chmod 755 /usr/local/bin/kubectl \
  && curl \
    --output /opt/aws.zip \
    https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip \
  && unzip -d /opt /opt/aws.zip \
  && /opt/aws/install \
  && rm /opt/aws.zip \
  && rm -rf /opt/aws

COPY docker-entrypoint.sh /usr/local/bin/

USER zookage:zookage
ENTRYPOINT ["docker-entrypoint.sh"]
