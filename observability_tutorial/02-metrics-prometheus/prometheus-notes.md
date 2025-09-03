# Prometheus Metrics - Essential Guide

## What is Prometheus?
**Prometheus = Time-series database that scrapes metrics from your Kubernetes cluster**

## Quick Setup
```bash
# Install with Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring

# Access locally
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## The Four Metric Types

### 1. Counter 📈 (Only goes up)
```promql
http_requests_total{method="GET"} 15420
# Use rate() to get per-second: rate(http_requests_total[5m])
```

### 2. Gauge 📊 (Goes up and down)  
```promql
node_memory_usage_bytes 8589934592
# Use directly: avg(node_memory_usage_bytes)
```

### 3. Histogram 📊📈 (Buckets for percentiles)
```promql
# Use histogram_quantile() for percentiles
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### 4. Summary 📋 (Pre-calculated percentiles)
```promql
http_request_duration_seconds{quantile="0.95"} 0.245
```

## Essential PromQL Queries

### Cluster Health
```promql
# Targets up/down
up

# Running pods
count(kube_pod_status_phase{phase="Running"})

# Memory usage %
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# CPU usage %
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) * 100
```

### Application Monitoring
```promql
# Request rate
rate(http_requests_total[5m])

# Error rate %
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100

# Response time 95th percentile
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

## Command Line Queries (No UI Needed)

### Simple Query Script
```bash
# query.sh
QUERY="$1"
ENCODED=$(echo "$QUERY" | sed 's/ /%20/g' | sed 's/{/%7B/g' | sed 's/}/%7D/g')
curl -s "localhost:9090/api/v1/query?query=$ENCODED" | jq -r '.data.result[0].value[1]'

# Usage
bash query.sh "up"
bash query.sh "node_memory_MemAvailable_bytes"
```

### Dashboard Script
```bash
# Get cluster overview
echo "Memory: $(bash query.sh 'node_memory_MemAvailable_bytes') bytes available"
echo "Pods: $(bash query.sh 'count(kube_pod_status_phase{phase="Running"})') running"
echo "Targets: $(bash query.sh 'count(up == 1)')/$(bash query.sh 'count(up)') up"
```

## Key Patterns

### Golden Signals
- **Latency**: Response time percentiles
- **Traffic**: Request rate  
- **Errors**: Error rate percentage
- **Saturation**: Resource utilization

### RED Method (for services)
- **Rate**: `rate(http_requests_total[5m])`
- **Errors**: `rate(http_requests_total{status=~"5.."}[5m])`  
- **Duration**: `histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))`

### USE Method (for resources)
- **Utilization**: `avg(rate(node_cpu_seconds_total{mode!="idle"}[5m]))`
- **Saturation**: `node_load1`
- **Errors**: `rate(node_network_receive_errs_total[5m])`

## What You Get Out of the Box
- **Node metrics**: CPU, memory, disk, network
- **Kubernetes metrics**: Pods, deployments, services
- **Application metrics**: HTTP requests, errors, latency
- **System metrics**: Load, file descriptors, processes

## Real-World Alerts
```promql
# High memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 80

# High error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5

# Pod crashes
increase(kube_pod_container_status_restarts_total[5m]) > 0

# Disk space low
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 85
```

## The Bottom Line
- **Prometheus scrapes metrics** from your cluster automatically
- **PromQL queries** let you analyze and alert on data
- **No UI needed** - curl + scripts work great
- **Focus on the Golden Signals** for most use cases
- **Start simple** - up, memory, CPU, pod count

Prometheus gives you **numbers about your system**. Next step: **logs give you the story behind the numbers**.