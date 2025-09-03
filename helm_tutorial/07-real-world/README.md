# 07. Real-World Example - E-commerce Microservices

## Application Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   User Service  │    │  Order Service  │
│   (React SPA)   │    │   (Node.js)     │    │   (Python)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Gateway   │
                    │   (Nginx)       │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │     Redis       │    │   Monitoring    │
│   (Database)    │    │    (Cache)      │    │  (Prometheus)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Chart Structure
```
ecommerce/
├── Chart.yaml
├── values.yaml
├── values-production.yaml
├── values-staging.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── user-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── order-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── api-gateway/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   └── hooks/
│       ├── db-migration.yaml
│       └── seed-data.yaml
└── charts/  # Dependencies downloaded here
```

## Chart.yaml with Dependencies
```yaml
apiVersion: v2
name: ecommerce
description: E-commerce microservices platform
type: application
version: 1.0.0
appVersion: "2.1.0"

dependencies:
  # Database
  - name: postgresql
    version: "12.1.2"
    repository: "https://charts.bitnami.com/bitnami"
    condition: postgresql.enabled
    
  # Cache
  - name: redis
    version: "17.3.7"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
    
  # Monitoring
  - name: prometheus
    version: "15.18.0"
    repository: "https://prometheus-community.github.io/helm-charts"
    condition: monitoring.enabled
    
  # Ingress Controller
  - name: ingress-nginx
    version: "4.4.0"
    repository: "https://kubernetes.github.io/ingress-nginx"
    condition: ingress.enabled
```

## Production Values (values-production.yaml)
```yaml
# Global configuration
global:
  environment: production
  domain: ecommerce.company.com
  
# Application images
images:
  frontend:
    repository: myregistry/ecommerce-frontend
    tag: "2.1.0"
  userService:
    repository: myregistry/user-service
    tag: "1.5.2"
  orderService:
    repository: myregistry/order-service
    tag: "1.3.1"
  apiGateway:
    repository: nginx
    tag: "1.21"

# Scaling configuration
scaling:
  frontend:
    replicas: 3
    hpa:
      enabled: true
      minReplicas: 3
      maxReplicas: 10
      targetCPU: 70
  userService:
    replicas: 5
    hpa:
      enabled: true
      minReplicas: 5
      maxReplicas: 20
      targetCPU: 80
  orderService:
    replicas: 3
    hpa:
      enabled: true
      minReplicas: 3
      maxReplicas: 15
      targetCPU: 75

# Resource limits
resources:
  frontend:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  userService:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi
  orderService:
    requests:
      cpu: 150m
      memory: 200Mi
    limits:
      cpu: 800m
      memory: 800Mi

# Database configuration
postgresql:
  enabled: false  # Use external managed database
  
externalDatabase:
  host: prod-postgres.company.com
  port: 5432
  database: ecommerce_prod
  existingSecret: db-credentials

# Cache configuration  
redis:
  enabled: true
  auth:
    enabled: true
    existingSecret: redis-credentials
  master:
    persistence:
      enabled: true
      size: 8Gi
  replica:
    replicaCount: 2

# Ingress configuration
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
  hosts:
    - host: ecommerce.company.com
      paths:
        - path: /
          pathType: Prefix
          service: frontend
        - path: /api/users
          pathType: Prefix  
          service: user-service
        - path: /api/orders
          pathType: Prefix
          service: order-service
  tls:
    - secretName: ecommerce-tls
      hosts:
        - ecommerce.company.com

# Monitoring
monitoring:
  enabled: true
  prometheus:
    server:
      persistentVolume:
        size: 50Gi
    alertmanager:
      enabled: true
      
# Security
security:
  networkPolicies:
    enabled: true
  podSecurityPolicy:
    enabled: true
```

## User Service Deployment Template
```yaml
# templates/user-service/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "ecommerce.fullname" . }}-user-service
  labels:
    {{- include "ecommerce.labels" . | nindent 4 }}
    app.kubernetes.io/component: user-service
spec:
  {{- if not .Values.scaling.userService.hpa.enabled }}
  replicas: {{ .Values.scaling.userService.replicas }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "ecommerce.selectorLabels" . | nindent 6 }}
      app.kubernetes.io/component: user-service
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      labels:
        {{- include "ecommerce.selectorLabels" . | nindent 8 }}
        app.kubernetes.io/component: user-service
    spec:
      containers:
      - name: user-service
        image: "{{ .Values.images.userService.repository }}:{{ .Values.images.userService.tag }}"
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP
        env:
        - name: NODE_ENV
          value: {{ .Values.global.environment }}
        - name: DB_HOST
          {{- if .Values.postgresql.enabled }}
          value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
          {{- else }}
          value: {{ .Values.externalDatabase.host }}
          {{- end }}
        - name: DB_NAME
          {{- if .Values.postgresql.enabled }}
          value: {{ .Values.postgresql.auth.database }}
          {{- else }}
          value: {{ .Values.externalDatabase.database }}
          {{- end }}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              {{- if .Values.postgresql.enabled }}
              name: {{ include "postgresql.secretName" .Subcharts.postgresql }}
              key: postgres-password
              {{- else }}
              name: {{ .Values.externalDatabase.existingSecret }}
              key: password
              {{- end }}
        - name: REDIS_HOST
          value: {{ include "redis.fullname" .Subcharts.redis }}-master
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ .Values.redis.auth.existingSecret }}
              key: redis-password
        livenessProbe:
          httpGet:
            path: /health
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          {{- toYaml .Values.resources.userService | nindent 12 }}
```

## Database Migration Hook
```yaml
# templates/hooks/db-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "ecommerce.fullname" . }}-db-migration-{{ .Release.Revision }}"
  annotations:
    "helm.sh/hook": post-install,pre-upgrade
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: db-migration
        image: "{{ .Values.images.userService.repository }}:{{ .Values.images.userService.tag }}"
        command:
        - /bin/sh
        - -c
        - |
          echo "Running database migrations..."
          npm run migrate
          echo "Migrations completed successfully"
        env:
        - name: DB_HOST
          {{- if .Values.postgresql.enabled }}
          value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
          {{- else }}
          value: {{ .Values.externalDatabase.host }}
          {{- end }}
        - name: DB_NAME
          {{- if .Values.postgresql.enabled }}
          value: {{ .Values.postgresql.auth.database }}
          {{- else }}
          value: {{ .Values.externalDatabase.database }}
          {{- end }}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              {{- if .Values.postgresql.enabled }}
              name: {{ include "postgresql.secretName" .Subcharts.postgresql }}
              key: postgres-password
              {{- else }}
              name: {{ .Values.externalDatabase.existingSecret }}
              key: password
              {{- end }}
```

## Deployment Commands
```bash
# Development deployment
helm install ecommerce ./ecommerce \
  -f values.yaml \
  --set global.environment=development

# Staging deployment  
helm install ecommerce ./ecommerce \
  -f values-staging.yaml \
  --namespace staging \
  --create-namespace

# Production deployment
helm install ecommerce ./ecommerce \
  -f values-production.yaml \
  --namespace production \
  --create-namespace

# Rolling update
helm upgrade ecommerce ./ecommerce \
  -f values-production.yaml \
  --set images.userService.tag=1.5.3

# Rollback if needed
helm rollback ecommerce 1
```

## Best Practices Demonstrated
1. **Modular structure** with separate service templates
2. **Environment-specific values** files
3. **External dependencies** with conditions
4. **Resource management** with requests/limits
5. **Health checks** for all services
6. **Database migrations** with hooks
7. **Horizontal Pod Autoscaling** for scalability
8. **Ingress routing** for external access
9. **Security** with network policies
10. **Monitoring** integration

This real-world example shows how to structure a production-ready Helm chart for a complex microservices application! 🚀