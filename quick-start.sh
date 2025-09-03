#!/bin/bash

echo "Starting Minikube..."
minikube start

echo "Deploying basic pod..."
kubectl apply -f 01-pods/simple-pod.yaml

echo "Creating service..."
kubectl apply -f 02-services/nodeport-service.yaml

echo "Checking deployment..."
kubectl get pods,services

echo "Access the service at:"
minikube service webapp-service --url