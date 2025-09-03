#!/usr/bin/env python3

import time
import random
import requests
import json
from datetime import datetime

# Simple trace generator without external dependencies
class SimpleTracer:
    def __init__(self, service_name, jaeger_endpoint):
        self.service_name = service_name
        self.jaeger_endpoint = jaeger_endpoint
        
    def create_trace(self, operation_name, duration_ms, tags=None, error=False):
        trace_id = f"{random.randint(100000000000000000, 999999999999999999):016x}"
        span_id = f"{random.randint(1000000000000000, 9999999999999999):016x}"
        
        start_time = int(time.time() * 1000000)  # microseconds
        
        span = {
            "traceID": trace_id,
            "spanID": span_id,
            "operationName": operation_name,
            "startTime": start_time,
            "duration": duration_ms * 1000,  # convert to microseconds
            "tags": [
                {"key": "service.name", "value": self.service_name},
                {"key": "span.kind", "value": "server"}
            ],
            "process": {
                "serviceName": self.service_name,
                "tags": []
            }
        }
        
        if tags:
            for key, value in tags.items():
                span["tags"].append({"key": key, "value": str(value)})
                
        if error:
            span["tags"].append({"key": "error", "value": True})
            span["logs"] = [{
                "timestamp": start_time + (duration_ms * 500),  # middle of span
                "fields": [
                    {"key": "event", "value": "error"},
                    {"key": "message", "value": "Operation failed"}
                ]
            }]
            
        return {"data": [span]}
    
    def send_trace(self, trace_data):
        try:
            response = requests.post(
                f"{self.jaeger_endpoint}/api/traces",
                json=trace_data,
                headers={"Content-Type": "application/json"},
                timeout=5
            )
            return response.status_code == 202
        except Exception as e:
            print(f"Failed to send trace: {e}")
            return False

def generate_sample_traces():
    tracer = SimpleTracer("demo-service", "http://localhost:14268")
    
    scenarios = [
        {
            "name": "fast_user_lookup",
            "operation": "GET /api/users/123",
            "duration": random.randint(50, 150),
            "tags": {"http.method": "GET", "user.id": "123", "http.status_code": 200},
            "error": False
        },
        {
            "name": "slow_database_query", 
            "operation": "database_query",
            "duration": random.randint(800, 1200),
            "tags": {"db.statement": "SELECT * FROM users", "db.type": "postgresql"},
            "error": False
        },
        {
            "name": "payment_timeout",
            "operation": "POST /api/payments",
            "duration": random.randint(2000, 3000),
            "tags": {"http.method": "POST", "payment.amount": "99.99", "http.status_code": 500},
            "error": True
        },
        {
            "name": "cache_hit",
            "operation": "cache_lookup",
            "duration": random.randint(5, 15),
            "tags": {"cache.key": "user:123", "cache.hit": True},
            "error": False
        },
        {
            "name": "external_api_call",
            "operation": "external_service_call",
            "duration": random.randint(300, 600),
            "tags": {"service.name": "payment-gateway", "http.url": "https://api.stripe.com"},
            "error": random.random() < 0.2  # 20% error rate
        }
    ]
    
    print("🔍 Generating sample traces...")
    
    for i in range(20):  # Generate 20 traces
        scenario = random.choice(scenarios)
        
        trace_data = tracer.create_trace(
            operation_name=scenario["operation"],
            duration_ms=scenario["duration"],
            tags=scenario["tags"],
            error=scenario["error"]
        )
        
        success = tracer.send_trace(trace_data)
        status = "✅" if success else "❌"
        error_indicator = " (ERROR)" if scenario["error"] else ""
        
        print(f"{status} {scenario['name']}: {scenario['duration']}ms{error_indicator}")
        
        time.sleep(random.uniform(0.5, 2.0))  # Random delay between traces
    
    print("\n🎉 Trace generation complete!")
    print("📊 Check Jaeger UI at: http://localhost:16686")

if __name__ == "__main__":
    generate_sample_traces()