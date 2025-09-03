#!/bin/bash

echo "🔍 Kubernetes Cluster Dashboard"
echo "================================"

# Helper function to query Prometheus
query() {
    local q="$1"
    local encoded=$(echo "$q" | sed 's/ /%20/g' | sed 's/{/%7B/g' | sed 's/}/%7D/g' | sed 's/=/%3D/g' | sed 's/"/%22/g')
    curl -s "localhost:9090/api/v1/query?query=$encoded" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "N/A"
}

# Cluster Overview
echo ""
echo "📊 Cluster Overview:"
TOTAL_PODS=$(query 'count(kube_pod_info)')
RUNNING_PODS=$(query 'count(kube_pod_status_phase)')
echo "   Total Pods: $TOTAL_PODS"
echo "   Running Pods: $RUNNING_PODS"

# Memory Usage
echo ""
echo "💾 Memory Usage:"
MEM_AVAILABLE=$(query 'node_memory_MemAvailable_bytes')
MEM_TOTAL=$(query 'node_memory_MemTotal_bytes')
if [[ "$MEM_AVAILABLE" != "N/A" && "$MEM_TOTAL" != "N/A" ]]; then
    MEM_USED_PCT=$(echo "scale=1; (1 - $MEM_AVAILABLE / $MEM_TOTAL) * 100" | bc -l 2>/dev/null || echo "N/A")
    MEM_AVAILABLE_GB=$(echo "scale=1; $MEM_AVAILABLE / 1024 / 1024 / 1024" | bc -l 2>/dev/null || echo "N/A")
    MEM_TOTAL_GB=$(echo "scale=1; $MEM_TOTAL / 1024 / 1024 / 1024" | bc -l 2>/dev/null || echo "N/A")
    echo "   Available: ${MEM_AVAILABLE_GB}GB / ${MEM_TOTAL_GB}GB"
    echo "   Used: ${MEM_USED_PCT}%"
else
    echo "   Memory data unavailable"
fi

# Disk Usage
echo ""
echo "💿 Disk Usage:"
DISK_AVAIL=$(query 'node_filesystem_avail_bytes')
DISK_SIZE=$(query 'node_filesystem_size_bytes')
if [[ "$DISK_AVAIL" != "N/A" && "$DISK_SIZE" != "N/A" ]]; then
    DISK_USED_PCT=$(echo "scale=1; (1 - $DISK_AVAIL / $DISK_SIZE) * 100" | bc -l 2>/dev/null || echo "N/A")
    DISK_AVAIL_GB=$(echo "scale=1; $DISK_AVAIL / 1024 / 1024 / 1024" | bc -l 2>/dev/null || echo "N/A")
    echo "   Available: ${DISK_AVAIL_GB}GB"
    echo "   Used: ${DISK_USED_PCT}%"
else
    echo "   Disk data unavailable"
fi

# Prometheus Stats
echo ""
echo "🔥 Prometheus Stats:"
PROM_TARGETS=$(query 'count(up)')
PROM_UP=$(query 'count(up == 1)')
echo "   Targets: $PROM_UP/$PROM_TARGETS up"

# Top Memory Consuming Pods
echo ""
echo "🏆 Top Memory Using Pods:"
curl -s "localhost:9090/api/v1/query?query=topk(5,container_memory_usage_bytes%7Bcontainer!%3D%22POD%22,container!%3D%22%22%7D)" | \
jq -r '.data.result[] | "\(.metric.pod): \((.value[1] | tonumber / 1024 / 1024 | floor))MB"' 2>/dev/null | head -5

echo ""
echo "Dashboard updated: $(date)"
echo "================================"