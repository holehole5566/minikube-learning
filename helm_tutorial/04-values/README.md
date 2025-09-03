# 04. Values & Configuration Management

## Values Hierarchy (Priority Order)
1. **Command line** `--set` flags (highest priority)
2. **Custom values file** `-f values.yaml`
3. **Chart's values.yaml** (default values)

## Default values.yaml Structure
```yaml
# Application configuration
app:
  name: webapp
  version: "1.0.0"

# Image configuration
image:
  repository: nginx
  tag: "1.21"
  pullPolicy: IfNotPresent

# Deployment configuration
replicaCount: 1
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 8080

# Ingress configuration
ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

# Environment-specific configs
environment: development
config:
  database:
    host: localhost
    port: 5432
    name: webapp_db
  redis:
    host: localhost
    port: 6379
```

## Override Values Methods

### Method 1: Command Line --set
```bash
# Single value
helm install webapp ./webapp --set replicaCount=3

# Multiple values
helm install webapp ./webapp \
  --set replicaCount=3 \
  --set image.tag=2.0 \
  --set service.type=NodePort

# Nested values
helm install webapp ./webapp --set config.database.host=postgres.example.com

# Arrays
helm install webapp ./webapp --set ingress.hosts[0].host=myapp.local
```

### Method 2: Custom Values File
```bash
# Create custom values
cat > production-values.yaml << EOF
replicaCount: 5

image:
  tag: "2.0"

service:
  type: LoadBalancer

ingress:
  enabled: true
  hosts:
    - host: myapp.production.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
EOF

# Install with custom values
helm install webapp ./webapp -f production-values.yaml
```

### Method 3: Multiple Values Files
```bash
# Base + environment specific
helm install webapp ./webapp \
  -f values.yaml \
  -f environments/production.yaml \
  -f secrets/production-secrets.yaml
```

## Environment-Specific Configurations

### Development (dev-values.yaml)
```yaml
replicaCount: 1
image:
  tag: "latest"
service:
  type: ClusterIP
ingress:
  enabled: false
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

### Staging (staging-values.yaml)
```yaml
replicaCount: 2
image:
  tag: "1.5"
service:
  type: ClusterIP
ingress:
  enabled: true
  hosts:
    - host: myapp-staging.company.com
resources:
  requests:
    cpu: 250m
    memory: 256Mi
```

### Production (prod-values.yaml)
```yaml
replicaCount: 5
image:
  tag: "1.4"  # Stable version
service:
  type: LoadBalancer
ingress:
  enabled: true
  hosts:
    - host: myapp.company.com
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.company.com
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

## Values Validation

### Schema Validation (values.schema.json)
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1,
      "maximum": 10
    },
    "image": {
      "type": "object",
      "properties": {
        "repository": {"type": "string"},
        "tag": {"type": "string"}
      },
      "required": ["repository", "tag"]
    }
  },
  "required": ["replicaCount", "image"]
}
```

## Values Commands
```bash
# Show computed values
helm get values webapp

# Show all values (including defaults)
helm get values webapp --all

# Validate values against schema
helm lint ./webapp -f production-values.yaml

# Show what values would be used
helm template webapp ./webapp -f production-values.yaml --debug
```

## Best Practices
- Use meaningful nested structure
- Provide sensible defaults
- Document values with comments
- Use schema validation for critical values
- Keep environment-specific values in separate files
- Never put secrets in values files (use Kubernetes secrets)

Next: Learn chart dependencies in `05-dependencies/`