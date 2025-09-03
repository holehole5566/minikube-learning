# Ingress Notes

## Overview
Ingress provides HTTP/HTTPS routing to services based on hostnames and paths.

## Service Access Comparison

| Type | Access Method | Use Case |
|------|---------------|----------|
| **ClusterIP** | Internal only | Service-to-service communication |
| **NodePort** | `<node-ip>:<port>` | Direct external access |
| **Ingress** | `hostname/path` | HTTP routing with domains |

## Ingress Setup

### 1. Enable Ingress Controller
```bash
minikube addons enable ingress
```

### 2. Create Ingress Resource
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: webapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: webapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: webapp-service
            port:
              number: 8080
```

## Key Components

### Host-based Routing
- `webapp.local` → routes to specific service
- Multiple hosts can route to different services

### Path-based Routing
```yaml
paths:
- path: /api
  backend:
    service:
      name: api-service
- path: /web
  backend:
    service:
      name: web-service
```

### Annotations
- `nginx.ingress.kubernetes.io/rewrite-target: /` - URL rewriting
- `nginx.ingress.kubernetes.io/ssl-redirect: "false"` - Disable HTTPS redirect

## Testing Ingress

### Method 1: Host Header
```bash
curl -H "Host: webapp.local" http://192.168.49.2
```

### Method 2: DNS/Hosts File
```bash
# Add to /etc/hosts
192.168.49.2 webapp.local

# Then access normally
curl http://webapp.local
```

## Benefits
- **Domain-based routing**: Professional URLs
- **SSL termination**: Handle HTTPS certificates
- **Load balancing**: Distribute traffic across pods
- **Path routing**: Route different paths to different services
- **Single entry point**: One IP for multiple services

## Commands
```bash
# Check ingress status
kubectl get ingress

# Describe ingress details
kubectl describe ingress webapp-ingress

# Get ingress controller pods
kubectl get pods -n ingress-nginx
```

## Production Considerations
- Use real domain names
- Configure SSL certificates
- Set up proper DNS records
- Consider ingress controller scaling