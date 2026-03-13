package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

type FileConfig struct {
	Target      *string  `json:"target" yaml:"target"`
	Requests    *int     `json:"requests" yaml:"requests"`
	Concurrency *int     `json:"concurrency" yaml:"concurrency"`
	Timeout     *string  `json:"timeout" yaml:"timeout"`
	Duration    *string  `json:"duration" yaml:"duration"`
	Method      *string  `json:"method" yaml:"method"`
	Body        *string  `json:"body" yaml:"body"`
	Headers     []string `json:"headers" yaml:"headers"`
}

func LoadConfig(path string) (*FileConfig, error) {
	ext := strings.ToLower(filepath.Ext(path))

	switch ext {
	case ".json":
		return loadJSON(path)
	case ".yaml", ".yml":
		return loadYAML(path)
	default:
		return nil, fmt.Errorf("unsupported config file extension %q, supported: .json, .yaml, .yml", ext)
	}
}

func loadJSON(path string) (*FileConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	if len(strings.TrimSpace(string(data))) == 0 {
		return &FileConfig{}, nil
	}

	var cfg FileConfig
	if err := json.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse JSON config: %w", err)
	}

	return &cfg, nil
}

func loadYAML(path string) (*FileConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	if len(strings.TrimSpace(string(data))) == 0 {
		return &FileConfig{}, nil
	}

	var cfg FileConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse YAML config: %w", err)
	}

	return &cfg, nil
}


func MergeConfig(file *FileConfig, cli RunConfig, changed map[string]bool) RunConfig {
	if file == nil {
		return cli
	}

	merged := cli

	if file.Target != nil && !changed["target"] && !changed["url"] {
		merged.Target = *file.Target
	}

	if file.Requests != nil && !changed["requests"] && !changed["n"] {
		merged.Requests = *file.Requests
	}

	if file.Concurrency != nil && !changed["concurrency"] && !changed["c"] {
		merged.Concurrency = *file.Concurrency
	}

	if file.Timeout != nil && !changed["timeout"] && !changed["t"] {
		if d, err := time.ParseDuration(*file.Timeout); err == nil {
			merged.Timeout = d
		}
	}

	if file.Duration != nil && !changed["duration"] && !changed["d"] {
		if d, err := time.ParseDuration(*file.Duration); err == nil {
			merged.Duration = d
		}
	}

	if file.Method != nil && !changed["method"] && !changed["m"] {
		merged.Method = strings.ToUpper(*file.Method)
	}

	if file.Body != nil && !changed["body"] && !changed["b"] {
		merged.Body = *file.Body
	}

	if len(file.Headers) > 0 && !changed["header"] && !changed["H"] {
		merged.Headers = file.Headers 
	}

	return merged
}
