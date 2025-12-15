"""
RunPod Serverless Handler for Coqui XTTS-v2 Voice Cloning
This handler processes incoming requests and generates voice-cloned audio using XTTS-v2.
"""

import runpod
import torch
import os
import tempfile
import requests
import traceback
import base64
from TTS.api import TTS

# Global model instance (loaded once, reused across requests)
model = None

def load_model():
    """Load the XTTS-v2 model once at startup"""
    global model
    
    if model is not None:
        print("Model already loaded, skipping...")
        return
    
    print("🚀 Loading Coqui XTTS-v2 model...")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"📱 Using device: {device}")
    
    try:
        # Load XTTS-v2 model
        model = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)
        print("✅ XTTS-v2 model loaded successfully!")
        
    except Exception as e:
        print(f"❌ Model load error: {e}")
        traceback.print_exc()
        raise


def download_audio(url, timeout=30):
    """Download reference audio from URL"""
    try:
        print(f"📥 Downloading reference audio from: {url}")
        response = requests.get(url, timeout=timeout)
        response.raise_for_status()
        print(f"✅ Downloaded {len(response.content)} bytes")
        return response.content
    except Exception as e:
        raise Exception(f"Failed to download reference audio: {str(e)}")


def handler(job):
    """
    RunPod handler function - processes each inference request
    
    Expected input format:
    {
        "text": "Text to generate speech for",
        "reference_audio_url": "https://example.com/reference.wav",
        "language": "en" (optional, defaults to "en")
    }
    
    Returns:
    {
        "audio_base64": "base64-encoded WAV file",
        "generation_time": 2.5,
        "audio_size_bytes": 123456
    }
    """
    try:
        job_input = job["input"]
        
        # Extract parameters
        text = job_input.get("text")
        reference_audio_url = job_input.get("reference_audio_url")
        language = job_input.get("language", "en")
        
        # Validate inputs
        if not text:
            return {"error": "Missing required parameter: text"}
        
        if not reference_audio_url:
            return {"error": "Missing required parameter: reference_audio_url"}
        
        print(f"🎤 Generating audio for: '{text[:50]}...'")
        
        import time
        start_time = time.time()
        
        # Download reference audio
        reference_audio_bytes = download_audio(reference_audio_url)
        
        # Save reference audio to temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as ref_file:
            ref_file.write(reference_audio_bytes)
            ref_audio_path = ref_file.name
        
        # Create output file path
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as output_file:
            output_path = output_file.name
        
        try:
            # Generate speech with XTTS-v2
            print(f"🎵 Running XTTS-v2 inference (language: {language})...")
            model.tts_to_file(
                text=text,
                speaker_wav=ref_audio_path,
                language=language,
                file_path=output_path
            )
            
            # Read generated audio
            with open(output_path, "rb") as f:
                audio_bytes = f.read()
            
            # Encode to base64 for transmission
            audio_base64 = base64.b64encode(audio_bytes).decode('utf-8')
            
            generation_time = time.time() - start_time
            
            print(f"✅ Generation complete in {generation_time:.2f}s")
            print(f"📊 Generated audio size: {len(audio_bytes)} bytes")
            
            return {
                "audio_base64": audio_base64,
                "generation_time": generation_time,
                "audio_size_bytes": len(audio_bytes),
                "text_length": len(text),
                "language": language
            }
            
        finally:
            # Cleanup temporary files
            try:
                os.unlink(ref_audio_path)
                os.unlink(output_path)
            except Exception as cleanup_error:
                print(f"⚠️ Cleanup warning: {cleanup_error}")
    
    except Exception as e:
        error_msg = f"Error during inference: {str(e)}"
        print(f"❌ {error_msg}")
        traceback.print_exc()
        return {"error": error_msg, "traceback": traceback.format_exc()}


# Load model on startup
print("=" * 50)
print("🚀 Initializing RunPod Serverless Worker")
print("=" * 50)
load_model()

# Start the RunPod serverless worker
print("=" * 50)
print("✅ Worker ready! Waiting for jobs...")
print("=" * 50)

runpod.serverless.start({"handler": handler})
