# 06. Hooks & Lifecycle Management

## What are Helm Hooks?
Hooks allow you to intervene at certain points in a release lifecycle (install, upgrade, delete) to run jobs like database migrations, backups, or cleanup tasks.

## Hook Types

### Installation Hooks
- `pre-install`: Before any resources are created
- `post-install`: After all resources are created and ready

### Upgrade Hooks  
- `pre-upgrade`: Before upgrade starts
- `post-upgrade`: After upgrade completes

### Deletion Hooks
- `pre-delete`: Before resources are deleted
- `post-delete`: After resources are deleted

### Rollback Hooks
- `pre-rollback`: Before rollback starts
- `post-rollback`: After rollback completes

## Hook Annotations
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "webapp.fullname" . }}-db-migration"
  annotations:
    # Hook type
    "helm.sh/hook": pre-upgrade,post-install
    
    # Hook weight (execution order)
    "helm.sh/hook-weight": "1"
    
    # Hook deletion policy
    "helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```

## Database Migration Hook
```yaml
# templates/hooks/db-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "webapp.fullname" . }}-db-migration"
  annotations:
    "helm.sh/hook": pre-upgrade,post-install
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    metadata:
      name: "{{ include "webapp.fullname" . }}-db-migration"
    spec:
      restartPolicy: Never
      containers:
      - name: db-migration
        image: "{{ .Values.migration.image.repository }}:{{ .Values.migration.image.tag }}"
        command:
        - /bin/sh
        - -c
        - |
          echo "Running database migrations..."
          npm run migrate
        env:
        - name: DB_HOST
          value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
        - name: DB_NAME
          value: {{ .Values.postgresql.auth.database }}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "postgresql.secretName" .Subcharts.postgresql }}
              key: postgres-password
```

## Backup Hook (Pre-Upgrade)
```yaml
# templates/hooks/backup.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "webapp.fullname" . }}-backup-{{ .Release.Revision }}"
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "-1"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: backup
        image: postgres:13
        command:
        - /bin/bash
        - -c
        - |
          echo "Creating database backup..."
          pg_dump -h $DB_HOST -U postgres $DB_NAME > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
          echo "Backup completed"
        env:
        - name: DB_HOST
          value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
        - name: DB_NAME
          value: {{ .Values.postgresql.auth.database }}
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ include "postgresql.secretName" .Subcharts.postgresql }}
              key: postgres-password
        volumeMounts:
        - name: backup-storage
          mountPath: /backup
      volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-pvc
```

## Cleanup Hook (Post-Delete)
```yaml
# templates/hooks/cleanup.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "webapp.fullname" . }}-cleanup"
  annotations:
    "helm.sh/hook": post-delete
    "helm.sh/hook-weight": "1"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: cleanup
        image: alpine:3.16
        command:
        - /bin/sh
        - -c
        - |
          echo "Cleaning up external resources..."
          # Remove S3 buckets, DNS records, etc.
          echo "Cleanup completed"
```

## Init Container vs Hook

### Init Container (runs every pod start)
```yaml
# templates/deployment.yaml
spec:
  template:
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox:1.35
        command:
        - /bin/sh
        - -c
        - |
          until nc -z $DB_HOST $DB_PORT; do
            echo "Waiting for database..."
            sleep 2
          done
        env:
        - name: DB_HOST
          value: {{ include "postgresql.primary.fullname" .Subcharts.postgresql }}
        - name: DB_PORT
          value: "5432"
```

### Hook (runs once per release lifecycle)
```yaml
# templates/hooks/db-setup.yaml
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "1"
spec:
  template:
    spec:
      containers:
      - name: db-setup
        image: postgres:13
        command: ["psql", "-c", "CREATE DATABASE IF NOT EXISTS webapp;"]
```

## Hook Deletion Policies

### before-hook-creation
Deletes previous hook before creating new one
```yaml
"helm.sh/hook-delete-policy": before-hook-creation
```

### hook-succeeded  
Deletes hook after successful completion
```yaml
"helm.sh/hook-delete-policy": hook-succeeded
```

### hook-failed
Deletes hook after failure
```yaml
"helm.sh/hook-delete-policy": hook-failed
```

### Multiple policies
```yaml
"helm.sh/hook-delete-policy": before-hook-creation,hook-succeeded
```

## Hook Weights (Execution Order)
```yaml
# Backup first (weight: -2)
"helm.sh/hook-weight": "-2"

# Then migration (weight: -1)  
"helm.sh/hook-weight": "-1"

# Then seed data (weight: 0, default)
"helm.sh/hook-weight": "0"

# Finally notify (weight: 1)
"helm.sh/hook-weight": "1"
```

## Testing Hooks
```bash
# Dry run to see hooks
helm install webapp ./webapp --dry-run --debug

# Install and watch hooks
helm install webapp ./webapp
kubectl get jobs -w

# Check hook logs
kubectl logs job/webapp-db-migration

# Upgrade to trigger pre/post-upgrade hooks
helm upgrade webapp ./webapp --set image.tag=2.0
```

## Best Practices
- Use appropriate hook types for the task
- Set proper hook weights for execution order
- Choose correct deletion policies
- Make hooks idempotent (safe to run multiple times)
- Add proper error handling in hook scripts
- Use timeouts for long-running hooks
- Test hooks in development environment

## Common Hook Patterns
- **Database migrations**: post-install, pre-upgrade
- **Backups**: pre-upgrade, pre-delete
- **Cache warming**: post-install, post-upgrade
- **Cleanup**: post-delete
- **Health checks**: post-install, post-upgrade
- **Notifications**: post-install, post-upgrade, post-delete

Next: Build a real-world application in `07-real-world/`