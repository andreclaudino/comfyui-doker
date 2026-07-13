# OpenWebUI MCP Integration Guide

## Helm Chart Auto-Configuration

When OpenWebUI is deployed via the Helm chart (`openwebui.enabled: true`), the MCP connection is **automatically configured** using the internal cluster service URL. No manual configuration is needed.

The chart generates the `MCP_SERVERS` environment variable from your Helm values:

```yaml
# In your values.yaml
mcp:
  token: "your-secret-token"
openwebui:
  enabled: true
```

This automatically sets:
```
MCP_SERVERS={"comfyui":{"url":"http://<release>-mcp:8000/mcp","headers":{"Authorization":"Bearer <token>"},"enabled":true,"timeout":300}}
```

> **Note:** If `mcp.token` is empty, the Authorization header will be empty. Set a token for production deployments.

### Subpath Ingress

When deploying behind nginx ingress with subpaths, the internal MCP URL remains the same (cluster-internal DNS). The `MCP_SERVERS` env var uses the internal service URL, not the ingress URL, for better performance.

## MCP Server Configuration (Manual Setup)

### Server URL
Replace `<your-mcp-ingress-host>` with your actual MCP ingress hostname.

If using Helm, this is the value of `mcp.ingress.host` you set during installation:

```bash
# Example: if you installed with:
#   --set mcp.ingress.host=mcp.comfyui.example.com
# Then the URL would be:
#   http://mcp.comfyui.example.com/mcp
```

```
<your-mcp-ingress-host>/mcp
```

### Authentication
- **Type**: Bearer Token
- **Token Source**: `MCP_TOKEN` from `comfyui-mcp-secret` in `comfyui` namespace

### Retrieve Token
```bash
kubectl get secret comfyui-mcp-secret -n comfyui -o jsonpath='{.data.MCP_TOKEN}' | base64 -d
```

## OpenWebUI Configuration

### Via Admin Panel
1. Open OpenWebUI → Settings → Connections → MCP Servers
2. Click "Add Server"
3. Configure:
   - **Name**: `comfyui`
   - **URL**: `<your-mcp-ingress-host>/mcp`
   - **Headers**: `Authorization: Bearer <TOKEN>`
   - **Enabled**: ✓
   - **Timeout**: `300`

### Via Config File (config.json)
```json
{
  "mcp": {
    "servers": {
      "comfyui": {
        "url": "<your-mcp-ingress-host>/mcp",
        "headers": {
          "Authorization": "Bearer YOUR_MCP_TOKEN_HERE"
        },
        "enabled": true,
        "timeout": 300
      }
    }
  }
}
```

### Via Docker Environment
```bash
docker run -d \
  -e MCP_SERVERS='{"comfyui":{"url":"<your-mcp-ingress-host>/mcp","headers":{"Authorization":"Bearer YOUR_MCP_TOKEN_HERE"},"enabled":true,"timeout":300}}' \
  -p 3000:8080 \
  ghcr.io/open-webui/open-webui:main
```

### Via Kubernetes ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: openwebui-config
  namespace: openwebui
data:
  config.json: |
    {
      "mcp": {
        "servers": {
          "comfyui": {
            "url": "<your-mcp-ingress-host>/mcp",
            "headers": {
              "Authorization": "Bearer YOUR_MCP_TOKEN_HERE"
            },
            "enabled": true,
            "timeout": 300
          }
        }
      }
    }
```

## Available MCP Tools

### generate_image
Generate images using ComfyUI workflows.

**Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| prompt | string | ✓ | - | Text prompt |
| negative_prompt | string | - | "" | Negative prompt |
| width | integer | - | 1024 | Image width |
| height | integer | - | 1024 | Image height |
| steps | integer | - | 20 | Sampling steps |
| cfg | number | - | 7.0 | CFG scale |
| sampler | string | - | "euler" | Sampler name |
| scheduler | string | - | "normal" | Scheduler name |
| seed | integer | - | -1 | Random seed (-1 = random) |
| model | string | - | - | Checkpoint name |
| vae | string | - | - | VAE name |
| clip_skip | integer | - | 1 | CLIP skip layers |
| batch_size | integer | - | 1 | Number of images |

**Example:**
```json
{
  "tool": "generate_image",
  "arguments": {
    "prompt": "A beautiful sunset over mountains, photorealistic, 8k",
    "negative_prompt": "blurry, low quality, distorted",
    "width": 1024,
    "height": 1024,
    "steps": 25,
    "cfg": 7.5,
    "sampler": "dpmpp_2m",
    "scheduler": "karras",
    "seed": -1
  }
}
```

### queue_prompt
Queue a custom ComfyUI workflow.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| workflow | object | ✓ | ComfyUI workflow JSON |
| client_id | string | - | Client ID for tracking |

**Example (SDXL):**
```json
{
  "tool": "queue_prompt",
  "arguments": {
    "workflow": {
      "3": {
        "inputs": {
          "seed": 12345,
          "steps": 20,
          "cfg": 7,
          "sampler_name": "dpmpp_2m",
          "scheduler": "karras",
          "denoise": 1,
          "model": ["4", 0],
          "positive": ["6", 0],
          "negative": ["7", 0],
          "latent_image": ["5", 0]
        },
        "class_type": "KSampler"
      },
      "4": {
        "inputs": {
          "ckpt_name": "sd_xl_base_1.0.safetensors"
        },
        "class_type": "CheckpointLoaderSimple"
      },
      "5": {
        "inputs": {
          "width": 1024,
          "height": 1024,
          "batch_size": 1
        },
        "class_type": "EmptyLatentImage"
      },
      "6": {
        "inputs": {
          "text": "A beautiful landscape",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "7": {
        "inputs": {
          "text": "ugly, blurry, low quality",
          "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
      },
      "8": {
        "inputs": {
          "samples": ["3", 0],
          "vae": ["4", 2]
        },
        "class_type": "VAEDecode"
      },
      "9": {
        "inputs": {
          "filename_prefix": "ComfyUI",
          "images": ["8", 0]
        },
        "class_type": "SaveImage"
      }
    }
  }
}
```

### get_queue_status
Get current queue status.

**Parameters:** None

**Response:**
```json
{
  "queue_running": [],
  "queue_pending": []
}
```

### get_history
Get generation history.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| prompt_id | string | - | Specific prompt ID |

### upload_image
Upload image to ComfyUI input directory.

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| image | string | ✓ | Base64 encoded image |
| filename | string | - | Custom filename |

**Example:**
```json
{
  "tool": "upload_image",
  "arguments": {
    "image": "iVBORw0KGgoAAAANSUhEUgAA...",
    "filename": "input_image.png"
  }
}
```

## Example Workflows

### Text-to-Image (SDXL)
```json
{
  "tool": "generate_image",
  "arguments": {
    "prompt": "Portrait of a cyberpunk character, neon lights, highly detailed",
    "model": "juggernautXL_v9Rdphoto2Lightning.safetensors",
    "width": 1024,
    "height": 1536,
    "steps": 30,
    "cfg": 6.5,
    "sampler": "dpmpp_2m",
    "scheduler": "karras"
  }
}
```

### Image-to-Image
```json
{
  "tool": "upload_image",
  "arguments": {
    "image": "BASE64_IMAGE_DATA",
    "filename": "init_image.png"
  }
}
```
Then use in custom workflow with `LoadImage` node referencing `init_image.png`.

### ControlNet (Canny)
```json
{
  "tool": "queue_prompt",
  "arguments": {
    "workflow": {
      "1": {
        "inputs": {
          "image": "init_image.png"
        },
        "class_type": "LoadImage"
      },
      "2": {
        "inputs": {
          "preprocessor": "canny",
          "image": ["1", 0],
          "resolution": 512
        },
        "class_type": "ControlNetPreprocessor"
      },
      "3": {
        "inputs": {
          "control_net_name": "control_v11p_sd15_canny.pth",
          "image": ["2", 0]
        },
        "class_type": "ControlNetLoader"
      },
      "4": {
        "inputs": {
          "strength": 1.0,
          "control_net": ["3", 0],
          "image": ["2", 0],
          "positive": ["5", 0],
          "negative": ["6", 0]
        },
        "class_type": "ControlNetApply"
      }
    }
  }
}
```

## Troubleshooting

### Connection Refused
- Verify MCP pod is running: `kubectl get pods -n comfyui -l app=comfyui-mcp`
- Check service: `kubectl get svc -n comfyui comfyui-mcp`
- Verify ingress: `kubectl get ingress -n comfyui comfyui-mcp`

### Authentication Failed
- Verify token matches: `kubectl get secret comfyui-mcp-secret -n comfyui -o jsonpath='{.data.MCP_TOKEN}' | base64 -d`
- Check MCP pod logs: `kubectl logs -n comfyui -l app=comfyui-mcp`

### Timeout Errors
- Increase timeout in OpenWebUI config (default 300s)
- Check ComfyUI queue: `kubectl exec -n comfyui deploy/comfyui -- curl localhost:8188/queue`

### Model Not Found
- Ensure model exists in PVC at `/comfyui/models/checkpoints/`
- List models: `kubectl exec -n comfyui deploy/comfyui -- ls /comfyui/models/checkpoints/`