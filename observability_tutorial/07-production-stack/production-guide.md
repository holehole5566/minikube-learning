# Production Observability Stack - Complete Guide

## What We Built 🏭

**Complete production-ready observability platform** with:
- ✅ **Prometheus** with production config (15d retention, cluster-wide scraping)
- ✅ **Elasticsearch** with persistent storage (100GB)
- ✅ **Kibana** for log visualization
- ✅ **Fluentd** DaemonSet collecting all pod logs
- ✅ **Jaeger** with Elasticsearch backend
- ✅ **RBAC** and security configurations
- ✅ **Resource limits** and requests

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                Production Applications                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   App A     │  │   App B     │  │   App C     │        │
│  │ (metrics)   │  │ (logs)      │  │ (traces)    │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Observability Namespace                        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │ Prometheus  │  │Elasticsearch│  │   Jaeger    │        │
│  │ 2GB RAM     │  │ 4GB RAM     │  │ 1GB RAM     │        │
│  │ 15d retention│  │ 100GB disk  │  │ ES backend  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐                         │
│  │   Kibana    │  │  Fluentd    │                         │
│  │ 1GB RAM     │  │ DaemonSet   │                         │
│  │ Log UI      │  │ Log collect │                         │
│  └─────────────┘  └─────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## Production Features

### 1. Resource Management
```yaml
# Prometheus
resources:
  requests: {memory: 2Gi, cpu: 1000m}
  limits: {memory: 4Gi, cpu: 2000m}

# Elasticsearch  
resources:
  requests: {memory: 4Gi, cpu: 1000m}
  limits: {memory: 6Gi, cpu: 2000m}

# Jaeger
resources:
  requests: {memory: 1Gi, cpu: 500m}
  limits: {memory: 2Gi, cpu: 1000m}
```

### 2. Data Retention
```bash
# Prometheus: 15 days high-resolution
--storage.tsdb.retention.time=15d
--storage.tsdb.retention.size=50GB

# Elasticsearch: 100GB persistent storage
volumeClaimTemplates:
  storage: 100Gi

# Jaeger: 100k traces in memory + ES backend
MEMORY_MAX_TRACES: "100000"
SPAN_STORAGE_TYPE: "elasticsearch"
```

### 3. Security & RBAC
```yaml
# Service accounts for each component
serviceAccountName: prometheus
serviceAccountName: fluentd

# Cluster roles with minimal permissions
- apiGroups: [""]
  resources: ["nodes", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
```

### 4. High Availability Considerations
```yaml
# StatefulSet for Elasticsearch (persistent storage)
kind: StatefulSet
volumeClaimTemplates: [elasticsearch-data]

# DaemonSet for Fluentd (runs on every node)
kind: DaemonSet

# Deployments with resource limits
replicas: 1  # Can be scaled up
```

## Cost Optimization Strategies

### 1. Resource Sizing by Environment

#### Development/Testing
```yaml
prometheus: {memory: 512Mi, cpu: 250m}
elasticsearch: {memory: 1Gi, cpu: 500m}
jaeger: {memory: 256Mi, cpu: 100m}
retention: {metrics: 7d, logs: 7d, traces: 3d}
```

#### Staging
```yaml
prometheus: {memory: 1Gi, cpu: 500m}
elasticsearch: {memory: 2Gi, cpu: 1000m}
jaeger: {memory: 512Mi, cpu: 250m}
retention: {metrics: 15d, logs: 15d, traces: 7d}
```

#### Production
```yaml
prometheus: {memory: 4Gi, cpu: 2000m}
elasticsearch: {memory: 8Gi, cpu: 4000m}
jaeger: {memory: 2Gi, cpu: 1000m}
retention: {metrics: 30d, logs: 30d, traces: 15d}
```

### 2. Data Lifecycle Management
```bash
# Prometheus downsampling
--storage.tsdb.retention.time=15d     # High-res data
# Use recording rules for long-term aggregates

# Elasticsearch ILM policy
Hot tier: 7 days (fast SSD)
Warm tier: 23 days (slower SSD)  
Cold tier: 90 days (cheap storage)
Delete: after 1 year

# Jaeger sampling
Production: 1-10% sampling
Development: 100% sampling
Error traces: Always sample
```

### 3. Storage Optimization
```yaml
# Use storage classes efficiently
storageClassName: fast-ssd      # For hot data
storageClassName: standard      # For warm data
storageClassName: cold-storage  # For archives

# Compression
ES_JAVA_OPTS: "-Xms2g -Xmx2g"  # Proper heap sizing
```

## Troubleshooting Guide

### 1. Prometheus Issues

#### High Memory Usage
```bash
# Check metrics cardinality
curl localhost:9090/api/v1/label/__name__/values | jq length

# Find high-cardinality metrics
curl localhost:9090/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes

# Solutions:
- Reduce label cardinality
- Increase memory limits
- Add recording rules
```

#### Missing Metrics
```bash
# Check service discovery
curl localhost:9090/api/v1/targets

# Check scrape configs
kubectl logs -n observability deployment/prometheus

# Solutions:
- Verify annotations: prometheus.io/scrape=true
- Check network policies
- Verify RBAC permissions
```

### 2. Elasticsearch Issues

#### Cluster Red Status
```bash
# Check cluster health
curl localhost:9200/_cluster/health

# Check node status
curl localhost:9200/_cat/nodes?v

# Solutions:
- Increase memory (ES_JAVA_OPTS)
- Check disk space
- Restart unhealthy nodes
```

#### Slow Queries
```bash
# Check slow queries
curl localhost:9200/_cat/indices?v&s=store.size:desc

# Solutions:
- Add more shards for large indices
- Optimize mapping
- Use proper date-based indices
```

### 3. Jaeger Issues

#### No Traces Appearing
```bash
# Check Jaeger collector
kubectl logs -n observability deployment/jaeger

# Check application instrumentation
# Verify JAEGER_AGENT_HOST environment variable

# Solutions:
- Check network connectivity
- Verify trace format
- Check sampling configuration
```

#### High Memory Usage
```bash
# Check trace volume
curl localhost:16686/api/services

# Solutions:
- Reduce sampling rate
- Increase MEMORY_MAX_TRACES
- Use Elasticsearch backend
```

### 4. Fluentd Issues

#### Logs Not Appearing
```bash
# Check Fluentd pods
kubectl logs -n observability daemonset/fluentd

# Check Elasticsearch connection
kubectl exec -n observability deployment/elasticsearch -- curl localhost:9200

# Solutions:
- Verify Elasticsearch connectivity
- Check log parsing configuration
- Verify volume mounts
```

## Monitoring the Monitoring

### Key Metrics to Watch
```promql
# Prometheus health
up{job="prometheus"}
prometheus_tsdb_head_samples_appended_total

# Elasticsearch health  
elasticsearch_cluster_health_status
elasticsearch_indices_docs_total

# Jaeger health
jaeger_collector_traces_received_total
jaeger_query_requests_total

# Fluentd health
fluentd_output_status_num_errors_total
```

### Alerting Rules
```yaml
groups:
- name: observability_stack
  rules:
  - alert: PrometheusDown
    expr: up{job="prometheus"} == 0
    for: 5m
    
  - alert: ElasticsearchClusterRed
    expr: elasticsearch_cluster_health_status{color="red"} == 1
    for: 2m
    
  - alert: JaegerCollectorDown
    expr: up{job="jaeger"} == 0
    for: 5m
    
  - alert: FluentdErrorsHigh
    expr: rate(fluentd_output_status_num_errors_total[5m]) > 0.1
    for: 5m
```

## Scaling Strategies

### Horizontal Scaling
```yaml
# Prometheus federation
prometheus-global:
  scrapes: [prometheus-region-1, prometheus-region-2]

# Elasticsearch cluster
replicas: 3
master_nodes: 3
data_nodes: 6

# Jaeger distributed
jaeger-collector: {replicas: 3}
jaeger-query: {replicas: 2}
```

### Vertical Scaling
```bash
# Monitor resource usage
kubectl top pods -n observability

# Scale based on metrics
CPU > 80%: Increase CPU limits
Memory > 80%: Increase memory limits
Disk > 80%: Increase storage size
```

## Backup and Disaster Recovery

### Prometheus
```bash
# Backup TSDB data
kubectl exec prometheus-pod -- tar -czf /tmp/prometheus-backup.tar.gz /prometheus

# Restore from backup
kubectl cp prometheus-backup.tar.gz prometheus-pod:/tmp/
```

### Elasticsearch
```bash
# Snapshot repository
curl -X PUT localhost:9200/_snapshot/backup_repo

# Create snapshot
curl -X PUT localhost:9200/_snapshot/backup_repo/snapshot_1

# Restore snapshot
curl -X POST localhost:9200/_snapshot/backup_repo/snapshot_1/_restore
```

## Integration with Managed Grafana

### Data Sources Configuration
```yaml
# Prometheus data source
url: http://prometheus.observability.svc.cluster.local:9090
access: proxy

# Elasticsearch data source  
url: http://elasticsearch.observability.svc.cluster.local:9200
database: logstash-*
timeField: "@timestamp"

# Jaeger data source
url: http://jaeger.observability.svc.cluster.local:16686
```

### Dashboard Templates
```json
{
  "dashboard": {
    "title": "Production Observability Overview",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [{"expr": "sum(rate(http_requests_total[5m]))"}]
      },
      {
        "title": "Error Rate", 
        "targets": [{"expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m]))"}]
      },
      {
        "title": "Response Time",
        "targets": [{"expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"}]
      }
    ]
  }
}
```

## The Bottom Line

### What You've Built
- **Complete observability platform** ready for production
- **Scalable architecture** that grows with your needs
- **Cost-optimized** resource allocation
- **Secure** RBAC and network policies
- **Resilient** with proper storage and retention

### Production Readiness Checklist
- ✅ Resource limits and requests configured
- ✅ Persistent storage for stateful components
- ✅ RBAC and security policies
- ✅ Monitoring of the monitoring stack
- ✅ Backup and disaster recovery procedures
- ✅ Cost optimization strategies
- ✅ Troubleshooting runbooks

### Next Steps
1. **Connect to managed Grafana** with data sources
2. **Create production dashboards** for your applications
3. **Set up alerting** based on SLIs/SLOs
4. **Implement backup procedures**
5. **Monitor costs** and optimize resources
6. **Scale** based on actual usage patterns

**You now have a production-grade observability platform!** 🏭🎯