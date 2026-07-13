## ADDED Requirements

### Requirement: Helm chart installs ComfyUI + MCP

The Helm chart SHALL deploy ComfyUI (main application) and ComfyUI-MCP (bridge server) as separate deployments in the same namespace.

#### Scenario: Default install creates all resources

- **WHEN** a user runs `helm install comfyui ./helm/comfyui` with default values
- **THEN** the chart creates: Namespace (if enabled), PVC, ComfyUI Deployment + Service, ComfyUI-MCP Deployment + Service + Secret

#### Scenario: Ingress can be disabled per component

- **WHEN** a user sets `comfyui.ingress.enabled: false` or `mcp.ingress.enabled: false`
- **THEN** the corresponding Ingress resource SHALL NOT be created

#### Scenario: MCP can be disabled entirely

- **WHEN** a user sets `mcp.enabled: false`
- **THEN** no MCP Deployment, Service, Ingress, or Secret SHALL be created

#### Scenario: Namespace creation is optional

- **WHEN** a user sets `namespace.create: true`
- **THEN** a Namespace resource SHALL be created
- **WHEN** `namespace.create: false` (default)
- **THEN** the user SHALL create the namespace beforehand or use `helm --create-namespace`

### Requirement: Storage is PVC-based

The chart SHALL create a PersistentVolumeClaim but MUST NOT create a PersistentVolume. The user is responsible for provisioning the PV beforehand.

#### Scenario: PVC uses specified storage class

- **WHEN** `storage.storageClass: ""` (default)
- **THEN** the PVC SHALL use the cluster's default storage class
- **WHEN** `storage.storageClass: "nfs-client"`
- **THEN** the PVC SHALL reference `nfs-client` StorageClass

#### Scenario: PVC uses existing claim

- **WHEN** `storage.existingClaim: "my-pvc"` is set
- **THEN** no PVC resource SHALL be created; the existing claim SHALL be referenced in deployments

### Requirement: All stateful directories persist on PV

The PVC SHALL be mounted at `/comfyui`. The ComfyUI deployment's command SHALL symlink `/comfyui/{models,custom_nodes,user,input,output}` into `/workspace/ComfyUI/` so all persistent data lives on the volume.

#### Scenario: Empty PV is initialized with directory structure

- **WHEN** the pod starts on an empty PV
- **THEN** the startup command SHALL create `models/`, `custom_nodes/`, `user/`, `input/`, `output/` directories inside `/comfyui`
- **THEN** each directory SHALL be symlinked to `/workspace/ComfyUI/<dir>`

#### Scenario: Existing data on PV is available

- **WHEN** the pod restarts and the PV already has data
- **THEN** the symlinks SHALL point to existing directories; no data SHALL be overwritten

### Requirement: Ingress uses cluster default class

The chart SHALL NOT hardcode any ingress controller. `ingressClassName` defaults to empty string, which uses the cluster's default IngressClass.

#### Scenario: User sets custom ingress class

- **WHEN** `comfyui.ingress.className: "traefik"` is set
- **THEN** the Ingress SHALL use `traefik` as ingress class name

#### Scenario: Ingress host is required

- **WHEN** `comfyui.ingress.enabled: true` but `comfyui.ingress.host: ""`
- **THEN** the Ingress SHALL NOT be created (chart renders safely)

### Requirement: MCP authentication is optional

The chart SHALL support three modes for MCP authentication: no auth, existing secret, or inline token.

#### Scenario: No authentication

- **WHEN** `mcp.token: ""` and `mcp.existingSecret: ""`
- **THEN** no Secret SHALL be created; MCP runs without authentication

#### Scenario: Existing secret

- **WHEN** `mcp.existingSecret: "my-mcp-token"`
- **THEN** the MCP deployment SHALL reference that secret's `MCP_TOKEN` key
- **WHEN** `mcp.existingSecret` and `mcp.token` are both set
- **THEN** `existingSecret` SHALL take precedence

#### Scenario: Inline token

- **WHEN** `mcp.token: "my-generated-token-here"`
- **THEN** a Secret SHALL be created with that value as `MCP_TOKEN`

### Requirement: Node selector is empty by default

The chart MUST NOT set any default node selector. Users configure GPU targeting themselves.

#### Scenario: NVIDIA GPU

- **WHEN** `comfyui.nodeSelector: {"nvidia.com/gpu.present": "true"}`
- **THEN** the pod SHALL only schedule on nodes with NVIDIA GPUs

#### Scenario: AMD GPU

- **WHEN** `comfyui.nodeSelector: {"amd.com/gpu.present": "true"}`
- **THEN** the pod SHALL only schedule on nodes with AMD GPUs

#### Scenario: No GPU (CPU)

- **WHEN** `comfyui.nodeSelector: {}` (default)
- **THEN** the pod SHALL schedule on any node
