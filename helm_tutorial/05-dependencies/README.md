# 05. Chart Dependencies

## What are Dependencies?
Dependencies allow you to include other charts as sub-charts, enabling you to build complex applications from reusable components.

## Chart.yaml Dependencies
```yaml
# Chart.yaml
apiVersion: v2
name: webapp
description: Web application with database
version: 0.1.0

dependencies:
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
  
  - name: redis
    version: "17.3.7"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
    
  - name: nginx
    version: "13.2.4"
    repository: "https://charts.bitnami.com/bitnami"
    alias: webserver
```

## Dependency Management Commands
```bash
# Download dependencies
helm dependency update

# List dependencies
helm dependency list

# Build dependencies (download and package)
helm dependency build
```

## Configure Dependencies in values.yaml
```yaml
# Main application config
app:
  name: webapp
  port: 3000

# PostgreSQL dependency configuration
postgresql:
  enabled: true
  auth:
    postgresPassword: "secretpassword"
    database: "webapp_db"
  primary:
    persistence:
      enabled: true
      size: 8Gi

# Redis dependency configuration  
redis:
  enabled: true
  auth:
    enabled: false
  master:
    persistence:
      enabled: false

# Nginx dependency (aliased as webserver)
webserver:
  enabled: true
  service:
    type: LoadBalancer
```

## Using Dependency Values in Templates
```yaml
# templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "webapp.fullname" . }}
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        env:
        {{- if .Values.postgresql.enabled }}
        - name: DB_HOST
          value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
        - name: DB_NAME
          value: {{ .Values.postgresql.auth.database }}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "postgresql.secretName" .Subcharts.postgresql }}
              key: postgres-password
        {{- end }}
        {{- if .Values.redis.enabled }}
        - name: REDIS_HOST
          value: {{ include "redis.fullname" .Subcharts.redis }}-master
        {{- end }}
```

## Conditional Dependencies
```yaml
# values.yaml - Environment-specific dependencies
# Development
postgresql:
  enabled: true
redis:
  enabled: false

# Production  
postgresql:
  enabled: false  # Use external managed database
redis:
  enabled: true

# External database configuration (when postgresql.enabled=false)
externalDatabase:
  host: "prod-postgres.company.com"
  port: 5432
  database: "webapp_prod"
  existingSecret: "db-credentials"
```

## Template with External vs Internal Database
```yaml
# templates/deployment.yaml
env:
{{- if .Values.postgresql.enabled }}
# Internal PostgreSQL
- name: DB_HOST
  value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "postgresql.secretName" .Subcharts.postgresql }}
      key: postgres-password
{{- else }}
# External database
- name: DB_HOST
  value: {{ .Values.externalDatabase.host }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.externalDatabase.existingSecret }}
      key: password
{{- end }}
```

## Local Dependencies (Sub-charts)
```bash
# Create local sub-chart
mkdir -p charts/database
helm create charts/database

# Chart.yaml (no repository needed for local charts)
dependencies:
  - name: database
    version: "0.1.0"
    # No repository - uses local charts/ directory
```

## Dependency Examples

### Full-Stack Application
```yaml
# Chart.yaml
dependencies:
  - name: postgresql    # Database
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
  
  - name: redis        # Cache
    version: "17.3.7" 
    repository: "https://charts.bitnami.com/bitnami"
    
  - name: nginx        # Reverse proxy
    version: "13.2.4"
    repository: "https://charts.bitnami.com/bitnami"
```

### Microservices with Shared Database
```yaml
# Chart.yaml
dependencies:
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    
  - name: user-service
    version: "0.1.0"
    # Local chart in charts/ directory
    
  - name: order-service  
    version: "0.1.0"
    # Local chart in charts/ directory
```

## Best Practices
- Pin dependency versions for reproducible builds
- Use conditions to enable/disable dependencies per environment
- Configure dependencies through values, not by modifying sub-charts
- Test with different dependency combinations
- Document required dependencies clearly
- Use aliases for multiple instances of same chart

## Troubleshooting
```bash
# Check dependency status
helm dependency list

# Update specific dependency
helm dependency update

# Clear dependency cache
rm -rf charts/ Chart.lock
helm dependency update
```

Next: Learn hooks and lifecycle management in `06-hooks/`