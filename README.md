# Kubernetes Tutorial with Minikube

## Install Minikube
```bash
# Download and install Minikube (ARM64)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
sudo install minikube-linux-arm64 /usr/local/bin/minikube

# Verify installation
minikube version
```

## Setup Commands
```bash
# Start Minikube
minikube start

# Check cluster status
kubectl cluster-info
kubectl get nodes

# Enable addons
minikube addons enable ingress
minikube addons enable dashboard
```

## Essential kubectl Commands
```bash
# Basic operations
kubectl get pods
kubectl get services
kubectl get deployments
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Apply/Delete resources
kubectl apply -f <file.yaml>
kubectl delete -f <file.yaml>

# Port forwarding
kubectl port-forward pod/<pod-name> 8080:80

# Execute commands in pod
kubectl exec -it <pod-name> -- /bin/bash
```

## Directory Structure
- `01-pods/` - Basic pod examples
- `02-services/` - Service configurations
- `03-deployments/` - Deployment manifests
- `04-configmaps-secrets/` - Configuration management
- `05-volumes/` - Storage examples
- `06-ingress/` - Ingress controllers
- `07-advanced/` - StatefulSets, Jobs, etc.

## Quick Start
1. Start with `01-pods/simple-pod.yaml`
2. Progress through each directory in order
3. Use `kubectl apply -f <file>` to deploy
4. Use `kubectl delete -f <file>` to cleanup