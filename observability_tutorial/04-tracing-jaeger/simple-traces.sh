#!/bin/bash

echo "🔍 Generating sample traces for Jaeger..."

# Function to generate a random hex string
random_hex() {
    local length=$1
    openssl rand -hex $((length/2))
}

# Function to send a trace
send_trace() {
    local service_name="$1"
    local operation_name="$2"
    local duration_ms="$3"
    local error="$4"
    
    local trace_id=$(random_hex 32)
    local span_id=$(random_hex 16)
    local start_time=$(($(date +%s) * 1000000))  # microseconds
    local duration_us=$((duration_ms * 1000))   # convert to microseconds
    
    local trace_json="{
        \"data\": [{
            \"traceID\": \"$trace_id\",
            \"spanID\": \"$span_id\",
            \"operationName\": \"$operation_name\",
            \"startTime\": $start_time,
            \"duration\": $duration_us,
            \"tags\": [
                {\"key\": \"service.name\", \"value\": \"$service_name\"},
                {\"key\": \"span.kind\", \"value\": \"server\"}
            ],
            \"process\": {
                \"serviceName\": \"$service_name\",
                \"tags\": []
            }
        }]
    }"
    
    # Send trace using Jaeger's thrift format endpoint
    echo "$trace_json" | curl -s -X POST \
        -H "Content-Type: application/x-thrift" \
        --data-binary @- \
        "localhost:14268/api/traces" > /dev/null
    
    local status="✅"
    if [ "$error" = "true" ]; then
        status="❌"
    fi
    
    echo "$status $service_name: $operation_name ($duration_ms ms)"
}

# Generate various trace scenarios
echo ""
echo "Generating traces..."

send_trace "user-service" "GET /api/users/123" 120 false
sleep 1

send_trace "order-service" "POST /api/orders" 250 false  
sleep 1

send_trace "payment-service" "process_payment" 1500 true
sleep 1

send_trace "user-service" "database_query" 800 false
sleep 1

send_trace "cache-service" "cache_lookup" 15 false
sleep 1

send_trace "order-service" "GET /api/orders/456" 95 false
sleep 1

send_trace "payment-service" "external_api_call" 2000 true
sleep 1

send_trace "user-service" "authenticate" 45 false
sleep 1

echo ""
echo "🎉 Trace generation complete!"
echo "📊 Check Jaeger UI at: http://localhost:16686"
echo ""
echo "Available services should include:"
echo "  - user-service"
echo "  - order-service" 
echo "  - payment-service"
echo "  - cache-service"