# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.8.4-base
#FROM runpod/worker-comfyui:5.8.4-base-cuda12.8.1

# ENV COMFY_ARGS="--use-sage-attention"

# Force correct PyTorch for Blackwell BEFORE any node installs
#RUN pip install \
#    torch==2.8.0 torchvision torchaudio \
#    --index-url https://download.pytorch.org/whl/cu128 \
#    --upgrade
#RUN pip install xformers sageattention

# Upgrade PyTorch to CUDA 13.0 (stable as of torch 2.12)
# Must happen before SageAttention or any node that pulls torch deps
#RUN pip install --upgrade \
#    torch==2.12.0 torchvision torchaudio \
#    --index-url https://download.pytorch.org/whl/cu130

# SageAttention must be installed AFTER the correct torch is in place
# so it compiles its CUDA kernels against cu130
# RUN pip install sageattention




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
RUN for i in 1 2 3; do \
      timeout 120 git clone https://github.com/1038lab/ComfyUI-QwenVL /comfyui/custom_nodes/ComfyUI-QwenVL && break; \
      rm -rf /comfyui/custom_nodes/ComfyUI-QwenVL; \
      [ $i -lt 3 ] && sleep 15 || exit 1; \
    done && \
    cd /comfyui/custom_nodes/ComfyUI-QwenVL && \
    for i in 1 2 3; do \
      timeout 300 pip install --no-cache-dir --timeout 60 -r requirements.txt && break; \
      [ $i -lt 3 ] && sleep 15 || exit 1; \
    done

RUN for i in 1 2 3; do \
      timeout 120 git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && break; \
      rm -rf /comfyui/custom_nodes/ComfyUI-KJNodes; \
      [ $i -lt 3 ] && sleep 15 || exit 1; \
    done && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && \
    (git checkout 33e2d3ac90e913bdec561361e1ebac7599a3de64 2>/dev/null || \
    (timeout 60 git fetch origin 33e2d3ac90e913bdec561361e1ebac7599a3de64 --depth=1 && \
    git checkout 33e2d3ac90e913bdec561361e1ebac7599a3de64) || \
    echo "WARN: commit unreachable, falling back to HEAD") && \
    for i in 1 2 3; do \
      timeout 300 pip install --no-cache-dir --timeout 60 -r requirements.txt && break; \
      [ $i -lt 3 ] && sleep 15 || exit 1; \
    done

RUN for i in 1 2 3; do \
      timeout 120 comfy node install --exit-on-fail was-ns@3.0.1 && break; \
      [ $i -lt 3 ] && sleep 15 || \
      (echo "WARN: was-ns@3.0.1 unavailable, falling back to latest" >&2 && \
       for j in 1 2 3; do \
         timeout 120 comfy node install --exit-on-fail was-ns && break; \
         [ $j -lt 3 ] && sleep 15 || exit 1; \
       done); \
    done

RUN for i in 1 2 3; do \
      timeout 120 git clone https://github.com/ClownsharkBatwing/RES4LYF /comfyui/custom_nodes/RES4LYF && break; \
      rm -rf /comfyui/custom_nodes/RES4LYF; \
      [ $i -lt 3 ] && sleep 15 || exit 1; \
    done && \
    cd /comfyui/custom_nodes/RES4LYF && \
    for i in 1 2 3; do \
      timeout 300 pip install --no-cache-dir --timeout 60 -r requirements.txt && break; \
      [ $i -lt 3 ] && sleep 15 || exit 1; \
    done

#RUN mkdir -p /comfyui/models/latent_upscale_models && \
#    wget -q -O /comfyui/models/latent_upscale_models/ltx-2.3-spatial-upscaler-x2-1.0.safetensors \
#    "https://huggingface.co/Lightricks/LTX-2.3/resolve/main/ltx-2.3-spatial-upscaler-x2-1.0.safetensors"

#COPY --from=localmodels checkpoints/ltx-2.3-22b-dev.safetensors /comfyui/models/checkpoints/ltx-2.3-22b-dev.safetensors


#RUN mkdir -p /comfyui/models/text_encoders && \
#    wget -q -O /comfyui/models/text_encoders/gemma_3_12B_it_fp8_e4m3fn.safetensors \
#         "https://huggingface.co/GitMylo/LTX-2-comfy_gemma_fp8_e4m3fn/resolve/main/gemma_3_12B_it_fp8_e4m3fn.safetensors"


#RUN pip install \
#    torch==2.8.0 torchvision torchaudio \
#    --index-url https://download.pytorch.org/whl/cu128 \
#    --upgrade

    # point comfyui at the network volume for all model types
# models are stored on the network volume at /runpod-volume/models/
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml