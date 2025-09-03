# Jaeger Distributed Tracing - Essential Guide

## What is Distributed Tracing?
**Distributed Tracing = Following a single request through multiple microservices**

Shows you the **complete journey** of a request and **where time is spent**.

## Quick Setup
```bash
# Deploy Jaeger all-in-one
kubectl apply -f jaeger-all-in-one.yaml

# Access UI and collector
kubectl port-forward -n monitoring svc/jaeger 16686:16686 &  # UI
kubectl port-forward -n monitoring svc/jaeger 14268:14268 &  # Collector

# Generate sample traces
bash simple-traces.sh

# View traces: http://localhost:16686
```

## Key Concepts

### Trace
**Complete request journey** with unique ID
```
Trace ID: abc123def456
Total Duration: 2.1s
Status: ERROR
Services: 4
```

### Span  
**Single operation** within a trace
```
Span: GET /api/users/123
Service: user-service
Duration: 120ms
Parent: api-gateway span
Children: database_query, cache_lookup
```

### Tags
**Searchable metadata** about spans
```
http.method: GET
http.status_code: 200
user.id: 123
error: true
service.name: user-service
```

### Logs
**Events within a span**
```
timestamp: 10:30:45.123
event: cache_miss
key: user:123
message: "Cache lookup failed, querying database"
```

## Trace Analysis Patterns

### 1. Performance Bottleneck
```
Request: 2.1s total
├── API Gateway: 50ms (2%)
├── User Service: 200ms (10%)  
└── Payment Service: 1.8s (86%) ← BOTTLENECK!
    └── External API: 1.7s ← ROOT CAUSE
```

### 2. Error Propagation
```
Request: FAILED
├── Order Service: SUCCESS
├── Payment Service: TIMEOUT ← ERROR STARTS HERE
│   └── External API: TIMEOUT
└── Error Response: 500
```

### 3. Service Dependencies
```
Frontend Request
├── Auth Service (required)
├── User Service → Database
├── Order Service → Payment Service → External API
└── Cache Service (optional)
```

## Real-World Use Cases

### Debugging Slow Requests
```bash
# 1. User reports: "Checkout is slow"
# 2. Search Jaeger: operation="POST /checkout" duration>2s
# 3. Find trace showing payment service taking 5s
# 4. Drill down: external payment API timeout
# 5. Fix: add timeout + retry logic
```

### Finding Error Sources
```bash
# 1. Metrics show 5% error rate
# 2. Search Jaeger: error=true
# 3. See errors starting in auth service
# 4. Check logs: "JWT token expired"
# 5. Fix: refresh token logic
```

### Capacity Planning
```bash
# 1. Trace shows database queries taking 800ms
# 2. Pattern: all slow during peak hours
# 3. Analysis: database CPU at 90%
# 4. Solution: scale database or add read replicas
```

## Jaeger UI Navigation

### Search Traces
```bash
Service: user-service          # Filter by service
Operation: GET /api/users      # Filter by operation  
Tags: error=true              # Filter by tags
Min Duration: 1s              # Performance issues
Max Duration: 10s             # Exclude timeouts
Lookback: 1h                  # Time range
```

### Trace View
- **Timeline**: Gantt chart of spans
- **Span Details**: Tags, logs, duration
- **Service Map**: Visual dependencies
- **Critical Path**: Longest spans highlighted

## The Observability Trinity

### How They Work Together
```bash
# 1. Metrics Alert (Prometheus)
error_rate > 5%

# 2. Find Specific Errors (Jaeger)  
Search: service=payment error=true
Result: Trace ID abc123

# 3. Get Detailed Context (Logs)
Search logs: trace_id=abc123
Result: "Payment gateway returned 503"

# Complete picture: External service is down
```

### When to Use Each
- **Metrics**: "Is there a problem?" (alerting)
- **Logs**: "What exactly happened?" (debugging)
- **Traces**: "Where in the flow?" (performance)

## Best Practices

### Span Naming
```bash
# Good
GET /api/users/{id}
database_query  
cache_lookup
external_api_call

# Bad
operation
function
process
```

### Essential Tags
```bash
# Always include
service.name, http.method, http.status_code, error

# Business context  
user.id, order.id, payment.amount, region
```

### Sampling Strategy
```bash
# Production
High traffic: 1-10% sampling
Low traffic: 100% sampling  
Errors: Always sample
```

## Common Trace Patterns

### Fan-out (Parallel)
```
Main Service
├── Service A (100ms) ║
├── Service B (150ms) ║ Parallel
├── Service C (80ms)  ║
└── Aggregate (20ms)
Total: 170ms (not 350ms!)
```

### Chain (Sequential)
```
Service A (100ms)
  → Service B (150ms)
    → Service C (80ms)
Total: 330ms
```

### Retry Pattern
```
Service A → Service B (timeout)
         → Service B (retry, timeout)  
         → Service B (retry, success)
```

## Production Monitoring

### Key Metrics from Traces
```bash
# Latency percentiles
P50, P95, P99 response times

# Error rates by service
Errors per service per minute

# Service dependencies
Which services call which

# Critical path analysis
Where most time is spent
```

### Alerting on Traces
```bash
# High latency
P95 > 2s for critical endpoints

# Error spikes  
Error rate > 5% for any service

# Dependency failures
External service timeouts
```

## The Bottom Line

### Distributed Tracing Gives You
- **End-to-end request visibility**
- **Performance bottleneck identification**  
- **Error source pinpointing**
- **Service dependency mapping**
- **Root cause analysis speed**

### Essential for
- **Microservices** (can't debug without it)
- **Performance optimization** (find the slow parts)
- **Error debugging** (trace error propagation)
- **Capacity planning** (understand load patterns)

### The Complete Observability Stack
1. **Prometheus**: Metrics and alerting
2. **ELK**: Logs and search
3. **Jaeger**: Traces and request flows
4. **Grafana**: Visualization and dashboards

**Together = Complete visibility into your distributed systems!** 🔍

## Quick Commands
```bash
# Check Jaeger status
bash trace-dashboard.sh

# Generate sample traces
bash simple-traces.sh

# Access UI
http://localhost:16686

# Search for slow requests
Service: any, Min Duration: 1s

# Search for errors  
Tags: error=true
```

Distributed tracing shows you **where your requests go and where they get stuck** - essential for modern microservices! 🚀