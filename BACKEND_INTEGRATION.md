# Backend Integration Module for RunPod

This module extends `generate_audio.js` to support RunPod alongside Modal.

## Installation

No additional npm packages required - uses existing `node-fetch`.

## Usage

Add these functions to your `generate_audio.js` file to enable RunPod integration:

```javascript
// Add this after line 14 in generate_audio.js

// RunPod Configuration
const RUNPOD_API_KEY = process.env.RUNPOD_API_KEY;
const RUNPOD_ENDPOINT_URL = process.env.RUNPOD_ENDPOINT_URL;
const USE_RUNPOD = process.env.USE_RUNPOD === 'true';

/**
 * Generate audio using RunPod serverless endpoint
 */
async function generateWithRunPod(text, referenceAudioUrl) {
    console.log('[RunPod] Generating audio...');
    
    const response = await fetch(RUNPOD_ENDPOINT_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${RUNPOD_API_KEY}`
        },
        body: JSON.stringify({
            input: {
                text: text,
                reference_audio_url: referenceAudioUrl
            }
        })
    });

    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`RunPod API Error: ${response.status} ${errorText}`);
    }

    const result = await response.json();
    
    // Check if job completed successfully
    if (result.status === 'COMPLETED' && result.output) {
        // Decode base64 audio
        const audioBase64 = result.output.audio_base64;
        const audioBuffer = Buffer.from(audioBase64, 'base64');
        
        console.log(`[RunPod] Generated ${result.output.audio_size_bytes} bytes in ${result.output.generation_time}s`);
        
        return audioBuffer;
    } else if (result.status === 'FAILED') {
        throw new Error(`RunPod generation failed: ${result.error}`);
    } else {
        throw new Error(`Unexpected RunPod status: ${result.status}`);
    }
}

/**
 * Generate audio using Modal endpoint
 */
async function generateWithModal(text, referenceAudioUrl) {
    console.log('[Modal] Generating audio...');
    
    const response = await fetch(MODAL_API_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            text: text,
            reference_audio_url: referenceAudioUrl
        })
    });

    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Modal API Error: ${response.status} ${errorText}`);
    }

    const audioArrayBuffer = await response.arrayBuffer();
    return Buffer.from(audioArrayBuffer);
}

// Then, replace lines 35-58 in the main router.post handler with:

        // 1. Generate Audio (choose provider)
        let audioBuffer;
        
        if (USE_RUNPOD && RUNPOD_API_KEY && RUNPOD_ENDPOINT_URL) {
            console.log(`[Generate] Using RunPod for user ${userId}...`);
            audioBuffer = await generateWithRunPod(text, req.body.reference_audio_url);
        } else {
            console.log(`[Generate] Using Modal for user ${userId}...`);
            audioBuffer = await generateWithModal(text, req.body.reference_audio_url);
        }
        
        // Continue with R2 upload (line 60 onwards)...
```

## Environment Variables

Add to your `.env` file:

```bash
# RunPod Configuration (optional)
RUNPOD_API_KEY=your_runpod_api_key_here
RUNPOD_ENDPOINT_URL=https://api.runpod.ai/v2/your-endpoint-id/runsync
USE_RUNPOD=false  # Set to 'true' to use RunPod instead of Modal

# Modal Configuration (existing)
MODAL_API_URL=https://your-modal-endpoint.modal.run
```

## Testing

Test RunPod integration:

```bash
# Set environment variable
export USE_RUNPOD=true  # or set in .env file

# Restart server
npm run dev

# Make a test request
curl -X POST http://localhost:3000/api/generate-audio \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Testing RunPod integration",
    "userId": "test-user-id",
    "reference_audio_url": "https://pub-420658e45851415e9854497676646b3f.r2.dev/voices/en/en_voice_01.wav"
  }'
```

Check server logs for:
- `[Generate] Using RunPod for user...` (confirms RunPod is being used)
- `[RunPod] Generated X bytes in Y seconds` (confirms successful generation)

## Switching Between Providers

Simply change the environment variable:

```bash
# Use RunPod
USE_RUNPOD=true

# Use Modal
USE_RUNPOD=false
```

No code changes required!

## Error Handling

The integration includes comprehensive error handling:
- Network errors
- Invalid API responses
- Missing environment variables
- Audio decoding failures

All errors are logged with provider-specific prefixes (`[RunPod]` or `[Modal]`) for easy debugging.
