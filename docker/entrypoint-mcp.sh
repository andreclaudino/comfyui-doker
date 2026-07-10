#!/bin/bash
set -euo pipefail

echo "=== ComfyUI-MCP Entrypoint ==="

MCP_HOST=${MCP_HOST:-0.0.0.0}
MCP_PORT=${MCP_PORT:-8000}
COMFYUI_URL=${COMFYUI_URL:-http://comfyui:8188}
MCP_TOKEN=${MCP_TOKEN:-""}
LOG_LEVEL=${LOG_LEVEL:-info}

export MCP_HOST MCP_PORT COMFYUI_URL MCP_TOKEN LOG_LEVEL

echo "Starting ComfyUI MCP server on ${MCP_HOST}:${MCP_PORT}"
echo "ComfyUI URL: ${COMFYUI_URL}"

exec python /app/mcp_server.py
