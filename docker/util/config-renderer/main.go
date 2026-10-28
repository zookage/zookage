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
	"encoding/json"
	"encoding/xml"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
	"text/template"

	"go.yaml.in/yaml/v3"
)

type pluginConfig struct {
	APIVersion      string `yaml:"apiVersion"`
	Kind            string `yaml:"kind"`
	ValuesConfigMap string `yaml:"valuesConfigMap"`
	SharedConfigMap string `yaml:"sharedConfigMap"`
	SharedMountPath string `yaml:"sharedMountPath"`
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "Usage: config-renderer <plugin-config-file>")
		os.Exit(2)
	}
	if err := run(os.Args[1], os.Stdin, os.Stdout); err != nil {
		fmt.Fprintf(os.Stderr, "config-renderer: %v\n", err)
		os.Exit(1)
	}
}

func run(configPath string, input io.Reader, output io.Writer) error {
	configData, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("read plugin configuration: %w", err)
	}
	var config pluginConfig
	if err := yaml.Unmarshal(configData, &config); err != nil {
		return fmt.Errorf("decode plugin configuration: %w", err)
	}
	if config.APIVersion != "zookage.io/v2" || config.Kind != "RenderConfig" {
		return errors.New("plugin configuration must be zookage.io/v2 RenderConfig")
	}
	if config.ValuesConfigMap == "" {
		config.ValuesConfigMap = "config-values"
	}

	decoder := yaml.NewDecoder(input)
	var documents []*yaml.Node
	var configMaps []*yaml.Node
	namedConfigMaps := make(map[string][]*yaml.Node)
	for {
		var document yaml.Node
		if err := decoder.Decode(&document); errors.Is(err, io.EOF) {
			break
		} else if err != nil {
			return fmt.Errorf("read resources: %w", err)
		}
		documents = append(documents, &document)
		if scalar(field(&document, "apiVersion")) != "v1" || scalar(field(&document, "kind")) != "ConfigMap" {
			continue
		}
		configMaps = append(configMaps, &document)
		name := scalar(field(field(&document, "metadata"), "name"))
		namedConfigMaps[name] = append(namedConfigMaps[name], &document)
	}
	// Snapshot all values before evaluating any resource, including the values
	// ConfigMaps themselves. Rendering order must not change template contexts.
	values, err := readNamedValues(namedConfigMaps, config.ValuesConfigMap)
	if err != nil {
		return err
	}
	scopedValues := make(map[string]map[string]string)
	for _, configMap := range configMaps {
		name := valuesReference(configMap)
		if name == "" || scopedValues[name] != nil {
			continue
		}
		overrides, err := readNamedValues(namedConfigMaps, name)
		if err != nil {
			return err
		}
		merged := make(map[string]string, len(values)+len(overrides))
		for key, value := range values {
			merged[key] = value
		}
		for key, value := range overrides {
			merged[key] = value
		}
		scopedValues[name] = merged
	}
	for _, configMap := range configMaps {
		name := scalar(field(field(configMap, "metadata"), "name"))
		templateValues := values
		if reference := valuesReference(configMap); reference != "" {
			templateValues = scopedValues[reference]
		}
		data := field(configMap, "data")
		if err := validateStringData(data); err != nil {
			return fmt.Errorf("ConfigMap %s: %w", name, err)
		}
		if data == nil {
			continue
		}
		for i := 0; i < len(data.Content); i += 2 {
			key, value := data.Content[i], data.Content[i+1]
			if !strings.Contains(value.Value, "{{") {
				continue
			}
			rendered, err := renderTemplate(name+"/"+key.Value, value.Value, templateValues)
			if err != nil {
				return err
			}
			value.Value = rendered
		}
	}
	if err := mountSharedConfig(documents, namedConfigMaps, config.SharedConfigMap, config.SharedMountPath); err != nil {
		return err
	}

	// Keep the original YAML nodes so all resources, annotations, binaryData,
	// and non-template scalar contents survive the transform.
	var result bytes.Buffer
	encoder := yaml.NewEncoder(&result)
	encoder.SetIndent(2)
	for _, document := range documents {
		if err := encoder.Encode(document); err != nil {
			return fmt.Errorf("encode resources: %w", err)
		}
	}
	if err := encoder.Close(); err != nil {
		return err
	}
	_, err = output.Write(result.Bytes())
	return err
}

func field(node *yaml.Node, name string) *yaml.Node {
	if node == nil {
		return nil
	}
	if node.Kind == yaml.DocumentNode && len(node.Content) == 1 {
		node = node.Content[0]
	}
	if node.Kind != yaml.MappingNode {
		return nil
	}
	for i := 0; i < len(node.Content); i += 2 {
		if node.Content[i].Value == name {
			return node.Content[i+1]
		}
	}
	return nil
}

func scalar(node *yaml.Node) string {
	if node == nil {
		return ""
	}
	return node.Value
}

func validateStringData(data *yaml.Node) error {
	if data == nil || data.Tag == "!!null" {
		return nil
	}
	if data.Kind != yaml.MappingNode {
		return errors.New("data must be a mapping of strings")
	}
	for i := 0; i < len(data.Content); i += 2 {
		key, value := data.Content[i], data.Content[i+1]
		if key.Kind != yaml.ScalarNode || key.Tag != "!!str" || value.Kind != yaml.ScalarNode || value.Tag != "!!str" {
			return fmt.Errorf("data.%s must be a string", key.Value)
		}
	}
	return nil
}

func readValues(configMap *yaml.Node) (map[string]string, error) {
	data := field(configMap, "data")
	name := scalar(field(field(configMap, "metadata"), "name"))
	if err := validateStringData(data); err != nil {
		return nil, fmt.Errorf("values ConfigMap %s: %w", name, err)
	}
	values := make(map[string]string)
	if data != nil {
		if err := data.Decode(&values); err != nil {
			return nil, fmt.Errorf("read values ConfigMap %s: %w", name, err)
		}
	}
	return values, nil
}

func valuesReference(configMap *yaml.Node) string {
	return scalar(field(field(field(configMap, "metadata"), "annotations"), "zookage.io/config-values"))
}

func readNamedValues(configMaps map[string][]*yaml.Node, name string) (map[string]string, error) {
	matches := configMaps[name]
	if len(matches) == 0 {
		return nil, fmt.Errorf("values ConfigMap %s not found", name)
	}
	if len(matches) != 1 {
		return nil, fmt.Errorf("multiple ConfigMaps named %s", name)
	}
	return readValues(matches[0])
}

func renderTemplate(name, source string, values map[string]string) (string, error) {
	tmpl, err := template.New(name).Option("missingkey=error").Parse(source)
	if err != nil {
		return "", fmt.Errorf("parse %s: %w", name, err)
	}
	var output bytes.Buffer
	if err := tmpl.Execute(&output, struct{ Values map[string]string }{Values: values}); err != nil {
		return "", fmt.Errorf("render %s: %w", name, err)
	}
	if strings.HasSuffix(name, ".xml") {
		if err := validateXML(output.Bytes()); err != nil {
			return "", fmt.Errorf("rendered XML %s: %w", name, err)
		}
	}
	if strings.HasSuffix(name, ".json") && !json.Valid(output.Bytes()) {
		return "", fmt.Errorf("rendered JSON %s is invalid", name)
	}
	return output.String(), nil
}

func validateXML(data []byte) error {
	decoder := xml.NewDecoder(bytes.NewReader(data))
	depth, roots := 0, 0
	for {
		token, err := decoder.Token()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return err
		}
		switch token := token.(type) {
		case xml.StartElement:
			if depth == 0 {
				roots++
			}
			depth++
		case xml.EndElement:
			depth--
		case xml.CharData:
			if depth == 0 && len(bytes.TrimSpace(token)) != 0 {
				return errors.New("text outside the XML root element")
			}
		}
	}
	if roots != 1 {
		return fmt.Errorf("expected one XML root element, got %d", roots)
	}
	return nil
}

func mountSharedConfig(documents []*yaml.Node, configMaps map[string][]*yaml.Node, name, mountPath string) error {
	if name == "" && mountPath == "" {
		return nil
	}
	if name == "" || !strings.HasPrefix(mountPath, "/") {
		return errors.New("sharedConfigMap and absolute sharedMountPath must both be set")
	}
	// Kustomize may already have appended the generator hash when an exec
	// transformer runs. Use the rendered name so changing the ConfigMap also
	// changes the Pod template's volume reference.
	var configMapName string
	for candidate, matches := range configMaps {
		if candidate != name && !isGeneratedName(candidate, name) {
			continue
		}
		if len(matches) != 1 || configMapName != "" {
			return fmt.Errorf("expected one shared ConfigMap named %s", name)
		}
		configMapName = candidate
	}
	if configMapName == "" {
		return fmt.Errorf("shared ConfigMap %s not found", name)
	}

	for _, document := range documents {
		kind := scalar(field(document, "kind"))
		var podSpec *yaml.Node
		switch kind {
		case "Pod":
			podSpec = field(document, "spec")
		case "Deployment", "StatefulSet", "DaemonSet", "Job":
			podSpec = field(field(field(document, "spec"), "template"), "spec")
		case "CronJob":
			podSpec = field(field(field(field(field(document, "spec"), "jobTemplate"), "spec"), "template"), "spec")
		default:
			continue
		}
		resourceName := scalar(field(field(document, "metadata"), "name"))
		if podSpec == nil || podSpec.Kind != yaml.MappingNode {
			return fmt.Errorf("%s %s has no Pod spec", kind, resourceName)
		}
		if err := ensureSharedVolume(podSpec, name, configMapName); err != nil {
			return fmt.Errorf("%s %s: %w", kind, resourceName, err)
		}
		for _, containerField := range []string{"containers", "initContainers", "ephemeralContainers"} {
			containers := field(podSpec, containerField)
			if containers == nil {
				continue
			}
			if containers.Kind != yaml.SequenceNode {
				return fmt.Errorf("%s %s: %s must be a sequence", kind, resourceName, containerField)
			}
			for _, container := range containers.Content {
				containerName := scalar(field(container, "name"))
				if container.Kind != yaml.MappingNode || containerName == "" {
					return fmt.Errorf("%s %s: %s contains a container without a name", kind, resourceName, containerField)
				}
				if err := ensureSharedMount(container, name, mountPath); err != nil {
					return fmt.Errorf("%s %s %s %s: %w", kind, resourceName, containerField, containerName, err)
				}
			}
		}
	}
	return nil
}

func isGeneratedName(candidate, base string) bool {
	if !strings.HasPrefix(candidate, base+"-") || len(candidate) != len(base)+11 {
		return false
	}
	for _, char := range candidate[len(base)+1:] {
		if char < '0' || char > '9' {
			if char < 'a' || char > 'z' {
				return false
			}
		}
	}
	return true
}

func ensureSharedVolume(podSpec *yaml.Node, name, configMapName string) error {
	volumes, err := sequenceField(podSpec, "volumes")
	if err != nil {
		return err
	}
	var found bool
	for _, volume := range volumes.Content {
		if scalar(field(volume, "name")) != name {
			continue
		}
		configMap := field(volume, "configMap")
		volumeConfigMap := scalar(field(configMap, "name"))
		if found || (volumeConfigMap != name && volumeConfigMap != configMapName) || field(configMap, "items") != nil {
			return fmt.Errorf("volume %s conflicts with shared ConfigMap %s", name, configMapName)
		}
		found = true
	}
	if !found {
		volume := mappingNode()
		addField(volume, "name", stringNode(name))
		configMap := mappingNode()
		addField(configMap, "name", stringNode(configMapName))
		addField(volume, "configMap", configMap)
		volumes.Content = append(volumes.Content, volume)
	}
	return nil
}

func ensureSharedMount(container *yaml.Node, name, mountPath string) error {
	mounts, err := sequenceField(container, "volumeMounts")
	if err != nil {
		return err
	}
	var found bool
	for _, mount := range mounts.Content {
		mountName := scalar(field(mount, "name"))
		path := scalar(field(mount, "mountPath"))
		if mountName != name && path != mountPath {
			continue
		}
		if found || mountName != name || path != mountPath || field(mount, "subPath") != nil || field(mount, "subPathExpr") != nil {
			return fmt.Errorf("mount %s at %s conflicts with shared mount", mountName, path)
		}
		readOnly := field(mount, "readOnly")
		if readOnly != nil && (readOnly.Tag != "!!bool" || readOnly.Value != "true") {
			return fmt.Errorf("mount %s at %s is not read-only", name, mountPath)
		}
		if readOnly == nil {
			addField(mount, "readOnly", &yaml.Node{Kind: yaml.ScalarNode, Tag: "!!bool", Value: "true"})
		}
		found = true
	}
	if !found {
		mount := mappingNode()
		addField(mount, "name", stringNode(name))
		addField(mount, "mountPath", stringNode(mountPath))
		addField(mount, "readOnly", &yaml.Node{Kind: yaml.ScalarNode, Tag: "!!bool", Value: "true"})
		mounts.Content = append(mounts.Content, mount)
	}
	return nil
}

func sequenceField(node *yaml.Node, name string) (*yaml.Node, error) {
	sequence := field(node, name)
	if sequence == nil {
		sequence = &yaml.Node{Kind: yaml.SequenceNode, Tag: "!!seq"}
		addField(node, name, sequence)
	}
	if sequence.Kind != yaml.SequenceNode {
		return nil, fmt.Errorf("%s must be a sequence", name)
	}
	return sequence, nil
}

func mappingNode() *yaml.Node {
	return &yaml.Node{Kind: yaml.MappingNode, Tag: "!!map"}
}

func stringNode(value string) *yaml.Node {
	return &yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: value}
}

func addField(node *yaml.Node, name string, value *yaml.Node) {
	node.Content = append(node.Content, stringNode(name), value)
}
