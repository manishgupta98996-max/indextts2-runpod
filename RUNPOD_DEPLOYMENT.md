# RunPod Deployment Guide for IndexTTS2

Complete step-by-step guide to deploy IndexTTS2 voice cloning on RunPod serverless infrastructure.

## Prerequisites

1. **RunPod Account**: Sign up at https://www.runpod.io/
2. **Docker Hub Account**: Sign up at https://hub.docker.com/
3. **Docker Desktop**: Install Docker on your machine
4. **Git**: For version control

## Step 1: Create RunPod Account & Get API Key

1. Go to https://www.runpod.io/ and create an account
2. Navigate to **Settings** → **API Keys**
3. Click **Create API Key**
4. Copy and save your API key securely

## Step 2: Build the Docker Image

Navigate to the `runpod_integration` directory:

```bash
cd c:/Users/LENOVO/Desktop/CloneAnyVoice/voice-clone-studio-main/runpod_integration
```

Build the Docker image (this will take 10-15 minutes):

```bash
docker build -t your-dockerhub-username/indextts2-runpod:latest .
```

> **Note**: Replace `your-dockerhub-username` with your actual Docker Hub username

## Step 3: Push Docker Image to Docker Hub

Login to Docker Hub:

```bash
docker login
```

Push the image:

```bash
docker push your-dockerhub-username/indextts2-runpod:latest
```

## Step 4: Create RunPod Serverless Endpoint

1. Log in to RunPod Dashboard
2. Navigate to **Serverless** → **My Endpoints**
3. Click **+ New Endpoint**
4. Configure the endpoint:
   - **Name**: `indextts2-voice-clone`
   - **Docker Image**: `your-dockerhub-username/indextts2-runpod:latest`
   - **GPU Type**: Select **RTX A4000** or **RTX A5000** (recommended for balance of cost/performance)
   - **Container Disk**: `20 GB` (for model weights)
   - **Max Workers**: `3` (adjust based on expected traffic)
   - **Idle Timeout**: `5 seconds` (to reduce costs)
   - **Execution Timeout**: `600 seconds` (10 minutes max per request)

5. Click **Deploy**

## Step 5: Get Your Endpoint URL

After deployment, RunPod provides an endpoint URL:

```
https://api.runpod.ai/v2/<endpoint-id>/runsync
```

Copy this URL - you'll need it for backend configuration.

## Step 6: Update Backend Configuration

### Option A: Using .env file (Recommended)

Create or update `.env` in your `server/` directory:

```bash
# RunPod Configuration
RUNPOD_API_KEY=your-runpod-api-key-here
RUNPOD_ENDPOINT_URL=https://api.runpod.ai/v2/<endpoint-id>/runsync
USE_RUNPOD=true

# Keep Modal config for fallback
MODAL_API_URL=your-modal-url-here
```

### Option B: Direct code update

Edit `server/routes/generate_audio.js` and add RunPod configuration variables.

## Step 7: Test the Deployment

### Test with curl:

```bash
curl -X POST "https://api.runpod.ai/v2/<endpoint-id>/runsync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_RUNPOD_API_KEY" \
  -d '{
    "input": {
      "text": "Hello from IndexTTS2 on RunPod",
      "reference_audio_url": "https://pub-420658e45851415e9854497676646b3f.r2.dev/voices/en/en_voice_01.wav"
    }
  }'
```

Expected response:

```json
{
  "id": "sync-12345",
  "status": "COMPLETED",
  "output": {
    "audio_base64": "UklGRi4...",
    "generation_time": 2.5,
    "audio_size_bytes": 123456
  }
}
```

### Test from your SaaS:

1. Restart your backend server:
   ```bash
   cd server
   npm run dev
   ```

2. Open your application at http://localhost:8080
3. Navigate to the Dashboard
4. Try generating voice with a reference audio
5. Check the server logs for "Using RunPod" confirmation

## Troubleshooting

### Issue: Docker build fails with "No space left on device"

**Solution**: Clean up Docker:
```bash
docker system prune -a
```

### Issue: Model fails to download during build

**Solution**: Download model separately and add to Docker image:
```bash
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='IndexTeam/IndexTTS-2', local_dir='./models')"
```

Then update Dockerfile to COPY the models directory.

### Issue: RunPod returns "Worker not available"

**Solution**: 
- Increase idle timeout in RunPod settings
- Increase max workers
- Check GPU availability in your selected region

### Issue: Slow generation times (>10 seconds)

**Possible causes**:
- Cold start (first request after idle timeout)
- Reference audio file is too large (>10MB)
- Text is very long (>1000 characters)

**Solutions**:
- Increase idle timeout to keep workers warm
- Compress reference audio before sending
- Split long text into chunks

### Issue: High costs

**Solutions**:
- Reduce idle timeout (workers shut down faster)
- Use cheaper GPU like RTX 3090 instead of A5000
- Batch multiple requests if possible
- Consider switching to RunPod Community Cloud (cheaper but less reliable)

## Cost Optimization Tips

1. **Choose the right GPU**:
   - RTX A4000: $0.70/hour (~$0.01 per generation)
   - RTX A5000: $1.00/hour (~$0.014 per generation)
   - RTX 3090: $0.50/hour (~$0.007 per generation)

2. **Optimize idle timeout**:
   - For low traffic: 5 seconds
   - For moderate traffic: 30 seconds
   - For high traffic: 120 seconds

3. **Use async endpoint for batch jobs**:
   - Switch from `/runsync` to `/run` for non-real-time requests
   - Cheaper but requires polling for results

4. **Monitor usage**:
   - Check RunPod dashboard daily
   - Set up billing alerts
   - Track cost per generation

## Security Best Practices

1. **Never commit API keys**:
   - Use `.env` file
   - Add `.env` to `.gitignore`

2. **Restrict API key permissions**:
   - Create separate keys for dev/prod
   - Rotate keys regularly

3. **Implement rate limiting**:
   - Prevent abuse of your endpoint
   - Add middleware in backend

## Next Steps

- [ ] Monitor performance for 1 week
- [ ] Compare costs with Modal
- [ ] Optimize GPU type based on usage patterns
- [ ] Consider hybrid approach (RunPod for high volume, Modal for low latency)

## Support Resources

- RunPod Documentation: https://docs.runpod.io/
- IndexTTS2 GitHub: https://github.com/index-tts/index-tts
- RunPod Discord: https://discord.gg/runpod
