#!/bin/bash

echo "Installing Minikube for ARM64..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-arm64
sudo install minikube-linux-arm64 /usr/local/bin/minikube
rm minikube-linux-arm64

echo "Verifying installation..."
minikube version

echo "Starting Minikube..."
minikube start

echo "Enabling addons..."
minikube addons enable ingress
minikube addons enable dashboard

echo "Checking cluster status..."
kubectl cluster-info
kubectl get nodes

echo "Minikube setup complete!"