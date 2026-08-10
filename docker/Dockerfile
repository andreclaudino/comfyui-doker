# ComfyUI Docker image with GPU support
ARG CUDA=12.4
ARG TORCH_VERSION=2.4.1
ARG CUDNN=9
# Pin ComfyUI to a known-good commit. Rebuilding from a moving `master`
# drifts dependencies (e.g. comfy-kitchen 0.2.28 needs torch>=2.7 while the
# cuda12.4 base ships torch 2.6.0). 80acfcf (2026-07-13) is verified working
# with torch 2.6.0 / comfy-kitchen 0.2.19.
ARG COMFYUI_REF=80acfcf0fe6ea006f0d6176be8301ade1c0c4836

FROM pytorch/pytorch:${TORCH_VERSION}-cuda${CUDA}-cudnn${CUDNN}-runtime

ARG COMFYUI_REF

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends git gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Use --break-system-packages to bypass PEP 668 on Ubuntu 24.04+ base images
RUN pip install --break-system-packages --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /workspace

# COMFYUI_REF may be a branch, tag, or commit SHA; fetch it explicitly so the
# build is reproducible regardless of how far master has moved.
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && \
    git -C /workspace/ComfyUI fetch --depth 1 origin ${COMFYUI_REF} && \
    git -C /workspace/ComfyUI checkout ${COMFYUI_REF}

WORKDIR /workspace/ComfyUI

RUN pip install --break-system-packages --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip

RUN mkdir -p custom_nodes models output input user

# ComfyUI-Manager: auto-installs missing custom nodes and downloads models
# from the web UI when a workflow is loaded. Pinned to a stable release tag
# for reproducible builds (pygit2 has cp311 manylinux wheels, no libgit2 dev
# package needed).
ARG COMFYUI_MANAGER_VERSION=4.2.2
RUN git clone --depth 1 --branch ${COMFYUI_MANAGER_VERSION} \
        https://github.com/ltdrdata/ComfyUI-Manager.git \
        custom_nodes/ComfyUI-Manager && \
    pip install --break-system-packages --no-cache-dir \
        -r custom_nodes/ComfyUI-Manager/requirements.txt && \
    rm -rf /root/.cache/pip

COPY docker/entrypoint.sh /workspace/entrypoint.sh
RUN chmod +x /workspace/entrypoint.sh

ENV PYTHONPATH=/workspace/ComfyUI
ENV PYTHONDONTWRITEBYTECODE=1
ENV COMFYUI_PORT=8188
ENV COMFYUI_HOST=0.0.0.0
ENV COMFYUI_ARGS="--listen 0.0.0.0 --port 8188"
ENV COMFYUI_CUSTOM_NODES=""

EXPOSE 8188

ENTRYPOINT ["/workspace/entrypoint.sh"]
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
