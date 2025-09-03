# 01. Helm Installation & Setup

## Install Helm CLI

### Method 1: Script Installation (Recommended)
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Method 2: Manual Installation
```bash
# Download Helm
curl -LO https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz

# Extract and install
tar -xzf helm-v3.12.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Verify installation
helm version
```

## Add Popular Repositories
```bash
# Add Bitnami repository (most popular)
helm repo add bitnami https://charts.bitnami.com/bitnami

# Add stable repository
helm repo add stable https://charts.helm.sh/stable

# Add ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update repositories
helm repo update

# List repositories
helm repo list
```

## Basic Helm Commands
```bash
# Search for charts
helm search repo nginx
helm search hub wordpress

# Show chart information
helm show chart bitnami/nginx
helm show values bitnami/nginx

# Install a chart
helm install my-nginx bitnami/nginx

# List installed releases
helm list

# Get release status
helm status my-nginx

# Uninstall release
helm uninstall my-nginx
```

## Verify Setup
Run these commands to ensure everything works:
```bash
helm version
helm repo list
helm search repo nginx
```

Next: Create your first chart in `02-basic-chart/`