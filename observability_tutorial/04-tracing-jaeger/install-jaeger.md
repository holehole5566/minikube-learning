# Installing Jaeger in Kubernetes

## Method 1: Jaeger Operator (Recommended)

### Step 1: Install Jaeger Operator
```bash
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.47.0/jaeger-operator.yaml -n observability
```

### Step 2: Create Jaeger Instance
```yaml
# jaeger-simple.yaml
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger-simple
  namespace: monitoring
spec:
  strategy: allInOne
  allInOne:
    image: jaegertracing/all-in-one:latest
    options:
      memory:
        max-traces: 100000
  storage:
    type: memory
  ui:
    options:
      dependencies:
        menuEnabled: true
```

## Method 2: Simple YAML Deployment

### All-in-One Jaeger Deployment
```yaml
# jaeger-all-in-one.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
  namespace: monitoring
  labels:
    app: jaeger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.47
        ports:
        - containerPort: 16686  # UI
        - containerPort: 14268  # HTTP collector
        - containerPort: 14250  # gRPC collector
        - containerPort: 6831   # UDP agent (compact)
        - containerPort: 6832   # UDP agent (binary)
        env:
        - name: COLLECTOR_OTLP_ENABLED
          value: "true"
        - name: MEMORY_MAX_TRACES
          value: "100000"
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 1Gi
            cpu: 500m
---
apiVersion: v1
kind: Service
metadata:
  name: jaeger
  namespace: monitoring
  labels:
    app: jaeger
spec:
  selector:
    app: jaeger
  ports:
  - name: ui
    port: 16686
    targetPort: 16686
  - name: collector-http
    port: 14268
    targetPort: 14268
  - name: collector-grpc
    port: 14250
    targetPort: 14250
  - name: agent-compact
    port: 6831
    targetPort: 6831
    protocol: UDP
  - name: agent-binary
    port: 6832
    targetPort: 6832
    protocol: UDP
  type: ClusterIP
```

## Method 3: Helm Chart

### Install with Helm
```bash
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo update

helm install jaeger jaegertracing/jaeger \
  --namespace monitoring \
  --set provisionDataStore.cassandra=false \
  --set provisionDataStore.elasticsearch=false \
  --set storage.type=memory \
  --set agent.enabled=false \
  --set collector.enabled=false \
  --set query.enabled=false \
  --set allInOne.enabled=true
```

## Verification Commands

### Check Installation
```bash
# Check Jaeger pods
kubectl get pods -n monitoring | grep jaeger

# Check services
kubectl get svc -n monitoring | grep jaeger

# Port forward to UI
kubectl port-forward -n monitoring svc/jaeger 16686:16686 &

# Access UI at: http://localhost:16686
```

### Test Jaeger API
```bash
# Check health
curl localhost:16686/api/services

# Send test trace
curl -X POST localhost:14268/api/traces \
  -H "Content-Type: application/json" \
  -d '{
    "data": [{
      "traceID": "abc123",
      "spanID": "def456", 
      "operationName": "test-operation",
      "startTime": 1609459200000000,
      "duration": 1000000,
      "process": {
        "serviceName": "test-service",
        "tags": []
      }
    }]
  }'
```

## Sample Application with Tracing

### Simple Python Flask App
```python
# app.py
from flask import Flask
from jaeger_client import Config
import opentracing
import time
import random

app = Flask(__name__)

# Jaeger configuration
config = Config(
    config={
        'sampler': {'type': 'const', 'param': 1},
        'logging': True,
        'reporter_batch_size': 1,
    },
    service_name='demo-service',
    validate=True,
)
tracer = config.initialize_tracer()
opentracing.set_global_tracer(tracer)

@app.route('/api/users/<user_id>')
def get_user(user_id):
    with tracer.start_span('get_user') as span:
        span.set_tag('user.id', user_id)
        span.set_tag('http.method', 'GET')
        
        # Simulate database call
        with tracer.start_span('database_query', child_of=span) as db_span:
            db_span.set_tag('db.statement', f'SELECT * FROM users WHERE id={user_id}')
            time.sleep(random.uniform(0.1, 0.3))  # Simulate DB latency
            
        # Simulate cache check
        with tracer.start_span('cache_lookup', child_of=span) as cache_span:
            cache_span.set_tag('cache.key', f'user:{user_id}')
            time.sleep(random.uniform(0.01, 0.05))  # Simulate cache latency
            
        return {'user_id': user_id, 'name': f'User {user_id}'}

@app.route('/api/orders')
def get_orders():
    with tracer.start_span('get_orders') as span:
        span.set_tag('http.method', 'GET')
        
        # Simulate calling user service
        with tracer.start_span('call_user_service', child_of=span) as user_span:
            user_span.set_tag('service.name', 'user-service')
            time.sleep(random.uniform(0.05, 0.15))
            
        # Simulate payment service call
        with tracer.start_span('call_payment_service', child_of=span) as payment_span:
            payment_span.set_tag('service.name', 'payment-service')
            # Simulate occasional slow payment
            if random.random() < 0.2:  # 20% chance of slow payment
                time.sleep(random.uniform(1.0, 2.0))
                payment_span.set_tag('error', True)
                payment_span.log_kv({'event': 'timeout', 'message': 'Payment gateway timeout'})
            else:
                time.sleep(random.uniform(0.1, 0.3))
                
        return {'orders': [{'id': 1, 'total': 99.99}]}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

### Dockerfile for Sample App
```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .
EXPOSE 5000

CMD ["python", "app.py"]
```

### Requirements
```txt
# requirements.txt
Flask==2.3.2
jaeger-client==4.8.0
opentracing==2.4.0
```

### Kubernetes Deployment
```yaml
# demo-app.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: demo-app:latest  # Build and push your image
        ports:
        - containerPort: 5000
        env:
        - name: JAEGER_AGENT_HOST
          value: "jaeger"
        - name: JAEGER_AGENT_PORT
          value: "6831"
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: monitoring
spec:
  selector:
    app: demo-app
  ports:
  - port: 5000
    targetPort: 5000
  type: ClusterIP
```

## Troubleshooting

### Common Issues

#### 1. No Traces Appearing
```bash
# Check Jaeger collector logs
kubectl logs -n monitoring deployment/jaeger

# Check application is sending traces
kubectl logs -n monitoring deployment/demo-app

# Verify Jaeger agent connectivity
kubectl exec -n monitoring deployment/demo-app -- nc -zv jaeger 6831
```

#### 2. UI Not Loading
```bash
# Check Jaeger UI service
kubectl get svc -n monitoring jaeger

# Port forward with correct port
kubectl port-forward -n monitoring svc/jaeger 16686:16686
```

#### 3. Traces Not Connected
- Check trace context propagation between services
- Verify same trace ID is used across service calls
- Ensure proper parent-child span relationships

## Next Steps
Once Jaeger is running:
1. **Generate sample traces** with demo application
2. **Explore Jaeger UI** to understand trace visualization
3. **Analyze performance bottlenecks**
4. **Correlate traces with metrics and logs**

Ready to trace requests! 🔍