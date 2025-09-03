#!/bin/bash

echo "🔍 Jaeger Tracing Dashboard"
echo "=========================="

# Check Jaeger health
echo ""
echo "📊 Jaeger Status:"
JAEGER_HEALTH=$(curl -s localhost:16686/api/services 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "   ✅ Jaeger UI: http://localhost:16686"
    echo "   ✅ Collector: http://localhost:14268"
    
    # Count services
    SERVICE_COUNT=$(echo "$JAEGER_HEALTH" | jq -r '.total' 2>/dev/null || echo "0")
    echo "   📈 Services tracked: $SERVICE_COUNT"
    
    # List services
    if [ "$SERVICE_COUNT" -gt 0 ]; then
        echo "   🏷️  Services:"
        echo "$JAEGER_HEALTH" | jq -r '.data[]' 2>/dev/null | sed 's/^/      - /'
    fi
else
    echo "   ❌ Jaeger not accessible"
fi

# Check recent traces
echo ""
echo "🔍 Recent Traces:"
TRACES=$(curl -s "localhost:16686/api/traces?service=user-service&limit=5" 2>/dev/null)
if [ $? -eq 0 ] && [ "$(echo "$TRACES" | jq -r '.data | length' 2>/dev/null)" -gt 0 ]; then
    echo "$TRACES" | jq -r '.data[] | "   📋 \(.traceID[0:16])... (\(.spans | length) spans, \((.spans[0].duration / 1000) | floor)ms)"' 2>/dev/null
else
    echo "   📝 No traces found (try generating some traces first)"
fi

# Trace generation suggestions
echo ""
echo "🚀 Generate Sample Traces:"
echo "   bash simple-traces.sh"
echo ""
echo "🔍 Analyze Traces:"
echo "   1. Open http://localhost:16686 in browser"
echo "   2. Select service from dropdown"
echo "   3. Click 'Find Traces'"
echo "   4. Click on trace to see timeline"
echo ""
echo "📊 Key Metrics to Look For:"
echo "   - Total request duration"
echo "   - Longest span (bottleneck)"
echo "   - Error spans (red highlighting)"
echo "   - Service dependencies"
echo ""
echo "Dashboard updated: $(date)"
echo "=========================="