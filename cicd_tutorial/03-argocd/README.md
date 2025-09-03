# 03. ArgoCD - GitOps Continuous Delivery

## What is ArgoCD?

**ArgoCD = GitOps continuous delivery tool for Kubernetes**
- **Git as source of truth**
- **Pull-based deployment**
- **Declarative application management**
- **Multi-cluster support**

## GitOps vs Traditional Deployment

### Traditional (Push-based)
```
CI System → kubectl apply → Kubernetes
- CI has cluster credentials
- No audit trail
- Hard to rollback
- Security risk
```

### GitOps (Pull-based)
```
Git Repository ← ArgoCD ← Kubernetes
- Git is source of truth
- Full audit trail
- Easy rollback (git revert)
- Secure (no external access)
```

## Core Concepts

### Application
**Defines what to deploy and where**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/user/app-config
    targetRevision: HEAD
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Project
**Groups applications and defines policies**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
spec:
  destinations:
  - namespace: production
    server: https://kubernetes.default.svc
  sourceRepos:
  - https://github.com/company/*
  roles:
  - name: developers
    policies:
    - p, proj:production:developers, applications, sync, production/*, allow
```

## ArgoCD vs Azure DevOps/GitHub Actions

### Azure DevOps Release Pipeline
```yaml
# azure-pipelines.yml
stages:
- stage: Deploy
  jobs:
  - deployment: DeployToK8s
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - task: KubernetesManifest@0
            inputs:
              action: deploy
              manifests: k8s/*.yaml
```

### ArgoCD Application
```yaml
# argocd-app.yaml (stored in Git)
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
spec:
  source:
    repoURL: https://github.com/company/web-app-config
    path: manifests/
  destination:
    namespace: production
  syncPolicy:
    automated: {}  # Auto-sync when Git changes
```

## Key Advantages

### 1. Git as Source of Truth
```bash
# Deployment history = Git history
git log --oneline
abc123 Update image to v1.2.3
def456 Scale replicas to 5
ghi789 Add new environment variables

# Rollback = Git revert
git revert abc123
# ArgoCD automatically applies the rollback
```

### 2. Declarative Management
```yaml
# Desired state in Git
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3  # Desired: 3 replicas
  template:
    spec:
      containers:
      - image: web-app:v1.2.3  # Desired: v1.2.3

# ArgoCD ensures actual state matches desired state
```

### 3. Multi-Environment Management
```
Git Repository Structure:
├── environments/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── values.yaml
│   └── production/
│       ├── kustomization.yaml
│       └── values.yaml
└── base/
    ├── deployment.yaml
    └── service.yaml
```

## Installation and Setup

### Install ArgoCD
```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### First Application
```yaml
# app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/company/argocd-apps
    targetRevision: HEAD
    path: applications/
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Real-World Workflow

### 1. Developer Workflow
```bash
# Developer makes changes
git clone https://github.com/company/web-app
cd web-app
# Make code changes
git commit -m "Add new feature"
git push origin main

# CI builds new image
# GitHub Actions/Azure DevOps builds web-app:v1.2.4
```

### 2. GitOps Workflow
```bash
# Update deployment config
git clone https://github.com/company/web-app-config
cd web-app-config
# Update image tag in k8s/deployment.yaml
sed -i 's/web-app:v1.2.3/web-app:v1.2.4/' k8s/deployment.yaml
git commit -m "Update to v1.2.4"
git push origin main

# ArgoCD detects change and syncs automatically
```

### 3. Automated Image Updates
```yaml
# Using ArgoCD Image Updater
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  annotations:
    argocd-image-updater.argoproj.io/image-list: web-app=myregistry/web-app
    argocd-image-updater.argoproj.io/write-back-method: git
spec:
  # ... application spec
```

## Integration with Tekton

### Complete CI/CD Flow
```
1. Developer pushes code
   ↓
2. Tekton builds and pushes image
   ↓
3. Tekton updates Git config repo
   ↓
4. ArgoCD detects Git change
   ↓
5. ArgoCD syncs to Kubernetes
```

### Tekton Task for GitOps
```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: update-gitops-repo
spec:
  params:
  - name: image-tag
  - name: git-repo
  steps:
  - name: update-config
    image: alpine/git
    script: |
      git clone $(params.git-repo) /workspace
      cd /workspace
      sed -i 's/image: web-app:.*/image: web-app:$(params.image-tag)/' k8s/deployment.yaml
      git add .
      git commit -m "Update image to $(params.image-tag)"
      git push origin main
```

## Observability Integration

### ArgoCD Metrics
```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
```

### Key Metrics
```promql
# Application sync status
argocd_app_info{sync_status="Synced"}

# Sync frequency
rate(argocd_app_reconcile_count[5m])

# Failed syncs
argocd_app_info{health_status="Degraded"}
```

### Notifications
```yaml
# Slack notifications
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: Application {{.app.metadata.name}} deployed to {{.app.spec.destination.namespace}}
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

## Advanced Patterns

### 1. Progressive Delivery
```yaml
# Canary deployment with Argo Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 30s}
      - setWeight: 50
      - pause: {duration: 30s}
```

### 2. Multi-Cluster GitOps
```yaml
# Production cluster application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app-prod
spec:
  destination:
    server: https://prod-cluster.company.com
    namespace: production
```

### 3. App of Apps Pattern
```yaml
# Root application that manages other applications
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
spec:
  source:
    path: applications/
  # This directory contains multiple Application manifests
```

## Best Practices

### 1. Repository Structure
```
├── apps/                    # Application definitions
│   ├── web-app.yaml
│   └── api-app.yaml
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── base/                    # Base Kubernetes manifests
    ├── deployment.yaml
    └── service.yaml
```

### 2. Security
```yaml
# RBAC for ArgoCD
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: argocd-application-controller
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### 3. Sync Policies
```yaml
# Automated sync with prune and self-heal
syncPolicy:
  automated:
    prune: true      # Delete resources not in Git
    selfHeal: true   # Revert manual changes
  syncOptions:
  - CreateNamespace=true
```

## Comparison Summary

| Feature | GitHub Actions | Azure DevOps | ArgoCD |
|---------|---------------|--------------|---------|
| **Deployment Model** | Push-based | Push-based | Pull-based |
| **Source of Truth** | CI pipeline | Release pipeline | Git repository |
| **Rollback** | Re-run pipeline | Redeploy | Git revert |
| **Audit Trail** | Pipeline logs | Release history | Git history |
| **Security** | External credentials | Service connections | No external access |
| **Multi-cluster** | Complex setup | Azure Arc | Native support |

## Next Steps
- **Advanced deployment strategies** (canary, blue-green)
- **Multi-cluster management**
- **Integration with observability stack**
- **Security and compliance**

ArgoCD gives you **GitOps-powered continuous delivery** with full audit trails! 🚀