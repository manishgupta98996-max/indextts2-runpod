# RunPod Dockerfile for IndexTTS2 Voice Cloning
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

# Set working directory
WORKDIR /app

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    libsndfile1 \
    ffmpeg \
    build-essential \
    wget \
    curl \
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

# Initialize git-lfs
RUN git lfs install

# Install uv (fast Python package manager)
RUN pip install --no-cache-dir uv

# Clone IndexTTS2 repository
RUN git clone https://github.com/index-tts/index-tts.git /app/indextts

# Install IndexTTS2 dependencies using uv
WORKDIR /app/indextts
RUN uv pip install --system -e .

# Create model cache directories
RUN mkdir -p /model_cache /checkpoints

# Download IndexTTS2 model weights from Hugging Face at build time
RUN python -c "from huggingface_hub import snapshot_download; \
    snapshot_download( \
    repo_id='IndexTeam/IndexTTS-2', \
    cache_dir='/model_cache', \
    local_dir='/checkpoints', \
    local_dir_use_symlinks=False \
    )"

# Copy handler code
WORKDIR /app
COPY handler.py .

# Environment variables
ENV MODEL_DIR=/model_cache
ENV CHECKPOINT_DIR=/checkpoints

# Expose port for health checks
EXPOSE 8000

# Start the RunPod handler
CMD ["python", "-u", "handler.py"]
