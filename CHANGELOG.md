# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Helm chart** at `helm/comfyui/` replacing Kustomize (`k8s/`)
  - 12 templates: Namespace (conditional), PVC, ComfyUI Deployment + Service + Ingress, MCP Deployment + Service + Ingress + Secret, _helpers.tpl, NOTES.txt
  - All infrastructure values parameterized via `values.yaml` (~40 parameters)
  - ComfyUI Manager installed by default as a custom node
  - Ingress uses cluster default class (no controller hardcoding)
  - Three MCP authentication modes: no auth, existing secret, inline token
- **Nginx ingress subpath routing** (optional, behind `nginx.enabled`)
  - Configurable `rewrite-target`, `use-regex`, and proxy timeout annotations
  - WebSocket support with configurable `proxy-send-timeout` and `proxy-read-timeout` (default 3600s)
  - `proxy-body-size: "0"` disables body size limit for large image transfers
- **Additional Ingresses** for subpath routing (`additionalIngresses` on comfyui, mcp, openwebui)
  - Deploy extra Ingress resources alongside the main one for subpath routing
  - Supports custom annotations, host, path, and TLS per additional ingress
- **OpenWebUI as optional chart component** (`openwebui.enabled`)
  - Deployment, Service, and Ingress templates (conditional)
  - Auto-configured MCP connection from Helm values
  - Supports `additionalIngresses` for subpath routing
- **ComfyUI base URL support** (`comfyui.env.COMFYUI_BASE_URL`)
  - Adds `--base-url` flag to COMFYUI_ARGS for correct asset routing under subpath
- **Architecture Decision Record** at `docs/adrs/002-nginx-ingress-subpath.md`
- **Multi-accelerator Docker images**
  - `docker/Dockerfile.cpu` — CPU-only inference (python:3.12-slim + PyTorch CPU wheels)
  - `docker/Dockerfile.rocm` — AMD ROCm 7.2 support (rocm/pytorch official base image)
  - `docker/Dockerfile.intel` — Intel XPU support (intel-extension-for-pytorch official base image)
  - Existing CUDA Dockerfile supports ARG-driven builds for CUDA 11.8–13.2
- **CI/CD multi-accelerator build matrix**
  - CUDA variants: 11.8, 12.4, 12.6, 12.8, 13.0, 13.2
  - Additional jobs: ROCm 7.2, Intel XPU, CPU-only, MCP Server
  - Helm chart validation (lint + template) in CI
  - K3d validation testing deployment on PR merge
- **CI/CD optimizations**
  - Added `--break-system-packages` to all pip commands in all Dockerfiles,
    fixing PEP 668 failures on CUDA 13.0 and 13.2 (Ubuntu 24.04 / Python 3.12
    base images enforce externally-managed-environment)
  - Docker builds only trigger on push to main and tags (removed PR trigger)
  - CI still runs on `workflow_dispatch` (manual trigger)
- **Documentation** at `docs/helm/`
  - `README.md` — architecture overview and accelerator support matrix
  - `INSTALL.md` — step-by-step install guide with PV creation examples, subpath deployment guide
  - `VALUES.md` — complete configuration reference (nginx, openwebui, additionalIngresses)
  - `EXAMPLES.md` — concrete scenarios for all accelerators, subpath behind nginx ingress
- **OpenWebUI MCP configuration** at `openwebui/mcp-config.md`
  - Helm auto-configuration section for MCP connection when deployed via chart
- **Architecture Decision Record** at `docs/adrs/001-helm-migration.md`

### Changed

- README updated from Kustomize-based to Helm-based deployment instructions
- Updated `.gitignore` with `worktrees/` pattern

### Removed

- `k8s/` directory (Kustomize configuration fully replaced by Helm chart)

### Security

- GPU resource names are auto-detected from vendor setting (nvidia.com/gpu, amd.com/gpu, or gpu.intel.com/i915)
- MCP token stored as Kubernetes Secret (base64 encoded)
