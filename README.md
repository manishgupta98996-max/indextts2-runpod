# IndexTTS2 RunPod Deployment

Build Docker image for RunPod serverless voice cloning.

## Quick Start

### 1. Create GitHub Repository
1. Go to https://github.com/new
2. Name: `indextts2-runpod`
3. Set to **Public** (required for free GitHub Actions)
4. Click **Create repository**

### 2. Add Docker Hub Secrets
In your GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username (e.g., `warisjamil`) |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token (create at https://hub.docker.com/settings/security) |

### 3. Push Code
```bash
cd runpod_integration
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/indextts2-runpod.git
git push -u origin main
```

### 4. Monitor Build
Go to your repo → **Actions** tab → Watch the build progress (~10-15 min)

## Files Included
- `Dockerfile` - Container build config
- `handler.py` - RunPod worker handler
- `requirements.txt` - Python dependencies
- `.github/workflows/build-docker.yml` - CI/CD pipeline

## Cost: $0 (Free!)
GitHub Actions provides 2,000 free minutes/month for public repos.
