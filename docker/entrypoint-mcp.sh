#!/bin/bash
set -euo pipefail

echo "=== ComfyUI-MCP Entrypoint ==="

MCP_HOST=${MCP_HOST:-0.0.0.0}
MCP_PORT=${MCP_PORT:-8000}
COMFYUI_URL=${COMFYUI_URL:-http://comfyui:8188}
MCP_TOKEN=${MCP_TOKEN:-""}
LOG_LEVEL=${LOG_LEVEL:-info}

echo "MCP Host: ${MCP_HOST}"
echo "MCP Port: ${MCP_PORT}"
echo "ComfyUI URL: ${COMFYUI_URL}"
echo "Log Level: ${LOG_LEVEL}"

export MCP_HOST MCP_PORT COMFYUI_URL MCP_TOKEN LOG_LEVEL

exec python -m comfyui_mcp --host "${MCP_HOST}" --port "${MCP_PORT}"
