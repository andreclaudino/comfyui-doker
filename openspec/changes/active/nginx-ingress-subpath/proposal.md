## Why

The current Helm chart creates ingress resources with a single root path (`/`) and no controller-specific annotations. This works for dedicated hostnames but fails when users need to deploy multiple services behind a single nginx ingress controller on different subpaths — a common pattern in homelabs and shared clusters. Without rewrite rules, subpath routing breaks assets, API calls, and WebSocket connections.

## Rationale

nginx-ingress supports path rewriting via the `rewrite-target` annotation and handles WebSocket upgrades transparently when proxy timeouts are configured correctly. Adding these as optional annotations in the Helm chart lets users deploy ComfyUI + MCP + OpenWebUI under a single domain (e.g., `example.com/comfyui`, `example.com/mcp`, `example.com/chat`) without external reverse proxies.

## What Changes

- Add **nginx ingress annotations** (`use-regex`, `rewrite-target`, proxy timeouts) as configurable values
- Add **`comfyui.additionalIngresses`** support — deploy extra Ingress resources for subpath routing alongside a dedicated hostname
- Add **`openwebui.enabled`** — deploy OpenWebUI as a first-class chart component with its own subpath ingress
- Add **OpenWebUI** deployment template, service, and ingress (optional, behind a flag)
- Update `values.yaml` with new `nginx` and `openwebui` sections
- Update ingress templates to support capture groups and path rewriting
- Add WebSocket timeout configuration for nginx
- Update documentation in `docs/helm/` and `openwebui/`

## Capabilities

### New Capabilities

- `ingress-rewrite`: Configurable nginx rewrite rules + WebSocket timeouts in chart values
- `subpath-routing`: ComfyUI and MCP on subpaths of a single hostname
- `openwebui-deployment`: Optional OpenWebUI deployment with subpath ingress

### Modified Capabilities

- `helm-chart`: Updated ingress templates support regex capture groups
- `mcp-integration`: MCP config guide updated for subpath URLs

## Will do / Won't do

| Will do | Won't do |
|---------|----------|
| Optional nginx rewrite annotations in values.yaml | Make nginx the default ingress controller |
| Configurable WebSocket proxy timeouts | Health check path customization (uses /health) |
| Extra ingress resource for subpath routing (additionalIngresses) | Ingress API deprecation / migration support |
| Optional OpenWebUI deployment template | OpenWebUI state management (PVC, etc.) |
| Update docs for subpath scenarios | TLS automation (cert-manager, etc.) |
| ComfyUI `--base-path` / `--base-url` for subpath assets | Support for ingress controllers other than nginx |
| ADR documenting the subpath architecture | |

## Implementation plan

1. **ADR**: `docs/adrs/002-nginx-ingress-subpath.md`
2. **values.yaml**: Add `nginx` section, `additionalIngresses`, `openwebui` section
3. **Ingress templates**: Update `comfyui-ingress.yaml` and `mcp-ingress.yaml` for rewrite support
4. **New template**: `openwebui-deployment.yaml` (conditional)
5. **New template**: `openwebui-service.yaml` (conditional)
6. **New template**: `openwebui-ingress.yaml` (conditional)
7. **Deployment env**: Add `COMFYUI_BASE_PATH` / `--base-url` to ComfyUI deployment
8. **Docs**: Update `docs/helm/VALUES.md` with new parameters
9. **Docs**: Update `docs/helm/INSTALL.md` with subpath examples
10. **Docs**: Update `openwebui/mcp-config.md` for subpath ingress URLs
11. **Changelog**: Update `CHANGELOG.md`

## Impact

- **Non-breaking**: All existing installs continue working (new values are optional)
- **Ingress complexity**: Users new to nginx rewrite rules may find `additionalIngresses` confusing → mitigated by examples in docs
- **Chart size**: +3 templates, +~20 values → still manageable
- **Validation**: `helm lint` and `helm template --validate` must pass
