#!/bin/bash

# Simple Prometheus query script
# Usage: ./query.sh "your_promql_query"

QUERY="$1"
if [ -z "$QUERY" ]; then
    echo "Usage: $0 'promql_query'"
    echo "Example: $0 'up'"
    exit 1
fi

# URL encode the query
ENCODED_QUERY=$(echo "$QUERY" | sed 's/ /%20/g' | sed 's/{/%7B/g' | sed 's/}/%7D/g' | sed 's/=/%3D/g' | sed 's/"/%22/g')

# Query Prometheus
curl -s "localhost:9090/api/v1/query?query=$ENCODED_QUERY" | jq -r '.data.result[] | "\(.metric | to_entries | map("\(.key)=\(.value)") | join(" ")) value=\(.value[1])"' 2>/dev/null || curl -s "localhost:9090/api/v1/query?query=$ENCODED_QUERY"