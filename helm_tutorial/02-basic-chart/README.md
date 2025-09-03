# 02. Basic Chart Creation

## Create Your First Chart
```bash
# Create a new chart
helm create webapp

# Chart structure created:
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

## Understanding Chart Structure

### Chart.yaml - Chart Metadata
```yaml
apiVersion: v2
name: webapp
description: A Helm chart for Kubernetes
type: application
version: 0.1.0        # Chart version
appVersion: "1.16.0"   # Application version
```

### values.yaml - Default Configuration
```yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
```

### templates/ - Kubernetes Manifests
Templates use Go templating with Helm functions to generate Kubernetes YAML.

## Deploy Your Chart
```bash
# Install the chart
helm install my-webapp ./webapp

# Check deployment
kubectl get pods,services

# View generated manifests (dry-run)
helm install my-webapp ./webapp --dry-run --debug

# Upgrade the chart
helm upgrade my-webapp ./webapp

# Rollback to previous version
helm rollback my-webapp 1
```

## Customize Your Chart
Edit `values.yaml` to change defaults:
```yaml
replicaCount: 3

image:
  repository: httpd
  tag: "2.4"

service:
  type: NodePort
  port: 8080
```

## Chart Commands
```bash
# Validate chart
helm lint ./webapp

# Package chart
helm package ./webapp

# Install from package
helm install my-webapp webapp-0.1.0.tgz
```

Next: Learn templating in `03-templating/`