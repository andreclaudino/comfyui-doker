## Context

ComfyUI-doker currently uses Kustomize (`k8s/`) with raw YAML manifests hardcoding personal values: NFS server IP `10.0.0.98`, node name `julia`, ingress IPs, GPU-specific flags. Only NVIDIA CUDA 12.4 images are built. The `k8s/` directory has been cleaned of secrets but remains non-portable.

We are migrating to Helm for parameterized deployments and expanding the CI build matrix to support all major GPU accelerators.

## Goals / Non-Goals

**Goals:**
- Replace Kustomize with a Helm chart at `helm/comfyui/`
- All infrastructure values parameterized via `values.yaml`
- PVC-based storage (no PV creation in chart)
- Multi-accelerator Docker images: CUDA (11.8–13.2), ROCm 7.2, Intel XPU, CPU
- Default ingress class: cluster default (not nginx)
- Persist models, custom_nodes, user, input, output on PV
- ComfyUI Manager installed by default as a custom node
- Full documentation in `docs/helm/`

**Non-Goals:**
- Creating PVs in the chart (user creates them externally)
- Automatic GPU discovery or operator installation
- Monitoring, dashboards, or backup automation
- Windows or Apple Silicon support
- Helm chart publication to a registry (local install only)

## Decisions

### Decision 1: Helm chart structure
Chart at `helm/comfyui/` with flat templates (no subdirectories). Templates use Go templates with `{{ .Values.* }}`. 12 templates total: namespace (conditional), pvc, comfyui-deployment, comfyui-service, comfyui-ingress, mcp-deployment (conditional), mcp-service, mcp-ingress (conditional), mcp-secret (conditional), _helpers.tpl, NOTES.txt.

### Decision 2: PV not managed by chart
The chart creates a PVC with configurable `storageClass` and `size`. The PV must exist beforehand. This avoids namespace-scoping issues and lets users choose their storage backend (NFS, EBS, hostPath, Longhorn, etc.).

### Decision 3: Ingress uses cluster default class
`ingressClassName: ""` by default — users set it to their cluster's ingress controller (nginx, traefik, contour, etc.). No default annotations. This makes the chart controller-agnostic.

### Decision 4: Full persistence via PV symlinks
PVC mounts at `/comfyui`. The deployment's `command` creates subdirectories and symlinks:
```bash
for d in models custom_nodes user input output; do
  mkdir -p /comfyui/$d
  rm -rf /workspace/ComfyUI/$d && ln -sf /comfyui/$d /workspace/ComfyUI/$d
done
exec /workspace/entrypoint.sh "$@"
```
This ensures ComfyUI sees all data on the PV while its code runs from the immutable image.

### Decision 5: ComfyUI Manager installed by default
`COMFYUI_CUSTOM_NODES` defaults to `https://github.com/ltdrdata/ComfyUI-Manager.git`. The entrypoint clones it once into the PV (`/comfyui/custom_nodes/`). Users add more models/nodes via the Manager UI.

### Decision 6: Multi-accelerator Dockerfiles
Separate Dockerfiles for each accelerator family sharing the same entrypoint:
- `docker/Dockerfile` — CUDA (ARG-driven, one file for all CUDA versions)
- `docker/Dockerfile.rocm` — ROCm (Ubuntu + pip ROCm index)
- `docker/Dockerfile.intel` — Intel XPU (Ubuntu + Intel compute runtime + pip XPU)
- `docker/Dockerfile.cpu` — CPU-only (python:3.12-slim + pip CPU)

### Decision 7: CI matrix per variant
Each variant becomes a matrix entry in the GitHub Actions workflow. Tags include variant suffix (e.g., `v1.2.3-cuda12.4`, `latest-rocm7.2`). CUDA variants share one Dockerfile; ROCm, Intel, CPU each need separate build jobs.

### Decision 8: MCP follows same patterns
MCP deployment reuses the same PVC (read-only for config). Its own ingress uses the same cluster-default class. Secret is optional (existingSecret or inline token). If neither is set, MCP runs without authentication (documented as a risk).

### Decision 9: Node selector is user responsibility
`comfyui.nodeSelector: {}` by default. No GPU selector preset. Documentation provides examples for each accelerator (NVIDIA, AMD, Intel) and CPU-only (no selector). Users configure based on their cluster's GPU operator labels.

## Risks / Trade-offs

- [Risk] CPU image is ~2 GB vs CUDA ~10 GB → Mitigation: separate Dockerfile keeps CUDA image lean for GPU users
- [Risk] ROCm/Intel images are large (Ubuntu + driver stacks) → Mitigation: documented expected image sizes
- [Risk] CI build time increases from ~1 job to ~10 jobs → Mitigation: parallel matrix builds; acceptable trade-off
- [Risk] Helm chart is more complex than Kustomize → Mitigation: comprehensive `docs/helm/` documentation
- [Risk] PVC without PV creation can confuse new users → Mitigation: INSTALL.md includes PV creation examples for common backends
- [Risk] MCP without auth is insecure if exposed → Mitigation: SECURITY.md warning and existingSecret documentation

## Open Questions

- Should we publish multi-arch manifests (linux/amd64 + linux/arm64) for the CPU image? ARM Macs are common for CPU-only ComfyUI.
