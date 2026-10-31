/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.zookage.console.web;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.api.model.PodBuilder;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class PodServiceTest {
  @Test
  void showsPodList() {
    Pod pod =
        new PodBuilder()
            .withNewMetadata()
            .withName("client-node-0")
            .withCreationTimestamp("2026-10-31T00:00:00Z")
            .endMetadata()
            .withNewSpec()
            .addNewContainer()
            .withName("client-node")
            .endContainer()
            .endSpec()
            .withNewStatus()
            .withPhase("Running")
            .addNewContainerStatus()
            .withName("client-node")
            .withReady(true)
            .withRestartCount(2)
            .endContainerStatus()
            .endStatus()
            .build();

    String output =
        PodService.format(List.of(pod), "zookage", Instant.parse("2026-10-31T01:00:00Z"));

    assertTrue(output.startsWith("NAME"));
    assertTrue(output.contains("client-node-0  1/1    Running"));
    assertTrue(output.contains("2         1h"));
  }

  @Test
  void showsEmptyNamespaceMessage() {
    assertEquals(
        "No resources found in zookage namespace.\n",
        PodService.format(List.of(), "zookage", Instant.EPOCH));
  }
}
