# Installing Prometheus in Kubernetes

## Method 1: Helm Chart (Recommended)

### Step 1: Add Prometheus Helm Repository
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Step 2: Create Namespace
```bash
kubectl create namespace monitoring
```

### Step 3: Install Prometheus Stack
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false
```

### Step 4: Verify Installation
```bash
kubectl get pods -n monitoring
```

Expected output:
```
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          2m
prometheus-grafana-7b48c7d5c4-xyz123                     3/3     Running   0          2m
prometheus-kube-prometheus-operator-6d8c5c9b8f-abc456    1/1     Running   0          2m
prometheus-kube-state-metrics-85b5c8b5c4-def789          1/1     Running   0          2m
prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          2m
prometheus-prometheus-node-exporter-ghi012               1/1     Running   0          2m
```

## Method 2: Manual YAML (Learning Purpose)

### Step 1: Create Prometheus ConfigMap
```yaml
# prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
    - job_name: 'kubernetes-nodes'
      kubernetes_sd_configs:
      - role: node
```

### Step 2: Create Prometheus Deployment
```yaml
# prometheus-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prometheus
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:latest
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: config
          mountPath: /etc/prometheus
        args:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
      volumes:
      - name: config
        configMap:
          name: prometheus-config
```

### Step 3: Create Service
```yaml
# prometheus-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: prometheus
  namespace: monitoring
spec:
  selector:
    app: prometheus
  ports:
  - port: 9090
    targetPort: 9090
  type: ClusterIP
```

## Access Prometheus UI

### Method 1: Port Forward
```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
```

Then open: http://localhost:9090

### Method 2: Create Ingress (Production)
```yaml
# prometheus-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
spec:
  rules:
  - host: prometheus.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-kube-prometheus-prometheus
            port:
              number: 9090
```

## What Gets Installed

### Core Components
- **Prometheus Server**: Metrics collection and storage
- **AlertManager**: Alert routing and management
- **Node Exporter**: System metrics from nodes
- **Kube State Metrics**: Kubernetes object metrics
- **Grafana**: Visualization (bonus!)

### Default Metrics Available
```bash
# Check available metrics
curl http://localhost:9090/api/v1/label/__name__/values
```

Key metrics you'll see:
- `up` - Target availability
- `node_cpu_seconds_total` - CPU usage
- `node_memory_MemAvailable_bytes` - Memory
- `kube_pod_status_phase` - Pod status
- `container_cpu_usage_seconds_total` - Container CPU

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
kubectl describe pod -n monitoring prometheus-xyz
```

#### 2. No Metrics Showing
```bash
# Check service discovery
kubectl get servicemonitors -n monitoring
kubectl get podmonitors -n monitoring
```

#### 3. Permission Issues
```bash
# Check RBAC
kubectl get clusterrole prometheus-kube-prometheus-prometheus
```

### Verification Commands
```bash
# Check all monitoring resources
kubectl get all -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Visit: http://localhost:9090/targets

# Test a simple query
# Visit: http://localhost:9090/graph
# Query: up
```

## Next Steps
Once Prometheus is running, you'll be able to:
1. **Explore metrics** in the Prometheus UI
2. **Write PromQL queries** to analyze data
3. **Create alerts** for important conditions
4. **Visualize data** in Grafana

Ready to explore the metrics! 🎯