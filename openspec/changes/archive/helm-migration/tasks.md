## 1. Architecture Decision Record

- [ ] 1.1 Create `docs/adrs/001-helm-migration.md` documenting the decision to migrate from Kustomize to Helm with multi-accelerator support
  - Target: `docs/adrs/001-helm-migration.md`
  - Context: decision rationale, alternatives considered, consequences
  - Ref: proposal.md, design.md

## 2. Docker CPU Image

- [ ] 2.1 Create `docker/Dockerfile.cpu` for CPU-only inference based on `python:3.12-slim` with PyTorch CPU wheels
  - Target: `docker/Dockerfile.cpu`
  - Content: base python:3.12-slim, install git, pip install torch from CPU index, clone ComfyUI, copy entrypoint.sh
  - Ref: specs accelerator-images, design.md Decision 6

## 3. Docker ROCm Image

- [ ] 3.1 Create `docker/Dockerfile.rocm` for AMD GPU inference based on Ubuntu 22.04 with ROCm stack
  - Target: `docker/Dockerfile.rocm`
  - Content: Ubuntu 22.04, install ROCm 7.2 runtime, pip install torch from ROCm index, clone ComfyUI
  - Ref: specs accelerator-images, design.md Decision 6

## 4. Docker Intel Image

- [ ] 4.1 Create `docker/Dockerfile.intel` for Intel Arc/GPU inference with XPU support
  - Target: `docker/Dockerfile.intel`
  - Content: Ubuntu 22.04, install Intel compute runtime, pip install torch from XPU index, clone ComfyUI
  - Ref: specs accelerator-images, design.md Decision 6

## 5. Helm Chart Foundation

- [ ] 5.1 Create `helm/comfyui/Chart.yaml` with chart metadata (apiVersion, name, version, description)
  - Target: `helm/comfyui/Chart.yaml`
  - Ref: design.md Decision 1

- [ ] 5.2 Create `helm/comfyui/values.yaml` with all configurable parameters and sensible defaults
  - Target: `helm/comfyui/values.yaml`
  - Content: ~40 values covering storage, comfyui, mcp, ingress, namespace
  - Ref: design.md, specs helm-deployment

- [ ] 5.3 Create `helm/comfyui/templates/_helpers.tpl` with named templates for names, labels, selectors
  - Target: `helm/comfyui/templates/_helpers.tpl`
  - Ref: standard Helm chart conventions

## 6. Helm Templates — Storage

- [ ] 6.1 Create `helm/comfyui/templates/namespace.yaml` (conditional on namespace.create)
  - Target: `helm/comfyui/templates/namespace.yaml`
  - Ref: specs helm-deployment "Namespace creation is optional"

- [ ] 6.2 Create `helm/comfyui/templates/pvc.yaml` with support for existingClaim or dynamic provisioning
  - Target: `helm/comfyui/templates/pvc.yaml`
  - Ref: specs helm-deployment "Storage is PVC-based", design.md Decision 2

## 7. Helm Templates — ComfyUI

- [ ] 7.1 Create `helm/comfyui/templates/comfyui-deployment.yaml` with PVC mount, symlink command, nodeSelector, resource config
  - Target: `helm/comfyui/templates/comfyui-deployment.yaml`
  - Ref: specs helm-deployment, design.md Decisions 4, 5, 9

- [ ] 7.2 Create `helm/comfyui/templates/comfyui-service.yaml` (ClusterIP, port 8188)
  - Target: `helm/comfyui/templates/comfyui-service.yaml`

- [ ] 7.3 Create `helm/comfyui/templates/comfyui-ingress.yaml` (conditional, cluster default class, no default annotations)
  - Target: `helm/comfyui/templates/comfyui-ingress.yaml`
  - Ref: specs helm-deployment "Ingress uses cluster default class"

## 8. Helm Templates — MCP

- [ ] 8.1 Create `helm/comfyui/templates/mcp-deployment.yaml` (conditional on mcp.enabled, reuses PVC)
  - Target: `helm/comfyui/templates/mcp-deployment.yaml`
  - Ref: design.md Decision 8, specs helm-deployment

- [ ] 8.2 Create `helm/comfyui/templates/mcp-service.yaml` (ClusterIP, port 8000, conditional)
  - Target: `helm/comfyui/templates/mcp-service.yaml`

- [ ] 8.3 Create `helm/comfyui/templates/mcp-ingress.yaml` (conditional, same pattern as comfyui ingress)
  - Target: `helm/comfyui/templates/mcp-ingress.yaml`

- [ ] 8.4 Create `helm/comfyui/templates/mcp-secret.yaml` (conditional on token/existingSecret, supports no-auth mode)
  - Target: `helm/comfyui/templates/mcp-secret.yaml`
  - Ref: specs helm-deployment "MCP authentication is optional"

- [ ] 8.5 Create `helm/comfyui/templates/NOTES.txt` with post-install instructions (URLs, next steps)
  - Target: `helm/comfyui/templates/NOTES.txt`

## 9. Helm Validation

- [ ] 9.1 Run `helm lint helm/comfyui/` and fix all warnings/errors
  - Command: `helm lint helm/comfyui/`
  - Ref: config rules — "all deterministic validations must be run"

- [ ] 9.2 Run `helm template --validate helm/comfyui/` to validate against Kubernetes schema
  - Command: `helm template comfyui helm/comfyui/ --validate`

## 10. CI/CD Workflow

- [ ] 10.1 Expand `.github/workflows/docker-publish.yml` build matrix to include all CUDA variants (11.8, 12.4, 12.6, 13.0, 13.2)
  - Target: `.github/workflows/docker-publish.yml`
  - Change: add matrix entries, adjust metadata-action tags
  - Ref: specs accelerator-images

- [ ] 10.2 Add ROCm build job to `.github/workflows/docker-publish.yml`
  - Target: `.github/workflows/docker-publish.yml`
  - Change: new job using Dockerfile.rocm with appropriate tags

- [ ] 10.3 Add Intel build job to `.github/workflows/docker-publish.yml`
  - Target: `.github/workflows/docker-publish.yml`
  - Change: new job using Dockerfile.intel with appropriate tags

- [ ] 10.4 Add CPU build job to `.github/workflows/docker-publish.yml`
  - Target: `.github/workflows/docker-publish.yml`
  - Change: new job using Dockerfile.cpu with appropriate tags

- [ ] 10.5 Add K3d validation job to `.github/workflows/docker-publish.yml`
  - Target: `.github/workflows/docker-publish.yml`
  - Change: new job that starts K3d, installs the Helm chart, verifies pods start
  - Ref: config rules — "final proposal must include a K3d validation step"

## 11. Documentation

- [ ] 11.1 Create `docs/helm/README.md` with architecture overview, prerequisites, and index
  - Target: `docs/helm/README.md`
  - Ref: specs helm-docs

- [ ] 11.2 Create `docs/helm/INSTALL.md` with step-by-step install, upgrade, uninstall, and PV creation examples
  - Target: `docs/helm/INSTALL.md`
  - Ref: specs helm-docs

- [ ] 11.3 Create `docs/helm/VALUES.md` with complete configuration table (all ~40 values with type/default/description)
  - Target: `docs/helm/VALUES.md`
  - Ref: specs helm-docs

- [ ] 11.4 Create `docs/helm/EXAMPLES.md` with concrete scenarios: NVIDIA, AMD, Intel, CPU, minimal, production
  - Target: `docs/helm/EXAMPLES.md`
  - Ref: specs helm-docs, specs accelerator-images

- [ ] 11.5 Trigger documentation review agent to verify all docs are accurate and complete
  - Action: run documentation review against docs/helm/ and specs
  - Ref: config rules — "every change must trigger a documentation review agent"

## 12. Cleanup

- [ ] 12.1 Remove `k8s/` directory (Kustomize configs are replaced by Helm chart)
  - Target: `k8s/`
  - Command: `git rm -r k8s/`

- [ ] 12.2 Update `CHANGELOG.md` following keepachangelog format with helm-migration entry
  - Target: `CHANGELOG.md`
  - Ref: config rules — "every change must include a task to update CHANGELOG.md"
