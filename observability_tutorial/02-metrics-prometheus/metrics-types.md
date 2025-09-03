# Prometheus Metrics Types

## The Four Metric Types

### 1. Counter 📈
**What**: A value that only goes up (or resets to zero)
**Use Cases**: Requests, errors, bytes sent

```promql
# Examples
http_requests_total{method="GET", status="200"} 15420
http_requests_total{method="POST", status="500"} 23
node_network_transmit_bytes_total{device="eth0"} 1048576000
```

**Key Point**: Use `rate()` to get per-second rate
```promql
# Requests per second over last 5 minutes
rate(http_requests_total[5m])

# Error rate percentage
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100
```

### 2. Gauge 📊
**What**: A value that can go up and down
**Use Cases**: CPU usage, memory usage, temperature, queue size

```promql
# Examples
node_memory_MemAvailable_bytes 8589934592
node_cpu_usage_percent 75.2
kube_pod_status_ready{condition="true"} 1
container_memory_usage_bytes{pod="web-app-123"} 536870912
```

**Key Point**: Use directly or with functions like `avg()`, `max()`
```promql
# Average CPU usage across all nodes
avg(node_cpu_usage_percent)

# Maximum memory usage by pod
max(container_memory_usage_bytes) by (pod)
```

### 3. Histogram 📊📈
**What**: Samples observations and counts them in buckets
**Use Cases**: Request duration, response size

```promql
# Histogram creates multiple metrics:
http_request_duration_seconds_bucket{le="0.1"} 1000   # <= 100ms
http_request_duration_seconds_bucket{le="0.5"} 1500   # <= 500ms  
http_request_duration_seconds_bucket{le="1.0"} 1800   # <= 1s
http_request_duration_seconds_bucket{le="+Inf"} 2000  # All requests
http_request_duration_seconds_sum 450.5               # Total time
http_request_duration_seconds_count 2000              # Total requests
```

**Key Point**: Use `histogram_quantile()` for percentiles
```promql
# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Average response time
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

### 4. Summary 📋
**What**: Similar to histogram but calculates quantiles on client side
**Use Cases**: Request duration, response size (when you need exact quantiles)

```promql
# Summary creates these metrics:
http_request_duration_seconds{quantile="0.5"} 0.12    # 50th percentile
http_request_duration_seconds{quantile="0.9"} 0.25    # 90th percentile
http_request_duration_seconds{quantile="0.99"} 0.45   # 99th percentile
http_request_duration_seconds_sum 450.5               # Total time
http_request_duration_seconds_count 2000              # Total requests
```

## Real-World Examples

### Web Application Metrics
```promql
# Request Rate (Counter)
rate(http_requests_total[5m])

# Error Rate (Counter)
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])

# Response Time 95th percentile (Histogram)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Active Users (Gauge)
active_users_total

# Memory Usage (Gauge)
process_resident_memory_bytes
```

### Kubernetes Metrics
```promql
# Pod CPU Usage (Gauge)
rate(container_cpu_usage_seconds_total[5m])

# Pod Memory Usage (Gauge)  
container_memory_usage_bytes

# Pod Restart Count (Counter)
kube_pod_container_status_restarts_total

# Available Pods (Gauge)
kube_deployment_status_replicas_available
```

## Choosing the Right Type

### Use Counter When:
- Value only increases (requests, errors, bytes)
- You want to calculate rates
- You need to track totals over time

### Use Gauge When:
- Value can go up and down (CPU, memory, queue size)
- You want current state
- You need to track resource utilization

### Use Histogram When:
- You need percentiles (95th, 99th)
- You want to understand distribution
- Client-side calculation is expensive

### Use Summary When:
- You need exact quantiles
- You have limited bandwidth
- Server-side calculation is expensive

## Common Patterns

### Golden Signals
```promql
# Latency (Histogram)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Traffic (Counter)
rate(http_requests_total[5m])

# Errors (Counter)
rate(http_requests_total{status=~"5.."}[5m])

# Saturation (Gauge)
avg(node_cpu_usage_percent) > 80
```

### RED Method (Rate, Errors, Duration)
```promql
# Rate
rate(http_requests_total[5m])

# Errors  
rate(http_requests_total{status=~"5.."}[5m])

# Duration
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### USE Method (Utilization, Saturation, Errors)
```promql
# Utilization
avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)

# Saturation
node_load1 / count(node_cpu_seconds_total{mode="idle"}) by (instance)

# Errors
rate(node_network_receive_errs_total[5m])
```

## Next Steps
Now that you understand metric types, let's:
1. **Explore actual metrics** in your Prometheus instance
2. **Write PromQL queries** to analyze the data
3. **Create alerts** based on these metrics

Ready to query some real data! 🔍