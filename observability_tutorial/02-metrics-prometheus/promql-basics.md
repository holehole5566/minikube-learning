# PromQL Basics - Essential Queries

## Access Prometheus
- **SSH Tunnel**: `ssh -L 9090:localhost:9090 ec2-user@YOUR_EC2_IP`
- **Direct**: Add port 9090 to EC2 security group, then `http://YOUR_EC2_IP:9090`

## Essential PromQL Queries

### 1. Basic Queries
```promql
# Check if targets are up
up

# All available metrics
{__name__=~".+"}

# Specific metric
node_cpu_seconds_total
```

### 2. Kubernetes Cluster Health
```promql
# Pod status
kube_pod_status_phase

# Running pods only
kube_pod_status_phase{phase="Running"}

# Pods by namespace
kube_pod_info{namespace="monitoring"}

# Node status
kube_node_status_condition{condition="Ready", status="true"}
```

### 3. Resource Usage
```promql
# CPU usage per pod (rate over 5 minutes)
rate(container_cpu_usage_seconds_total[5m])

# Memory usage by pod
container_memory_usage_bytes{container!="POD", container!=""}

# Disk usage
node_filesystem_avail_bytes{fstype!="tmpfs"}

# Network traffic
rate(node_network_receive_bytes_total[5m])
```

### 4. Application Metrics
```promql
# HTTP request rate
rate(prometheus_http_requests_total[5m])

# HTTP errors
rate(prometheus_http_requests_total{code=~"5.."}[5m])

# Request duration 95th percentile
histogram_quantile(0.95, rate(prometheus_http_request_duration_seconds_bucket[5m]))
```

### 5. Aggregation Functions
```promql
# Average CPU across all nodes
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m]))

# Maximum memory usage by pod
max(container_memory_usage_bytes) by (pod)

# Sum of network traffic
sum(rate(node_network_receive_bytes_total[5m])) by (device)

# Count running pods
count(kube_pod_status_phase{phase="Running"})
```

### 6. Filtering and Grouping
```promql
# Filter by labels
container_memory_usage_bytes{namespace="monitoring"}

# Regex matching
kube_pod_info{pod=~"prometheus.*"}

# Group by labels
sum(container_memory_usage_bytes) by (namespace)

# Multiple conditions
kube_pod_status_phase{phase="Running", namespace!="kube-system"}
```

## Try These Queries

### Cluster Overview
```promql
# 1. How many pods are running?
count(kube_pod_status_phase{phase="Running"})

# 2. CPU usage by node
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) * 100

# 3. Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# 4. Disk usage percentage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100
```

### Monitoring Stack Health
```promql
# 1. Prometheus targets up
up{job="prometheus"}

# 2. Prometheus query rate
rate(prometheus_engine_queries_total[5m])

# 3. Grafana status
up{job="grafana"}

# 4. AlertManager status
up{job="alertmanager"}
```

## Common Patterns

### Rate Calculations
```promql
# Always use rate() with counters
rate(metric_total[5m])  # Per-second rate over 5 minutes

# For gauges, use directly
node_memory_usage_bytes
```

### Time Ranges
```promql
# 5 minutes
[5m]

# 1 hour  
[1h]

# 1 day
[1d]
```

### Mathematical Operations
```promql
# Percentage
(metric_used / metric_total) * 100

# Difference
metric_now - metric_5m_ago

# Ratio
metric_errors / metric_total
```

## Quick Test Commands

### Via curl (from EC2)
```bash
# Basic query
curl "localhost:9090/api/v1/query?query=up"

# Pod count
curl "localhost:9090/api/v1/query?query=count(kube_pod_status_phase{phase=\"Running\"})"

# CPU usage
curl "localhost:9090/api/v1/query?query=avg(rate(node_cpu_seconds_total{mode!=\"idle\"}[5m]))*100"
```

## Next Steps
1. **Access Prometheus UI** using SSH tunnel or security group
2. **Try these queries** in the Graph tab
3. **Explore your metrics** - see what's available
4. **Create alerts** based on important thresholds

The real power comes from the UI where you can visualize these queries! 📊