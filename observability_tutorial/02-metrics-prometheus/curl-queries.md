# Prometheus with curl - Command Line Queries

## Basic API Structure
```bash
# Query API endpoint
curl "localhost:9090/api/v1/query?query=PROMQL_QUERY"

# Pretty print JSON
curl -s "localhost:9090/api/v1/query?query=up" | jq .
```

## Essential Queries to Try

### 1. Check What's Being Monitored
```bash
# All targets status
curl -s "localhost:9090/api/v1/query?query=up" | jq '.data.result[] | {job: .metric.job, instance: .metric.instance, status: .value[1]}'
```

### 2. Kubernetes Cluster Health
```bash
# Running pods count
curl -s "localhost:9090/api/v1/query?query=count(kube_pod_status_phase{phase=\"Running\"})" | jq '.data.result[0].value[1]'

# Node status
curl -s "localhost:9090/api/v1/query?query=kube_node_status_condition{condition=\"Ready\",status=\"true\"}" | jq '.data.result[].metric.node'
```

### 3. Resource Usage
```bash
# CPU usage percentage
curl -s "localhost:9090/api/v1/query?query=avg(rate(node_cpu_seconds_total{mode!=\"idle\"}[5m]))*100" | jq '.data.result[0].value[1]'

# Memory usage percentage  
curl -s "localhost:9090/api/v1/query?query=(1-(node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes))*100" | jq '.data.result[0].value[1]'

# Disk usage
curl -s "localhost:9090/api/v1/query?query=node_filesystem_avail_bytes{fstype!=\"tmpfs\"}" | jq '.data.result[] | {device: .metric.device, available_bytes: .value[1]}'
```

### 4. Pod Information
```bash
# Pods by namespace
curl -s "localhost:9090/api/v1/query?query=kube_pod_info" | jq '.data.result[] | {namespace: .metric.namespace, pod: .metric.pod}'

# Pod memory usage
curl -s "localhost:9090/api/v1/query?query=container_memory_usage_bytes{container!=\"POD\",container!=\"\"}" | jq '.data.result[] | {pod: .metric.pod, container: .metric.container, memory_bytes: .value[1]}'
```

## Hands-On Practice

Let's run these step by step: