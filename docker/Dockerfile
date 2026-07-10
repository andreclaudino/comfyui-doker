# Multi-stage build for ComfyUI with GPU support
# Usage: docker build --build-arg CUDA_VERSION=12.4.1 -t comfyui .
# Supported CUDA versions: 11.8.0, 12.1.0, 12.4.1, 13.0.0

# Build args
ARG CUDA_VERSION=12.4.1
ARG UBUNTU_VERSION=22.04
ARG TORCH_VERSION=2.4.1
ARG TORCHVISION_VERSION=0.19.1
ARG TORCHAUDIO_VERSION=2.4.1
ARG XFORMERS_VERSION=0.0.28

# Select PyTorch index URL and xformers index based on CUDA version
# CUDA 13.0 uses cu126 index (latest compatible), CUDA 12.x uses cu124, CUDA 11.x uses cu118
FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS builder

ARG CUDA_VERSION
ARG TORCH_VERSION
ARG TORCHVISION_VERSION
ARG TORCHAUDIO_VERSION
ARG XFORMERS_VERSION

# Determine PyTorch index URL based on CUDA version
RUN if [ "$(echo ${CUDA_VERSION} | cut -d. -f1)" = "13" ]; then \
        echo "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu126" > /tmp/torch.env; \
    elif [ "$(echo ${CUDA_VERSION} | cut -d. -f1)" = "12" ] && [ "$(echo ${CUDA_VERSION} | cut -d. -f2)" -ge "4" ]; then \
        echo "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu124" > /tmp/torch.env; \
    else \
        echo "TORCH_INDEX_URL=https://download.pytorch.org/whl/cu118" > /tmp/torch.env; \
    fi

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Set working directory
WORKDIR /workspace

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install wheel
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch with CUDA support
RUN . /tmp/torch.env && \
    pip install --no-cache-dir --index-url ${TORCH_INDEX_URL} \
    torch==${TORCH_VERSION} \
    torchvision==${TORCHVISION_VERSION} \
    torchaudio==${TORCHAUDIO_VERSION}

# Install xformers with CUDA support
RUN . /tmp/torch.env && \
    pip install --no-cache-dir xformers==${XFORMERS_VERSION} --index-url ${TORCH_INDEX_URL} || \
    echo "xformers not available for this CUDA version, skipping"

# Install ComfyUI dependencies
RUN pip install --no-cache-dir \
    einops==0.8.0 \
    transformers==4.44.2 \
    safetensors==0.4.5 \
    accelerate==0.34.2 \
    kornia==0.7.4 \
    Pillow==10.4.0 \
    scipy==1.13.1 \
    numpy==1.26.4 \
    tqdm==4.66.5 \
    psutil==6.0.0 \
    pyyaml==6.0.1 \
    requests==2.32.3 \
    aiohttp==3.10.5 \
    aiofiles==24.1.0 \
    tornado==6.4.1 \
    websockets==13.1 \
    peft==0.13.2 \
    bitsandbytes==0.44.1

# Final stage - runtime
FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS runtime

ARG CUDA_VERSION

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    git \
    wget \
    curl \
    ca-certificates \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libglib2.0-0 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Set working directory
WORKDIR /workspace

# Clone ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# Set working directory to ComfyUI
WORKDIR /workspace/ComfyUI

# Install ComfyUI requirements
RUN pip install --no-cache-dir -r requirements.txt

# Create custom nodes directory
RUN mkdir -p /workspace/ComfyUI/custom_nodes

# Create directory for models
RUN mkdir -p /workspace/ComfyUI/models

# Create directory for output
RUN mkdir -p /workspace/ComfyUI/output

# Create directory for input
RUN mkdir -p /workspace/ComfyUI/input

# Create directory for user config
RUN mkdir -p /workspace/ComfyUI/user

# Copy entrypoint script
COPY docker/entrypoint.sh /workspace/entrypoint.sh
RUN chmod +x /workspace/entrypoint.sh

# Set environment variables
ENV PYTHONPATH=/workspace/ComfyUI
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# ComfyUI configuration
ENV COMFYUI_PORT=8188
ENV COMFYUI_HOST=0.0.0.0
ENV COMFYUI_ARGS="--listen 0.0.0.0 --port 8188"

# Custom nodes environment variable (comma-separated repo URLs)
ENV COMFYUI_CUSTOM_NODES=""

# Expose ComfyUI port
EXPOSE 8188

# Set entrypoint
ENTRYPOINT ["/workspace/entrypoint.sh"]

# Default command to start ComfyUI
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]