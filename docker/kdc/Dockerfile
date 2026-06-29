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
ARG ubuntu_image

# hadolint ignore=DL3006
FROM ${ubuntu_image}

ENV DEBIAN_FRONTEND=noninteractive
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends jq krb5-admin-server krb5-kdc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --gid 1090 kdc \
  && useradd --system --no-log-init --shell /sbin/nologin --uid 1090 --gid kdc kdc \
  && chown -R kdc:kdc /etc/krb5kdc /var/lib/krb5kdc

COPY --chmod=755 entrypoint.sh /usr/local/bin/kdc-entrypoint.sh

USER kdc:kdc

EXPOSE 10088/tcp 10088/udp
VOLUME ["/var/lib/krb5kdc"]
ENTRYPOINT ["kdc-entrypoint.sh"]
