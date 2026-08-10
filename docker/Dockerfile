# ComfyUI Docker image with GPU support
ARG CUDA=12.4
ARG TORCH_VERSION=2.4.1
ARG CUDNN=9
ARG COMFYUI_REF=master

FROM pytorch/pytorch:${TORCH_VERSION}-cuda${CUDA}-cudnn${CUDNN}-runtime

ARG COMFYUI_REF

ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends git gcc g++ && \
    rm -rf /var/lib/apt/lists/*

# Use --break-system-packages to bypass PEP 668 on Ubuntu 24.04+ base images
RUN pip install --break-system-packages --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /workspace

RUN git clone --depth 1 --branch ${COMFYUI_REF} \
    https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

WORKDIR /workspace/ComfyUI

RUN pip install --break-system-packages --no-cache-dir -r requirements.txt && \
    rm -rf /root/.cache/pip

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
