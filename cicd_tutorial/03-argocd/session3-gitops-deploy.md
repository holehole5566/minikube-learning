# Session 3: GitOps Deploy (10 minutes)

## What We're Doing
**Add ArgoCD for GitOps** - deploy apps automatically from Git (no more kubectl apply!)

## Step 1: Install ArgoCD (1 minute)
```bash
# Create namespace and install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## Step 2: Wait for ArgoCD to be Ready (2 minutes)
```bash
# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## Step 3: Create Simple GitOps App (30 seconds)
```bash
cat << EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simple-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

## Step 4: Watch GitOps Magic (2 minutes)
```bash
# Check ArgoCD application
kubectl get application -n argocd

# See what ArgoCD deployed
kubectl get all -l app.kubernetes.io/instance=simple-app

# Check the actual app
kubectl get pods | grep guestbook
```

## Step 5: Access ArgoCD UI (Optional)
```bash
# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Access at: https://localhost:8080
# Username: admin
# Password: (from step 2)
```

## What Just Happened?
- ✅ **ArgoCD installed** and running
- ✅ **App deployed from Git** (no kubectl apply!)
- ✅ **Automatic sync** - Git is source of truth
- ✅ **Self-healing** - manual changes get reverted

## The GitOps Difference
```bash
# Traditional: Push-based
kubectl apply -f deployment.yaml

# GitOps: Pull-based  
Git Repository → ArgoCD → Kubernetes
```

**Session 3 Complete!** 🎉

You now have **complete Kubernetes-native CI/CD**:
- **Tekton**: Builds in your cluster
- **ArgoCD**: Deploys from Git
- **Your observability**: Monitors everything!