# Helm Basic Chart Notes

## Chart Structure
```
webapp/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default configuration values
├── templates/          # Kubernetes manifest templates
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl    # Template helpers
└── charts/            # Chart dependencies
```

## Key Files

### Chart.yaml
- Contains chart metadata (name, version, appVersion)
- `version`: Chart version (increment when chart changes)
- `appVersion`: Application version being deployed

### values.yaml
- Default configuration values
- Referenced in templates as `{{ .Values.key }}`
- Can be overridden at install time

### Templates
- Kubernetes YAML with Go templating
- Use `{{ .Values.* }}` for dynamic values
- Generate actual Kubernetes manifests

## Basic Commands

### Create Chart
```bash
helm create webapp
```

### Validate Chart
```bash
helm lint ./webapp
```

### Preview Manifests (Dry Run)
```bash
helm install my-webapp ./webapp --dry-run --debug
```

### Package Chart
```bash
helm package ./webapp
# Creates: webapp-0.1.0.tgz
```

## Using Packaged Charts (.tgz)

### Install from Package
```bash
# Basic install
helm install my-webapp webapp-0.1.0.tgz

# With custom values
helm install my-webapp webapp-0.1.0.tgz --set replicaCount=5

# With values file
helm install my-webapp webapp-0.1.0.tgz -f custom-values.yaml
```

### Override Values
```bash
# Command line
--set key=value
--set image.tag=latest
--set replicaCount=3

# Values file
-f custom-values.yaml
```

## Chart Management

### Install/Upgrade/Rollback
```bash
# Install
helm install release-name ./chart

# Upgrade
helm upgrade release-name ./chart

# Rollback
helm rollback release-name 1
```

### List Releases
```bash
helm list
```

### Uninstall
```bash
helm uninstall release-name
```

## Customization Example

### Original values.yaml
```yaml
replicaCount: 1
image:
  repository: nginx
  tag: ""
service:
  type: ClusterIP
  port: 80
```

### Custom values.yaml
```yaml
replicaCount: 3
image:
  repository: httpd
  tag: "2.4"
service:
  type: NodePort
  port: 8080
```

## Template Variables
- `{{ .Values.* }}` - Values from values.yaml
- `{{ .Chart.Name }}` - Chart name
- `{{ .Chart.Version }}` - Chart version
- `{{ .Release.Name }}` - Release name

## Best Practices
1. Always validate with `helm lint`
2. Use `--dry-run` to preview changes
3. Version your charts properly
4. Use meaningful release names
5. Keep values.yaml well-documented
6. Package charts for distribution

## Next Steps
- Learn advanced templating (03-templating)
- Understand chart dependencies
- Explore Helm hooks
- Study real-world examples