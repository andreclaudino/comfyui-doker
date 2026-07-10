# ComfyUI Kubernetes Deployment

Production-ready Kubernetes deployment for ComfyUI with GPU support, MCP integration, and OpenWebUI connectivity.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ARCHITECTURE                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                │
│  │   OpenWebUI  │────▶│  ComfyUI-MCP │────▶│   ComfyUI    │                │
│  │  (Port 3000) │     │  (Port 8080) │     │  (Port 8188) │                │
│  └──────────────┘     └──────────────┘     └──────┬───────┘                │
│                                                    │                        │
│  ┌────────────────────────────────────────────────┼────────────────────┐   │
│  │                    KUBERNETES CLUSTER           │                    │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────┐  │  ┌─────────────┐  │   │
│  │  │   Ingress   │  │  Ingress    │  │ Service │  │  │  Service    │  │   │
│  │  │  (nginx)    │  │  (nginx)    │  │(ClusterIP)   │  │(ClusterIP)  │  │   │
│  │  └──────┬──────┘  └──────┬──────┘  └────┬────┘  │  └──────┬──────┘  │   │
│  │         │                │             │         │         │         │   │
│  │  ┌──────▼──────┐  ┌──────▼──────┐  ┌────▼─────┐  ┌──▼─────────▼──┐  │   │
│  │  │ comfyui.mcp.│  │ comfyui.    │  │ Deployment│  │ Deployment  │  │   │
│  │  │ 10.0.0.200. │  │ 10.0.0.200. │  │comfyui-mcp│  │  comfyui    │  │   │
│  │  │ nip.io      │  │ nip.io      │  │          │  │             │  │   │
│  │  └─────────────┘  └─────────────┘  └────┬─────┘  └──────┬──────┘  │   │
│  │                                           │             │          │   │
│  │                    ┌──────────────────────┘             │          │   │
│  │                    ▼                                  ▼          │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │              PERSISTENT VOLUME (NFS)                     │   │   │
│  │  │  /mnt/suzi/home/claudino/.volumes/comfyui (100Gi, RWX)  │   │   │
│  │  │  ├── models/     ├── output/     ├── input/             │   │   │
│  │  │  ├── custom_nodes/   ├── user/                         │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  │                                                               │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                      EXTERNAL DEPENDENCIES                        │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │  │
│  │  │  NFS Server  │  │  GPU Nodes   │  │  Container   │           │  │
│  │  │  (10.0.0.98) │  │  (NVIDIA)    │  │  Registry    │           │  │
│  │  └──────────────┘  └──────────────┘  │  (GHCR)      │           │  │
│  └───────────────────────────────────────┴──────────────┘           │
└───────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes cluster (v1.28+) with NVIDIA GPU nodes
- NVIDIA GPU Operator installed
- NGINX Ingress Controller
- NFS server (10.0.0.98) with `/mnt/suzi/home/claudino/.volumes/comfyui` exported
- kubectl configured with cluster admin access
- kustomize (v5.0+) or kubectl with kustomize built-in
- Docker/GHCR access for image pulls

## Quick Start

```bash
# Clone repository
git clone https://github.com/andreclaudino/comfyui-doker.git
cd comfyui-doker

# Build and push Docker image
# (Or use the pre-built image from GHCR)
docker build -t ghcr.io/andreclaudino/comfyui-doker:latest -f docker/Dockerfile .
docker push ghcr.io/andreclaudino/comfyui-doker:latest

# Deploy to Kubernetes
kubectl apply -k k8s/

# Verify deployment
kubectl get pods -n comfyui -w

# Access ComfyUI
# http://comfyui.10.0.0.200.nip.io

# Access MCP Server
# http://comfyui-mcp.10.0.0.200.nip.io/mcp
```

## Build Docker Image (GitHub Actions)

The repository includes a GitHub Actions workflow for automated builds:

### Automatic Triggers
- Push to `main` branch
- Tag push (v*)
- Pull requests to `main`
- Manual workflow dispatch

### Manual Build
```bash
# Trigger via GitHub CLI
gh workflow run docker-publish.yml -f tag=v1.0.0

# Or via GitHub web UI: Actions > Build and Push Docker Image > Run workflow
```

### Image Tags Generated
- `latest` (from main branch)
- `v1.0.0` (semver tags)
- `v1.0` (major.minor)
- `sha-<commit>` (commit SHA)
- `pr-<number>` (pull requests)

### Registry
Images are pushed to: `ghcr.io/andreclaudino/comfyui-doker`

## Kubernetes Deployment Steps

### 1. Prepare NFS Storage

On the NFS server (10.0.0.98):

```bash
# Create export directory
sudo mkdir -p /mnt/suzi/home/claudino/.volumes/comfyui
sudo chown -R 1000:1000 /mnt/suzi/home/claudino/.volumes/comfyui
sudo chmod -R 775 /mnt/suzi/home/claudino/.volumes/comfyui

# Configure exports
echo "/mnt/suzi/home/claudino/.volumes/comfyui 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -ra
```

### 2. Verify NFS Access from Cluster

```bash
# Test mount from a pod
kubectl run nfs-test --image=busybox --rm -it --restart=Never -- \
  sh -c "mount -t nfs 10.0.0.98:/mnt/suzi/home/claudino/.volumes/comfyui /mnt && ls /mnt && umount /mnt"
```

### 3. Deploy with Kustomize

```bash
# Preview resources
kubectl kustomize k8s/

# Apply all resources
kubectl apply -k k8s/

# Or apply individually
kubectl apply -f k8s/storage/namespace.yaml
kubectl apply -f k8s/storage/pv.yaml
kubectl apply -f k8s/storage/pvc.yaml
kubectl apply -f k8s/comfyui/
kubectl apply -f k8s/comfyui-mcp/
```

### 4. Verify Deployment

```bash
# Check all resources
kubectl get all -n comfyui

# Check pods
kubectl get pods -n comfyui -o wide

# Check PVC binding
kubectl get pvc -n comfyui

# Check ingress
kubectl get ingress -n comfyui

# View logs
kubectl logs -n comfyui -l app=comfyui -f
kubectl logs -n comfyui -l app=comfyui-mcp -f
```

### 5. Generate MCP Token

```bash
# Create initial token
kubectl create secret generic comfyui-mcp-token \
  --from-literal=MCP_TOKEN=$(openssl rand -hex 32) \
  --namespace=comfyui \
  --dry-run=client -o yaml | kubectl apply -f -

# View token
kubectl get secret comfyui-mcp-token -n comfyui -o jsonpath='{.data.MCP_TOKEN}' | base64 -d
```

### 6. Rotate MCP Token

```bash
# Generate new token and update secret
kubectl create secret generic comfyui-mcp-token \
  --from-literal=MCP_TOKEN=$(openssl rand -hex 32) \
  --namespace=comfyui \
  --dry-run=client -o yaml | kubectl replace -f -

# Restart MCP deployment to pick up new token
kubectl rollout restart deployment/comfyui-mcp -n comfyui
```

## NFS Setup on suzi (10.0.0.98)

### Server Configuration

```bash
# Install NFS server
sudo apt-get update && sudo apt-get install -y nfs-kernel-server

# Create shared directory
sudo mkdir -p /mnt/suzi/home/claudino/.volumes/comfyui
sudo chown -R 1000:1000 /mnt/suzi/home/claudino/.volumes/comfyui
sudo chmod -R 775 /mnt/suzi/home/claudino/.volumes/comfyui

# Configure exports
cat << 'EOF' | sudo tee /etc/exports.d/comfyui.exports
/mnt/suzi/home/claudino/.volumes/comfyui 10.0.0.0/24(rw,sync,no_subtree_check,no_root_squash,insecure)
EOF

# Apply exports
sudo exportfs -ra

# Verify
sudo exportfs -v
showmount -e 10.0.0.98
```

### Firewall Configuration

```bash
# Allow NFS traffic from Kubernetes nodes
sudo ufw allow from 10.0.0.0/24 to any port nfs
sudo ufw allow from 10.0.0.0/24 to any port 2049
sudo ufw allow from 10.0.0.0/24 to any port 111
sudo ufw allow from 10.0.0.0/24 to any port 20048

# Or with iptables
sudo iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 2049 -j ACCEPT
sudo iptables -A INPUT -s 10.0.0.0/24 -p udp --dport 2049 -j ACCEPT
sudo iptables -A INPUT -s 10.0.0.0/24 -p tcp --dport 111 -j ACCEPT
sudo iptables -A INPUT -s 10.0.0.0/24 -p udp --dport 111 -j ACCEPT
```

### Client Verification

```bash
# From any Kubernetes node
showmount -e 10.0.0.98
mount -t nfs 10.0.0.98:/mnt/suzi/home/claudino/.volumes/comfyui /mnt/test
ls /mnt/test
umount /mnt/test
```

## Environment Variables Reference

### ComfyUI Deployment

| Variable | Default | Description |
|----------|---------|-------------|
| `COMFYUI_CUSTOM_NODES` | `""` | Comma-separated custom node repo URLs |
| `NVIDIA_VISIBLE_DEVICES` | `all` | GPU visibility |
| `PYTHONUNBUFFERED` | `1` | Unbuffered Python output |
| `COMFYUI_PORT` | `8188` | ComfyUI HTTP port |
| `COMFYUI_HOST` | `0.0.0.0` | Bind address |
| `COMFYUI_ARGS` | `--listen 0.0.0.0 --port 8188` | Additional CLI arguments |

### ComfyUI-MCP Deployment

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_TOKEN` | (from secret) | Bearer token for authentication |
| `COMFYUI_URL` | `http://comfyui:8188` | ComfyUI service URL |
| `MCP_HOST` | `0.0.0.0` | MCP server bind address |
| `MCP_PORT` | `8080` | MCP server port |
| `LOG_LEVEL` | `INFO` | Logging level |

### Docker Build Args

| Arg | Default | Description |
|-----|---------|-------------|
| `BUILDKIT_INLINE_CACHE` | `1` | Enable BuildKit inline cache |

## MCP Integration

### OpenWebUI Configuration

See [openwebui/mcp-config.md](openwebui/mcp-config.md) for detailed integration guide.

Quick setup:
```json
{
  "mcp": {
    "servers": {
      "comfyui": {
        "url": "http://comfyui-mcp.10.0.0.200.nip.io/mcp",
        "headers": {
          "Authorization": "Bearer YOUR_MCP_TOKEN"
        },
        "enabled": true,
        "timeout": 300
      }
    }
  }
}
```

### Available MCP Tools

- `generate_image` - Text-to-image generation
- `queue_prompt` - Custom workflow execution
- `get_queue_status` - Queue monitoring
- `get_history` - Generation history
- `upload_image` - Image upload for img2img

### Testing MCP Connection

```bash
# Get token
TOKEN=$(kubectl get secret comfyui-mcp-token -n comfyui -o jsonpath='{.data.MCP_TOKEN}' | base64 -d)

# Test with curl
curl -X POST http://comfyui-mcp.10.0.0.200.nip.io/mcp \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## Troubleshooting

### Pod Stuck in Pending

```bash
# Check events
kubectl describe pod -n comfyui -l app=comfyui

# Common causes:
# - No GPU nodes available (check node selector)
# - PVC not bound (check NFS server)
# - Resource requests exceed capacity
```

### GPU Not Available

```bash
# Verify GPU plugin
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, gpu: .status.capacity["nvidia.com/gpu"]}'

# Check NVIDIA device plugin
kubectl get pods -n kube-system -l name=nvidia-device-plugin-ds

# Verify GPU in pod
kubectl exec -n comfyui -it deploy/comfyui -- nvidia-smi
```

### NFS Mount Issues

```bash
# Check PV/PVC status
kubectl get pv,pvc -n comfyui

# Check NFS connectivity from node
kubectl debug node/<node-name> -it --image=busybox -- sh -c "mount -t nfs 10.0.0.98:/mnt/suzi/home/claudino/.volumes/comfyui /mnt && ls /mnt"

# Check PVC events
kubectl describe pvc comfyui-pvc -n comfyui
```

### Image Pull Errors

```bash
# Check image pull secret
kubectl get secret -n comfyui

# For GHCR private images, create pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<github-token> \
  --namespace=comfyui

# Add to deployment
kubectl patch deployment comfyui -n comfyui -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"ghcr-secret"}]}}}}'
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress -n comfyui

# Test DNS resolution
nslookup comfyui.10.0.0.200.nip.io

# Check nginx logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### MCP Authentication Failures

```bash
# Verify token in secret matches config
kubectl get secret comfyui-mcp-token -n comfyui -o jsonpath='{.data.MCP_TOKEN}' | base64 -d

# Check MCP pod logs
kubectl logs -n comfyui -l app=comfyui-mcp | grep -i auth

# Test with correct token
TOKEN=$(kubectl get secret comfyui-mcp-token -n comfyui -o jsonpath='{.data.MCP_TOKEN}' | base64 -d)
curl -H "Authorization: Bearer $TOKEN" http://comfyui-mcp.10.0.0.200.nip.io/mcp
```

### Out of Memory / OOM Kills

```bash
# Check resource limits
kubectl describe pod -n comfyui -l app=comfyui | grep -A 10 Limits

# Increase memory limits in deployment.yaml
# Adjust based on model size:
# - SDXL: 24Gi+ recommended
# - SD1.5: 16Gi+ recommended
# - With multiple models: 32Gi+
```

### Custom Nodes Not Loading

```bash
# Check COMFYUI_CUSTOM_NODES env var
kubectl get deployment comfyui -n comfyui -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="COMFYUI_CUSTOM_NODES")].value}'

# Add custom nodes (comma-separated URLs)
kubectl set env deployment/comfyui -n comfyui COMFYUI_CUSTOM_NODES="https://github.com/ltdrdata/ComfyUI-Manager.git,https://github.com/cubiq/ComfyUI_essentials.git"

# Restart to apply
kubectl rollout restart deployment/comfyui -n comfyui
```

## Scaling Considerations

### Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: comfyui-hpa
  namespace: comfyui
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: comfyui
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: nvidia.com/gpu
      target:
        type: Utilization
        averageUtilization: 80
```

### Multiple GPU Nodes

Add node affinity for multi-GPU scheduling:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: nvidia.com/gpu.product
          operator: In
          values:
          - NVIDIA-A100
          - NVIDIA-H100
```

## Backup & Disaster Recovery

### Backup PVC Data

```bash
# Create backup pod
kubectl run backup-comfyui --image=busybox --rm -it --restart=Never \
  -v comfyui-pvc:/data \
  -v $(pwd)/backups:/backup \
  -- tar czf /backup/comfyui-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore PVC Data

```bash
# Restore from backup
kubectl run restore-comfyui --image=busybox --rm -it --restart=Never \
  -v comfyui-pvc:/data \
  -v $(pwd)/backups:/backup \
  -- tar xzf /backup/comfyui-20240115.tar.gz -C /data
```

## License

MIT License - Copyright (c) 2025 Andre Claudino

See [LICENSE](LICENSE) for details.