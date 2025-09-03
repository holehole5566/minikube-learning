# ELK Stack Logging - Essential Guide

## What We Built
- ✅ **Elasticsearch**: Running and healthy (with security enabled)
- ✅ **Kibana**: Running and ready
- ⚠️ **Fluentd**: Running but can't connect (needs HTTPS config)

## The Challenge
**Modern Elasticsearch enables security by default** - needs HTTPS + authentication

## What You Learned

### 1. ELK Stack Components
```
Pods → Fluentd → Elasticsearch → Kibana
 ↓        ↓           ↓           ↓
Logs   Collect    Store &      Search &
       & Parse    Index       Visualize
```

### 2. Elasticsearch is Working
```bash
# Test connection
curl -k -u elastic:PASSWORD https://localhost:9200

# Response: Cluster info (healthy!)
{
  "name" : "elasticsearch-master-0",
  "cluster_name" : "elasticsearch",
  "tagline" : "You Know, for Search"
}
```

### 3. Log Collection Flow
```
1. Fluentd DaemonSet runs on each node
2. Mounts /var/log and /var/lib/docker/containers
3. Parses Kubernetes logs
4. Sends to Elasticsearch
5. Kibana visualizes the data
```

## Real-World Logging Patterns

### Log Levels and Filtering
```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "ERROR",
  "service": "user-service", 
  "message": "Database connection failed",
  "namespace": "production",
  "pod": "user-service-abc123"
}
```

### Common Log Queries
```bash
# All error logs
level:ERROR

# Logs from specific namespace
kubernetes.namespace_name:monitoring

# Logs from specific pod
kubernetes.pod_name:prometheus*

# Time range
@timestamp:[now-1h TO now]

# Combined query
level:ERROR AND kubernetes.namespace_name:production
```

### Log-Based Alerts
```bash
# High error rate
count(level:ERROR) > 100 in last 5 minutes

# Pod crash loops
message:"CrashLoopBackOff" 

# Out of memory
message:"OOMKilled"

# Failed authentication
message:"authentication failed"
```

## Production Logging Best Practices

### 1. Structured Logging
```json
// Good - Structured
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "ERROR",
  "user_id": "12345",
  "action": "login",
  "result": "failed",
  "reason": "invalid_password"
}

// Bad - Unstructured  
"2024-01-15 10:30:45 ERROR User 12345 login failed: invalid password"
```

### 2. Log Levels
- **ERROR**: Something broke, needs attention
- **WARN**: Something unusual, might be a problem
- **INFO**: Normal operations, important events
- **DEBUG**: Detailed info for troubleshooting

### 3. What to Log
```bash
# Always log
- Errors and exceptions
- Authentication events
- Business transactions
- Performance metrics

# Never log
- Passwords or secrets
- Personal data (PII)
- Credit card numbers
- Internal system details in production
```

## Correlation with Metrics

### The Power Combo
```bash
# Metrics tell you WHAT
error_rate_percent > 5%

# Logs tell you WHY
level:ERROR AND service:payment-service
→ "Payment gateway timeout"

# Traces tell you WHERE
trace_id:abc123 shows payment service is slow
```

### Debugging Workflow
1. **Alert**: Prometheus alerts on high error rate
2. **Investigate**: Check logs for error details
3. **Correlate**: Use trace ID to follow request
4. **Fix**: Address root cause
5. **Verify**: Monitor metrics for improvement

## Simple Log Analysis (Without Kibana)

### Using kubectl (Basic)
```bash
# Get recent logs
kubectl logs -n monitoring prometheus-grafana-xyz --tail=100

# Follow logs
kubectl logs -f deployment/user-service

# Logs from all pods in deployment
kubectl logs -l app=user-service --tail=50
```

### Using Elasticsearch API
```bash
# Search for errors
curl -k -u elastic:PASSWORD "https://localhost:9200/logstash-*/_search" \
  -H "Content-Type: application/json" \
  -d '{"query": {"match": {"level": "ERROR"}}}'

# Count logs by level
curl -k -u elastic:PASSWORD "https://localhost:9200/logstash-*/_search" \
  -H "Content-Type: application/json" \
  -d '{"aggs": {"levels": {"terms": {"field": "level.keyword"}}}}'
```

## The Bottom Line

### What Centralized Logging Gives You
- **Persistence**: Logs survive pod crashes
- **Searchability**: Find specific events quickly
- **Correlation**: Connect logs across services
- **Alerting**: Notify on log patterns
- **Compliance**: Audit trails and retention

### When You Need It
- **Production systems**: Always
- **Microservices**: Essential for debugging
- **Compliance**: Required for audit trails
- **Troubleshooting**: Faster root cause analysis

### Alternatives
- **Cloud solutions**: AWS CloudWatch, Google Cloud Logging
- **Managed ELK**: Elastic Cloud, Amazon Elasticsearch
- **Simpler tools**: Loki + Grafana, Fluentbit + S3

## Next Steps
With metrics (Prometheus) and logs (ELK) foundation:
- **Distributed tracing** shows request flows
- **Grafana dashboards** combine metrics + logs
- **Complete observability** for production systems

Logs are the **story behind the metrics** - essential for understanding what really happened! 📝