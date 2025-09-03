# Application Performance Monitoring - Complete Guide

## What is APM?
**APM = Monitoring your applications from the inside, focusing on business metrics and user experience**

Goes beyond "CPU is 80%" to "Payment processing is slow, causing revenue loss"

## The APM Stack

### 1. Custom Metrics 📊
**Business and application-specific measurements**
```python
# Business metrics
orders_created_total.inc()
revenue_dollars.observe(99.99)
user_signups_total.labels(source='mobile').inc()

# Performance metrics
request_duration.observe(0.245)
database_queries_total.inc()
cache_hit_ratio.set(0.85)
```

### 2. Health Checks 🏥
**Application readiness for Kubernetes**
```python
@app.route('/startup')  # Is app starting?
@app.route('/ready')    # Can serve traffic?
@app.route('/health')   # Still alive?
```

### 3. SLIs/SLOs 🎯
**Service level indicators and objectives**
```bash
SLI: What we measure
- Availability: 99.9% uptime
- Latency: 95% of requests < 200ms
- Error Rate: < 0.1% errors

SLO: What we promise
- "99.9% of API requests will succeed"
- "95% of requests complete in < 500ms"
```

## Real-World Implementation

### E-commerce Application Metrics
```python
# Revenue tracking
revenue_total = Counter('revenue_dollars_total', 'Total revenue', ['product_category'])
orders_total = Counter('orders_total', 'Total orders', ['status'])
cart_abandonment = Counter('cart_abandonment_total', 'Cart abandonments', ['step'])

# User behavior  
user_signups = Counter('user_signups_total', 'User signups', ['source'])
feature_usage = Counter('feature_usage_total', 'Feature usage', ['feature_name'])

# Performance
checkout_duration = Histogram('checkout_duration_seconds', 'Checkout time')
payment_success_rate = Gauge('payment_success_rate', 'Payment success rate')
```

### Health Check Implementation
```python
@app.route('/ready')
def ready():
    checks = {}
    all_ready = True
    
    # Check database
    db_ok, db_msg = check_database()
    checks['database'] = {'status': 'ok' if db_ok else 'error', 'message': db_msg}
    if not db_ok:
        all_ready = False
    
    # Check cache
    cache_ok, cache_msg = check_cache()
    checks['cache'] = {'status': 'ok' if cache_ok else 'error', 'message': cache_msg}
    if not cache_ok:
        all_ready = False
    
    status_code = 200 if all_ready else 503
    return jsonify({'status': 'ready' if all_ready else 'not_ready', 'checks': checks}), status_code
```

### Kubernetes Integration
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apm-app
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
```

## SLI/SLO Implementation

### Defining SLIs
```python
# Availability SLI
availability_sli = successful_requests / total_requests

# Latency SLI (95th percentile under 500ms)
latency_sli = requests_under_500ms / total_requests

# Error Rate SLI
error_rate_sli = error_requests / total_requests
```

### Setting SLOs
```yaml
slos:
  availability:
    target: 99.9%    # 99.9% of requests succeed
    window: 30d      # Over 30 days
    
  latency:
    target: 95%      # 95% of requests under 500ms
    threshold: 500ms
    window: 7d
    
  error_rate:
    target: 99.5%    # 0.5% error rate maximum
    window: 24h
```

### Error Budget Management
```python
def calculate_error_budget(slo_target, time_window_hours, current_sli):
    error_budget_total = (1 - slo_target) * time_window_hours * 3600
    current_error_rate = 1 - current_sli
    errors_consumed = current_error_rate * time_window_hours * 3600
    error_budget_remaining = max(0, error_budget_total - errors_consumed)
    
    return {
        'total_budget': error_budget_total,
        'consumed': errors_consumed,
        'remaining': error_budget_remaining,
        'percentage_remaining': (error_budget_remaining / error_budget_total) * 100
    }
```

## Integration with Managed Grafana

### Dashboard Queries
```promql
# Availability SLI
sum(rate(http_requests_total{status!~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Latency SLI (percentage under threshold)
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m])) / sum(rate(http_request_duration_seconds_count[5m]))

# Error Budget Burn Rate
(1 - availability_sli) / (1 - 0.999)  # For 99.9% SLO

# Business Metrics
sum(rate(orders_created_total[5m])) * 60  # Orders per minute
sum(rate(revenue_dollars_total[5m])) * 3600  # Revenue per hour
```

### Alert Rules
```yaml
groups:
- name: slo_alerts
  rules:
  - alert: HighErrorBudgetBurn
    expr: (1 - availability_sli) / (1 - 0.999) > 10
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High error budget burn rate"
      
  - alert: LatencySLOBreach
    expr: latency_sli < 0.95
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Latency SLO breach"
      
  - alert: RevenueDropAlert
    expr: rate(revenue_dollars_total[5m]) < 100  # Less than $100/5min
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Revenue drop detected"
```

## APM Best Practices

### 1. Metric Selection
```bash
# Focus on user-impacting metrics
✅ Order completion rate
✅ Payment success rate  
✅ Page load time
✅ Feature adoption

❌ Internal function calls
❌ Code coverage
❌ Lines of code
❌ CPU of individual pods
```

### 2. Health Check Strategy
```bash
# Startup Probe: Basic bootstrap
- Configuration loaded
- Database schema migrated
- Critical services initialized

# Readiness Probe: Can serve traffic
- Database connected
- Cache available
- External dependencies reachable

# Liveness Probe: Still functioning
- Not deadlocked
- Memory not exhausted
- Critical threads responsive
```

### 3. SLO Setting
```bash
# Start realistic, improve over time
- Begin with 99% (not 99.99%)
- Measure current performance first
- Align with business requirements
- Consider error budget for deployments
```

### 4. Label Strategy
```bash
# Good - Low cardinality
service=user-api, method=GET, status=2xx

# Bad - High cardinality (avoid)
user_id=12345, session_id=abc123, trace_id=xyz789
```

## The Complete Observability Picture

### How APM Fits
```bash
# Infrastructure Monitoring (Prometheus)
"CPU is at 80%, memory at 60%"

# Application Performance Monitoring  
"Payment processing is slow, causing revenue loss"
"User signups dropped 30% after deployment"
"95th percentile latency increased to 800ms"

# Business Intelligence
"Premium users convert 3x better"
"Mobile users abandon cart at checkout step 2"
"Feature X drives 40% of revenue"
```

### The Debugging Workflow
```bash
1. Business Alert: "Revenue dropped 20%"
2. APM Investigation: "Payment success rate fell to 85%"
3. Infrastructure Check: "Payment service pods restarting"
4. Trace Analysis: "External payment API timeouts"
5. Log Analysis: "Payment gateway returned 503 errors"
6. Root Cause: "Payment provider outage"
7. Solution: "Switch to backup payment provider"
```

## Production Deployment Checklist

### ✅ Custom Metrics
- [ ] Business KPIs instrumented
- [ ] Performance metrics tracked
- [ ] Error rates monitored
- [ ] User experience measured

### ✅ Health Checks
- [ ] Startup probe implemented
- [ ] Readiness probe checks dependencies
- [ ] Liveness probe detects deadlocks
- [ ] Health endpoints return proper status codes

### ✅ SLIs/SLOs
- [ ] SLIs defined and measured
- [ ] SLOs set based on user needs
- [ ] Error budgets calculated
- [ ] Burn rate alerts configured

### ✅ Integration
- [ ] Metrics scraped by Prometheus
- [ ] Dashboards created in Grafana
- [ ] Alerts configured for SLO breaches
- [ ] Runbooks created for incidents

## The Bottom Line

### APM Gives You
- **Business visibility**: Revenue, conversions, user behavior
- **User experience**: Real performance from user perspective
- **Proactive monitoring**: Catch issues before users complain
- **Data-driven decisions**: Deploy based on error budget
- **Faster debugging**: Know exactly what's broken

### Essential For
- **Production applications** (always)
- **Business-critical services** (required)
- **User-facing applications** (mandatory)
- **Revenue-generating systems** (non-negotiable)

### The Modern Observability Stack
1. **Infrastructure**: Prometheus + Node Exporter
2. **Applications**: Custom metrics + Health checks
3. **Logs**: ELK/EFK stack
4. **Traces**: Jaeger distributed tracing
5. **Visualization**: Managed Grafana
6. **Alerting**: SLO-based alerts

**APM bridges the gap between "system is running" and "business is healthy"** 🎯

## Quick Start Commands
```bash
# Add metrics to your app
pip install prometheus_client

# Implement health checks
@app.route('/health')
@app.route('/ready')

# Deploy with probes
kubectl apply -f deployment-with-probes.yaml

# Create Grafana dashboard
- Import Prometheus data source
- Query: sum(rate(orders_created_total[5m]))
- Set SLO alerts

# Monitor error budget
Query: (1 - availability_sli) / (1 - slo_target)
```

Your applications are now **observable, reliable, and business-aware**! 🚀