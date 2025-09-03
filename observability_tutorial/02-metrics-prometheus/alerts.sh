#!/bin/bash

echo "🚨 Cluster Health Alerts"
echo "========================"

# Helper function
query() {
    local q="$1"
    local encoded=$(echo "$q" | sed 's/ /%20/g' | sed 's/{/%7B/g' | sed 's/}/%7D/g' | sed 's/=/%3D/g' | sed 's/"/%22/g')
    curl -s "localhost:9090/api/v1/query?query=$encoded" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0"
}

# Check memory usage
MEM_AVAILABLE=$(query 'node_memory_MemAvailable_bytes')
MEM_TOTAL=$(query 'node_memory_MemTotal_bytes')
if [[ "$MEM_AVAILABLE" != "0" && "$MEM_TOTAL" != "0" ]]; then
    MEM_USED_PCT=$(echo "scale=1; (1 - $MEM_AVAILABLE / $MEM_TOTAL) * 100" | bc -l 2>/dev/null)
    if (( $(echo "$MEM_USED_PCT > 80" | bc -l) )); then
        echo "🔴 HIGH MEMORY USAGE: ${MEM_USED_PCT}%"
    else
        echo "🟢 Memory usage OK: ${MEM_USED_PCT}%"
    fi
fi

# Check disk usage
DISK_AVAIL=$(query 'node_filesystem_avail_bytes')
DISK_SIZE=$(query 'node_filesystem_size_bytes')
if [[ "$DISK_AVAIL" != "0" && "$DISK_SIZE" != "0" ]]; then
    DISK_USED_PCT=$(echo "scale=1; (1 - $DISK_AVAIL / $DISK_SIZE) * 100" | bc -l 2>/dev/null)
    if (( $(echo "$DISK_USED_PCT > 85" | bc -l) )); then
        echo "🔴 HIGH DISK USAGE: ${DISK_USED_PCT}%"
    else
        echo "🟢 Disk usage OK: ${DISK_USED_PCT}%"
    fi
fi

# Check pod failures
FAILED_PODS=$(query 'count(kube_pod_status_phase{phase="Failed"})')
if [[ "$FAILED_PODS" != "0" && "$FAILED_PODS" -gt 0 ]]; then
    echo "🔴 FAILED PODS: $FAILED_PODS pods in failed state"
else
    echo "🟢 No failed pods"
fi

# Check Prometheus targets
TARGETS_DOWN=$(query 'count(up == 0)')
if [[ "$TARGETS_DOWN" != "0" && "$TARGETS_DOWN" -gt 0 ]]; then
    echo "🔴 MONITORING ISSUE: $TARGETS_DOWN targets down"
else
    echo "🟢 All monitoring targets up"
fi

echo ""
echo "Alert check completed: $(date)"