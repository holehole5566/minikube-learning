# 03. Logging with ELK Stack

## What is the ELK Stack?

**E**lasticsearch + **L**ogstash + **K**ibana = Centralized logging solution
(We'll use **Fluentd** instead of Logstash = **EFK Stack**)

### Components
- **Elasticsearch**: Stores and indexes logs
- **Fluentd**: Collects logs from pods
- **Kibana**: Visualizes and searches logs

## Why Centralized Logging?

### The Problem
```bash
# Traditional way - logs disappear when pods die
kubectl logs pod-abc123  # Pod crashes
kubectl logs pod-abc123  # ERROR: pod not found
```

### The Solution
```
Pods → Fluentd → Elasticsearch → Kibana
 ↓        ↓           ↓           ↓
Logs   Collect    Store &      Search &
       & Parse    Index       Visualize
```

## Architecture
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Pod A    │    │    Pod B    │    │    Pod C    │
│   (logs)    │    │   (logs)    │    │   (logs)    │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                  ┌─────────────┐
                  │  Fluentd    │
                  │ DaemonSet   │
                  └─────────────┘
                           │
                  ┌─────────────┐
                  │Elasticsearch│
                  │  Cluster    │
                  └─────────────┘
                           │
                  ┌─────────────┐
                  │   Kibana    │
                  │     UI      │
                  └─────────────┘
```

## Learning Path
1. **Install EFK Stack** in Kubernetes
2. **Understand log flow** from pods to Elasticsearch
3. **Search logs** with Kibana queries
4. **Create log dashboards** for monitoring
5. **Set up log-based alerts**
6. **Correlate logs with metrics**

Let's start collecting those logs! 📝