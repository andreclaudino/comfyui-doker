## ADDED Requirements

### Requirement: OpenWebUI is an optional chart component

The chart SHALL support deploying OpenWebUI as an optional component behind the `openwebui.enabled` flag.

#### Scenario: openwebui.enabled is false (default)

- **GIVEN** `openwebui.enabled: false` (default)
- **WHEN** the chart renders
- **THEN** NO OpenWebUI resources SHALL be created

#### Scenario: openwebui.enabled is true with ingress

- **GIVEN** `openwebui.enabled: true` and `openwebui.ingress.host: "chat.example.com"`
- **WHEN** the chart renders
- **THEN** the following resources SHALL be created:
  - Deployment (`openwebui-deployment.yaml`)
  - Service (`openwebui-service.yaml`, ClusterIP, port 8080)
  - Ingress (`openwebui-ingress.yaml`)

#### Scenario: openwebui ingress disabled

- **GIVEN** `openwebui.enabled: true` and `openwebui.ingress.enabled: false`
- **WHEN** the chart renders
- **THEN** only Deployment and Service SHALL be created (no Ingress)

### Requirement: OpenWebUI MCP connection

The OpenWebUI deployment SHALL be pre-configured to connect to the ComfyUI-MCP service running in the same namespace.

#### Scenario: MCP is enabled

- **GIVEN** `mcp.enabled: true` and `openwebui.enabled: true`
- **WHEN** the OpenWebUI deployment renders
- **THEN** the environment variable `MCP_SERVERS` SHALL contain a JSON config pointing to the internal MCP service URL
- **THEN** if `mcp.token` is set, the `Authorization` header SHALL include the Bearer token

#### Scenario: MCP is disabled

- **GIVEN** `mcp.enabled: false` and `openwebui.enabled: true`
- **WHEN** the deployment renders
- **THEN** NO `MCP_SERVERS` env var SHALL be set (documented warning in NOTES.txt)

### Requirement: OpenWebUI image is configurable

#### Scenario: custom image

- **GIVEN** `openwebui.image.repository: "my-registry/open-webui"` and `openwebui.image.tag: "v0.3.0"`
- **WHEN** the deployment renders
- **THEN** the image SHALL be `my-registry/open-webui:v0.3.0`

### Requirement: OpenWebUI supports additionalIngresses

OpenWebUI SHALL support the same `additionalIngresses` pattern as ComfyUI and MCP for subpath routing.

#### Scenario: OpenWebUI on subpath

- **GIVEN** `openwebui.additionalIngresses` is configured with a subpath
- **WHEN** the chart renders
- **THEN** extra Ingress resources SHALL be created for the subpath

### Requirement: OpenWebUI without persistence

The chart SHALL NOT create a PVC for OpenWebUI by default. Users can mount their own volume for persistence.

#### Scenario: no storage configured

- **GIVEN** default OpenWebUI values
- **WHEN** the deployment renders
- **THEN** NO volume mounts SHALL be added
- **THEN** NOTES.txt SHALL warn that chat history is ephemeral

#### Scenario: user mounts custom volume

- **GIVEN** `openwebui.extraVolumes` and `openwebui.extraVolumeMounts` are set
- **WHEN** the deployment renders
- **THEN** the specified volumes SHALL be mounted into the OpenWebUI container
