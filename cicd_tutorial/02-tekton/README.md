# 02. Tekton Pipelines

## What is Tekton?

**Tekton = Kubernetes-native CI/CD framework**
- **Tasks** run as pods
- **Pipelines** orchestrate tasks
- **Triggers** respond to events
- **Results** stored in cluster

## Core Concepts

### Task
**Single unit of work (like a job)**
```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: build-image
spec:
  params:
  - name: image-name
  steps:
  - name: build
    image: gcr.io/kaniko-project/executor
    command: ["/kaniko/executor"]
    args:
    - --dockerfile=Dockerfile
    - --destination=$(params.image-name)
```

### Pipeline
**Series of tasks**
```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-deploy
spec:
  params:
  - name: git-url
  - name: image-name
  tasks:
  - name: test
    taskRef:
      name: run-tests
  - name: build
    taskRef:
      name: build-image
    runAfter: [test]
  - name: deploy
    taskRef:
      name: deploy-app
    runAfter: [build]
```

### PipelineRun
**Execution of a pipeline**
```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: build-deploy-run-1
spec:
  pipelineRef:
    name: build-deploy
  params:
  - name: git-url
    value: https://github.com/user/app
  - name: image-name
    value: myregistry/app:latest
```

## Tekton vs Traditional CI/CD

### GitHub Actions
```yaml
jobs:
  build:
    runs-on: ubuntu-latest  # Fixed runner
    steps:
    - run: npm test
    - run: docker build
    - run: docker push
```

### Tekton
```yaml
tasks:
- name: test
  taskSpec:
    steps:
    - image: node:16  # Any image
      script: npm test
- name: build
  taskSpec:
    steps:
    - image: gcr.io/kaniko-project/executor
      script: build and push
```

## Key Advantages

### 1. Resource Efficiency
```bash
# Traditional: Always-on agents
GitHub Runner: 2 CPU, 7GB RAM (always running)

# Tekton: On-demand pods
Task Pod: Scales from 0, uses only what needed
```

### 2. Kubernetes Integration
```yaml
# Access cluster resources directly
- name: deploy
  steps:
  - image: kubectl
    script: |
      kubectl apply -f deployment.yaml
      kubectl rollout status deployment/app
```

### 3. Observability Integration
```bash
# Monitor with your existing stack
kubectl logs -f pipelinerun/build-deploy-run-1
# Logs go to your ELK stack
# Metrics go to Prometheus
```

## Installation and Setup

### Install Tekton
```bash
# Install Tekton Pipelines
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Install Tekton Dashboard
kubectl apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml
```

### Basic Pipeline Example
```yaml
# simple-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello-world
spec:
  steps:
  - name: hello
    image: alpine
    script: |
      echo "Hello from Tekton!"
      echo "Running in pod: $HOSTNAME"
---
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: hello-pipeline
spec:
  tasks:
  - name: hello-task
    taskRef:
      name: hello-world
---
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: hello-run
spec:
  pipelineRef:
    name: hello-pipeline
```

## Real-World Pipeline

### Node.js Application Pipeline
```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: nodejs-pipeline
spec:
  params:
  - name: git-url
  - name: git-revision
    default: main
  - name: image-name
  
  workspaces:
  - name: source-code
  
  tasks:
  # Clone source code
  - name: fetch-source
    taskRef:
      name: git-clone
    params:
    - name: url
      value: $(params.git-url)
    - name: revision
      value: $(params.git-revision)
    workspaces:
    - name: output
      workspace: source-code
  
  # Run tests
  - name: test
    runAfter: [fetch-source]
    taskSpec:
      workspaces:
      - name: source
      steps:
      - name: test
        image: node:16
        workingDir: $(workspaces.source.path)
        script: |
          npm ci
          npm test
    workspaces:
    - name: source
      workspace: source-code
  
  # Build and push image
  - name: build-push
    runAfter: [test]
    taskRef:
      name: buildah
    params:
    - name: IMAGE
      value: $(params.image-name)
    workspaces:
    - name: source
      workspace: source-code
  
  # Deploy to staging
  - name: deploy-staging
    runAfter: [build-push]
    taskSpec:
      params:
      - name: image
      steps:
      - name: deploy
        image: bitnami/kubectl
        script: |
          kubectl set image deployment/app app=$(params.image) -n staging
          kubectl rollout status deployment/app -n staging
    params:
    - name: image
      value: $(params.image-name)
```

## Integration with Observability

### Monitoring Tekton Pipelines
```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: tekton-pipelines
spec:
  selector:
    matchLabels:
      app: tekton-pipelines-controller
  endpoints:
  - port: metrics
```

### Pipeline Metrics
```promql
# Pipeline success rate
sum(rate(tekton_pipelinerun_count{status="success"}[5m])) / sum(rate(tekton_pipelinerun_count[5m]))

# Pipeline duration
histogram_quantile(0.95, rate(tekton_pipelinerun_duration_seconds_bucket[5m]))

# Failed pipelines
sum(rate(tekton_pipelinerun_count{status="failed"}[5m]))
```

### Log Collection
```bash
# Tekton logs automatically collected by Fluentd
kubectl logs -f pipelinerun/nodejs-pipeline-run-1

# Searchable in Kibana
kubernetes.namespace_name:tekton-pipelines AND level:ERROR
```

## Best Practices

### 1. Resource Management
```yaml
# Set resource limits
steps:
- name: build
  image: node:16
  resources:
    requests:
      memory: 512Mi
      cpu: 250m
    limits:
      memory: 1Gi
      cpu: 500m
```

### 2. Security
```yaml
# Use service accounts
spec:
  serviceAccountName: pipeline-sa
  
# Limit permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pipeline-role
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "update", "patch"]
```

### 3. Workspace Management
```yaml
# Use persistent volumes for large workspaces
workspaces:
- name: source-code
  persistentVolumeClaim:
    claimName: pipeline-workspace
```

## Next Steps
- **ArgoCD integration** for GitOps deployment
- **Triggers** for automated pipeline execution
- **Advanced patterns** like parallel execution
- **Multi-cluster** deployments

Tekton gives you **Kubernetes-native CI** with full observability! 🔧