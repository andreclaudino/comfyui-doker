# Usage Examples

## NVIDIA CUDA (Default)

```bash
# CUDA 12.4 (default)
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.ingress.host=comfyui.example.com

# CUDA 12.6
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.image.tag=latest-cuda12.6 \
  --set comfyui.ingress.host=comfyui.example.com

# CUDA 13.2
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.image.tag=latest-cuda13.2 \
  --set comfyui.ingress.host=comfyui.example.com
```

### Required Node Selector

```yaml
comfyui:
  nodeSelector:
    nvidia.com/gpu.present: "true"
```

### GPU Operator Labels (examples)

| GPU Product | Label |
|------------|-------|
| NVIDIA A100 | `nvidia.com/gpu.product: "NVIDIA-A100-80GB"` |
| NVIDIA H100 | `nvidia.com/gpu.product: "NVIDIA-H100-80GB-HGX"` |
| NVIDIA RTX 4090 | `nvidia.com/gpu.product: "NVIDIA-GeForce-RTX-4090"` |
| NVIDIA RTX 3090 | `nvidia.com/gpu.product: "NVIDIA-GeForce-RTX-3090"` |

---

## AMD ROCm

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.image.tag=latest-rocm7.2 \
  --set comfyui.gpu.vendor=amd \
  --set comfyui.ingress.host=comfyui.example.com
```

### Required Node Selector

```yaml
comfyui:
  nodeSelector:
    amd.com/gpu.present: "true"
```

### Notes

- ROCm image is based on Ubuntu 22.04 (~4 GB larger than CUDA image)
- Tested on AMD MI250, MI300, and RX 7900 series
- Requires AMD GPU Operator or k8s-device-plugin

---

## Intel XPU

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.image.tag=latest-intel \
  --set comfyui.gpu.vendor=intel \
  --set comfyui.ingress.host=comfyui.example.com
```

### Required Node Selector

```yaml
comfyui:
  nodeSelector:
    intel.com/gpu.present: "true"
```

### Notes

- Intel image includes Level Zero runtime, compute runtime, and media drivers
- Tested on Intel Arc A770, Arc A580, and integrated Arc GPUs
- Requires [Intel GPU Device Plugin](https://github.com/intel/intel-device-plugins-for-kubernetes)

---

## CPU-only

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.image.tag=latest-cpu \
  --set comfyui.gpu.vendor=cpu \
  --set comfyui.gpu.count=0 \
  --set comfyui.env.COMFYUI_ARGS="--listen 0.0.0.0 --port 8188 --cpu" \
  --set comfyui.ingress.host=comfyui.example.com
```

### Required Node Selector

No node selector needed — the pod will schedule on any available node.

```yaml
comfyui:
  nodeSelector: {}
```

### Notes

- Uses `python:3.12-slim` base image (~2 GB)
- PyTorch installed from CPU-only index (`download.pytorch.org/whl/cpu`)
- Inference is significantly slower than GPU, but functional
- Add `--cpu` flag to `COMFYUI_ARGS` to suppress CUDA warnings

---

## Minimal (no MCP, no Ingress)

```bash
helm install comfyui ./helm/comfyui \
  --namespace comfyui --create-namespace \
  --set comfyui.ingress.enabled=false \
  --set mcp.enabled=false
```

Access via port forward:

```bash
kubectl port-forward -n comfyui svc/comfyui 8188:8188
```

---

## Production (with TLS, resource limits, and auth)

```yaml
# production-values.yaml
namespace:
  create: true
  name: comfyui

storage:
  storageClass: fast-nvme
  size: 200Gi

comfyui:
  image:
    tag: latest-cuda12.4
  ingress:
    enabled: true
    host: comfyui.mycompany.com
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - hosts:
          - comfyui.mycompany.com
        secretName: comfyui-tls
  resources:
    requests:
      cpu: 8
      memory: 32Gi
    limits:
      cpu: 16
      memory: 64Gi
  nodeSelector:
    nvidia.com/gpu.product: "NVIDIA-A100-80GB"
  livenessProbe:
    enabled: true
  readinessProbe:
    enabled: true

mcp:
  token: "my-generated-64-char-token"
  ingress:
    enabled: true
    host: mcp.comfyui.mycompany.com
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
    tls:
      - hosts:
          - mcp.comfyui.mycompany.com
        secretName: mcp-tls
```

```bash
helm install comfyui ./helm/comfyui --namespace comfyui -f production-values.yaml
```
