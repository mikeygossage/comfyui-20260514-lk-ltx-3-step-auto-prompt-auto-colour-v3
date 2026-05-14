# clean base image containing only comfyui, comfy-cli and comfyui-manager
# FROM runpod/worker-comfyui:5.8.4-base
FROM runpod/worker-comfyui:5.4.1-base-cuda12.8.1

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""


RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
 && rm -rf /var/lib/apt/lists/*



# install custom nodes into comfyui
RUN git clone https://github.com/1038lab/ComfyUI-QwenVL /comfyui/custom_nodes/ComfyUI-QwenVL && \
    cd /comfyui/custom_nodes/ComfyUI-QwenVL && \
    pip install --no-cache-dir -r requirements.txt

RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && \
    (git checkout 33e2d3ac90e913bdec561361e1ebac7599a3de64 2>/dev/null || \
    (git fetch origin 33e2d3ac90e913bdec561361e1ebac7599a3de64 --depth=1 && \
    git checkout 33e2d3ac90e913bdec561361e1ebac7599a3de64) || \
    echo "WARN: commit unreachable, falling back to HEAD") && \
    pip install --no-cache-dir -r requirements.txt

RUN comfy node install --exit-on-fail was-ns@3.0.1 || \
    (echo "WARN: was-ns@3.0.1 unavailable, falling back to latest" >&2 && \
    comfy node install --exit-on-fail was-ns)

# point comfyui at the network volume for all model types
# models are stored on the network volume at /runpod-volume/models/
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml