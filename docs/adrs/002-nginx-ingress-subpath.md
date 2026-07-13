# ADR 002: Nginx Ingress Subpath Routing and OpenWebUI Integration

**Date:** 2026-07-13

**Status:** Accepted

## Context

The Helm chart currently creates ingress resources with a single root path (`/` for ComfyUI, `/mcp` for MCP) and no controller-specific annotations. This works for dedicated hostnames but fails when users need to deploy multiple services behind a single nginx ingress controller on different subpaths -- a common pattern in homelabs and shared clusters.

Without rewrite rules, subpath routing breaks:
- Static asset serving (JS, CSS, images)
- API calls routed through path prefixes
- WebSocket connections for live queue progress

Additionally, OpenWebUI (a popular chat interface for MCP) is not part of the Helm chart and requires separate deployment.

## Decision

We will:

1. **Add optional nginx ingress annotations** (`use-regex`, `rewrite-target`, proxy timeouts) as configurable values under a top-level `nginx` section
2. **Add `additionalIngresses` support** to each component (comfyui, mcp, openwebui) for subpath routing alongside dedicated hostnames
3. **Add `COMFYUI_BASE_URL`** environment variable so ComfyUI generates correct asset paths when served under a subpath
4. **Add OpenWebUI as an optional chart component** (behind `openwebui.enabled` flag) with its own deployment, service, and ingress templates
5. All new values are optional and default to current behavior (backward compatible)

## Alternatives Considered

### Alternative 1: Require separate hostnames per service
- **Pro**: No rewrite rules needed; simpler ingress config
- **Con**: Requires a wildcard DNS or multiple TLS certificates; doesn't work in shared clusters with limited DNS control
- **Rejected**: Common homelab setups need single-domain multi-path routing

### Alternative 2: Deploy a standalone reverse proxy (Traefik, Caddy) outside the chart
- **Pro**: More flexible routing; controller-agnostic
- **Con**: Adds operational complexity; users must manage another service; doesn't integrate with the Helm chart
- **Rejected**: nginx ingress annotations are the idiomatic Kubernetes approach

### Alternative 3: Use ingress-nginx specific CRDs (VirtualServer/VirtualHost)
- **Pro**: More expressive than annotations; supports advanced routing
- **Con**: Requires CRD installation; not available in all clusters; more complex
- **Rejected**: Annotations are sufficient for subpath rewrite and WebSocket proxying

## Consequences

### Positive
- **Subpath routing**: Users can deploy ComfyUI + MCP + OpenWebUI under a single domain (e.g., `example.com/comfyui`, `example.com/mcp`, `example.com/chat`)
- **WebSocket support**: Long proxy timeouts prevent connection drops during image generation
- **OpenWebUI integration**: First-class component reduces deployment friction
- **Backward compatible**: All new values default to disabled/empty; existing installs unchanged

### Negative
- **nginx-specific**: Rewrite annotations only work with the nginx ingress controller; users with other controllers won't benefit from the `nginx` section
- **Complexity**: `additionalIngresses` and capture groups (`(/|$)(.*)`) can be confusing for users unfamiliar with regex-based routing
- **OpenWebUI without PVC**: Chat history is ephemeral by default; users must mount their own PVC for persistence

### Neutral
- Requires ComfyUI to support `--base-url` flag (verified in current image versions)
- Chart size increases by +3 templates and ~20 new values
- Documentation must cover subpath examples with clear explanations of capture groups
