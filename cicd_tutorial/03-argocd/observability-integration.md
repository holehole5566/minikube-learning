# Observability Integration with CI/CD

## The Answer to Your Question 🎯

### **Logs: Automatic ✅**
```bash
# Fluentd automatically collects ALL pod logs
# No configuration needed!

# Tekton logs → Your ELK stack
kubectl logs -n tekton-pipelines deployment/tekton-pipelines-controller

# ArgoCD logs → Your ELK stack  
kubectl logs -n argocd deployment/argocd-server

# Pipeline run logs → Your ELK stack
kubectl logs pipelinerun/simple-run-1756909236
```

### **Metrics: Manual Configuration Required ❌→✅**
```bash
# Before: Prometheus didn't know about new services
# After: Added scraping targets

# Tekton metrics now scraped from:
tekton-pipelines-controller.tekton-pipelines.svc.cluster.local:9090
tekton-events-controller.tekton-pipelines.svc.cluster.local:9090

# ArgoCD metrics now scraped from:
argocd-metrics.argocd.svc.cluster.local:8082
argocd-server-metrics.argocd.svc.cluster.local:8083
```

## What We Just Fixed

### **Updated Prometheus Config**
```yaml
# Added to prometheus.yml
scrape_configs:
  # Your existing configs...
  
  # NEW: Tekton metrics
  - job_name: 'tekton-pipelines'
    static_configs:
    - targets: 
      - 'tekton-pipelines-controller.tekton-pipelines.svc.cluster.local:9090'
  
  # NEW: ArgoCD metrics  
  - job_name: 'argocd'
    static_configs:
    - targets:
      - 'argocd-metrics.argocd.svc.cluster.local:8082'
```

## Key Metrics You Can Now Monitor

### **Tekton Pipeline Metrics**
```promql
# Pipeline success rate
sum(rate(tekton_pipelinerun_count{status="success"}[5m])) / sum(rate(tekton_pipelinerun_count[5m]))

# Pipeline duration
histogram_quantile(0.95, rate(tekton_pipelinerun_duration_seconds_bucket[5m]))

# Failed pipelines
sum(rate(tekton_pipelinerun_count{status="failed"}[5m]))

# Active pipeline runs
tekton_pipelinerun_count{status="running"}
```

### **ArgoCD Application Metrics**
```promql
# Application sync status
argocd_app_info{sync_status="Synced"}

# Out of sync applications
argocd_app_info{sync_status!="Synced"}

# Application health
argocd_app_info{health_status="Healthy"}

# Sync frequency
rate(argocd_app_reconcile_count[5m])
```

## The Rule for Future Services

### **Logs: Always Automatic** ✅
```bash
# Fluentd DaemonSet automatically collects logs from:
- All pods in all namespaces
- No configuration needed
- Logs appear in your ELK stack immediately
```

### **Metrics: Check and Configure** ⚙️
```bash
# For any new service, check:
1. Does it expose metrics? (look for :9090, :8080, :metrics ports)
2. Add scraping target to Prometheus config
3. Restart Prometheus

# Quick check command:
kubectl get svc -n <namespace> | grep -E "9090|8080|metrics"
```

## Verification Commands

### **Check Prometheus Targets**
```bash
# Port forward Prometheus (if not already)
kubectl port-forward -n observability svc/prometheus 9090:9090 &

# Check targets at: http://localhost:9090/targets
# Look for tekton-pipelines and argocd jobs
```

### **Check Available Metrics**
```bash
# Query Tekton metrics
curl "localhost:9090/api/v1/query?query=tekton_pipelinerun_count"

# Query ArgoCD metrics  
curl "localhost:9090/api/v1/query?query=argocd_app_info"
```

### **Check Logs in ELK**
```bash
# Tekton logs searchable in Kibana:
kubernetes.namespace_name:tekton-pipelines

# ArgoCD logs searchable in Kibana:
kubernetes.namespace_name:argocd

# Pipeline run logs:
kubernetes.pod_name:simple-run-*
```

## Summary

### **What Happens Automatically** ✅
- **All pod logs** collected by Fluentd
- **Basic Kubernetes metrics** (CPU, memory, pods)
- **Your application metrics** (if annotated)

### **What Needs Manual Config** ⚙️
- **Service-specific metrics** (Tekton, ArgoCD, etc.)
- **Custom dashboards** in Grafana
- **Alerting rules** for new metrics

### **Best Practice** 🎯
```bash
# When adding new services, always check:
kubectl get svc -n <namespace> | grep metrics

# If metrics exist, add to Prometheus config:
- job_name: 'service-name'
  static_configs:
  - targets: ['service.namespace.svc.cluster.local:port']
```

**Your CI/CD pipelines are now fully observable!** 📊🔍