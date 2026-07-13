# Values Reference

All configurable values for the ComfyUI Helm chart.

## Global

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nameOverride` | string | `""` | Override the chart name |
| `fullnameOverride` | string | `""` | Override the full resource name |

## Namespace

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `namespace.create` | bool | `false` | Create namespace resource |
| `namespace.name` | string | `"comfyui"` | Namespace name |

## Storage

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `storage.storageClass` | string | `""` | Storage class for PVC (empty = cluster default) |
| `storage.accessMode` | string | `"ReadWriteOnce"` | PVC access mode |
| `storage.size` | string | `"50Gi"` | PVC storage size |
| `storage.existingClaim` | string | `""` | Existing PVC name (if set, no PVC is created) |
| `storage.mountPath` | string | `"/comfyui"` | PVC mount path inside containers |

## ComfyUI

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `comfyui.image.repository` | string | `"ghcr.io/andreclaudino/comfyui-doker"` | Image repository |
| `comfyui.image.tag` | string | `"latest-cuda12.4"` | Image tag |
| `comfyui.image.pullPolicy` | string | `"Always"` | Image pull policy |
| `comfyui.imagePullSecrets` | list | `[]` | Image pull secrets |
| `comfyui.replicas` | int | `1` | Number of replicas |
| `comfyui.service.port` | int | `8188` | Service port |
| `comfyui.service.type` | string | `"ClusterIP"` | Service type |
| `comfyui.ingress.enabled` | bool | `true` | Enable ingress |
| `comfyui.ingress.className` | string | `""` | Ingress class (empty = cluster default) |
| `comfyui.ingress.host` | string | `""` | Ingress hostname (required for ingress) |
| `comfyui.ingress.path` | string | `"/"` | Ingress path |
| `comfyui.ingress.pathType` | string | `"Prefix"` | Ingress path type |
| `comfyui.ingress.annotations` | object | `{}` | Additional ingress annotations |
| `comfyui.ingress.tls` | list | `[]` | TLS configuration |
| `comfyui.ingress.additionalIngresses` | list | `[]` | Additional ingress resources for subpath routing |
| `comfyui.env.COMFYUI_CUSTOM_NODES` | string | `"https://github.com/ltdrdata/ComfyUI-Manager.git"` | Custom nodes repo URLs (comma-separated) |
| `comfyui.env.COMFYUI_ARGS` | string | `"--listen 0.0.0.0 --port 8188"` | ComfyUI CLI arguments |
| `comfyui.env.COMFYUI_BASE_URL` | string | `""` | ComfyUI base URL for subpath asset routing (empty = root path) |
| `comfyui.env.NVIDIA_VISIBLE_DEVICES` | string | `"all"` | NVIDIA GPU visibility |
| `comfyui.env.PYTHONUNBUFFERED` | string | `"1"` | Python unbuffered output |
| `comfyui.resources.requests.cpu` | string | `"4"` | CPU request |
| `comfyui.resources.requests.memory` | string | `"16Gi"` | Memory request |
| `comfyui.resources.limits.cpu` | string | `"8"` | CPU limit |
| `comfyui.resources.limits.memory` | string | `"24Gi"` | Memory limit |
| `comfyui.gpu.vendor` | string | `"nvidia"` | GPU vendor (`nvidia`, `amd`, `intel`, `cpu`) |
| `comfyui.gpu.count` | int | `1` | Number of GPUs requested |
| `comfyui.gpu.resourceName` | string | `""` | Custom GPU resource name (auto-set from vendor) |
| `comfyui.nodeSelector` | object | `{}` | Node selector for pod scheduling |
| `comfyui.tolerations` | list | `[]` | Pod tolerations |
| `comfyui.affinity` | object | `{}` | Pod affinity |
| `comfyui.securityContext` | object | `{"allowPrivilegeEscalation": false, "readOnlyRootFilesystem": false, "runAsNonRoot": false}` | Container security context |
| `comfyui.livenessProbe.enabled` | bool | `false` | Enable liveness probe |
| `comfyui.readinessProbe.enabled` | bool | `false` | Enable readiness probe |
| `comfyui.extraLabels` | object | `{}` | Additional pod labels |
| `comfyui.extraAnnotations` | object | `{}` | Additional pod annotations |

## MCP (ComfyUI-MCP)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mcp.enabled` | bool | `true` | Enable MCP deployment |
| `mcp.image.repository` | string | `"ghcr.io/andreclaudino/comfyui-mcp"` | MCP image repository |
| `mcp.image.tag` | string | `"latest"` | MCP image tag |
| `mcp.image.pullPolicy` | string | `"Always"` | MCP image pull policy |
| `mcp.imagePullSecrets` | list | `[]` | MCP image pull secrets |
| `mcp.service.port` | int | `8000` | MCP service port |
| `mcp.service.type` | string | `"ClusterIP"` | MCP service type |
| `mcp.ingress.enabled` | bool | `true` | Enable MCP ingress |
| `mcp.ingress.className` | string | `""` | MCP ingress class |
| `mcp.ingress.host` | string | `""` | MCP ingress hostname (required for ingress) |
| `mcp.ingress.path` | string | `"/mcp"` | MCP ingress path |
| `mcp.ingress.pathType` | string | `"Prefix"` | MCP ingress path type |
| `mcp.ingress.annotations` | object | `{}` | MCP ingress annotations |
| `mcp.ingress.tls` | list | `[]` | MCP TLS configuration |
| `mcp.ingress.additionalIngresses` | list | `[]` | Additional ingress resources for subpath routing |
| `mcp.token` | string | `""` | MCP inline token (creates secret) |
| `mcp.existingSecret` | string | `""` | MCP existing secret name (takes precedence over token) |
| `mcp.existingSecretKey` | string | `"MCP_TOKEN"` | Key within existing secret |
| `mcp.env.COMFYUI_URL` | string | `"http://{{ .Release.Name }}-comfyui:8188"` | ComfyUI internal URL |
| `mcp.env.LOG_LEVEL` | string | `"info"` | MCP log level |
| `mcp.resources.requests.cpu` | string | `"500m"` | MCP CPU request |
| `mcp.resources.requests.memory` | string | `"512Mi"` | MCP memory request |
| `mcp.resources.limits.cpu` | string | `"1000m"` | MCP CPU limit |
| `mcp.resources.limits.memory` | string | `"1Gi"` | MCP memory limit |
| `mcp.livenessProbe.enabled` | bool | `true` | Enable MCP liveness probe |
| `mcp.readinessProbe.enabled` | bool | `true` | Enable MCP readiness probe |
| `mcp.nodeSelector` | object | `{}` | MCP node selector |
| `mcp.tolerations` | list | `[]` | MCP tolerations |
| `mcp.affinity` | object | `{}` | MCP affinity |
| `mcp.extraLabels` | object | `{}` | MCP additional labels |
| `mcp.extraAnnotations` | object | `{}` | MCP additional annotations |

## Nginx Ingress Controller

When `nginx.enabled: true`, the following annotations are automatically added to all ingress resources:

- `nginx.ingress.kubernetes.io/use-regex` — enables regex path matching
- `nginx.ingress.kubernetes.io/rewrite-target` — path rewrite target (capture group reference)
- `nginx.ingress.kubernetes.io/proxy-connect-timeout` — proxy connect timeout
- `nginx.ingress.kubernetes.io/proxy-send-timeout` — proxy send timeout (for WebSocket)
- `nginx.ingress.kubernetes.io/proxy-read-timeout` — proxy read timeout (for WebSocket)
- `nginx.ingress.kubernetes.io/proxy-body-size: "0"` — disables body size limit (hardcoded)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `nginx.enabled` | bool | `false` | Enable nginx-specific ingress annotations (rewrite, WebSocket timeouts) |
| `nginx.rewriteTarget` | string | `"/$2"` | Rewrite target annotation value (capture group reference) |
| `nginx.useRegex` | bool | `true` | Enable regex path matching |
| `nginx.proxyConnectTimeout` | int | `5` | Proxy connect timeout in seconds |
| `nginx.proxySendTimeout` | int | `3600` | Proxy send timeout in seconds (long for WebSocket) |
| `nginx.proxyReadTimeout` | int | `3600` | Proxy read timeout in seconds (long for WebSocket) |

## OpenWebUI

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `openwebui.enabled` | bool | `false` | Enable OpenWebUI deployment |
| `openwebui.image.repository` | string | `"ghcr.io/open-webui/open-webui"` | Image repository |
| `openwebui.image.tag` | string | `"main"` | Image tag |
| `openwebui.image.pullPolicy` | string | `"Always"` | Image pull policy |
| `openwebui.service.port` | int | `8080` | Service port |
| `openwebui.service.type` | string | `"ClusterIP"` | Service type |
| `openwebui.ingress.enabled` | bool | `true` | Enable OpenWebUI ingress |
| `openwebui.ingress.className` | string | `""` | Ingress class (empty = cluster default) |
| `openwebui.ingress.host` | string | `""` | Ingress hostname (required for ingress) |
| `openwebui.ingress.path` | string | `"/"` | Ingress path |
| `openwebui.ingress.pathType` | string | `"Prefix"` | Ingress path type |
| `openwebui.ingress.annotations` | object | `{}` | Additional ingress annotations |
| `openwebui.ingress.tls` | list | `[]` | TLS configuration |
| `openwebui.ingress.additionalIngresses` | list | `[]` | Additional ingress resources for subpath routing |
| `openwebui.env.MCP_SERVERS` | string | `""` | MCP server configuration (auto-generated when deployed via Helm) |
| `openwebui.resources.requests.cpu` | string | `"250m"` | CPU request |
| `openwebui.resources.requests.memory` | string | `"512Mi"` | Memory request |
| `openwebui.resources.limits.cpu` | string | `"1000m"` | CPU limit |
| `openwebui.resources.limits.memory` | string | `"2Gi"` | Memory limit |
| `openwebui.extraVolumeMounts` | list | `[]` | Additional volume mounts |
| `openwebui.extraVolumes` | list | `[]` | Additional volumes |
