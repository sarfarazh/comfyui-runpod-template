#!/bin/bash

echo "runpod-template: Starting SSH server..."
service ssh start

# Ensure network volume models directory is mounted correctly
if [ -d "/runpod-volume/ComfyUI/models" ]; then
    echo "runpod-template: Network volume detected. Using models from /runpod-volume/ComfyUI/models"
    ln -sf /runpod-volume/ComfyUI/models /opt/ComfyUI/models
else
    echo "runpod-template: Warning: Network volume for models not detected. Using local models directory."
fi

# Ensure extra_model_paths.yaml is copied to ComfyUI
if [ ! -f "/opt/ComfyUI/extra_model_paths.yaml" ]; then
    echo "runpod-template: Copying extra_model_paths.yaml to ComfyUI directory..."
    cp /src/extra_model_paths.yaml /opt/ComfyUI/extra_model_paths.yaml
fi

# Ensure correct permissions
chown -R root:root /opt/ComfyUI
chmod -R 755 /opt/ComfyUI

# Restore Custom Nodes from Snapshot before starting ComfyUI
echo "runpod-template: Running snapshot restoration..."
/bin/bash /opt/restore_snapshot.sh

# Start JupyterLab (optional)
echo "runpod-template: Starting JupyterLab..."
nohup jupyter lab --NotebookApp.token="comfyui" \
    --allow-root --no-browser --port=8888 --ip=0.0.0.0 \
    --NotebookApp.disable_check_xsrf=True \
    --NotebookApp.allow_origin='*' \
    --NotebookApp.base_url="/" \
    --notebook-dir=/opt/ComfyUI \
    --ServerApp.terminado_settings='{"shell_command":["/bin/bash"], "cwd": "/opt/ComfyUI"}' &

# Wait for JupyterLab to fully start
echo "runpod-template: Waiting for JupyterLab..."
sleep 10

# Start ComfyUI
echo "runpod-template: Starting ComfyUI..."
nohup python3 /opt/ComfyUI/main.py --listen --port 8188 &

# Keep container running
tail -f /dev/null
