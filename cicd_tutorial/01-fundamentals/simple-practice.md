# Simple Practice - 10 Minutes

## What You'll Do
**Compare GitHub Actions vs Tekton** with the simplest possible example

## GitHub Actions Way (What You Know)
```yaml
# .github/workflows/hello.yml
name: Hello World
on: [push]
jobs:
  hello:
    runs-on: ubuntu-latest  # External runner
    steps:
    - run: echo "Hello from GitHub Actions!"
```

## Tekton Way (What You'll Learn)
```yaml
# hello-task.yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello-task
spec:
  steps:
  - name: hello
    image: alpine
    script: echo "Hello from Tekton!"
```

## Hands-On (Copy-Paste These Commands)

### 1. Install Tekton (30 seconds)
```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

### 2. Create Simple Task (30 seconds)
```bash
cat << EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: hello-task
spec:
  steps:
  - name: hello
    image: alpine
    script: echo "Hello from Tekton in Kubernetes!"
EOF
```

### 3. Run the Task (30 seconds)
```bash
cat << EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: hello-run
spec:
  taskRef:
    name: hello-task
EOF
```

### 4. See Results (30 seconds)
```bash
# Watch it run
kubectl get taskrun hello-run

# See the logs (like GitHub Actions logs)
kubectl logs -f taskrun/hello-run
```

## What You Just Did
- ✅ **Replaced GitHub Actions runner** with Kubernetes pod
- ✅ **Same result** but running in your cluster
- ✅ **Logs collected** by your observability stack
- ✅ **Resources auto-cleaned** when done

## The Difference
```bash
# GitHub Actions: External runner, separate monitoring
# Tekton: Your cluster, your observability stack

# Check in Prometheus (your existing stack!)
kubectl logs -n observability deployment/prometheus | grep tekton
```

**Total time: 2 minutes setup + 30 seconds to see results**

**Ready for the next 10-minute session?** We'll build a simple 3-step pipeline! 🚀