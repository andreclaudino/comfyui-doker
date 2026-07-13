# Installation Guide

## Prerequisites

- **Helm 3** installed on your client machine
- **kubectl** configured with cluster admin access
- **Kubernetes cluster** v1.28+ with nodes matching your accelerator
- **GPU operator** for your hardware:
  - NVIDIA: [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/)
  - AMD: [AMD GPU Operator](https://github.com/ROCm/k8s-device-plugin)
  - Intel: [Intel GPU Device Plugin](https://github.com/intel/intel-device-plugins-for-kubernetes)
- **PersistentVolume** matching your storage configuration (see below)

## Step 1: Create a PersistentVolume

The Helm chart creates a PVC but expects the PV to exist beforehand. Choose one of the following methods:

### Option A: NFS (network storage)

```bash
# On the NFS server
sudo mkdir -p /srv/nfs/comfyui
sudo chown -R 1000:1000 /srv/nfs/comfyui
echo "/srv/nfs/comfyui <cluster-cidr>(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports
sudo exportfs -ra

# PV manifest (nfs-pv.yaml)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: comfyui-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  nfs:
    path: /srv/nfs/comfyui
    server: <nfs-server-ip>
  storageClassName: nfs-client

# Apply
kubectl apply -f nfs-pv.yaml
```

### Option B: HostPath (single node / testing)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: comfyui-pv
  labels:
    type: local
spec:
  capacity:
    storage: 50Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-path
  hostPath:
    path: /var/lib/rancher/k3s/storage/comfyui
```

### Option C: StorageClass (dynamic provisioning)

If your cluster has a default StorageClass (e.g., `csi-hostpath`, `ebs-csi`, `longhorn`), no PV creation is needed — the PVC will dynamically provision one.

## Step 2: Install the Chart

### Basic install (NVIDIA CUDA 12.4)

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui \
  --create-namespace \
  --set comfyui.ingress.host=comfyui.example.com
```

### CPU-only install

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui \
  --create-namespace \
  --set comfyui.image.tag=latest-cpu \
  --set comfyui.gpu.vendor=cpu \
  --set comfyui.gpu.count=0 \
  --set comfyui.env.COMFYUI_ARGS="--listen 0.0.0.0 --port 8188 --cpu" \
  --set comfyui.ingress.host=comfyui.example.com
```

### Minimal install (no ingress, no MCP)

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui \
  --create-namespace \
  --set comfyui.ingress.enabled=false \
  --set mcp.enabled=false
```

### Install with custom values file

```bash
# Create my-values.yaml
cat > my-values.yaml << 'EOF'
comfyui:
  image:
    tag: latest-cuda12.6
  ingress:
    enabled: true
    host: comfyui.mycompany.com
  resources:
    requests:
      cpu: 8
      memory: 32Gi
    limits:
      cpu: 16
      memory: 64Gi
  nodeSelector:
    nvidia.com/gpu.present: "true"
storage:
  size: 200Gi
  storageClass: fast-nvme
mcp:
  token: "my-secret-token-here"
EOF

helm install comfyui ./helm/comfyui --namespace comfyui --create-namespace -f my-values.yaml
```

## Step 3: Access ComfyUI

### Via Ingress (if configured)

```
http://comfyui.example.com
```

### Via Port Forward

```bash
kubectl port-forward -n comfyui svc/comfyui 8188:8188
# Open http://localhost:8188
```

### Via MCP Server

```bash
# Get MCP token (if using inline token)
kubectl get secret -n comfyui comfyui-mcp -o jsonpath='{.data.MCP_TOKEN}' | base64 -d

# Port forward MCP
kubectl port-forward -n comfyui svc/comfyui-mcp 8000:8000

# Test connection
curl -X POST http://localhost:8000/mcp \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}'
```

## Upgrading

```bash
# Pull latest chart changes
git pull

# Upgrade release
helm upgrade comfyui ./helm/comfyui --namespace comfyui -f my-values.yaml

# Check upgrade status
helm history comfyui -n comfyui
```

## Uninstalling

```bash
# Remove all chart resources (PVC is NOT deleted by default)
helm uninstall comfyui -n comfyui

# To also delete PVC:
kubectl delete pvc -n comfyui comfyui-pvc
```

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| Pod stuck in Pending | No GPU node available | Check `nodeSelector` matches your GPU operator labels |
| PVC stays Pending | No matching PV or StorageClass | Check PV exists and StorageClass is correct |
| ImagePullBackOff | Wrong image tag or registry | Verify `comfyui.image.tag` exists in the registry |
| MCP connection refused | MCP disabled or wrong URL | Set `mcp.enabled=true` and verify `COMFYUI_URL` |
| ComfyUI no GPU found | Wrong image for GPU type | Use correct image tag (e.g., `latest-rocm7.2` for AMD) |
