## Why

The current Kustomize-based deployment (`k8s/`) hardcodes personal infrastructure values (NFS path, node names, IPs) and only supports NVIDIA CUDA GPUs. This makes the project unusable out-of-the-box for anyone else. We need a portable, configurable deployment system.

## Rationale

Helm provides parameterization through `values.yaml`, standardized packaging, and a rich ecosystem. Combined with a multi-accelerator CI build matrix, users can deploy ComfyUI on any infrastructure with a single `helm install` command — choosing the right image tag for their GPU and configuring only their infrastructure specifics.

## What Changes

- **BREAKING**: Replace `k8s/` (Kustomize) with `helm/comfyui/` (Helm chart)
- Add multi-accelerator Docker images: CUDA (11.8–13.2), ROCm, Intel, CPU
- Add `docs/helm/` with install guide, values reference, and accelerator examples
- Add ADR documenting the architectural decision

## Capabilities

### New Capabilities

- `helm-deployment`: Helm chart deploying ComfyUI + MCP with all resources templated
- `accelerator-images`: CI build matrix producing Docker images for CUDA/ROCm/Intel/CPU
- `helm-docs`: Documentation in `docs/helm/` covering install, values, and accelerator selection

### Modified Capabilities

*(None — no existing specs to modify)*

## Will do / Won't do

| Will do | Won't do |
|---------|----------|
| Helm chart with PVC, deployments, services, ingresses | Create PV in the chart (user manages PV) |
| Multi-CUDA (11.8, 12.4, 12.6, 13.0, 13.2) images | Apple Silicon / Metal support |
| ROCm (AMD) and Intel XPU images | Windows container support |
| CPU-only image | Automatic GPU discovery |
| Documentation for all accelerator variants | Monitoring / dashboards |
| ADR documenting the decision | Backup automation |
| Remove `k8s/` directory | |

## Implementation plan

1. **ADR**: `docs/adrs/001-helm-migration.md`
2. **Docker**: `docker/Dockerfile.rocm`, `docker/Dockerfile.intel`, `docker/Dockerfile.cpu`
3. **Helm chart**: `helm/comfyui/Chart.yaml`, `values.yaml`, `templates/*`
4. **CI**: `.github/workflows/docker-publish.yml` — expand build matrix
5. **Docs**: `docs/helm/README.md`, `INSTALL.md`, `VALUES.md`, `EXAMPLES.md`
6. **Changelog**: `CHANGELOG.md`
7. **Cleanup**: Remove `k8s/` directory

## Impact

- Build: CI takes longer (10+ image variants), needs more GitHub Actions runners
- Deploy: Requires Helm 3, no longer uses `kubectl apply -k`
- Config: Existing Kustomize overrides need porting to Helm `--set` or `values.yaml`
- Docs: Migration guide needed for existing users
