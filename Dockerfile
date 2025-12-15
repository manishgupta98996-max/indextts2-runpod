# RunPod Dockerfile for Coqui XTTS Voice Cloning
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

WORKDIR /app

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV PYTHONUNBUFFERED=1
ENV COQUI_TOS_AGREED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libsndfile1 \
    ffmpeg \
    espeak-ng \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Install core dependencies first (without version pinning for compatibility)
RUN pip install --no-cache-dir runpod requests soundfile

# Install Coqui TTS
RUN pip install --no-cache-dir TTS

# Copy handler
COPY handler.py .

# Pre-download XTTS-v2 model
RUN python -c "from TTS.api import TTS; TTS('tts_models/multilingual/multi-dataset/xtts_v2')"

# Expose port
EXPOSE 8000

# Start handler
CMD ["python", "-u", "handler.py"]
