# Helm Templating Notes

## Template Syntax Basics

### Built-in Objects
```yaml
# Chart info
name: {{ .Chart.Name }}
version: {{ .Chart.Version }}

# Release info
name: {{ .Release.Name }}
namespace: {{ .Release.Namespace }}

# Values from values.yaml
replicas: {{ .Values.replicaCount }}
image: {{ .Values.image.repository }}
```

### Template Functions
```yaml
# String functions
name: {{ .Values.name | upper }}
tag: {{ .Values.image.tag | default "latest" }}
host: {{ .Values.database.host | quote }}

# Conditionals
{{- if .Values.ingress.enabled }}
# ingress config here
{{- end }}

# With blocks (scope)
{{- with .Values.database }}
- name: DB_HOST
  value: {{ .host }}
- name: DB_PORT
  value: {{ .port | quote }}
{{- end }}

# Loops - lists
{{- range .Values.environments }}
- name: {{ .name }}
  value: {{ .value }}
{{- end }}

# Loops - maps
{{- range $key, $value := .Values.config }}
{{ $key }}: {{ $value | quote }}
{{- end }}
```

## Template Commands
```bash
# Render templates without installing
helm template my-app ./chart

# Render with custom values
helm template my-app ./chart --set replicas=3

# Render specific template only
helm template my-app ./chart -s templates/deployment.yaml

# Debug templates
helm install my-app ./chart --dry-run --debug
```

## Real-World Usage

### What Most Teams Actually Use (90%)
```yaml
# Simple variable substitution
image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
replicas: {{ .Values.replicaCount }}

# Basic conditionals
{{- if .Values.ingress.enabled }}
# ingress config
{{- end }}

# Simple loops
{{- range .Values.env }}
- name: {{ .name }}
  value: {{ .value }}
{{- end }}
```

### Common Pattern - Simple Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.appName }}
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: {{ .Values.appName }}
  template:
    spec:
      containers:
      - name: {{ .Values.appName }}
        image: {{ .Values.image }}
        ports:
        - containerPort: {{ .Values.port }}
```

### Simple values.yaml
```yaml
appName: myapp
image: nginx:1.20
replicas: 2
port: 80
env:
  - name: ENV
    value: production
```

## Real-World Recommendations

### For Most Developers (80% of cases):
1. **Use existing charts** (bitnami, official charts)
2. **Simple value overrides** with `--set` or `-f values.yaml`
3. **Avoid complex templating** unless necessary

### When to Use Complex Templating:
- **Platform teams** creating company-wide charts
- **Multi-environment** deployments (dev/staging/prod)
- **Infrastructure as Code** scenarios

### The 80/20 Rule:
- **80%** = Simple `{{ .Values.* }}` substitution
- **20%** = Complex functions (usually platform teams)

## Template Helpers (_helpers.tpl)
```yaml
{{/* Define reusable template */}}
{{- define "myapp.name" -}}
{{- default .Chart.Name .Values.nameOverride }}
{{- end }}

{{/* Use helper */}}
name: {{ include "myapp.name" . }}
```

## Best Practices
- Start simple, add complexity only when needed
- Use `{{- }}` to control whitespace
- Always quote string values: `{{ .value | quote }}`
- Test templates with `helm template`
- Use existing charts when possible
- Keep templates readable and maintainable

## Common Functions
- `upper` / `lower` - Change case
- `quote` - Add quotes around values
- `default` - Provide fallback values
- `indent` / `nindent` - Format YAML indentation
- `include` - Use template helpers