# Multi-stage build for ComfyUI with GPU support
# Usage: docker build --build-arg CUDA=12.4 -t comfyui .
# Supported CUDA versions: 11.8, 12.1, 12.4, 13.0

ARG CUDA=12.4
ARG TORCH_VERSION=2.4.1
ARG COMFYUI_REF=master

# Select base image and versions based on CUDA version
FROM pytorch/pytorch:${TORCH_VERSION}-cuda${CUDA}-cudnn9-runtime AS base

ARG CUDA
ARG TORCH_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_CACHE_DIR=/tmp/pip-cache

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget curl ca-certificates \
    libglib2.0-0 libsm6 libxext6 libxrender-dev libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN git clone --depth 1 --branch ${COMFYUI_REF} \
    https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

WORKDIR /workspace/ComfyUI

RUN pip install --no-cache-dir -r requirements.txt && \
    rm -rf /tmp/pip-cache /root/.cache/pip

RUN mkdir -p custom_nodes models output input user

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
