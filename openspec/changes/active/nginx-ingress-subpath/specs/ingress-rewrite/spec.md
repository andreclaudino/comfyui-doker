## ADDED Requirements

### Requirement: Nginx rewrite annotations are optional and configurable

The chart SHALL support an `nginx` configuration section that, when enabled, adds nginx-specific ingress annotations for path rewriting and WebSocket support.

#### Scenario: nginx section is empty (default)

- **GIVEN** a default `values.yaml` (no nginx section or `nginx.enabled: false`)
- **WHEN** the chart renders ingress templates
- **THEN** NO nginx-specific annotations SHALL be added
- **THEN** behavior SHALL be identical to the current chart

#### Scenario: nginx section is enabled

- **GIVEN** `nginx.enabled: true`
- **WHEN** the chart renders comfyui and mcp ingress templates
- **THEN** each Ingress SHALL include the following annotations:
  - `nginx.ingress.kubernetes.io/use-regex: "true"`
  - `nginx.ingress.kubernetes.io/rewrite-target: {{ .Values.nginx.rewriteTarget }}`
  - `nginx.ingress.kubernetes.io/proxy-send-timeout: {{ .Values.nginx.proxySendTimeout }}`
  - `nginx.ingress.kubernetes.io/proxy-read-timeout: {{ .Values.nginx.proxyReadTimeout }}`
  - `nginx.ingress.kubernetes.io/proxy-connect-timeout: {{ .Values.nginx.proxyConnectTimeout }}`
  - `nginx.ingress.kubernetes.io/proxy-body-size: "0"`

#### Scenario: nginx values use defaults

- **GIVEN** `nginx.enabled: true` with no other nginx values
- **THEN** the chart SHALL use these defaults:
  - `rewriteTarget: "/$2"`
  - `useRegex: true`
  - `proxyConnectTimeout: 5`
  - `proxySendTimeout: 3600`
  - `proxyReadTimeout: 3600`

### Requirement: Additional Ingresses for subpath routing

Each component (comfyui, mcp, openwebui) SHALL support an `additionalIngresses` list to define extra Ingress resources.

#### Scenario: additionalIngresses is empty (default)

- **GIVEN** `comfyui.ingress.additionalIngresses: []` (default)
- **WHEN** the chart renders
- **THEN** only the main ComfyUI Ingress SHALL be created

#### Scenario: one additional ingress for subpath

- **GIVEN** the following values:
```yaml
comfyui:
  ingress:
    enabled: true
    host: comfyui.example.com
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
- **WHEN** the chart renders
- **THEN** TWO Ingress resources SHALL be created:
  1. Main Ingress for `comfyui.example.com` with path `/`
  2. Additional Ingress for `apps.example.com` with subpath `/comfyui(/|$)(.*)` and nginx rewrite annotations

#### Scenario: additional ingress backend targets the same service

- **WHEN** an additional Ingress is created
- **THEN** it SHALL target the same backend service and port as the main Ingress

### Requirement: WebSocket proxy timeouts on nginx ingresses

When `nginx.enabled: true`, both comfyui and mcp ingresses SHALL have long proxy timeouts suitable for WebSocket connections.

#### Scenario: WebSocket timeouts on comfyui ingress

- **GIVEN** `nginx.enabled: true`
- **WHEN** the comfyui Ingress is rendered
- **THEN** `nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"` SHALL be present
- **THEN** `nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"` SHALL be present

### Requirement: ComfyUI base URL for subpath asset routing

The chart SHALL support setting a base URL so ComfyUI generates correct asset paths when served under a subpath.

#### Scenario: base URL is empty (default)

- **GIVEN** `comfyui.env.COMFYUI_BASE_URL: ""` (default)
- **WHEN** the deployment renders
- **THEN** NO `--base-url` flag SHALL be added to COMFYUI_ARGS

#### Scenario: base URL is set

- **GIVEN** `comfyui.env.COMFYUI_BASE_URL: "/comfyui"`
- **WHEN** the deployment renders
- **THEN** `--base-url /comfyui` SHALL be appended to COMFYUI_ARGS
