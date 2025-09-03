# 🚀 Quick Start - Simple Hands-On Practice

## What We'll Build (5 minutes each)

### **Step 1: Simple Tekton Task** 
```yaml
# Just runs "hello world" in a pod
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello
spec:
  steps:
  - name: hello
    image: alpine
    script: echo "Hello from Kubernetes CI/CD!"
```

### **Step 2: Simple Pipeline**
```yaml
# Runs the hello task
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: simple-pipeline
spec:
  tasks:
  - name: say-hello
    taskRef:
      name: hello
```

### **Step 3: Simple ArgoCD App**
```yaml
# Deploys a simple nginx
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: simple-app
spec:
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps
    path: guestbook
  destination:
    namespace: default
```

## **Practice Sessions**

### **Session 1: Install & Hello World (10 min)**
- Install Tekton (1 command)
- Run hello world task
- See it in your observability stack

### **Session 2: Simple Pipeline (10 min)**  
- Create 3-step pipeline (test → build → deploy)
- Run it and watch logs
- Check metrics in Prometheus

### **Session 3: GitOps Deploy (10 min)**
- Install ArgoCD (1 command)
- Deploy simple app from Git
- See automatic sync

**Total time: 30 minutes of actual hands-on**

## **Super Simple Configs**

All configs are:
- **< 20 lines each**
- **Copy-paste ready**
- **No complex parameters**
- **Immediate results**

**Want to try the first 10-minute session?** Just say "let's start" and I'll give you the exact commands to copy-paste! 🎯