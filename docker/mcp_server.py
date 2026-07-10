import json
import logging
import os
from typing import Any

import httpx
from mcp.server.fastmcp import FastMCP
from starlette.responses import Response

logger = logging.getLogger("comfyui-mcp")

COMFYUI_URL = os.environ.get("COMFYUI_URL", "http://comfyui:8188")
MCP_TOKEN = os.environ.get("MCP_TOKEN", "")
LOG_LEVEL = os.environ.get("LOG_LEVEL", "info").upper()

logging.basicConfig(
    level=getattr(logging, LOG_LEVEL, logging.INFO),
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)

MCP_HOST = os.environ.get("MCP_HOST", "0.0.0.0")
MCP_PORT = int(os.environ.get("MCP_PORT", "8000"))

mcp = FastMCP("comfyui", host=MCP_HOST, port=MCP_PORT, json_response=True)


@mcp.custom_route("/health", methods=["GET"])
async def health_check(request):
    return Response(json.dumps({"status": "ok"}), media_type="application/json")


def get_headers() -> dict[str, str]:
    headers = {"Content-Type": "application/json"}
    if MCP_TOKEN:
        headers["Authorization"] = f"Bearer {MCP_TOKEN}"
    return headers


async def comfyui_request(
    method: str, endpoint: str, data: dict[str, Any] | None = None
) -> dict[str, Any]:
    url = f"{COMFYUI_URL}/{endpoint.lstrip('/')}"
    async with httpx.AsyncClient(timeout=300.0) as client:
        if method == "GET":
            resp = await client.get(url, headers=get_headers())
        else:
            resp = await client.post(url, json=data, headers=get_headers())
        resp.raise_for_status()
        return resp.json()


@mcp.tool()
async def generate_image(
    prompt: str,
    negative_prompt: str = "",
    width: int = 1024,
    height: int = 1024,
    steps: int = 20,
    cfg_scale: float = 7.0,
    seed: int = -1,
    model: str = "",
) -> str:
    workflow = {
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed if seed >= 0 else 0,
                "steps": steps,
                "cfg": cfg_scale,
                "sampler_name": "euler",
                "scheduler": "normal",
                "denoise": 1.0,
                "model": ["4", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["5", 0],
            },
        },
        "4": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {"ckpt_name": model if model else "sd_xl_base_1.0.safetensors"},
        },
        "5": {
            "class_type": "EmptyLatentImage",
            "inputs": {"width": width, "height": height, "batch_size": 1},
        },
        "6": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": prompt, "clip": ["4", 1]},
        },
        "7": {
            "class_type": "CLIPTextEncode",
            "inputs": {"text": negative_prompt, "clip": ["4", 1]},
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["3", 0], "vae": ["4", 2]},
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {"filename_prefix": "comfyui", "images": ["8", 0]},
        },
    }
    result = await comfyui_request("POST", "prompt", {"prompt": workflow})
    return json.dumps(result, indent=2)


@mcp.tool()
async def queue_prompt(workflow_json: str) -> str:
    workflow = json.loads(workflow_json)
    result = await comfyui_request(
        "POST", "prompt", {"prompt": workflow}
    )
    return json.dumps(result, indent=2)


@mcp.tool()
async def get_queue_status() -> str:
    result = await comfyui_request("GET", "queue")
    return json.dumps(result, indent=2)


@mcp.tool()
async def get_history(max_items: int = 20) -> str:
    result = await comfyui_request("GET", "history")
    items = dict(list(result.items())[:max_items])
    return json.dumps(items, indent=2)


@mcp.tool()
async def upload_image(image_data: str, filename: str) -> str:
    import base64

    image_bytes = base64.b64decode(image_data)
    files = {"image": (filename, image_bytes, "image/png")}
    async with httpx.AsyncClient(timeout=300.0) as client:
        resp = await client.post(
            f"{COMFYUI_URL}/upload/image", files=files
        )
        resp.raise_for_status()
        return json.dumps(resp.json(), indent=2)


@mcp.resource("comfyui://queue")
async def queue_info() -> str:
    return await get_queue_status()


@mcp.resource("comfyui://history")
async def history_info() -> str:
    return await get_history()


if __name__ == "__main__":
    logger.info("Starting ComfyUI MCP server")
    mcp.run(transport="streamable-http")
