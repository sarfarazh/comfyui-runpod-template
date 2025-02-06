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

# Read JSON and clone missing repositories
jq -r '.git_custom_nodes | to_entries[] | select(.value.disabled == false) | .key' "$SNAPSHOT_FILE" | while read -r repo; do
    repo_name=$(basename "$repo" .git)
    target_dir="$CUSTOM_NODES_DIR/$repo_name"

    if [ -d "$target_dir" ]; then
        echo "runpod-template: $repo_name already exists. Skipping..."
    else
        echo "runpod-template: Cloning $repo into $target_dir..."
        # Check if it's the UltimateSDUpscale repository
        if [[ "$repo" == *"ComfyUI_UltimateSDUpscale"* ]]; then
            git clone --recursive "$repo" "$target_dir" || { echo "Failed to clone $repo"; exit 1; }
        else
            git clone "$repo" "$target_dir" || { echo "Failed to clone $repo"; exit 1; }
        fi
    fi
done

echo "runpod-template: Custom nodes cloned successfully"

# Install missing dependencies for each custom node
find "$CUSTOM_NODES_DIR" -name "requirements.txt" -print0 | while IFS= read -r -d '' req_file; do
    if [ -s "$req_file" ]; then
        echo "Installing dependencies from: $req_file"
        pip3 install --no-cache-dir -r "$req_file"
    else
        echo "Skipping empty requirements file: $req_file"
    fi
done


echo "runpod-template: Installed dependencies for custom nodes."

# Ensure user configuration files are copied
if [ -d "/src/user" ]; then
    echo "runpod-template: Copying user settings to $USER_CONFIG_PATH"
    cp -r /src/user/* "$USER_CONFIG_PATH/"
else
    echo "runpod-template: Warning: /src/user not found. Skipping user settings copy."
fi

echo "runpod-template: Custom nodes setup completed successfully."
