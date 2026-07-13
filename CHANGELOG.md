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
- **Multi-accelerator Docker images**
  - `docker/Dockerfile.cpu` — CPU-only inference (python:3.12-slim)
  - `docker/Dockerfile.rocm` — AMD ROCm 7.2 support (Ubuntu 22.04)
  - `docker/Dockerfile.intel` — Intel XPU support (Ubuntu 22.04 + compute runtime)
  - Existing CUDA Dockerfile supports ARG-driven builds for CUDA 11.8–13.2
- **CI/CD multi-accelerator build matrix**
  - CUDA variants: 11.8, 12.4, 12.6, 12.8, 13.0, 13.2
  - Additional jobs: ROCm 7.2, Intel XPU, CPU-only, MCP Server
  - Helm chart validation (lint + template) in CI
  - K3d validation testing deployment on PR merge
- **Documentation** at `docs/helm/`
  - `README.md` — architecture overview and accelerator support matrix
  - `INSTALL.md` — step-by-step install guide with PV creation examples
  - `VALUES.md` — complete configuration reference
  - `EXAMPLES.md` — concrete scenarios for all accelerators
- **Architecture Decision Record** at `docs/adrs/001-helm-migration.md`

### Changed

- README updated from Kustomize-based to Helm-based deployment instructions
- Updated `.gitignore` with `worktrees/` pattern

### Removed

- `k8s/` directory (Kustomize configuration fully replaced by Helm chart)

### Security

- GPU resource names are auto-detected from vendor setting (nvidia.com/gpu, amd.com/gpu, or gpu.intel.com/i915)
- MCP token stored as Kubernetes Secret (base64 encoded)
