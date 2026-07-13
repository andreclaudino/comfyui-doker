## ADDED Requirements

### Requirement: CI builds multiple CUDA variants

The CI workflow SHALL build Docker images for CUDA 11.8, 12.4, 12.6, 13.0, and 13.2 using the same `docker/Dockerfile` with different build arguments. Each SHALL be tagged with a variant suffix (e.g., `-cuda12.4`, `-cuda13.0`).

#### Scenario: CUDA variants are published

- **WHEN** a push to `main` occurs
- **THEN** images SHALL be built for all CUDA versions in the matrix
- **THEN** each image SHALL be tagged with `latest-{variant}` and `sha-{commit}-{variant}`

#### Scenario: Semver tags include CUDA suffix

- **WHEN** a git tag `v1.2.3` is pushed
- **THEN** images SHALL be tagged as `1.2.3-cuda12.4`, `1.2-cuda12.4`, etc. per variant

### Requirement: CI builds ROCm image

The CI workflow SHALL build a ROCm variant using `docker/Dockerfile.rocm` based on Ubuntu 22.04 with PyTorch installed from the ROCm index.

#### Scenario: ROCm image is published

- **WHEN** a push to `main` occurs
- **THEN** a `latest-rocm7.2` (or latest ROCm version) image SHALL be built and pushed

### Requirement: CI builds Intel XPU image

The CI workflow SHALL build an Intel variant using `docker/Dockerfile.intel` with Intel compute runtime, Level Zero, and PyTorch XPU.

#### Scenario: Intel image is published

- **WHEN** a push to `main` occurs
- **THEN** a `latest-intel` image SHALL be built and pushed

### Requirement: CI builds CPU-only image

The CI workflow SHALL build a CPU-only variant using `docker/Dockerfile.cpu` based on `python:3.12-slim` with PyTorch CPU wheels.

#### Scenario: CPU image is published

- **WHEN** a push to `main` occurs
- **THEN** a `latest-cpu` image SHALL be built and pushed

### Requirement: CUDA image is the default

The `latest` (no suffix) and `latest-cuda12.4` tags SHALL point to the same image. The Helm chart defaults to `latest-cuda12.4`.

#### Scenario: Latest alias is maintained

- **WHEN** the CI completes building all variants
- **THEN** the `latest` tag SHALL be aliased to the CUDA 12.4 image

### Requirement: CPU image runs with --cpu flag

The CPU-only image SHALL require the `--cpu` flag added to `COMFYUI_ARGS` or the startup command. The Helm chart documentation SHALL document this.

#### Scenario: CPU image without --cpu logs a warning

- **WHEN** the CPU image starts without `--cpu`
- **THEN** ComfyUI SHALL fail to detect a GPU and log a warning; inference SHALL still work (CPU fallback)
