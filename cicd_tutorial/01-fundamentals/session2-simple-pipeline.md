# Session 2: Simple Pipeline (10 minutes)

## What We're Doing
**Create a 3-step pipeline**: test → build → deploy (like GitHub Actions workflow)

## Step 1: Create Pipeline Tasks (1 minute)
```bash
cat << EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: test-task
spec:
  steps:
  - name: test
    image: alpine
    script: |
      echo "🧪 Running tests..."
      sleep 2
      echo "✅ All tests passed!"
---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: build-task
spec:
  steps:
  - name: build
    image: alpine
    script: |
      echo "🔨 Building application..."
      sleep 3
      echo "✅ Build successful!"
---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: deploy-task
spec:
  steps:
  - name: deploy
    image: alpine
    script: |
      echo "🚀 Deploying to cluster..."
      sleep 2
      echo "✅ Deployment complete!"
EOF
```

## Step 2: Create Pipeline (30 seconds)
```bash
cat << EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: simple-pipeline
spec:
  tasks:
  - name: test
    taskRef:
      name: test-task
  - name: build
    taskRef:
      name: build-task
    runAfter: [test]
  - name: deploy
    taskRef:
      name: deploy-task
    runAfter: [build]
EOF
```

## Step 3: Run Pipeline (30 seconds)
```bash
cat << EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: simple-run-$(date +%s)
spec:
  pipelineRef:
    name: simple-pipeline
EOF
```

## Step 4: Watch It Run (2 minutes)
```bash
# Watch pipeline progress
kubectl get pipelinerun

# See all the pods running
kubectl get pods | grep simple-run

# Follow the logs
kubectl logs -f pipelinerun/simple-run-* --all-containers
```

## What You Built
- ✅ **3-step pipeline** (test → build → deploy)
- ✅ **Sequential execution** (waits for each step)
- ✅ **Multiple pods** running your tasks
- ✅ **Same as GitHub Actions** but in your cluster

**Session 2 Complete!** 🎉