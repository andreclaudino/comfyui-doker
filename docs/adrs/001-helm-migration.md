# ADR 001: Migrate from Kustomize to Helm with Multi-Accelerator Support

**Date:** 2026-07-13

**Status:** Accepted

## Context

The ComfyUI-doker project originally used Kustomize (`k8s/`) with raw YAML manifests. These manifests hardcoded personal infrastructure values — NFS server IP (`10.0.0.98`), node names (`julia`), ingress IPs, and GPU-specific flags. Only NVIDIA CUDA 12.4 images were built.

This approach made the project:
- **Non-portable**: Every new deployment required editing raw YAML
- **Single-accelerator**: Only CUDA 12.4 was supported
- **Hard to configure**: No parameterization mechanism
- **Difficult to document**: Manually keeping docs in sync with YAML

We needed a portable, configurable deployment system supporting multiple GPU accelerators.

## Decision

We will:

1. **Replace Kustomize with a Helm chart** at `helm/comfyui/`
2. **Parameterize all infrastructure values** via `values.yaml`
3. **Support multi-accelerator Docker images**: CUDA (11.8, 12.4, 12.6, 12.8, 13.0, 13.2), ROCm 7.2, Intel XPU, CPU
4. **Use PVC-based storage** (PV managed externally by the user)
5. **Use cluster-default ingress class** (no controller hardcoding)
6. **Persist all stateful data** via symlinks on PVC mount
7. **Install ComfyUI Manager by default**
8. **Expand CI build matrix** to cover all accelerator variants
9. **Document everything** in `docs/helm/`

## Alternatives Considered

### Alternative 1: Continue with Kustomize + Patches
- **Pro**: Less migration effort
- **Con**: Still requires manual patching per variant; no package management
- **Rejected**: Does not solve the core portability problem

### Alternative 2: Plain Kubernetes YAML with env variables
- **Pro**: Simple, no new tooling
- **Con**: No standardized way to package, version, or document parameters
- **Rejected**: Helm provides these benefits out of the box

### Alternative 3: Use Kustomize with kustomize plugins
- **Pro**: Familiar tooling
- **Con**: Plugin ecosystem is less mature than Helm; harder to share
- **Rejected**: Helm is the de facto standard for Kubernetes packaging

## Consequences

### Positive
- **Portability**: One `helm install` works on any cluster
- **Configurability**: All values in `values.yaml`, overridable via `--set`
- **Multi-accelerator**: Users choose the right image tag for their hardware
- **Standardization**: Follows Helm best practices and conventions
- **Documentability**: Auto-generated values reference

### Negative
- **Migration effort**: Existing users must port Kustomize overrides to Helm values
- **Breaking change**: `kubectl apply -k k8s/` no longer works
- **Complexity**: Helm chart templates are more complex than raw YAML
- **CI time**: Build matrix increased from 1 to ~10 image variants

### Neutral
- Requires Helm 3 installed on the client
- PVC management remains user responsibility
- GPU operators still need separate installation

## Compliance

- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Kubernetes PVC Conventions](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [OCI Docker Image Tagging](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#pulling)
