# Helm Hooks - Simple Guide

## What Are Hooks?
**Hooks = Jobs that run at specific times during deployment**

Think of them as "before" and "after" scripts for your deployments.

## The 3 Most Important Hooks

### 1. Database Migration (post-install, pre-upgrade)
```yaml
annotations:
  "helm.sh/hook": post-install,pre-upgrade
```
**When**: After first install, before each upgrade
**Why**: Update database schema safely

### 2. Backup (pre-upgrade)  
```yaml
annotations:
  "helm.sh/hook": pre-upgrade
```
**When**: Before upgrading
**Why**: Backup data in case upgrade fails

### 3. Cleanup (post-delete)
```yaml
annotations:
  "helm.sh/hook": post-delete  
```
**When**: After deleting the app
**Why**: Clean up external resources (S3 buckets, DNS, etc.)

## Simple Hook Template
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: my-hook
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: hook-job
        image: alpine
        command: ["echo", "Hello from hook!"]
```

## Hook Order (Weights)
```
-1: Backup first
 0: Default  
 1: Migration
 2: Health check last
```

## When Do You Actually Need Hooks?

### You NEED hooks for:
- **Database migrations** (schema changes)
- **Backups before upgrades** (safety)
- **Cleanup external resources** (S3, DNS)

### You DON'T need hooks for:
- **Waiting for services** (use init containers)
- **Simple configuration** (use regular templates)
- **Basic deployments** (hooks add complexity)

## Real-World Usage
**80% of teams**: Never write custom hooks, use existing charts
**15% of teams**: Use simple migration hooks only  
**5% of teams**: Complex hook workflows (platform teams)

## The Bottom Line
- **Hooks = Jobs that run during deployment lifecycle**
- **Most common**: Database migration hook
- **Start simple**: Only add hooks when you actually need them
- **Alternative**: Many teams use CI/CD pipelines instead of hooks

Hooks are powerful but add complexity. Use them only when simpler solutions don't work.