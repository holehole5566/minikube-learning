# 04. Distributed Tracing with Jaeger

## What is Distributed Tracing?

**Distributed Tracing = Following a single request through multiple services**

### The Problem
```
User Request → API Gateway → Auth Service → User Service → Database
                    ↓
              Order Service → Payment Service → External API

# Which service is slow? Where did the error occur?
```

### The Solution: Traces
```
Trace ID: abc123 (2.1s total)
├── API Gateway (50ms) ✓
├── Auth Service (100ms) ✓  
├── User Service (200ms) ✓
└── Order Service (1.75s) ❌ SLOW!
    └── Payment Service (1.7s) ❌ ROOT CAUSE
        └── External API timeout (1.6s)
```

## Key Concepts

### Trace
**A complete journey of one request**
- Unique Trace ID (e.g., abc123def456)
- Shows end-to-end flow
- Total duration and status

### Span
**One operation within a trace**
- Service name (e.g., "user-service")
- Operation name (e.g., "GET /users/123")
- Start time and duration
- Parent-child relationships

### Tags and Logs
**Metadata about spans**
- Tags: Key-value pairs (http.method=GET, error=true)
- Logs: Timestamped events within a span

## Jaeger Architecture
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│Application A│    │Application B│    │Application C│
│  (traces)   │    │  (traces)   │    │  (traces)   │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                  ┌─────────────┐
                  │   Jaeger    │
                  │   Agent     │
                  └─────────────┘
                           │
                  ┌─────────────┐
                  │   Jaeger    │
                  │ Collector   │
                  └─────────────┘
                           │
                  ┌─────────────┐
                  │   Storage   │
                  │(Elasticsearch)│
                  └─────────────┘
                           │
                  ┌─────────────┐
                  │   Jaeger    │
                  │     UI      │
                  └─────────────┘
```

## Learning Path
1. **Install Jaeger** in Kubernetes
2. **Understand trace structure** (traces, spans, tags)
3. **Instrument applications** to generate traces
4. **Analyze request flows** in Jaeger UI
5. **Find performance bottlenecks**
6. **Correlate with metrics and logs**

Let's start tracing! 🔍