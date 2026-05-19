# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base
#FROM runpod/worker-comfyui:5.8.4-base-cuda12.8.1

ENV COMFY_ARGS="--use-sage-attention"

# Force correct PyTorch for Blackwell BEFORE any node installs
#RUN pip install \
#    torch==2.8.0 torchvision torchaudio \
#    --index-url https://download.pytorch.org/whl/cu128 \
#    --upgrade
#RUN pip install xformers sageattention

# Upgrade PyTorch to CUDA 13.0 (stable as of torch 2.12)
# Must happen before SageAttention or any node that pulls torch deps
RUN pip install --upgrade \
    torch==2.12.0 torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu130

# SageAttention must be installed AFTER the correct torch is in place
# so it compiles its CUDA kernels against cu130
RUN pip install sageattention==2.2.0 --no-build-isolation




# build-time tokens for gated downloads — never baked into final image.
# pass via: docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""


RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
 && rm -rf /var/lib/apt/lists/*

#RUN git clone https://github.com/Lightricks/ComfyUI-LTXVideo \
#    /comfyui/custom_nodes/ComfyUI-LTXVideo && \
#    cd /comfyui/custom_nodes/ComfyUI-LTXVideo && \
#    pip install --no-cache-dir -r requirements.txt

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

#RUN git clone https://github.com/ClownsharkBatwing/RES4LYF /comfyui/custom_nodes/RES4LYF && \
#    cd /comfyui/custom_nodes/RES4LYF && \
#    pip install --no-cache-dir -r requirements.txt
#RUN mkdir -p /comfyui/models/latent_upscale_models && \
#    wget -q -O /comfyui/models/latent_upscale_models/ltx-2.3-spatial-upscaler-x2-1.0.safetensors \
#    "https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.0.safetensors"


#RUN pip install \
#    torch==2.8.0 torchvision torchaudio \
#    --index-url https://download.pytorch.org/whl/cu128 \
#    --upgrade

    # point comfyui at the network volume for all model types
# models are stored on the network volume at /runpod-volume/models/
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml