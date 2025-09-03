#!/bin/bash

echo "🏭 Production Observability Stack Dashboard"
echo "==========================================="

# Check namespace
echo ""
echo "📊 Observability Stack Status:"
kubectl get pods -n observability --no-headers | while read line; do
    name=$(echo $line | awk '{print $1}')
    ready=$(echo $line | awk '{print $2}')
    status=$(echo $line | awk '{print $3}')
    
    if [[ "$status" == "Running" && "$ready" == *"/"* ]]; then
        ready_count=$(echo $ready | cut -d'/' -f1)
        total_count=$(echo $ready | cut -d'/' -f2)
        if [[ "$ready_count" == "$total_count" ]]; then
            echo "   ✅ $name: $status ($ready)"
        else
            echo "   🟡 $name: $status ($ready)"
        fi
    elif [[ "$status" == "Running" ]]; then
        echo "   ✅ $name: $status"
    else
        echo "   🔄 $name: $status"
    fi
done

# Check services
echo ""
echo "🌐 Services:"
kubectl get svc -n observability --no-headers | while read line; do
    name=$(echo $line | awk '{print $1}')
    type=$(echo $line | awk '{print $2}')
    cluster_ip=$(echo $line | awk '{print $3}')
    ports=$(echo $line | awk '{print $5}')
    echo "   📡 $name ($type): $cluster_ip:$ports"
done

# Resource usage
echo ""
echo "💾 Resource Usage:"
kubectl top pods -n observability 2>/dev/null | tail -n +2 | while read line; do
    name=$(echo $line | awk '{print $1}')
    cpu=$(echo $line | awk '{print $2}')
    memory=$(echo $line | awk '{print $3}')
    echo "   📈 $name: CPU=$cpu, Memory=$memory"
done || echo "   ℹ️  Metrics server not available for resource usage"

# Storage usage
echo ""
echo "💿 Storage:"
kubectl get pvc -n observability --no-headers 2>/dev/null | while read line; do
    name=$(echo $line | awk '{print $1}')
    status=$(echo $line | awk '{print $2}')
    volume=$(echo $line | awk '{print $3}')
    capacity=$(echo $line | awk '{print $4}')
    echo "   💾 $name: $status ($capacity)"
done || echo "   ℹ️  No persistent volumes found"

# Port forwarding instructions
echo ""
echo "🔗 Access Instructions:"
echo "   Prometheus:  kubectl port-forward -n observability svc/prometheus 9090:9090"
echo "   Kibana:      kubectl port-forward -n observability svc/kibana 5601:5601"
echo "   Jaeger:      kubectl port-forward -n observability svc/jaeger 16686:16686"
echo ""
echo "   Then access:"
echo "   📊 Prometheus: http://localhost:9090"
echo "   📝 Kibana:     http://localhost:5601"
echo "   🔍 Jaeger:     http://localhost:16686"

# Health checks
echo ""
echo "🏥 Health Checks:"

# Check if we can reach services internally
kubectl exec -n observability deployment/prometheus -- wget -q --spider http://localhost:9090 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Prometheus: Healthy"
else
    echo "   ❌ Prometheus: Not responding"
fi

kubectl exec -n observability deployment/kibana -- curl -s http://localhost:5601 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Kibana: Healthy"
else
    echo "   ❌ Kibana: Not responding"
fi

kubectl exec -n observability deployment/jaeger -- wget -q --spider http://localhost:16686 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Jaeger: Healthy"
else
    echo "   ❌ Jaeger: Not responding"
fi

# Configuration summary
echo ""
echo "⚙️  Configuration Summary:"
echo "   📊 Prometheus: 15d retention, cluster-wide scraping"
echo "   📝 Elasticsearch: Single node, 100GB storage"
echo "   🔍 Jaeger: Elasticsearch backend, 100k traces"
echo "   📡 Fluentd: All pod logs collected"

echo ""
echo "Dashboard updated: $(date)"
echo "==========================================="