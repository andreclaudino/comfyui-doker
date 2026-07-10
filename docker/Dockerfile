# Multi-stage build for ComfyUI with GPU support
# Usage: docker build --build-arg CUDA_VERSION=12.4.1 -t comfyui .
# Supported CUDA versions: 11.8.0, 12.1.0, 12.4.1, 13.0.0

ARG CUDA_VERSION=12.4.1
ARG UBUNTU_VERSION=22.04
ARG TORCH_VERSION=2.4.1
ARG TORCHVISION_VERSION=0.19.1
ARG TORCHAUDIO_VERSION=2.4.1
ARG XFORMERS_VERSION=0.0.28

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS builder

ARG CUDA_VERSION
ARG TORCH_VERSION
ARG TORCHVISION_VERSION
ARG TORCHAUDIO_VERSION
ARG XFORMERS_VERSION

RUN if [ "$(echo ${CUDA_VERSION} | cut -d. -f1)" = "13" ]; then \
        echo "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu126" > /tmp/torch.env; \
    elif [ "$(echo ${CUDA_VERSION} | cut -d. -f1)" = "12" ] && [ "$(echo ${CUDA_VERSION} | cut -d. -f2)" -ge "4" ]; then \
        echo "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu124" > /tmp/torch.env; \
    else \
        echo "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu118" > /tmp/torch.env; \
    fi

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_CACHE_DIR=/tmp/pip-cache

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv git wget curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

WORKDIR /workspace

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip setuptools wheel

RUN . /tmp/torch.env && \
    pip install --no-cache-dir --index-url ${TORCH_INDEX_URL} \
    torch==${TORCH_VERSION} \
    torchvision==${TORCHVISION_VERSION} \
    torchaudio==${TORCHAUDIO_VERSION} && \
    rm -rf /tmp/pip-cache /root/.cache/pip

RUN . /tmp/torch.env && \
    pip install --no-cache-dir xformers==${XFORMERS_VERSION} --index-url ${TORCH_INDEX_URL} || true && \
    rm -rf /tmp/pip-cache /root/.cache/pip

RUN pip install --no-cache-dir \
    einops==0.8.0 transformers==4.44.2 safetensors==0.4.5 \
    accelerate==0.34.2 kornia==0.7.4 Pillow==10.4.0 \
    scipy==1.13.1 numpy==1.26.4 tqdm==4.66.5 psutil==6.0.0 \
    pyyaml==6.0.1 requests==2.32.3 aiohttp==3.10.5 \
    aiofiles==24.1.0 tornado==6.4.1 websockets==13.1 \
    peft==0.13.2 bitsandbytes==0.44.1 && \
    rm -rf /tmp/pip-cache /root/.cache/pip

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS runtime

ARG CUDA_VERSION

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv git wget curl ca-certificates \
    libglib2.0-0 libsm6 libxext6 libxrender-dev libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /workspace

RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

WORKDIR /workspace/ComfyUI

RUN pip install --no-cache-dir -r requirements.txt && \
    rm -rf /tmp/pip-cache /root/.cache/pip

RUN mkdir -p custom_nodes models output input user

COPY docker/entrypoint.sh /workspace/entrypoint.sh
RUN chmod +x /workspace/entrypoint.sh

ENV PYTHONPATH=/workspace/ComfyUI
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV COMFYUI_PORT=8188
ENV COMFYUI_HOST=0.0.0.0
ENV COMFYUI_ARGS="--listen 0.0.0.0 --port 8188"
ENV COMFYUI_CUSTOM_NODES=""

EXPOSE 8188

ENTRYPOINT ["/workspace/entrypoint.sh"]
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
