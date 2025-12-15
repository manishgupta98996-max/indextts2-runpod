# RunPod Dockerfile for Coqui XTTS Voice Cloning
# Using XTTS-v2 which installs easily via pip and provides high-quality voice cloning

FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

WORKDIR /app

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libsndfile1 \
    ffmpeg \
    build-essential \
    wget \
    curl \
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and handler
COPY requirements.txt .
COPY handler.py .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Coqui TTS (includes XTTS-v2)
RUN pip install --no-cache-dir TTS

# Create model cache directories
RUN mkdir -p /model_cache

# Pre-download XTTS-v2 model to avoid cold start delays
RUN python -c "from TTS.api import TTS; TTS('tts_models/multilingual/multi-dataset/xtts_v2')"

# Environment variables
ENV HF_HOME=/model_cache
ENV COQUI_TOS_AGREED=1

# Expose port for health checks
EXPOSE 8000

# Start the RunPod handler
CMD ["python", "-u", "handler.py"]
