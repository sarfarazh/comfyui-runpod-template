#!/usr/bin/env bash

set -e  # Exit immediately if any command fails

SNAPSHOT_FILE="/opt/ComfyUI/custom_nodes/ComfyUI-Manager/snapshots/custom_nodes_snapshot.json"
CUSTOM_NODES_DIR="/opt/ComfyUI/custom_nodes"
USER_CONFIG_PATH="/opt/ComfyUI/user"

echo "Installing llama_cpp..."
pip3 install --no-cache-dir llama-cpp-python || { echo "Failed to install llama_cpp"; exit 1; }

echo "runpod-template: Checking snapshot restore..."

# Ensure snapshot file exists
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "runpod-template: No snapshot file found at $SNAPSHOT_FILE. Exiting..."
    exit 0
fi

echo "runpod-template: Restoring custom nodes from snapshot..."
comfy node restore-snapshot "$SNAPSHOT_FILE"

echo "runpod-template: Custom nodes restored successfully."

# Install missing dependencies for each custom node
echo "runpod-template: Installing dependencies for custom nodes..."
find "$CUSTOM_NODES_DIR" -name "requirements.txt" -print0 | while IFS= read -r -d '' req_file; do
    if [ -s "$req_file" ]; then
        echo "Installing dependencies from: $req_file"
        pip3 install --no-cache-dir -r "$req_file"
    else
        echo "Skipping empty requirements file: $req_file"
    fi
done

echo "runpod-template: Fixing dependencies for ComfyUI nodes..."
python3 "$CUSTOM_NODES_DIR/ComfyUI-Manager/cm-cli.py" restore-dependencies

# Ensure user configuration files are copied
if [ -d "/src/user" ]; then
    echo "runpod-template: Copying user settings to $USER_CONFIG_PATH"
    cp -r /src/user/* "$USER_CONFIG_PATH/"
else
    echo "runpod-template: Warning: /src/user not found. Skipping user settings copy."
fi

echo "runpod-template: Custom nodes setup completed successfully."
