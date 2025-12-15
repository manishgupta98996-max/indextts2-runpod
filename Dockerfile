# RunPod Dockerfile for IndexTTS2 Voice Cloning
# Uses uv package manager as recommended by IndexTTS2 documentation

FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

WORKDIR /app

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    python3.10-venv \
    git \
    git-lfs \
    libsndfile1 \
    ffmpeg \
    espeak-ng \
    build-essential \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Make python3.10 the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# Upgrade pip and install uv
RUN pip install --upgrade pip
RUN pip install uv

# Initialize git-lfs
RUN git lfs install

# Clone IndexTTS2 repository with git-lfs
RUN git clone https://github.com/index-tts/index-tts.git /app/index-tts

# Change to index-tts directory
WORKDIR /app/index-tts

# Pull LFS files
RUN git lfs pull

# Create virtual environment and install dependencies using uv
RUN uv venv .venv --python 3.10
ENV PATH="/app/index-tts/.venv/bin:$PATH"

# Install dependencies with uv
RUN uv pip install -e .

# Install runpod in the venv
RUN uv pip install runpod requests

# Create model cache directories
RUN mkdir -p /model_cache /checkpoints

# Download IndexTTS2 model from Hugging Face
RUN python -c "from huggingface_hub import snapshot_download; \
    snapshot_download( \
    repo_id='IndexTeam/IndexTTS-2', \
    cache_dir='/model_cache', \
    local_dir='/checkpoints', \
    local_dir_use_symlinks=False \
    )"

# Copy handler
WORKDIR /app
COPY handler.py .

# Environment variables
ENV MODEL_DIR=/model_cache
ENV CHECKPOINT_DIR=/checkpoints

# Expose port
EXPOSE 8000

# Start handler
CMD ["python", "-u", "handler.py"]
