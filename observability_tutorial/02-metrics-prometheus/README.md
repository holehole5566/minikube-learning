# 02. Metrics with Prometheus

## What is Prometheus? 🔥

**Prometheus** = Time-series database + metrics collector + alerting system

### Key Features
- **Pull-based**: Scrapes metrics from targets
- **Time-series**: Stores metrics with timestamps
- **PromQL**: Powerful query language
- **Service Discovery**: Automatically finds Kubernetes services
- **Alerting**: Built-in alert manager

## Prometheus Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Application │    │   Node      │    │ Kubernetes  │
│   Metrics   │    │  Exporter   │    │   API       │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                  ┌─────────────┐
                  │ Prometheus  │
                  │   Server    │
                  └─────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
  │   Grafana   │ │ AlertManager│ │   PromQL    │
  │ (Visualize) │ │ (Alerting)  │ │  (Queries)  │
  └─────────────┘ └─────────────┘ └─────────────┘
```

## Learning Path
1. **Install Prometheus** in Kubernetes
2. **Understand metrics types** (counter, gauge, histogram)
3. **Explore built-in metrics** from Kubernetes
4. **Write PromQL queries** to analyze data
5. **Create custom metrics** from applications
6. **Set up alerts** for important conditions

Let's start building! 🚀