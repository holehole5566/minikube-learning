# Custom Application Metrics

## Why Custom Metrics Matter

### Infrastructure vs Application Metrics
```bash
# Infrastructure tells you:
"CPU is at 80%, memory at 60%"

# Application metrics tell you:
"Payment processing is slow, causing revenue loss"
"User signups dropped 30% after the last deployment"
"Feature X is used by 85% of premium users"
```

## Prometheus Client Libraries

### Python Example
```python
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
import random

# Business metrics
orders_created = Counter('orders_created_total', 'Total orders created', ['product_type'])
revenue = Counter('revenue_dollars_total', 'Total revenue in dollars', ['currency'])
active_users = Gauge('active_users_current', 'Currently active users')

# Performance metrics
request_duration = Histogram('http_request_duration_seconds', 
                           'HTTP request duration', ['method', 'endpoint'])
database_queries = Counter('database_queries_total', 'Database queries', ['operation'])
cache_hit_ratio = Gauge('cache_hit_ratio', 'Cache hit ratio')

# Application health
app_info = Gauge('app_info', 'Application info', ['version', 'environment'])

class MetricsCollector:
    def __init__(self):
        # Set application info
        app_info.labels(version='1.2.0', environment='production').set(1)
        
    def record_order(self, product_type, amount, currency='USD'):
        """Record a new order"""
        orders_created.labels(product_type=product_type).inc()
        revenue.labels(currency=currency).inc(amount)
        
    def record_request(self, method, endpoint, duration):
        """Record HTTP request metrics"""
        request_duration.labels(method=method, endpoint=endpoint).observe(duration)
        
    def record_database_query(self, operation):
        """Record database query"""
        database_queries.labels(operation=operation).inc()
        
    def update_active_users(self, count):
        """Update active user count"""
        active_users.set(count)
        
    def update_cache_ratio(self, hits, total):
        """Update cache hit ratio"""
        ratio = hits / total if total > 0 else 0
        cache_hit_ratio.set(ratio)

# Usage example
metrics = MetricsCollector()

def process_order(product_type, amount):
    start_time = time.time()
    
    # Simulate order processing
    metrics.record_database_query('insert')
    time.sleep(random.uniform(0.1, 0.3))
    
    # Record the order
    metrics.record_order(product_type, amount)
    
    # Record request duration
    duration = time.time() - start_time
    metrics.record_request('POST', '/api/orders', duration)
    
    return {'status': 'success', 'duration': duration}

# Start metrics server
if __name__ == '__main__':
    start_http_server(8000)  # Metrics available at :8000/metrics
    
    # Simulate some activity
    while True:
        process_order('premium', random.uniform(50, 200))
        metrics.update_active_users(random.randint(100, 500))
        metrics.update_cache_ratio(random.randint(80, 95), 100)
        time.sleep(random.uniform(1, 5))
```

### Node.js Example
```javascript
const client = require('prom-client');

// Create a Registry
const register = new client.Registry();

// Business metrics
const ordersCreated = new client.Counter({
    name: 'orders_created_total',
    help: 'Total orders created',
    labelNames: ['product_type'],
    registers: [register]
});

const revenue = new client.Counter({
    name: 'revenue_dollars_total', 
    help: 'Total revenue in dollars',
    labelNames: ['currency'],
    registers: [register]
});

const activeUsers = new client.Gauge({
    name: 'active_users_current',
    help: 'Currently active users',
    registers: [register]
});

// Performance metrics
const httpDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'HTTP request duration',
    labelNames: ['method', 'route'],
    buckets: [0.1, 0.5, 1, 2, 5],
    registers: [register]
});

class MetricsCollector {
    recordOrder(productType, amount, currency = 'USD') {
        ordersCreated.labels(productType).inc();
        revenue.labels(currency).inc(amount);
    }
    
    recordRequest(method, route, duration) {
        httpDuration.labels(method, route).observe(duration);
    }
    
    updateActiveUsers(count) {
        activeUsers.set(count);
    }
}

// Express middleware for automatic request metrics
function metricsMiddleware(req, res, next) {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        httpDuration.labels(req.method, req.route?.path || req.path).observe(duration);
    });
    
    next();
}

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
});

module.exports = { MetricsCollector, metricsMiddleware };
```

### Go Example
```go
package main

import (
    "math/rand"
    "net/http"
    "time"
    
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    // Business metrics
    ordersCreated = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "orders_created_total",
            Help: "Total orders created",
        },
        []string{"product_type"},
    )
    
    revenue = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "revenue_dollars_total", 
            Help: "Total revenue in dollars",
        },
        []string{"currency"},
    )
    
    activeUsers = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "active_users_current",
            Help: "Currently active users",
        },
    )
    
    // Performance metrics
    requestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "http_request_duration_seconds",
            Help: "HTTP request duration",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )
)

func init() {
    // Register metrics
    prometheus.MustRegister(ordersCreated)
    prometheus.MustRegister(revenue)
    prometheus.MustRegister(activeUsers)
    prometheus.MustRegister(requestDuration)
}

func recordOrder(productType string, amount float64) {
    ordersCreated.WithLabelValues(productType).Inc()
    revenue.WithLabelValues("USD").Add(amount)
}

func recordRequest(method, endpoint string, duration float64) {
    requestDuration.WithLabelValues(method, endpoint).Observe(duration)
}

func main() {
    // Simulate metrics
    go func() {
        for {
            recordOrder("premium", rand.Float64()*200+50)
            activeUsers.Set(float64(rand.Intn(400) + 100))
            time.Sleep(time.Duration(rand.Intn(5)+1) * time.Second)
        }
    }()
    
    // Metrics endpoint
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8000", nil)
}
```

## Business Metrics Examples

### E-commerce Application
```python
# Revenue tracking
revenue_total = Counter('revenue_dollars_total', 'Total revenue', ['product_category'])
orders_total = Counter('orders_total', 'Total orders', ['status'])
cart_abandonment = Counter('cart_abandonment_total', 'Cart abandonments', ['step'])

# User behavior
user_signups = Counter('user_signups_total', 'User signups', ['source'])
feature_usage = Counter('feature_usage_total', 'Feature usage', ['feature_name'])
page_views = Counter('page_views_total', 'Page views', ['page'])

# Inventory
inventory_level = Gauge('inventory_level', 'Current inventory', ['product_id'])
low_stock_alerts = Counter('low_stock_alerts_total', 'Low stock alerts')
```

### SaaS Application
```python
# Subscription metrics
active_subscriptions = Gauge('active_subscriptions', 'Active subscriptions', ['plan'])
subscription_churn = Counter('subscription_churn_total', 'Subscription cancellations', ['reason'])
mrr = Gauge('monthly_recurring_revenue', 'Monthly recurring revenue')

# Usage metrics
api_calls = Counter('api_calls_total', 'API calls', ['endpoint', 'user_tier'])
storage_used = Gauge('storage_used_bytes', 'Storage used', ['user_id'])
feature_limits_hit = Counter('feature_limits_hit_total', 'Feature limits hit', ['feature'])

# User engagement
daily_active_users = Gauge('daily_active_users', 'Daily active users')
session_duration = Histogram('session_duration_seconds', 'User session duration')
```

### Banking Application
```python
# Transaction metrics
transactions_total = Counter('transactions_total', 'Total transactions', ['type', 'status'])
transaction_amount = Histogram('transaction_amount_dollars', 'Transaction amounts')
fraud_alerts = Counter('fraud_alerts_total', 'Fraud alerts', ['severity'])

# Account metrics
account_balance = Gauge('account_balance_dollars', 'Account balance', ['account_type'])
loan_applications = Counter('loan_applications_total', 'Loan applications', ['status'])
credit_score_checks = Counter('credit_score_checks_total', 'Credit score checks')
```

## Kubernetes Deployment with Metrics

### Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .
EXPOSE 5000 8000

CMD ["python", "app.py"]
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-app
  namespace: monitoring
spec:
  replicas: 2
  selector:
    matchLabels:
      app: metrics-app
  template:
    metadata:
      labels:
        app: metrics-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8000"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: metrics-app:latest
        ports:
        - containerPort: 5000  # Application
        - containerPort: 8000  # Metrics
        env:
        - name: ENVIRONMENT
          value: "production"
        resources:
          requests:
            memory: 128Mi
            cpu: 100m
          limits:
            memory: 256Mi
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: metrics-app
  namespace: monitoring
  labels:
    app: metrics-app
spec:
  selector:
    app: metrics-app
  ports:
  - name: http
    port: 5000
    targetPort: 5000
  - name: metrics
    port: 8000
    targetPort: 8000
```

## Best Practices

### 1. Metric Naming
```bash
# Good
orders_created_total
user_login_duration_seconds
payment_processing_errors_total

# Bad  
orders
login_time
errors
```

### 2. Label Strategy
```bash
# Good - Low cardinality
method=GET, status=200, service=user-api

# Bad - High cardinality (avoid)
user_id=12345, session_id=abc123, request_id=xyz789
```

### 3. Metric Types
```bash
# Counters: Things that increase
requests_total, errors_total, bytes_sent_total

# Gauges: Current values
active_connections, queue_size, temperature

# Histograms: Distributions
request_duration_seconds, response_size_bytes
```

### 4. Business Context
```bash
# Always include business context
revenue_dollars_total{product="premium", region="us-east"}
user_signups_total{source="mobile", campaign="summer2024"}
```

## Next Steps
With custom metrics in place:
1. **Create business dashboards** in your managed Grafana
2. **Set up SLI/SLO monitoring**
3. **Implement intelligent alerting**
4. **Track user experience metrics**

Your applications are now **observable from the inside**! 📊