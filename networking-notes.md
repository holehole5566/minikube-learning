# Kubernetes Networking Notes

## Minikube on EC2 - Access Patterns

### Current Setup
- Minikube cluster runs inside EC2 instance
- Minikube IP: `192.168.49.2` (internal to EC2 only)
- Cannot access Minikube IP from outside EC2

### Service Types & Access

#### ClusterIP
- Internal cluster access only
- Example: `10.99.139.232:8080`

#### NodePort
- Exposes service on node IP
- Format: `<node-ip>:<nodeport>`
- Example: `192.168.49.2:30080`
- **Still requires EC2-level access**

### Access Methods

#### ✅ Inside EC2
```bash
curl http://192.168.49.2:30080
```

#### ✅ SSH Tunnel
```bash
ssh -L 30080:192.168.49.2:30080 ec2-user@<ec2-public-ip>
# Then access: http://localhost:30080
```

#### ✅ Port Forward
```bash
kubectl port-forward service/webapp-service 8080:8080 --address=0.0.0.0
# Access via EC2 public IP:8080 (if security group allows)
```

#### ❌ Direct External Access
```bash
# This won't work without EC2 security group configuration
curl http://<ec2-public-ip>:30080
```

### Key Points
- NodePort ≠ External access
- Need EC2 security groups + NodePort for external access
- Minikube networking is isolated within EC2
- Use port-forward for temporary external access