# 01. CI/CD Fundamentals

## Traditional vs Kubernetes-Native CI/CD

### Your Experience: GitHub Actions/Azure DevOps
```yaml
# GitHub Actions example
name: Deploy to Kubernetes
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest  # External runner
    steps:
    - uses: actions/checkout@v2
    - name: Build Docker image
      run: docker build -t myapp .
    - name: Push to registry
      run: docker push myapp
    - name: Deploy to K8s
      run: kubectl apply -f deployment.yaml  # Push-based
```

### Kubernetes-Native Approach
```yaml
# Tekton Pipeline (runs in K8s)
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-deploy
spec:
  tasks:
  - name: build
    taskRef:
      name: buildah  # Runs as pod in cluster
  - name: deploy
    taskRef:
      name: argocd-sync  # GitOps pull-based
```

## Key Concepts

### 1. GitOps Pattern
**"Git as single source of truth"**
```
Developer → Git Repository → ArgoCD → Kubernetes
    ↓           ↓              ↓         ↓
  Commit    Git Webhook    Detects     Applies
  Changes   Triggers       Changes     Changes
```

### 2. Pull vs Push Deployment

#### Push-Based (Traditional)
```
CI System → Pushes → Kubernetes Cluster
- CI has cluster credentials
- Security risk if CI compromised
- Limited rollback capabilities
```

#### Pull-Based (GitOps)
```
Git Repository ← Pulls ← ArgoCD (in cluster)
- Cluster pulls from Git
- No external access needed
- Git history = deployment history
```

### 3. Pipeline as Code
```yaml
# Everything defined in YAML
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: microservice-pipeline
spec:
  params:
  - name: git-url
  - name: image-name
  tasks:
  - name: test
  - name: build
  - name: security-scan
  - name: deploy
```

## The Kubernetes-Native Stack

### Build Layer: Tekton
- **Pods as build agents**
- **Kubernetes-native resources**
- **Scalable and secure**

### Deploy Layer: ArgoCD
- **GitOps continuous delivery**
- **Declarative deployments**
- **Multi-cluster support**

### Observe Layer: Your Stack!
- **Prometheus** monitors pipelines
- **Logs** from build pods
- **Traces** through deployment process

## Comparison Table

| Aspect | GitHub Actions | Azure DevOps | Kubernetes-Native |
|--------|---------------|--------------|-------------------|
| **Runners** | GitHub-hosted/Self-hosted VMs | Azure agents/Self-hosted | Pods in cluster |
| **Deployment** | Push-based | Push-based | Pull-based (GitOps) |
| **Scaling** | Limited by runner capacity | Agent pools | Auto-scaling pods |
| **Security** | External credentials | Service connections | RBAC + Network policies |
| **Observability** | Separate monitoring | Azure Monitor | Unified with cluster |
| **Cost** | Per-minute billing | Per-agent licensing | Cluster resources |
| **Kubernetes Integration** | kubectl commands | Azure CLI | Native resources |

## When to Choose Each

### Stick with GitHub Actions/Azure DevOps When:
- **Simple applications** with basic K8s deployments
- **Mixed infrastructure** (not just Kubernetes)
- **Team expertise** in existing tools
- **External integrations** are critical

### Move to Kubernetes-Native When:
- **Kubernetes-first** organization
- **Complex microservices** architecture
- **Resource optimization** is important
- **GitOps adoption** is desired
- **Unified observability** is needed

## Learning Path

### Phase 1: Understand GitOps
- Git as source of truth
- Declarative vs imperative
- Pull-based deployments

### Phase 2: Tekton Basics
- Tasks and Pipelines
- Building in Kubernetes
- Integration with registries

### Phase 3: ArgoCD Deployment
- Application definitions
- Sync strategies
- Multi-environment management

### Phase 4: Advanced Patterns
- Canary deployments
- Multi-cluster GitOps
- Integration with observability

Ready to dive into GitOps! 🚀