// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"go.yaml.in/yaml/v3"
)

func TestRunPluginConfigurationVersion(t *testing.T) {
	resources := []string{
		configMapResource(t, "config-values", map[string]any{"name": "global"}, ""),
		configMapResource(t, "role-values", map[string]any{"name": "role"}, ""),
		configMapResource(t, "settings", map[string]any{"name": "{{ .Values.name }}"}, "role-values"),
	}
	tests := []struct {
		apiVersion string
		kind       string
		valid      bool
	}{
		{"zookage.io/v1", "RenderConfig", true},
		{"zookage.io/v2", "RenderConfig", true},
		{"zookage.io/v3", "RenderConfig", false},
		{"other.io/v2", "RenderConfig", false},
		{"zookage.io/v1", "Other", false},
		{"zookage.io/v2", "Other", false},
	}
	for _, test := range tests {
		t.Run(test.apiVersion+"/"+test.kind, func(t *testing.T) {
			configuration := "apiVersion: " + test.apiVersion + "\nkind: " + test.kind + "\n"
			output, err := runResourcesWithConfiguration(t, configuration, resources...)
			if test.valid {
				if err != nil {
					t.Fatal(err)
				}
				assertScalar(t, field(decodeResources(t, output)["settings"], "data"), "name", "role")
			} else {
				if err == nil || !strings.Contains(err.Error(), "plugin configuration must be") {
					t.Fatalf("error = %v, want unsupported plugin configuration error", err)
				}
				if output != "" {
					t.Fatalf("wrote partial output on failure: %q", output)
				}
			}
		})
	}
}

func TestRunGlobalValues(t *testing.T) {
	for _, valuesName := range []string{"config-values", "custom-values"} {
		t.Run(valuesName, func(t *testing.T) {
			configuration := ""
			if valuesName != "config-values" {
				configuration = "valuesConfigMap: " + valuesName + "\n"
			}
			resources := []string{
				configMapResource(t, valuesName, map[string]any{"name": "global"}, ""),
				configMapResource(t, "settings", map[string]any{
					"plain":    "unchanged",
					"text":     "{{ .Values.name }}",
					"site.xml": "<configuration>{{ .Values.name }}</configuration>",
					"app.json": `{"name":"{{ .Values.name }}"}`,
				}, ""),
				"apiVersion: v1\nkind: Secret\nmetadata:\n  name: secret\nstringData:\n  plain: '{{ .Values.name }}'\n",
			}
			output, err := runResources(t, configuration, resources...)
			if err != nil {
				t.Fatal(err)
			}
			documents := decodeResources(t, output)
			settings := field(documents["settings"], "data")
			assertScalar(t, settings, "plain", "unchanged")
			assertScalar(t, settings, "text", "global")
			assertScalar(t, settings, "site.xml", "<configuration>global</configuration>")
			assertScalar(t, settings, "app.json", `{"name":"global"}`)
			assertScalar(t, field(documents["secret"], "stringData"), "plain", "{{ .Values.name }}")
		})
	}
}

func TestRunScopedValues(t *testing.T) {
	resources := []string{
		configMapResource(t, "config-values", map[string]any{
			"auth": "simple", "fallback": "false", "shared": "global", "optional": "present",
		}, ""),
		configMapResource(t, "yarn-values", map[string]any{
			"auth": "kerberos", "fallback": "true", "optional": "", "role": "yarn",
		}, ""),
		configMapResource(t, "client-values", map[string]any{"auth": "kerberos", "role": "client"}, ""),
		configMapResource(t, "yarn", map[string]any{
			"settings": "{{ .Values.auth }}/{{ .Values.fallback }}/{{ .Values.shared }}/{{ .Values.optional }}/{{ .Values.role }}",
		}, "yarn-values"),
		configMapResource(t, "client", map[string]any{
			"settings": "{{ .Values.auth }}/{{ .Values.fallback }}/{{ .Values.shared }}/{{ .Values.optional }}/{{ .Values.role }}",
		}, "client-values"),
		configMapResource(t, "default", map[string]any{
			"settings": "{{ .Values.auth }}/{{ .Values.fallback }}/{{ .Values.shared }}/{{ .Values.optional }}",
		}, ""),
	}
	output, err := runResources(t, "", resources...)
	if err != nil {
		t.Fatal(err)
	}
	documents := decodeResources(t, output)
	assertScalar(t, field(documents["yarn"], "data"), "settings", "kerberos/true/global//yarn")
	assertScalar(t, field(documents["client"], "data"), "settings", "kerberos/false/global/present/client")
	assertScalar(t, field(documents["default"], "data"), "settings", "simple/false/global/present")
	assertScalar(t, field(field(documents["yarn"], "metadata"), "annotations"), "zookage.io/config-values", "yarn-values")
	assertScalar(t, field(field(documents["yarn"], "metadata"), "annotations"), "config.kubernetes.io/local-config", "true")
	assertScalar(t, field(documents["yarn"], "binaryData"), "untouched", "YWJj")
}

func TestRunSnapshotsAllValuesBeforeRendering(t *testing.T) {
	resources := []string{
		configMapResource(t, "config-values", map[string]any{
			"name": "global", "indirect": "{{ .Values.name }}",
		}, ""),
		configMapResource(t, "role-values", map[string]any{
			"name": "role", "indirect": "{{ .Values.name }}",
		}, ""),
		configMapResource(t, "settings", map[string]any{
			"name": "{{ .Values.name }}", "indirect": "{{ .Values.indirect }}",
		}, "role-values"),
		configMapResource(t, "global-settings", map[string]any{"indirect": "{{ .Values.indirect }}"}, ""),
	}
	for _, order := range [][]int{{0, 1, 2}, {0, 2, 1}, {1, 0, 2}, {1, 2, 0}, {2, 0, 1}, {2, 1, 0}} {
		output, err := runResources(t, "", resources[order[0]], resources[order[1]], resources[order[2]], resources[3])
		if err != nil {
			t.Fatalf("order %v: %v", order, err)
		}
		documents := decodeResources(t, output)
		assertScalar(t, field(documents["settings"], "data"), "name", "role")
		assertScalar(t, field(documents["settings"], "data"), "indirect", "{{ .Values.name }}")
		assertScalar(t, field(documents["global-settings"], "data"), "indirect", "{{ .Values.name }}")
		assertScalar(t, field(documents["role-values"], "data"), "indirect", "global")
	}
}

func TestRunValuesErrors(t *testing.T) {
	global := configMapResource(t, "config-values", map[string]any{"name": "global"}, "")
	scoped := configMapResource(t, "settings", map[string]any{"text": "{{ .Values.name }}"}, "role-values")
	role := configMapResource(t, "role-values", map[string]any{"name": "role"}, "")
	tests := []struct {
		name      string
		resources []string
		wantError string
	}{
		{"missing global", []string{role}, "values ConfigMap config-values not found"},
		{"duplicate global", []string{global, global}, "multiple ConfigMaps named config-values"},
		{"missing scoped", []string{global, scoped}, "values ConfigMap role-values not found"},
		{"duplicate scoped", []string{global, role, scoped, role}, "multiple ConfigMaps named role-values"},
		{"non-string global", []string{configMapResource(t, "config-values", map[string]any{"name": true}, "")}, "values ConfigMap config-values: data.name must be a string"},
		{"non-string scoped", []string{global, scoped, configMapResource(t, "role-values", map[string]any{"name": 123}, "")}, "values ConfigMap role-values: data.name must be a string"},
		{"non-scalar scoped", []string{global, scoped, configMapResource(t, "role-values", map[string]any{"name": []string{"role"}}, "")}, "values ConfigMap role-values: data.name must be a string"},
		{"non-string target", []string{global, configMapResource(t, "settings", map[string]any{"name": false}, "")}, "ConfigMap settings: data.name must be a string"},
		{"scoped validation without template", []string{global, configMapResource(t, "settings", map[string]any{"name": "literal"}, "missing")}, "values ConfigMap missing not found"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			output, err := runResources(t, "", test.resources...)
			if err == nil || !strings.Contains(err.Error(), test.wantError) {
				t.Fatalf("error = %v, want %q", err, test.wantError)
			}
			if output != "" {
				t.Fatalf("wrote partial output on failure: %q", output)
			}
		})
	}
}

func TestRenderTemplateErrors(t *testing.T) {
	tests := []struct {
		name      string
		source    string
		wantError string
	}{
		{"missing.txt", "{{ .Values.missing }}", "render missing.txt"},
		{"invalid.txt", "{{", "parse invalid.txt"},
		{"unclosed.xml", "<root>{{ .Values.name }}", "rendered XML unclosed.xml"},
		{"multiple.xml", "<a>{{ .Values.name }}</a><b/>", "expected one XML root element, got 2"},
		{"outside.xml", "{{ .Values.name }}<root/>", "text outside the XML root element"},
		{"empty.xml", `{{ "" }}`, "expected one XML root element, got 0"},
		{"invalid.json", `{"{{ .Values.name }}":}`, "rendered JSON invalid.json is invalid"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := renderTemplate(test.name, test.source, map[string]string{"name": "value"})
			if err == nil || !strings.Contains(err.Error(), test.wantError) {
				t.Fatalf("error = %v, want %q", err, test.wantError)
			}
		})
	}
}

func configMapResource(t *testing.T, name string, data map[string]any, valuesReference string) string {
	t.Helper()
	annotations := map[string]string{"config.kubernetes.io/local-config": "true"}
	if valuesReference != "" {
		annotations["zookage.io/config-values"] = valuesReference
	}
	resource := map[string]any{
		"apiVersion": "v1",
		"kind":       "ConfigMap",
		"metadata":   map[string]any{"name": name, "annotations": annotations},
		"data":       data,
		"binaryData": map[string]string{"untouched": "YWJj"},
	}
	encoded, err := yaml.Marshal(resource)
	if err != nil {
		t.Fatal(err)
	}
	return string(encoded)
}

func runResources(t *testing.T, configuration string, resources ...string) (string, error) {
	t.Helper()
	configuration = "apiVersion: zookage.io/v1\nkind: RenderConfig\n" + configuration
	return runResourcesWithConfiguration(t, configuration, resources...)
}

func runResourcesWithConfiguration(t *testing.T, configuration string, resources ...string) (string, error) {
	t.Helper()
	configPath := filepath.Join(t.TempDir(), "plugin.yaml")
	if err := os.WriteFile(configPath, []byte(configuration), 0600); err != nil {
		t.Fatal(err)
	}
	var output bytes.Buffer
	err := run(configPath, strings.NewReader(strings.Join(resources, "---\n")), &output)
	return output.String(), err
}

func decodeResources(t *testing.T, output string) map[string]*yaml.Node {
	t.Helper()
	documents := make(map[string]*yaml.Node)
	decoder := yaml.NewDecoder(strings.NewReader(output))
	for {
		var document yaml.Node
		if err := decoder.Decode(&document); errors.Is(err, io.EOF) {
			break
		} else if err != nil {
			t.Fatal(err)
		}
		name := scalar(field(field(&document, "metadata"), "name"))
		documents[name] = &document
	}
	return documents
}

func assertScalar(t *testing.T, mapping *yaml.Node, key, want string) {
	t.Helper()
	if node := field(mapping, key); node == nil || node.Kind != yaml.ScalarNode || node.Value != want {
		t.Errorf("%s = %v, want %q", key, node, want)
	}
}
