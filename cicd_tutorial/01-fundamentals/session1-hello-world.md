# Session 1: Hello World (10 minutes)

## What We're Doing
**Replace GitHub Actions with Tekton** - simplest possible example

## Step 1: Install Tekton (1 minute)
```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

## Step 2: Create Hello Task (30 seconds)
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
    script: |
      echo "🚀 Hello from Tekton!"
      echo "Running in pod: \$HOSTNAME"
      echo "This replaces GitHub Actions runner!"
EOF
```

## Step 3: Run the Task (30 seconds)
```bash
cat << EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: hello-run-$(date +%s)
spec:
  taskRef:
    name: hello-task
EOF
```

## Step 4: See Results (1 minute)
```bash
# Check status
kubectl get taskrun

# See the logs (like GitHub Actions logs)
kubectl logs -l tekton.dev/taskRun --tail=20

# Check what pods ran
kubectl get pods | grep hello
```

## What Just Happened?
- ✅ **Tekton installed** in your cluster
- ✅ **Task ran as pod** (not external runner)
- ✅ **Logs collected** by your observability stack
- ✅ **Pod auto-cleaned** when done

## The Difference
```bash
# GitHub Actions: Runs on GitHub servers
runs-on: ubuntu-latest

# Tekton: Runs in YOUR cluster as pods
image: alpine  # Any container image
```

**Session 1 Complete!** 🎉

Ready for **Session 2** (Simple Pipeline)? Or want to explore what we just built?