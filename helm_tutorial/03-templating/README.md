# 03. Helm Templating

## Template Syntax Basics

### Variables and Values
```yaml
# In templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name }}
  labels:
    app: {{ .Values.app.name }}
    version: {{ .Values.app.version }}
spec:
  replicas: {{ .Values.replicaCount }}
```

### Built-in Objects
```yaml
# Chart information
name: {{ .Chart.Name }}
version: {{ .Chart.Version }}

# Release information  
name: {{ .Release.Name }}
namespace: {{ .Release.Namespace }}

# Kubernetes capabilities
apiVersion: {{ .Capabilities.KubeVersion }}
```

## Template Functions

### String Functions
```yaml
# Upper/lower case
name: {{ .Values.name | upper }}
image: {{ .Values.image.repository | lower }}

# Default values
tag: {{ .Values.image.tag | default "latest" }}

# Quote strings
env:
  - name: DB_HOST
    value: {{ .Values.database.host | quote }}
```

### Logic Functions
```yaml
# If/else conditions
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Release.Name }}-ingress
{{- end }}

# With blocks (scope)
{{- with .Values.database }}
env:
  - name: DB_HOST
    value: {{ .host }}
  - name: DB_PORT
    value: {{ .port | quote }}
{{- end }}
```

### Range (Loops)
```yaml
# Loop through lists
{{- range .Values.environments }}
- name: {{ .name }}
  value: {{ .value }}
{{- end }}

# Loop through maps
{{- range $key, $value := .Values.config }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
```

## Template Helpers

### _helpers.tpl
```yaml
{{/*
Expand the name of the chart.
*/}}
{{- define "webapp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "webapp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
```

### Using Helpers
```yaml
# In templates/deployment.yaml
metadata:
  name: {{ include "webapp.fullname" . }}
  labels:
    app.kubernetes.io/name: {{ include "webapp.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
```

## Advanced Templating

### Include Files
```yaml
# Include another template
{{ include "webapp.labels" . | indent 4 }}

# Include raw files
data:
  config.json: |
{{ .Files.Get "config.json" | indent 4 }}
```

### Template Debugging
```bash
# Render templates without installing
helm template my-webapp ./webapp

# Debug with values
helm template my-webapp ./webapp --set replicaCount=3

# Show only specific template
helm template my-webapp ./webapp -s templates/deployment.yaml
```

## Best Practices
- Use `{{- }}` to control whitespace
- Always quote string values
- Use helpers for repeated logic
- Validate templates with `helm lint`
- Test with different value combinations

Next: Master values and configuration in `04-values/`