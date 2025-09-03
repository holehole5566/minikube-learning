# Real-World Helm Application - E-commerce Example

## The Big Picture
**One chart, multiple microservices, multiple environments**

This shows how real companies structure Helm charts for complex applications.

## Application Architecture
```
Frontend (React) → User Service (Node.js) → Database (PostgreSQL)
                ↘ Order Service (Python) ↗     Cache (Redis)
```

## Chart Structure (The Key Pattern)
```
ecommerce/
├── Chart.yaml              # Dependencies
├── values.yaml             # Development defaults
├── values-production.yaml  # Production overrides
└── templates/
    ├── frontend/           # Frontend microservice
    ├── user-service/       # User API microservice  
    ├── order-service/      # Order API microservice
    └── hooks/              # Database migrations
```

## Real-World Patterns

### 1. Microservice Templates
**One directory per service** - keeps things organized
```yaml
# templates/user-service/deployment.yaml
- name: user-service
  image: "{{ .Values.images.userService.repository }}:{{ .Values.images.userService.tag }}"
  env:
  - name: DB_HOST
    value: {{ include "ecommerce.fullname" . }}-postgresql
```

### 2. Environment-Specific Values
```yaml
# Development (values.yaml)
postgresql:
  enabled: true          # Use internal database
scaling:
  userService:
    replicas: 2          # Small scale

# Production (values-production.yaml)  
postgresql:
  enabled: false         # Use external managed DB
externalDatabase:
  host: "prod-postgres.company.com"
scaling:
  userService:
    replicas: 10         # High scale
```

### 3. Service Discovery
**Services talk to each other by name**
```yaml
env:
- name: API_BASE_URL
  value: "http://{{ include "ecommerce.fullname" . }}-user-service:3000"
```

### 4. Database Migration Hook
```yaml
annotations:
  "helm.sh/hook": post-install,pre-upgrade
# Runs schema updates safely during deployments
```

## Deployment Commands

### Development
```bash
helm install ecommerce .
# Uses internal database, 2 replicas each service
```

### Production
```bash
helm install ecommerce . -f values-production.yaml
# Uses external database, 5-10 replicas, TLS, autoscaling
```

### Rolling Updates
```bash
helm upgrade ecommerce . --set images.userService.tag=1.5.3
# Updates just one service
```

## Key Results

### Development vs Production
```
Development:
- Internal PostgreSQL + Redis
- 2 replicas per service  
- Basic nginx images
- No ingress/TLS

Production:
- External managed database
- 5-10 replicas per service
- Custom application images  
- TLS + ingress + autoscaling
```

## Why This Matters

### Real Company Benefits
1. **Same chart everywhere** - no environment drift
2. **Modular services** - update independently  
3. **Proper scaling** - dev is small, prod is big
4. **Safe migrations** - hooks handle database changes
5. **Service mesh ready** - proper service discovery

### Best Practices Demonstrated
- **Separate templates per service** (maintainable)
- **Environment-specific values** (flexible)
- **External dependencies** (production-ready)
- **Resource management** (cost-effective)
- **Health checks** (reliable)

## The Bottom Line
This is how real companies deploy complex applications:
- **Microservices** in separate templates
- **Environment-specific** configurations
- **External services** in production
- **Automated migrations** with hooks
- **Proper scaling** and monitoring

Start simple, but this pattern scales to any size application!