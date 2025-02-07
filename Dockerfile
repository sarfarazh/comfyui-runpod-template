# Use the official Python base image with CUDA support
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# Disable tracking for ComfyUI if supported
ENV COMFYUI_DISABLE_TRACKING=1

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL="/bin/bash" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    MODEL_PATH="/runpod-volume/ComfyUI/models" \
    COMFYUI_PATH="/opt/ComfyUI" \
    CUSTOM_NODES_PATH="/opt/ComfyUI/custom_nodes" \
    USER_CONFIG_PATH="/opt/ComfyUI/user" \
    RUNPOD_SERVERLESS="true"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    git \
    nano \
    tree \
    wget \
    openssh-server \
    sudo \
    build-essential \
    cmake \
    g++ \
    gcc \
    python3-dev \
    libopenblas-dev \
    liblapack-dev \
    locales \
    bash \
    ffmpeg \
    libsm6 \
    libxext6 \
    jq \
    ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale properly
RUN locale-gen en_US.UTF-8

# Install JupyterLab and ComfyUI dependencies
RUN pip3 install --no-cache-dir --upgrade pip setuptools && \
    pip3 install --no-cache-dir jupyterlab notebook jupyter_http_over_ws jupyterlab_code_formatter jupyterlab_widgets terminado onnxruntime-gpu llama-cpp-python xformers accelerate insightface \
    safetensors "numpy<2" comfy-cli

# Clone ComfyUI repository (pinned version)
RUN git clone --branch v0.3.13 --depth 1 https://github.com/comfyanonymous/ComfyUI.git $COMFYUI_PATH

# Clone ComfyUI-Manager (pinned version) into custom_nodes directory
RUN git clone --branch 3.17.7 --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git $CUSTOM_NODES_PATH/ComfyUI-Manager

# Clone ComfyUI-F5-TTS (Text-to-Speech support)
RUN git clone https://github.com/niknah/ComfyUI-F5-TTS.git $CUSTOM_NODES_PATH/ComfyUI-F5-TTS

# Set working directory to ComfyUI
WORKDIR $COMFYUI_PATH

# Install Python dependencies for ComfyUI
RUN pip3 install --no-cache-dir -r requirements.txt

# Add ComfyUI to Python path
ENV PYTHONPATH="$COMFYUI_PATH" \
    PIP_ROOT_USER_ACTION=ignore

# Ensure execution permissions for prestartup_script.py
RUN chmod +x $CUSTOM_NODES_PATH/ComfyUI-Manager/prestartup_script.py

# Create necessary directories
RUN mkdir -p /runpod-volume/ComfyUI/models \
             $USER_CONFIG_PATH/default/ComfyUI-Manager/snapshots

# Copy snapshot & extra_model_paths.yaml
COPY src/user/default/ComfyUI-Manager/snapshots/custom_nodes_snapshot.json $CUSTOM_NODES_PATH/ComfyUI-Manager/snapshots/custom_nodes_snapshot.json
COPY src/extra_model_paths.yaml $COMFYUI_PATH/extra_model_paths.yaml
COPY src/restore_snapshot.sh /opt/restore_snapshot.sh
COPY src/user/ $USER_CONFIG_PATH/
COPY rp_handler.py /opt/rp_handler.py

# Set execute permissions
RUN chmod +x /opt/restore_snapshot.sh

# Install dependencies for ComfyUI-F5-TTS
WORKDIR $CUSTOM_NODES_PATH/ComfyUI-F5-TTS
RUN git submodule update --init --recursive && \
    pip3 install --no-cache-dir -r requirements.txt && \
    pip3 install --no-cache-dir "huggingface-hub~=0.25.2" "gradio>=4.18,<4.24"

# Restore dependencies using cm-cli.py
WORKDIR $COMFYUI_PATH
RUN pip3 install --no-cache-dir toml && \
    python3 $CUSTOM_NODES_PATH/ComfyUI-Manager/cm-cli.py restore-dependencies

# Expose necessary ports
EXPOSE 8188 8888 22

# Copy and set execute permissions for scripts
COPY start.sh /opt/start.sh
RUN chmod 755 /opt/start.sh /opt/rp_handler.py

# Set the entrypoint
ENTRYPOINT ["/opt/start.sh"]
