# RunPod ComfyUI Template

A ready-to-use template for running ComfyUI with ComfyUI-Manager on RunPod. This template provides a containerized environment with CUDA support, JupyterLab, and SSH access, perfect for AI image generation and manipulation workflows.

## 🌟 Features

- 🎨 ComfyUI with ComfyUI-Manager pre-installed
- 🚀 CUDA 11.8.0 with cuDNN 8 support
- 📊 JupyterLab interface with pre-configured token
- 🔑 SSH access for remote development
- 🐳 Docker-based deployment
- 📦 Pre-configured custom nodes and extensions
- 🔄 Automatic node restoration from snapshot
- 🗄️ Network volume support for models test 2

## 🏗️ Project Structure

```
runpod-template/
├── Dockerfile              # Container configuration with CUDA, Python, ComfyUI setup
├── start.sh               # Startup script for services
└── README.md             # Documentation
```

## 🔧 Container Configuration

The container includes:
- Ubuntu 22.04 base with CUDA 11.8.0 and cuDNN 8
- Python 3 with pip
- JupyterLab
- ComfyUI and ComfyUI-Manager
- SSH server
- Common dependencies (git, ffmpeg, etc.)

## 🚪 Exposed Ports

- `8188`: ComfyUI interface
- `8888`: JupyterLab interface
- `22`: SSH access

## 🚀 Usage

### Building the Container

```bash
docker build -t comfyui-runpod .
```

### Running Locally

```bash
docker run -p 8188:8188 -p 8888:8888 -p 22:22 comfyui-runpod
```

### Services Access

Once running, the container provides:
1. ComfyUI at `http://<your-ip>:8188`
2. JupyterLab at `http://<your-ip>:8888/lab?token=comfyui`
3. SSH access on port 22

### Models Directory

The container supports two modes for model storage:
- Network Volume: Models are stored in `/runpod-volume/ComfyUI/models`
- Local Storage: Falls back to local models directory if network volume is not detected

## 🔒 Security Notes

- JupyterLab is configured with a default token: "comfyui"
- SSH server is enabled by default
- All services are exposed to network access
- Consider additional security measures for production deployment

## 🛠️ Advanced Configuration

### Custom Nodes Management
- Custom nodes are automatically restored from `custom_nodes_snapshot.json`
- The snapshot includes both git-managed and pip-installed nodes
- Node states (enabled/disabled) are preserved

### Environment Variables
- `PYTHONPATH`: Set to "/opt/ComfyUI"
- `MODEL_PATH`: Set to "/runpod-volume/ComfyUI/models"
- `PIP_ROOT_USER_ACTION`: Set to "ignore"

## 📝 Note

This template is designed for RunPod deployment but can be used in any environment that supports Docker containers with CUDA capabilities. For production use, consider:
- Customizing security settings
- Adjusting model storage configuration
- Modifying custom node selection

---
For more information about RunPod, visit [RunPod Documentation](https://docs.runpod.io/)

