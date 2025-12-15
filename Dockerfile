# RunPod Dockerfile for IndexTTS2 Voice Cloning
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

# Set working directory
WORKDIR /app

# Install system dependencies (non-interactive to avoid tzdata prompt)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    libsndfile1 \
    ffmpeg \
    build-essential \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Initialize git-lfs
RUN git lfs install

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install IndexTTS2 from GitHub
RUN pip install --no-cache-dir git+https://github.com/index-tts/index-tts.git

# Create model cache directory
RUN mkdir -p /model_cache /checkpoints

# Download IndexTTS2 model weights from Hugging Face
# This happens at build time to avoid cold starts
RUN python -c "from huggingface_hub import snapshot_download; \
    snapshot_download( \
    repo_id='IndexTeam/IndexTTS-2', \
    cache_dir='/model_cache', \
    local_dir='/checkpoints', \
    local_dir_use_symlinks=False \
    )"

# Copy handler code
COPY handler.py .

# Expose port for health checks (RunPod expects this)
EXPOSE 8000

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV MODEL_DIR=/model_cache
ENV CHECKPOINT_DIR=/checkpoints

# Start the RunPod handler
CMD ["python", "-u", "handler.py"]
