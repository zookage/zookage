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

import io.fabric8.kubernetes.api.model.ContainerStatus;
import io.fabric8.kubernetes.api.model.Pod;
import io.fabric8.kubernetes.client.KubernetesClient;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class PodService {
  @Inject KubernetesClient client;

  @ConfigProperty(name = "zookage.namespace", defaultValue = "zookage")
  String namespace;

  public String list() {
    return format(client.pods().inNamespace(namespace).list().getItems(), namespace, Instant.now());
  }

  static String format(List<Pod> pods, String namespace, Instant now) {
    if (pods.isEmpty()) {
      return "No resources found in " + namespace + " namespace.\n";
    }
    int nameWidth =
        Math.max(
            4, pods.stream().mapToInt(pod -> pod.getMetadata().getName().length()).max().orElse(4));
    String header = formatRow(nameWidth, "NAME", "READY", "STATUS", "RESTARTS", "AGE");
    String rows =
        pods.stream()
            .sorted(Comparator.comparing(pod -> pod.getMetadata().getName()))
            .map(
                pod ->
                    formatRow(
                        nameWidth,
                        pod.getMetadata().getName(),
                        ready(pod),
                        status(pod),
                        Integer.toString(restarts(pod)),
                        age(pod, now)))
            .collect(Collectors.joining());
    return header + rows;
  }

  private static String formatRow(
      int nameWidth, String name, String ready, String status, String restarts, String age) {
    return ("%-" + nameWidth + "s  %-5s  %-20s  %-8s  %s%n")
        .formatted(name, ready, status, restarts, age);
  }

  private static String ready(Pod pod) {
    int desired = pod.getSpec().getContainers().size();
    int ready =
        pod.getStatus() == null || pod.getStatus().getContainerStatuses() == null
            ? 0
            : (int)
                pod.getStatus().getContainerStatuses().stream()
                    .filter(container -> Boolean.TRUE.equals(container.getReady()))
                    .count();
    return ready + "/" + desired;
  }

  private static String status(Pod pod) {
    if (pod.getMetadata().getDeletionTimestamp() != null) {
      return "Terminating";
    }
    if (pod.getStatus() == null) {
      return "Unknown";
    }
    if (pod.getStatus().getContainerStatuses() != null) {
      for (ContainerStatus container : pod.getStatus().getContainerStatuses()) {
        if (container.getState() != null && container.getState().getWaiting() != null) {
          String reason = container.getState().getWaiting().getReason();
          if (reason != null) {
            return reason;
          }
        }
        if (container.getState() != null && container.getState().getTerminated() != null) {
          String reason = container.getState().getTerminated().getReason();
          if (reason != null) {
            return reason;
          }
        }
      }
    }
    String phase = pod.getStatus().getPhase();
    return phase == null ? "Unknown" : "Succeeded".equals(phase) ? "Completed" : phase;
  }

  private static int restarts(Pod pod) {
    if (pod.getStatus() == null) {
      return 0;
    }
    return restartCount(pod.getStatus().getContainerStatuses())
        + restartCount(pod.getStatus().getInitContainerStatuses());
  }

  private static int restartCount(List<ContainerStatus> containers) {
    return containers == null
        ? 0
        : containers.stream()
            .mapToInt(
                container -> container.getRestartCount() == null ? 0 : container.getRestartCount())
            .sum();
  }

  private static String age(Pod pod, Instant now) {
    if (pod.getMetadata().getCreationTimestamp() == null) {
      return "<unknown>";
    }
    long seconds =
        Math.max(
            0,
            Duration.between(Instant.parse(pod.getMetadata().getCreationTimestamp()), now)
                .getSeconds());
    if (seconds < 60) {
      return seconds + "s";
    }
    if (seconds < 3600) {
      return seconds / 60 + "m";
    }
    if (seconds < 86400) {
      return seconds / 3600 + "h";
    }
    return seconds / 86400 + "d";
  }
}
