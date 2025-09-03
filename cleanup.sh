#!/bin/bash

echo "🧹 Kubernetes Resource Cleanup"
echo "=============================="

# Function to delete resources safely
safe_delete() {
    local resource=$1
    local namespace=${2:-"default"}
    
    if kubectl get $resource -n $namespace &>/dev/null; then
        echo "🗑️  Deleting $resource in namespace $namespace"
        kubectl delete $resource -n $namespace --timeout=60s
    else
        echo "✅ $resource not found in namespace $namespace"
    fi
}

# 1. Clean up CI/CD resources
echo ""
echo "1. Cleaning up CI/CD resources..."
safe_delete "application simple-app" "argocd"
safe_delete "pipelinerun --all" "default"
safe_delete "taskrun --all" "default"
safe_delete "pipeline --all" "default"
safe_delete "task --all" "default"

# 2. Clean up namespaces (this will delete everything inside)
echo ""
echo "2. Cleaning up namespaces..."
kubectl delete namespace argocd --timeout=120s 2>/dev/null || echo "✅ argocd namespace not found"
kubectl delete namespace tekton-pipelines --timeout=120s 2>/dev/null || echo "✅ tekton-pipelines namespace not found"
kubectl delete namespace tekton-pipelines-resolvers --timeout=120s 2>/dev/null || echo "✅ tekton-pipelines-resolvers namespace not found"
kubectl delete namespace observability --timeout=120s 2>/dev/null || echo "✅ observability namespace not found"
kubectl delete namespace monitoring --timeout=120s 2>/dev/null || echo "✅ monitoring namespace not found"

# 3. Clean up remaining resources in default namespace
echo ""
echo "3. Cleaning up default namespace..."
kubectl delete deployment,service,pod --all --timeout=60s 2>/dev/null || echo "✅ Default namespace clean"

# 4. Clean up cluster-wide resources
echo ""
echo "4. Cleaning up cluster-wide resources..."
kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/part-of=tekton-pipelines --timeout=60s 2>/dev/null || echo "✅ Tekton cluster resources clean"
kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/part-of=argocd --timeout=60s 2>/dev/null || echo "✅ ArgoCD cluster resources clean"

# 5. Clean up CRDs
echo ""
echo "5. Cleaning up Custom Resource Definitions..."
kubectl delete crd -l app.kubernetes.io/part-of=tekton-pipelines --timeout=60s 2>/dev/null || echo "✅ Tekton CRDs clean"
kubectl delete crd -l app.kubernetes.io/part-of=argocd --timeout=60s 2>/dev/null || echo "✅ ArgoCD CRDs clean"

# 6. Final status check
echo ""
echo "6. Final status check..."
echo "📊 Remaining namespaces:"
kubectl get namespaces

echo ""
echo "📊 Remaining pods:"
kubectl get pods --all-namespaces | grep -v "kube-system\|kube-public\|kube-node-lease" || echo "✅ No user pods remaining"

echo ""
echo "🎉 Cleanup complete!"
echo "=============================="