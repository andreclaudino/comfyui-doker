#!/bin/bash
set -euo pipefail

# Entrypoint script for ComfyUI
# Handles custom nodes installation and starts ComfyUI

set -e

echo "=== ComfyUI Entrypoint ==="
echo "Starting ComfyUI container..."

# Set default values for environment variables
COMFYUI_HOST=${COMFYUI_HOST:-0.0.0.0}
COMFYUI_PORT=${COMFYUI_PORT:-8188}
COMFYUI_ARGS=${COMFYUI_ARGS:-"--listen 0.0.0.0 --port 8188"}
COMFYUI_CUSTOM_NODES=${COMFYUI_CUSTOM_NODES:-""}

# Set Python path
export PYTHONPATH=/workspace/ComfyUI:${PYTHONPATH:-}
export PYTHONUNBUFFERED=1
export PYTHONDONTWRITEBYTECODE=1

# Set ComfyUI directories
export COMFYUI_DIR=/workspace/ComfyUI
export COMFYUI_MODELS_DIR=${COMFYUI_MODELS_DIR:-/workspace/ComfyUI/models}
export COMFYUI_OUTPUT_DIR=${COMFYUI_OUTPUT_DIR:-/workspace/ComfyUI/output}
export COMFYUI_INPUT_DIR=${COMFYUI_INPUT_DIR:-/workspace/ComfyUI/input}
export COMFYUI_USER_DIR=${COMFYUI_USER_DIR:-/workspace/ComfyUI/user}
export COMFYUI_CUSTOM_NODES_DIR=${COMFYUI_CUSTOM_NODES_DIR:-/workspace/ComfyUI/custom_nodes}

# Create directories if they don't exist
mkdir -p "${COMFYUI_MODELS_DIR}"
mkdir -p "${COMFYUI_OUTPUT_DIR}"
mkdir -p "${COMFYUI_INPUT_DIR}"
mkdir -p "${COMFYUI_USER_DIR}"
mkdir -p "${COMFYUI_CUSTOM_NODES_DIR}"

# Function to install custom nodes
install_custom_nodes() {
    local custom_nodes="${COMFYUI_CUSTOM_NODES}"
    
    if [ -z "${custom_nodes}" ]; then
        echo "No custom nodes specified (COMFYUI_CUSTOM_NODES is empty)"
        return 0
    fi

    echo "Installing custom nodes from: ${custom_nodes}"
    
    # Split comma-separated URLs
    IFS=',' read -ra NODE_URLS <<< "${custom_nodes}"
    
    for node_url in "${NODE_URLS[@]}"; do
        # Trim whitespace
        node_url=$(echo "${node_url}" | xargs)
        
        if [ -z "${node_url}" ]; then
            continue
        fi
        
        # Extract repo name from URL
        repo_name=$(basename "${node_url}" .git)
        
        echo "Installing custom node: ${repo_name} from ${node_url}"
        
        # Clone or update the repository
        if [ -d "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}" ]; then
            echo "  Repository exists, pulling latest changes..."
            cd "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}"
            git pull || echo "  Warning: Failed to pull latest changes for ${repo_name}"
        else
            echo "  Cloning repository..."
            git clone "${node_url}" "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}" || {
                echo "  Error: Failed to clone ${node_url}"
                continue
            }
        fi
        
        # Install requirements if present
        if [ -f "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}/requirements.txt" ]; then
            echo "  Installing requirements for ${repo_name}..."
            pip install --no-cache-dir -r "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}/requirements.txt" || {
                echo "  Warning: Failed to install requirements for ${repo_name}"
            }
        fi
        
        # Install pyproject.toml if present (modern Python packaging)
        if [ -f "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}/pyproject.toml" ]; then
            echo "  Installing package from pyproject.toml for ${repo_name}..."
            pip install --no-cache-dir -e "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}" || {
                echo "  Warning: Failed to install package for ${repo_name}"
            }
        fi
        
        # Run install.py if present (ComfyUI custom node convention)
        if [ -f "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}/install.py" ]; then
            echo "  Running install.py for ${repo_name}..."
            cd "${COMFYUI_CUSTOM_NODES_DIR}/${repo_name}"
            python install.py || {
                echo "  Warning: install.py failed for ${repo_name}"
            }
        fi
        
        echo "  Completed installation of ${repo_name}"
    done
    
    echo "Custom nodes installation complete"
}

# Function to start ComfyUI
start_comfyui() {
    echo "Starting ComfyUI on ${COMFYUI_HOST}:${COMFYUI_PORT}..."
    echo "Arguments: ${COMFYUI_ARGS}"
    
    cd /workspace/ComfyUI
    
    # Execute ComfyUI with provided arguments
    exec python main.py ${COMFYUI_ARGS}
}

# Main execution
main() {
    echo "=== Starting ComfyUI Container ==="
    echo "Host: ${COMFYUI_HOST}"
    echo "Port: ${COMFYUI_PORT}"
    echo "Custom Nodes: ${COMFYUI_CUSTOM_NODES}"
    echo "Models Dir: ${COMFYUI_MODELS_DIR}"
    echo "Output Dir: ${COMFYUI_OUTPUT_DIR}"
    echo "Custom Nodes Dir: ${COMFYUI_CUSTOM_NODES_DIR}"
    echo "=================================="
    
    # Install custom nodes if specified
    install_custom_nodes
    
    # Start ComfyUI
    start_comfyui
}

# Handle signals gracefully
trap 'echo "Received signal, shutting down..."; exit 0' SIGTERM SIGINT

# Run main function
main "$@"