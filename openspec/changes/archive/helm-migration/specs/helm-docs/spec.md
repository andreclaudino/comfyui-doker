## ADDED Requirements

### Requirement: Documentation exists at docs/helm/

The project SHALL have documentation files under `docs/helm/` covering installation, configuration, and accelerator selection.

#### Scenario: README.md exists

- **WHEN** a user visits `docs/helm/README.md`
- **THEN** they SHALL find an overview of the Helm chart, architecture diagram, and links to other docs

### Requirement: Install guide explains prerequisites and steps

`docs/helm/INSTALL.md` SHALL list prerequisites (Helm 3, kubectl, cluster access) and provide step-by-step install, upgrade, and uninstall instructions.

#### Scenario: Install guide includes PV creation

- **WHEN** a user reads the install guide
- **THEN** they SHALL find instructions for creating a PV with examples for NFS, hostPath, and StorageClass-based provisioning

### Requirement: Values reference is comprehensive

`docs/helm/VALUES.md` SHALL contain a table of every configurable value in `values.yaml` with type, default, and description.

#### Scenario: Values table covers all parameters

- **WHEN** a user reads the values reference
- **THEN** every key from `values.yaml` SHALL appear in the table
- **THEN** nested keys SHALL be flattened (dot notation) for readability

### Requirement: Accelerator selection is documented

`docs/helm/EXAMPLES.md` SHALL include concrete examples for each accelerator type: NVIDIA (CUDA variants), AMD (ROCm), Intel, and CPU.

#### Scenario: NVIDIA guide includes node selector and image tag

- **WHEN** a user reads the NVIDIA section
- **THEN** they SHALL see the recommended image tag per CUDA version
- **THEN** they SHALL see the required `nodeSelector` for NVIDIA GPU nodes

#### Scenario: CPU guide includes --cpu flag

- **WHEN** a user reads the CPU section
- **THEN** they SHALL see that `comfyuiArgs` must include `--cpu`
- **THEN** they SHALL see that no node selector is needed
