# Health Checks and SLIs/SLOs

## Kubernetes Health Checks

### The Three Types

#### 1. Startup Probe
**"Is the application starting up?"**
```yaml
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 30  # 30 * 5s = 2.5 minutes to start
```

#### 2. Readiness Probe  
**"Is the application ready to serve traffic?"**
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
```

#### 3. Liveness Probe
**"Is the application still alive?"**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 30
  timeoutSeconds: 5
  failureThreshold: 3
```

## Health Check Implementation

### Python Flask Example
```python
from flask import Flask, jsonify
import time
import psycopg2
import redis
import requests

app = Flask(__name__)

class HealthChecker:
    def __init__(self):
        self.start_time = time.time()
        self.ready = False
        
    def check_database(self):
        """Check database connectivity"""
        try:
            conn = psycopg2.connect(
                host="postgres",
                database="myapp",
                user="user",
                password="password",
                connect_timeout=3
            )
            conn.close()
            return True, "Database connected"
        except Exception as e:
            return False, f"Database error: {str(e)}"
    
    def check_cache(self):
        """Check Redis cache"""
        try:
            r = redis.Redis(host='redis', port=6379, socket_timeout=3)
            r.ping()
            return True, "Cache connected"
        except Exception as e:
            return False, f"Cache error: {str(e)}"
    
    def check_external_service(self):
        """Check external API dependency"""
        try:
            response = requests.get(
                "https://api.external-service.com/health",
                timeout=5
            )
            if response.status_code == 200:
                return True, "External service available"
            else:
                return False, f"External service returned {response.status_code}"
        except Exception as e:
            return False, f"External service error: {str(e)}"

health_checker = HealthChecker()

@app.route('/startup')
def startup():
    """Startup probe - basic application bootstrap"""
    uptime = time.time() - health_checker.start_time
    
    if uptime < 10:  # Still starting up
        return jsonify({
            'status': 'starting',
            'uptime': uptime,
            'message': 'Application is starting up'
        }), 503
    
    return jsonify({
        'status': 'started',
        'uptime': uptime,
        'message': 'Application has started'
    }), 200

@app.route('/ready')
def ready():
    """Readiness probe - can serve traffic"""
    checks = {}
    all_ready = True
    
    # Check database
    db_ok, db_msg = health_checker.check_database()
    checks['database'] = {'status': 'ok' if db_ok else 'error', 'message': db_msg}
    if not db_ok:
        all_ready = False
    
    # Check cache
    cache_ok, cache_msg = health_checker.check_cache()
    checks['cache'] = {'status': 'ok' if cache_ok else 'error', 'message': cache_msg}
    if not cache_ok:
        all_ready = False
    
    # Optional: Check external services
    ext_ok, ext_msg = health_checker.check_external_service()
    checks['external_service'] = {'status': 'ok' if ext_ok else 'warning', 'message': ext_msg}
    # Note: External service failure doesn't make us not ready
    
    status_code = 200 if all_ready else 503
    
    return jsonify({
        'status': 'ready' if all_ready else 'not_ready',
        'timestamp': time.time(),
        'checks': checks
    }), status_code

@app.route('/health')
def health():
    """Liveness probe - is application alive"""
    uptime = time.time() - health_checker.start_time
    
    # Basic health checks
    checks = {
        'uptime': uptime,
        'status': 'healthy',
        'timestamp': time.time()
    }
    
    # Check if application is deadlocked or stuck
    # This is a simple example - in real apps you might check:
    # - Thread pool health
    # - Memory usage
    # - Critical resource availability
    
    return jsonify(checks), 200

@app.route('/metrics')
def metrics():
    """Expose health metrics for Prometheus"""
    db_ok, _ = health_checker.check_database()
    cache_ok, _ = health_checker.check_cache()
    ext_ok, _ = health_checker.check_external_service()
    
    metrics = f"""
# HELP app_health_check Health check status (1=healthy, 0=unhealthy)
# TYPE app_health_check gauge
app_health_check{{service="database"}} {1 if db_ok else 0}
app_health_check{{service="cache"}} {1 if cache_ok else 0}
app_health_check{{service="external_api"}} {1 if ext_ok else 0}

# HELP app_uptime_seconds Application uptime in seconds
# TYPE app_uptime_seconds counter
app_uptime_seconds {time.time() - health_checker.start_time}
"""
    
    return metrics, 200, {'Content-Type': 'text/plain'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

### Complete Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthy-app
  namespace: monitoring
spec:
  replicas: 3
  selector:
    matchLabels:
      app: healthy-app
  template:
    metadata:
      labels:
        app: healthy-app
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      containers:
      - name: app
        image: healthy-app:latest
        ports:
        - containerPort: 8080
        
        # Startup probe - gives app time to start
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 20  # 20 * 5s = 100s to start
        
        # Readiness probe - controls traffic routing
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
        
        # Liveness probe - restarts container if unhealthy
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 500m
        
        env:
        - name: DATABASE_URL
          value: "postgresql://user:pass@postgres:5432/myapp"
        - name: REDIS_URL
          value: "redis://redis:6379"
```

## Service Level Indicators (SLIs)

### What to Measure
```python
# Availability SLI
availability_sli = successful_requests / total_requests

# Latency SLI  
latency_sli = requests_under_threshold / total_requests

# Throughput SLI
throughput_sli = requests_per_second

# Error Rate SLI
error_rate_sli = error_requests / total_requests
```

### Implementation Example
```python
from prometheus_client import Counter, Histogram, Gauge
import time

# SLI Metrics
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'status'])
http_request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')
http_requests_current = Gauge('http_requests_current', 'Current HTTP requests')

# SLI Calculations
availability_sli = Gauge('sli_availability_ratio', 'Availability SLI (successful requests / total)')
latency_sli = Gauge('sli_latency_ratio', 'Latency SLI (fast requests / total)')
error_rate_sli = Gauge('sli_error_rate_ratio', 'Error rate SLI (errors / total)')

class SLICalculator:
    def __init__(self):
        self.window_size = 300  # 5 minutes
        self.latency_threshold = 0.5  # 500ms
        
    def calculate_slis(self):
        """Calculate SLIs over time window"""
        # These would typically query your metrics backend
        # For demo, using mock calculations
        
        total_requests = 1000
        successful_requests = 995
        fast_requests = 950
        error_requests = 5
        
        # Calculate SLIs
        availability = successful_requests / total_requests
        latency_ratio = fast_requests / total_requests  
        error_rate = error_requests / total_requests
        
        # Update metrics
        availability_sli.set(availability)
        latency_sli.set(latency_ratio)
        error_rate_sli.set(error_rate)
        
        return {
            'availability': availability,
            'latency': latency_ratio,
            'error_rate': error_rate
        }

# Middleware to track SLIs
def sli_middleware(request, response):
    start_time = time.time()
    
    def after_request():
        duration = time.time() - start_time
        status = response.status_code
        
        # Record metrics
        http_requests_total.labels(
            method=request.method,
            status=f"{status//100}xx"
        ).inc()
        
        http_request_duration.observe(duration)
        
        # Update SLI calculations periodically
        if time.time() % 60 < 1:  # Every minute
            SLICalculator().calculate_slis()
    
    return after_request
```

## Service Level Objectives (SLOs)

### Defining SLOs
```yaml
# SLO Configuration
slos:
  availability:
    target: 99.9%  # 99.9% of requests succeed
    window: 30d    # Over 30 days
    
  latency:
    target: 95%    # 95% of requests under 500ms
    threshold: 500ms
    window: 7d
    
  error_rate:
    target: 99.5%  # 99.5% of requests succeed (0.5% error rate)
    window: 24h
```

### SLO Monitoring
```python
class SLOMonitor:
    def __init__(self):
        self.slos = {
            'availability': {'target': 0.999, 'current': 0.0},
            'latency': {'target': 0.95, 'current': 0.0},
            'error_rate': {'target': 0.995, 'current': 0.0}
        }
    
    def check_slo_burn_rate(self, sli_value, slo_target, window_hours=1):
        """Calculate error budget burn rate"""
        error_budget = 1 - slo_target
        current_error_rate = 1 - sli_value
        
        if error_budget == 0:
            return float('inf') if current_error_rate > 0 else 0
            
        burn_rate = current_error_rate / error_budget
        return burn_rate
    
    def slo_status(self):
        """Get current SLO status"""
        calculator = SLICalculator()
        slis = calculator.calculate_slis()
        
        status = {}
        for slo_name, slo_config in self.slos.items():
            current_sli = slis.get(slo_name, 0)
            target = slo_config['target']
            
            burn_rate = self.check_slo_burn_rate(current_sli, target)
            
            status[slo_name] = {
                'current': current_sli,
                'target': target,
                'status': 'ok' if current_sli >= target else 'breach',
                'burn_rate': burn_rate,
                'error_budget_remaining': max(0, 1 - burn_rate)
            }
        
        return status

# SLO Alerting Rules (for Prometheus)
slo_alerts = """
groups:
- name: slo_alerts
  rules:
  - alert: HighErrorBudgetBurn
    expr: sli_availability_ratio < 0.999
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High error budget burn rate"
      description: "Availability SLI is {{ $value }}, below target of 99.9%"
      
  - alert: LatencySLOBreach  
    expr: sli_latency_ratio < 0.95
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Latency SLO breach"
      description: "Only {{ $value | humanizePercentage }} of requests under 500ms"
"""
```

## Error Budget Management

### Error Budget Calculation
```python
def calculate_error_budget(slo_target, time_window_hours, current_sli):
    """Calculate remaining error budget"""
    
    # Total allowed errors in time window
    error_budget_total = (1 - slo_target) * time_window_hours * 3600  # seconds
    
    # Current error rate
    current_error_rate = 1 - current_sli
    
    # Errors consumed so far
    errors_consumed = current_error_rate * time_window_hours * 3600
    
    # Remaining budget
    error_budget_remaining = max(0, error_budget_total - errors_consumed)
    
    return {
        'total_budget': error_budget_total,
        'consumed': errors_consumed,
        'remaining': error_budget_remaining,
        'percentage_remaining': (error_budget_remaining / error_budget_total) * 100
    }

# Example: 99.9% availability SLO over 30 days
budget = calculate_error_budget(
    slo_target=0.999,
    time_window_hours=30 * 24,  # 30 days
    current_sli=0.9985  # Current availability
)

print(f"Error budget remaining: {budget['percentage_remaining']:.1f}%")
```

## Best Practices

### 1. Health Check Design
```bash
# Startup: Basic bootstrap checks
- Application started
- Configuration loaded
- Critical resources initialized

# Readiness: Can serve traffic
- Database connected
- Cache available  
- Required services reachable

# Liveness: Still alive
- Not deadlocked
- Memory not exhausted
- Critical threads running
```

### 2. SLI Selection
```bash
# Choose SLIs that matter to users
- Request success rate (availability)
- Response time percentiles (latency)
- Throughput capacity (performance)
- Data freshness (consistency)
```

### 3. SLO Setting
```bash
# Start conservative, improve over time
- 99% availability (not 99.99%)
- 95th percentile latency (not 50th)
- Measure first, then set targets
- Align with business requirements
```

## Integration with Managed Grafana

### Dashboard Queries
```promql
# Availability SLI
sum(rate(http_requests_total{status!~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Latency SLI  
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) < 0.5

# Error Budget Burn Rate
(1 - availability_sli) / (1 - 0.999)  # For 99.9% SLO
```

### Alert Rules
```yaml
# Error budget alerts
- alert: ErrorBudgetBurnHigh
  expr: error_budget_burn_rate > 10
  for: 2m
  
- alert: ErrorBudgetBurnCritical  
  expr: error_budget_burn_rate > 100
  for: 1m
```

Your applications now have **comprehensive health monitoring** and **SLO tracking**! 🎯