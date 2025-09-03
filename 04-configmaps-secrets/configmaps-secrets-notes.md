# ConfigMaps & Secrets Notes

## Overview
- **ConfigMap**: Non-sensitive configuration data
- **Secret**: Sensitive data (passwords, tokens, keys)

## ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_url: "postgresql://localhost:5432/mydb"
  debug_mode: "true"
```

### Characteristics
- Plain text storage
- Key-value pairs
- Used for: URLs, feature flags, config files

## Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  username: YWRtaW4=  # admin (base64)
  password: cGFzc3dvcmQ=  # password (base64)
```

### Characteristics
- Base64 encoded (not encrypted!)
- Stored more securely in etcd
- Used for: passwords, API keys, certificates

## Using in Pods

### Environment Variables
```yaml
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database_url
- name: USERNAME
  valueFrom:
    secretKeyRef:
      name: app-secret
      key: username
```

### Volume Mounts (Alternative)
```yaml
volumes:
- name: config-volume
  configMap:
    name: app-config
- name: secret-volume
  secret:
    secretName: app-secret
```

## Commands
```bash
# Create resources
kubectl apply -f configmap.yaml

# View ConfigMap
kubectl get configmap app-config -o yaml

# View Secret (base64 encoded)
kubectl get secret app-secret -o yaml

# Decode secret manually
echo "YWRtaW4=" | base64 -d  # Returns: admin
```

## Best Practices
- Use ConfigMaps for non-sensitive config
- Use Secrets for passwords/tokens
- Separate config from application code
- Update configs without rebuilding images
- Consider external secret management for production