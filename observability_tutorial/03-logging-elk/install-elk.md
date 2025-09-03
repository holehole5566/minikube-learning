# Installing EFK Stack in Kubernetes

## Method 1: Helm Chart (Recommended)

### Step 1: Add Elastic Helm Repository
```bash
helm repo add elastic https://helm.elastic.co
helm repo update
```

### Step 2: Install Elasticsearch
```bash
helm install elasticsearch elastic/elasticsearch \
  --namespace monitoring \
  --set replicas=1 \
  --set minimumMasterNodes=1 \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=512Mi \
  --set resources.limits.cpu=1000m \
  --set resources.limits.memory=2Gi
```

### Step 3: Install Kibana
```bash
helm install kibana elastic/kibana \
  --namespace monitoring \
  --set resources.requests.cpu=100m \
  --set resources.requests.memory=256Mi
```

### Step 4: Install Fluentd
```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm install fluentd fluent/fluentd \
  --namespace monitoring \
  --set elasticsearch.host=elasticsearch-master \
  --set elasticsearch.port=9200
```

## Method 2: Simple YAML Deployment

### Elasticsearch Deployment
```yaml
# elasticsearch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: elasticsearch
  template:
    metadata:
      labels:
        app: elasticsearch
    spec:
      containers:
      - name: elasticsearch
        image: docker.elastic.co/elasticsearch/elasticsearch:7.17.0
        ports:
        - containerPort: 9200
        - containerPort: 9300
        env:
        - name: discovery.type
          value: single-node
        - name: ES_JAVA_OPTS
          value: "-Xms512m -Xmx512m"
        resources:
          requests:
            memory: 1Gi
            cpu: 500m
          limits:
            memory: 2Gi
            cpu: 1000m
---
apiVersion: v1
kind: Service
metadata:
  name: elasticsearch
  namespace: monitoring
spec:
  selector:
    app: elasticsearch
  ports:
  - port: 9200
    targetPort: 9200
  type: ClusterIP
```

### Kibana Deployment
```yaml
# kibana.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kibana
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kibana
  template:
    metadata:
      labels:
        app: kibana
    spec:
      containers:
      - name: kibana
        image: docker.elastic.co/kibana/kibana:7.17.0
        ports:
        - containerPort: 5601
        env:
        - name: ELASTICSEARCH_HOSTS
          value: "http://elasticsearch:9200"
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
  name: kibana
  namespace: monitoring
spec:
  selector:
    app: kibana
  ports:
  - port: 5601
    targetPort: 5601
  type: ClusterIP
```

### Fluentd DaemonSet
```yaml
# fluentd.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      serviceAccountName: fluentd
      containers:
      - name: fluentd
        image: fluent/fluentd-kubernetes-daemonset:v1-debian-elasticsearch
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: FLUENT_ELASTICSEARCH_SCHEME
          value: "http"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        resources:
          requests:
            memory: 200Mi
            cpu: 100m
          limits:
            memory: 500Mi
            cpu: 500m
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluentd
  namespace: monitoring
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluentd
rules:
- apiGroups: [""]
  resources: ["pods", "namespaces"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluentd
roleRef:
  kind: ClusterRole
  name: fluentd
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: fluentd
  namespace: monitoring
```

## Verification Commands

### Check Installation
```bash
# Check all logging components
kubectl get pods -n monitoring | grep -E "elasticsearch|kibana|fluentd"

# Check Elasticsearch health
kubectl port-forward -n monitoring svc/elasticsearch 9200:9200 &
curl localhost:9200/_cluster/health

# Check if logs are being indexed
curl localhost:9200/_cat/indices
```

### Access Kibana
```bash
# Port forward to Kibana
kubectl port-forward -n monitoring svc/kibana 5601:5601 &

# Access at: http://localhost:5601
```

## Troubleshooting

### Common Issues

#### 1. Elasticsearch Won't Start
```bash
# Check logs
kubectl logs -n monitoring deployment/elasticsearch

# Common fix: Increase memory
kubectl patch deployment elasticsearch -n monitoring -p '{"spec":{"template":{"spec":{"containers":[{"name":"elasticsearch","resources":{"requests":{"memory":"1Gi"}}}]}}}}'
```

#### 2. Fluentd Not Collecting Logs
```bash
# Check Fluentd logs
kubectl logs -n monitoring daemonset/fluentd

# Check permissions
kubectl get clusterrolebinding fluentd
```

#### 3. No Data in Kibana
```bash
# Check if indices exist
curl localhost:9200/_cat/indices

# Check Fluentd is sending to Elasticsearch
kubectl logs -n monitoring daemonset/fluentd | grep elasticsearch
```

## Next Steps
Once EFK is running:
1. **Create index patterns** in Kibana
2. **Search and filter logs**
3. **Build log dashboards**
4. **Set up log-based alerts**

Ready to start collecting logs! 📝