## 1. Architecture Decision Record

- [x] 1.1 Create `docs/adrs/002-nginx-ingress-subpath.md` documenting the decision to add nginx ingress rewrite + WebSocket + optional OpenWebUI
  - Target: `docs/adrs/002-nginx-ingress-subpath.md`
  - Context: decision rationale, alternatives considered, consequences
  - Ref: proposal.md, design.md

## 2. values.yaml — Add new configuration sections

- [x] 2.1 Add `nginx` section with rewrite and WebSocket timeout defaults
  - Target: `helm/comfyui/values.yaml`
  - Change: add `nginx.enabled`, `nginx.rewriteTarget`, `nginx.useRegex`, `nginx.proxyConnectTimeout`, `nginx.proxySendTimeout`, `nginx.proxyReadTimeout`
  - Ref: design.md Decision 1, spec ingress-rewrite

- [x] 2.2 Add `additionalIngresses` to `comfyui.ingress`
  - Target: `helm/comfyui/values.yaml`
  - Change: add `comfyui.ingress.additionalIngresses: []` list
  - Ref: design.md Decision 2

- [x] 2.3 Add `additionalIngresses` to `mcp.ingress`
  - Target: `helm/comfyui/values.yaml`
  - Change: add `mcp.ingress.additionalIngresses: []` list
  - Ref: design.md Decision 2

- [x] 2.4 Add `comfyui.env.COMFYUI_BASE_URL` for subpath asset routing
  - Target: `helm/comfyui/values.yaml`
  - Change: add `COMFYUI_BASE_URL: ""` to `comfyui.env`
  - Ref: design.md Decision 3

- [x] 2.5 Add `openwebui` section with deployment, service, ingress, and MCP connection config
  - Target: `helm/comfyui/values.yaml`
  - Change: add `openwebui.enabled`, `openwebui.image.*`, `openwebui.service.*`, `openwebui.ingress.*`, `openwebui.env.*`, `openwebui.resources.*`, `openwebui.extraVolumes`, `openwebui.extraVolumeMounts`
  - Ref: design.md Decision 4, spec openwebui-deployment

## 3. ComfyUI Ingress Template — Add nginx annotations + additionalIngresses

- [x] 3.1 Add nginx annotations block to `comfyui-ingress.yaml` (conditional on `nginx.enabled`)
  - Target: `helm/comfyui/templates/comfyui-ingress.yaml`
  - Change: insert `{{- if .Values.nginx.enabled }}` block with all nginx annotations
  - Ref: spec ingress-rewrite

- [x] 3.2 Add `additionalIngresses` loop to `comfyui-ingress.yaml`
  - Target: `helm/comfyui/templates/comfyui-ingress.yaml`
  - Change: add `{{- range .Values.comfyui.ingress.additionalIngresses }}` block to create extra Ingress resources
  - Ref: spec ingress-rewrite

## 4. MCP Ingress Template — Add nginx annotations + additionalIngresses

- [x] 4.1 Add nginx annotations block to `mcp-ingress.yaml` (conditional on `nginx.enabled`)
  - Target: `helm/comfyui/templates/mcp-ingress.yaml`
  - Change: insert `{{- if .Values.nginx.enabled }}` block with all nginx annotations
  - Ref: spec ingress-rewrite

- [x] 4.2 Add `additionalIngresses` loop to `mcp-ingress.yaml`
  - Target: `helm/comfyui/templates/mcp-ingress.yaml`
  - Change: add `{{- range .Values.mcp.ingress.additionalIngresses }}` block
  - Ref: spec ingress-rewrite

## 5. ComfyUI Deployment — Add base URL support

- [x] 5.1 Add `COMFYUI_BASE_URL` env var injection into `comfyui-deployment.yaml`
  - Target: `helm/comfyui/templates/comfyui-deployment.yaml`
  - Change: append `--base-url {{ .Values.comfyui.env.COMFYUI_BASE_URL }}` to COMFYUI_ARGS when COMFYUI_BASE_URL is non-empty
  - Ref: spec ingress-rewrite

## 6. OpenWebUI Deployment Template

- [x] 6.1 Create `helm/comfyui/templates/openwebui-deployment.yaml` (conditional on `openwebui.enabled`)
  - Target: `helm/comfyui/templates/openwebui-deployment.yaml`
  - Content: Deployment with OpenWebUI image, env vars for MCP connection (auto-generated from mcp values), optional volume mounts
  - Ref: spec openwebui-deployment

- [x] 6.2 Create `helm/comfyui/templates/openwebui-service.yaml` (conditional)
  - Target: `helm/comfyui/templates/openwebui-service.yaml`
  - Content: ClusterIP service exposing port from `openwebui.service.port`

- [x] 6.3 Create `helm/comfyui/templates/openwebui-ingress.yaml` (conditional, with nginx + additionalIngresses support)
  - Target: `helm/comfyui/templates/openwebui-ingress.yaml`
  - Content: Ingress template following same patterns as comfyui-ingress.yaml

## 7. Helm Validation

- [x] 7.1 Run `helm lint helm/comfyui/` and fix all warnings/errors
  - Command: `helm lint helm/comfyui/`
  - Ref: config rules

- [x] 7.2 Run `helm template --validate helm/comfyui/` to validate against Kubernetes schema
  - Command: `helm template comfyui helm/comfyui/ --validate`

## 8. Documentation

- [x] 8.1 Update `docs/helm/VALUES.md` with all new parameters (nginx, openwebui, additionalIngresses, base URL)
  - Target: `docs/helm/VALUES.md`
  - Ref: specs ingress-rewrite, openwebui-deployment

- [x] 8.2 Update `docs/helm/INSTALL.md` with subpath install examples
  - Target: `docs/helm/INSTALL.md`
  - Content: add "Subpath deployment" section with nginx ingress examples for comfyui + mcp + openwebui under one hostname

- [x] 8.3 Update `docs/helm/EXAMPLES.md` with subpath scenario
  - Target: `docs/helm/EXAMPLES.md`
  - Content: add "Subpath behind nginx ingress" example

- [x] 8.4 Update `openwebui/mcp-config.md` with subpath ingress URLs and auto-config when deployed via Helm
  - Target: `openwebui/mcp-config.md`
  - Content: add note about OpenWebUI MCP auto-configuration when deployed via Helm chart

- [x] 8.5 Trigger documentation review agent to verify all docs are accurate and complete
  - Action: run documentation review against updated docs/helm/ and openwebui/

## 9. Changelog

- [x] 9.1 Update `CHANGELOG.md` following keepachangelog format
  - Target: `CHANGELOG.md`
  - Change: add entries for nginx rewrite support, subpath routing, OpenWebUI component, and base URL support
