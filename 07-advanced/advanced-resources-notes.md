# Advanced Kubernetes Resources Notes

## Resource Types Comparison

| Resource | Pod Names | Storage | Lifecycle | Use Case |
|----------|-----------|---------|-----------|----------|
| **Deployment** | Random | Shared | Long-running | Stateless apps |
| **StatefulSet** | Ordered | Per-pod | Long-running | Databases |
| **Job** | Random | Temporary | Run-to-completion | Batch processing |
| **CronJob** | Random | Temporary | Scheduled | Periodic tasks |

## Job
Runs a task once to completion, then terminates.

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: pi-calculation
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl
        command: ["perl", "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

### Characteristics
- **One-time execution**: Pod runs until task completes
- **Restart policy**: Never or OnFailure
- **Backoff limit**: Max retry attempts
- **Use cases**: Data processing, migrations, calculations

## CronJob
Schedules Jobs to run at specific times.

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello-cron
spec:
  schedule: "*/1 * * * *"  # Every minute
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            command: ["echo", "Hello from CronJob"]
          restartPolicy: OnFailure
```

### Schedule Format
- `*/1 * * * *` - Every minute
- `0 2 * * *` - Daily at 2 AM
- `0 0 * * 0` - Weekly on Sunday
- Format: `minute hour day month weekday`

## StatefulSet
Manages pods with persistent identity and ordered deployment.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: "nginx"
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

### Key Features
- **Ordered naming**: `web-stateful-0`, `web-stateful-1`
- **Sequential deployment**: Pod 0 starts before Pod 1
- **Persistent storage**: Each pod gets its own volume
- **Stable network identity**: Consistent pod names
- **Use cases**: Databases, distributed systems, clustered apps

## Commands

### Jobs
```bash
# Check job status
kubectl get jobs

# View job logs
kubectl logs job/pi-calculation

# Delete completed jobs
kubectl delete job pi-calculation
```

### CronJobs
```bash
# List cronjobs
kubectl get cronjobs

# Check cronjob history
kubectl get jobs --selector=job-name=hello-cron

# Suspend cronjob
kubectl patch cronjob hello-cron -p '{"spec":{"suspend":true}}'
```

### StatefulSets
```bash
# Check statefulset status
kubectl get statefulsets

# Scale statefulset
kubectl scale statefulset web-stateful --replicas=3

# Delete statefulset (keeps PVCs)
kubectl delete statefulset web-stateful
```

## When to Use What

- **Job**: One-time data processing, database migrations
- **CronJob**: Log cleanup, backups, periodic reports
- **StatefulSet**: Databases (MySQL, PostgreSQL), message queues (Kafka)
- **Deployment**: Web servers, APIs, microservices