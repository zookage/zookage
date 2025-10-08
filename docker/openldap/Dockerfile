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

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
  && echo 'slapd slapd/internal/adminpw password admin' | debconf-set-selections \
  && echo 'slapd slapd/internal/generated_adminpw password admin' | debconf-set-selections \
  && echo 'slapd slapd/password1 password admin' | debconf-set-selections \
  && echo 'slapd slapd/password2 password admin' | debconf-set-selections \
  && echo 'slapd slapd/domain string example.com' | debconf-set-selections \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ldap-utils slapd \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER openldap:openldap
ENTRYPOINT ["slapd", "-d", "0"]
