# Helm Values & Configuration Management - Key Points

## The Main Concept
**One chart, multiple environments** - Use the same Helm chart with different configurations for dev/staging/production.

## Values Priority (Most Important!)
```
1. --set flags           (HIGHEST - overrides everything)
2. -f custom-values.yaml (MIDDLE - overrides defaults)  
3. Chart's values.yaml   (LOWEST - default values)
```

## Real-World Pattern
```bash
# Same chart, different environments
helm install myapp . -f environments/dev-values.yaml     # Development
helm install myapp . -f environments/staging-values.yaml # Staging  
helm install myapp . -f environments/prod-values.yaml    # Production

# Override specific values
helm install myapp . -f prod-values.yaml --set replicaCount=10
```

## Environment-Specific Values Structure
```yaml
# dev-values.yaml
replicaCount: 1
image:
  tag: "latest"
resources:
  requests:
    cpu: 100m

# prod-values.yaml  
replicaCount: 5
image:
  tag: "1.4"        # Stable version
service:
  type: LoadBalancer
resources:
  requests:
    cpu: 500m
```

## Key Commands
```bash
# Deploy with custom values
helm install app . -f prod-values.yaml

# Override single values
helm install app . --set replicaCount=3

# Multiple files (later overrides earlier)
helm install app . -f base.yaml -f prod.yaml

# See what values will be used
helm template app . -f prod-values.yaml

# Validate configuration
helm lint . -f prod-values.yaml
```

## Best Practices
1. **Structure values logically** (app, image, service, resources)
2. **Separate files per environment** (dev/staging/prod)
3. **Use meaningful defaults** in main values.yaml
4. **Never put secrets in values files** (use Kubernetes secrets)
5. **Validate with schema** for critical configurations

## Why This Matters
- **Same chart everywhere** - no environment-specific chart versions
- **Configuration as code** - track changes in git
- **Easy promotions** - promote same chart with different values
- **Consistent deployments** - reduce configuration drift

## The Bottom Line
Values management is how you make Helm charts reusable across environments. Master this, and you can deploy anywhere with confidence.