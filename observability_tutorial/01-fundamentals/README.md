# 01. Observability Fundamentals

## Observability vs Monitoring

### Traditional Monitoring
- **Reactive** - Tells you when something is broken
- **Known unknowns** - You monitor what you expect to fail
- **Limited scope** - Predefined metrics and alerts

### Observability  
- **Proactive** - Helps you understand why something broke
- **Unknown unknowns** - Discover issues you didn't expect
- **Full visibility** - Complete picture of system behavior

## The Three Pillars

### 1. Metrics 📊
**What**: Numerical data points over time
**Examples**: 
- CPU usage: 75%
- Request rate: 1000 req/sec  
- Error rate: 2.5%
- Response time: 250ms

**Use Cases**:
- Performance monitoring
- Capacity planning
- Alerting on thresholds
- Trend analysis

### 2. Logs 📝
**What**: Timestamped text records of events
**Examples**:
```
2024-01-15 10:30:45 INFO User login successful: user_id=12345
2024-01-15 10:30:46 ERROR Database connection failed: timeout after 5s
2024-01-15 10:30:47 WARN High memory usage: 85% of limit
```

**Use Cases**:
- Debugging specific issues
- Audit trails
- Security analysis
- Root cause analysis

### 3. Traces 🔍
**What**: Journey of a single request through distributed systems
**Example**:
```
Request → API Gateway → User Service → Database
   50ms      120ms        200ms        80ms
```

**Use Cases**:
- Performance bottlenecks
- Service dependencies
- Error propagation
- Latency analysis

## Kubernetes Observability Challenges

### 1. Dynamic Nature
- Pods come and go
- IP addresses change
- Services scale up/down
- **Solution**: Service discovery and labels

### 2. Distributed Systems
- Multiple services interact
- Complex request flows
- Failure cascades
- **Solution**: Distributed tracing

### 3. Container Ephemeral Nature
- Containers are temporary
- Logs disappear with containers
- State is not persistent
- **Solution**: Centralized logging

### 4. Scale and Complexity
- Hundreds of microservices
- Thousands of pods
- Massive data volumes
- **Solution**: Efficient aggregation and sampling

## Observability Stack Overview

### Metrics Stack
```
Applications → Prometheus → Grafana → Alerts
     ↓              ↓          ↓         ↓
   Expose       Collect    Visualize   Notify
   metrics      & store    & query    operators
```

### Logging Stack  
```
Applications → Fluentd → Elasticsearch → Kibana
     ↓            ↓           ↓            ↓
   Generate    Collect     Store &       Search &
    logs       & parse     index        visualize
```

### Tracing Stack
```
Applications → Jaeger Agent → Jaeger Collector → Jaeger UI
     ↓              ↓              ↓               ↓
  Instrument    Receive        Store &          Visualize
   requests      traces        analyze          traces
```

## Key Concepts

### Labels and Tags
**Purpose**: Add context to metrics, logs, and traces
```yaml
# Kubernetes labels become metric labels
metadata:
  labels:
    app: user-service
    version: v1.2.0
    environment: production
```

### Service Level Indicators (SLIs)
**What**: Metrics that matter to users
- **Availability**: 99.9% uptime
- **Latency**: 95% of requests < 200ms  
- **Throughput**: Handle 1000 req/sec
- **Error Rate**: < 0.1% errors

### Service Level Objectives (SLOs)
**What**: Target values for SLIs
- "99.9% of API requests should complete in < 500ms"
- "Service should be available 99.95% of the time"

### Golden Signals (The Four)
1. **Latency** - How long requests take
2. **Traffic** - How much demand on system
3. **Errors** - Rate of failed requests  
4. **Saturation** - How "full" your service is

## Next Steps
Ready to dive into **Prometheus** for metrics collection and monitoring! 

We'll start by setting up Prometheus to collect metrics from your Kubernetes cluster and applications.