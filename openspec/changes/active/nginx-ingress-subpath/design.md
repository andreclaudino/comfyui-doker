## Context

The Helm chart currently creates ingresses with a simple path (`/` for ComfyUI, `/mcp` for MCP) and no controller-specific annotations. The `ingressClassName` defaults to cluster default (empty string). This works when:

- Each service gets its own hostname (e.g., `comfyui.example.com`, `mcp.example.com`)
- The cluster's default ingress controller handles path routing correctly

It fails when:

- Users want to deploy behind a single hostname on subpaths (e.g., `example.com/comfyui`, `example.com/chat`)
- The ingress controller is nginx and requires `rewrite-target` to strip path prefixes
- WebSocket connections (used by ComfyUI for live progress) need extended proxy timeouts

OpenWebUI is currently not part of the Helm chart at all — it's documented as a standalone Docker Compose or manual K8s deployment in `openwebui/mcp-config.md`.

## Goals / Non-Goals

**Goals:**
- Add optional nginx rewrite annotations (`use-regex`, `rewrite-target`, proxy timeouts) as chart values
- Support deploying ComfyUI + MCP under subpaths of a single hostname
- Add `additionalIngresses` to the chart: users can define extra Ingress resources for different path mappings
- Add optional OpenWebUI deployment as a chart component (behind `openwebui.enabled`)
- ComfyUI must respect a base path so assets, API routes, and WebSocket paths work under a subpath
- All new values are optional and default to current behavior (backward compatible)

**Non-Goals:**
- Making nginx the default ingress controller
- Supporting ingress controllers other than nginx (rewrite annotations are nginx-specific)
- OpenWebUI persistent storage (user handles PVC separately)
- OpenWebUI authentication or user management
- Automating TLS/cert-manager

## Decisions

### Decision 1: nginx annotations are optional and grouped under `nginx`

New values go under a top-level `nginx` section. If empty (default), no annotations are added and behavior is identical to today.

```yaml
nginx:
  enabled: false          # master switch for all nginx features
  rewriteTarget: "/$2"    # rewrite-target annotation value
  useRegex: true          # use-regex annotation
  proxyConnectTimeout: 5  # seconds
  proxySendTimeout: 3600  # seconds (long for WebSocket)
  proxyReadTimeout: 3600  # seconds (long for WebSocket)
```

### Decision 2: `additionalIngresses` for subpath routing

Each component (comfyui, mcp, openwebui) can have `additionalIngresses` — a list of extra Ingress resources rendered alongside the main one. This lets users define one ingress at root (for dedicated hostname) plus another with rewrite rules (for subpath).

```yaml
comfyui:
  ingress:
    enabled: true
    host: comfyui.example.com   # main ingress: dedicated hostname
    path: /
    additionalIngresses:
      - name: subpath
        host: apps.example.com
        path: /comfyui(/|$)(.*)
        pathType: Prefix
        annotations:
          nginx.ingress.kubernetes.io/use-regex: "true"
          nginx.ingress.kubernetes.io/rewrite-target: /$2
```

### Decision 3: ComfyUI base path via COMFYUI_ARGS

ComfyUI supports `--base-url` (or `--base-path` in newer versions) to set the URL prefix. We add a new env value `comfyui.env.COMFYUI_BASE_URL` and pass it as `--base-url` (or `--front-end-route` depending on version — will document the correct flag based on the ComfyUI version in the image).

### Decision 4: OpenWebUI as optional chart component

OpenWebUI gets its own section in values.yaml:

```yaml
openwebui:
  enabled: false
  image:
    repository: ghcr.io/open-webui/open-webui
    tag: main
  service:
    port: 8080
  ingress:
    enabled: true
    host: ""
    path: /
    additionalIngresses: []
```

The OpenWebUI deployment template is minimal: it connects to MCP via the internal MCP service URL. No PVC (ephemeral config only — user can mount their own for persistence). The MCP config guide in `openwebui/` is updated to reference the internal service URL when deployed via Helm.

### Decision 5: WebSocket timeouts are nginx-specific annotations

ComfyUI uses WebSockets for live queue progress. The nginx ingress controller needs:
- `nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"`
- `nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"`
- `nginx.ingress.kubernetes.io/proxy-body-size: "0"` (disable body size check for large images)

These are set automatically on both comfyui and mcp ingresses when `nginx.enabled: true`.

## Risks / Trade-offs

- [Risk] nginx rewrite rules are complex and error-prone → Mitigation: documented examples with explanation of capture groups
- [Risk] `--base-url` flag may differ between ComfyUI versions → Mitigation: env var defaults to empty; user sets it explicitly
- [Risk] OpenWebUI without PVC loses chat history on restart → Mitigation: documented warning; user can mount a PVC manually
- [Risk] `additionalIngresses` can produce many K8s resources → Mitigation: documented as advanced feature
- [Risk] Proxy timeouts of 1 hour hold connections open → Mitigation: matches typical long-running ComfyUI generations; users can tune

## Open Questions

- Does the current ComfyUI version in our Docker images support `--base-url`? Need to verify and add the correct flag.
- Should OpenWebUI use the internal MCP service URL (cluster-internal) or the ingress URL? Internal is better for performance, but user may want external URL for debugging.
- Should we add a `podSecurityContext` for OpenWebUI (runs as non-root by default)?
