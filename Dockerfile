# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base

# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# install custom nodes into comfyui
RUN comfy node install --exit-on-fail comfyui-qwenvl@2.1.1 --mode remote || (echo "WARN: comfyui-qwenvl@2.1.1 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail comfyui-qwenvl --mode remote)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && cd /comfyui/custom_nodes/ComfyUI-KJNodes && (git checkout 33e2d3ac90e913bdec561361e1ebac7599a3de64 2>/dev/null || (git fetch origin 33e2d3ac90e913bdec561361e1ebac7599a3de64 --depth=1 && git checkout 33e2d3ac90e913bdec561361e1ebac7599a3de64) || echo "WARN: commit 33e2d3ac90e913bdec561361e1ebac7599a3de64 unreachable in https://github.com/kijai/ComfyUI-KJNodes, falling back to default branch HEAD")
RUN comfy node install --exit-on-fail was-ns@3.0.1 || (echo "WARN: was-ns@3.0.1 unavailable in registry, falling back to latest" >&2 && comfy node install --exit-on-fail was-ns)

# point comfyui at the network volume for all model types
# models are stored on the network volume at /runpod-volume/models/
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml