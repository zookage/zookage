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
