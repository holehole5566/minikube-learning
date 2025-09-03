# Three Pillars - Practical Examples

## 1. Metrics Examples 📊

### System Metrics
```
# CPU Usage
node_cpu_usage_percent{instance="worker-1"} 75.2

# Memory Usage  
node_memory_usage_bytes{instance="worker-1"} 8589934592

# Disk I/O
node_disk_io_operations_total{device="sda1"} 1250
```

### Application Metrics
```
# HTTP Requests
http_requests_total{method="GET", status="200"} 15420
http_requests_total{method="POST", status="500"} 23

# Response Time
http_request_duration_seconds{quantile="0.95"} 0.245

# Business Metrics
orders_created_total{region="us-east"} 1847
revenue_dollars_total{product="premium"} 25430.50
```

## 2. Logs Examples 📝

### Application Logs
```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "INFO",
  "service": "user-service",
  "message": "User login successful",
  "user_id": "12345",
  "ip": "192.168.1.100"
}

{
  "timestamp": "2024-01-15T10:30:46Z", 
  "level": "ERROR",
  "service": "order-service",
  "message": "Database connection failed",
  "error": "connection timeout after 5s",
  "database": "orders-db"
}
```

### Kubernetes Logs
```
# Pod logs
2024-01-15 10:30:45 user-service-7d4b8f9c-xk2m9 Starting application on port 3000
2024-01-15 10:30:46 user-service-7d4b8f9c-xk2m9 Connected to database successfully

# System logs
2024-01-15 10:30:47 kubelet Pod user-service-7d4b8f9c-abc123 exceeded memory limit
2024-01-15 10:30:48 kube-scheduler Failed to schedule pod: insufficient CPU
```

## 3. Traces Examples 🔍

### Simple Request Trace
```
Trace ID: abc123def456
Span ID: 789ghi012jkl

Request: GET /api/users/12345
├── API Gateway (50ms)
│   └── Authentication (15ms)
├── User Service (120ms)  
│   ├── Database Query (80ms)
│   └── Cache Lookup (25ms)
└── Response Formatting (30ms)

Total Duration: 200ms
```

### Complex Microservice Trace
```
Trace ID: xyz789abc123

Request: POST /api/orders
├── API Gateway (20ms)
├── Order Service (150ms)
│   ├── Validate Order (30ms)
│   ├── User Service Call (60ms)
│   │   └── Database Query (45ms)
│   ├── Inventory Service Call (40ms)
│   │   └── Redis Cache (15ms)
│   └── Payment Service Call (80ms)
│       └── External API (65ms)
└── Notification Service (25ms)

Total Duration: 275ms
Status: SUCCESS
```

## Real-World Scenario: E-commerce Checkout

### The Problem
"Checkout is slow and sometimes fails"

### Using the Three Pillars

#### 1. Metrics Tell Us WHAT
```
checkout_duration_seconds{quantile="0.95"} 8.5  # Too slow!
checkout_success_rate 0.92                      # 8% failure rate
payment_service_errors_total 145                # Payment issues
```

#### 2. Logs Tell Us WHERE
```json
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "ERROR", 
  "service": "payment-service",
  "message": "Payment gateway timeout",
  "order_id": "ORD-12345",
  "gateway": "stripe",
  "duration_ms": 5000
}
```

#### 3. Traces Tell Us WHY
```
Checkout Request (8.2s total)
├── Order Validation (0.1s) ✓
├── Inventory Check (0.2s) ✓  
├── User Verification (0.3s) ✓
└── Payment Processing (7.6s) ❌ SLOW!
    ├── Payment Gateway Call (7.5s) ❌
    └── Retry Logic (0.1s)
```

### The Solution
**Root Cause**: Payment gateway timeout
**Fix**: Reduce timeout, add circuit breaker, implement async processing

## Key Takeaways

### When to Use Each Pillar

#### Metrics 📊
- **Alerting**: "Error rate > 5%"
- **Dashboards**: Real-time system health
- **Capacity Planning**: "Need more CPU"
- **SLA Monitoring**: "99.9% uptime"

#### Logs 📝  
- **Debugging**: "What exactly failed?"
- **Audit**: "Who did what when?"
- **Security**: "Suspicious login attempts"
- **Business Intelligence**: "User behavior patterns"

#### Traces 🔍
- **Performance**: "Which service is slow?"
- **Dependencies**: "How do services interact?"
- **Error Propagation**: "Where did the error start?"
- **Optimization**: "Remove unnecessary calls"

### The Golden Rule
**Start with metrics for alerting, use logs for debugging, use traces for understanding**