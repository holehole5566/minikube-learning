#!/bin/bash

# Elasticsearch credentials
ES_USER="elastic"
ES_PASS="2kwPlRqbP1xSjD6e"
ES_URL="https://localhost:9200"

# Helper function to query Elasticsearch
es_query() {
    local endpoint="$1"
    curl -s -k -u "$ES_USER:$ES_PASS" "$ES_URL$endpoint"
}

# Check cluster health
echo "🔍 Elasticsearch Cluster Health:"
es_query "/_cluster/health" | jq -r '"Status: \(.status) | Nodes: \(.number_of_nodes) | Indices: \(.active_primary_shards)"'

echo ""
echo "📊 Available Indices:"
es_query "/_cat/indices?v" | head -10

echo ""
echo "🔍 Recent Logs (if any):"
# Try to get recent logs from logstash index pattern
es_query "/logstash-*/_search?size=5&sort=@timestamp:desc" | jq -r '.hits.hits[]._source | "\(.["@timestamp"]) [\(.kubernetes.namespace_name)/\(.kubernetes.pod_name)] \(.message // .log)"' 2>/dev/null || echo "No logs found yet (Fluentd may still be starting)"

echo ""
echo "📈 Log Count by Index:"
es_query "/_cat/count/*?v" | head -5