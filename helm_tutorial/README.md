# Helm Tutorial - Kubernetes Package Manager

## What is Helm?
Helm is the package manager for Kubernetes, like apt for Ubuntu or npm for Node.js. It helps you:
- Package Kubernetes applications into reusable charts
- Manage complex deployments with templates
- Version control your applications
- Share applications via repositories

## Prerequisites
- Kubernetes cluster running (Minikube)
- kubectl configured
- Basic Kubernetes knowledge (pods, services, deployments)

## Tutorial Roadmap

### 01. Installation & Setup
- Install Helm CLI
- Add popular repositories
- Basic Helm commands

### 02. Basic Chart Creation
- Create your first Helm chart
- Understand chart structure
- Deploy a simple application

### 03. Templating Basics
- Helm template syntax
- Built-in functions
- Conditional logic

### 04. Values & Configuration
- values.yaml files
- Override values
- Environment-specific configs

### 05. Chart Dependencies
- Add external charts as dependencies
- Manage sub-charts
- Database + application example

### 06. Hooks & Lifecycle
- Pre/post install hooks
- Jobs and init containers
- Database migrations

### 07. Real-World Example
- Complete microservices application
- Production-ready configurations
- Best practices

## Quick Start Commands
```bash
# Install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar -xz
sudo mv linux-amd64/helm /usr/local/bin/

# Add repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create your first chart
helm create my-app

# Install a chart
helm install my-release bitnami/nginx
```

## Learning Path
1. Start with `01-installation/`
2. Progress through each directory in order
3. Practice with hands-on examples
4. Build your own charts

Let's get started! 🚀