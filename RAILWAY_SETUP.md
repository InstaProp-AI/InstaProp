# Railway Quick Setup Guide

## Step-by-Step Railway Deployment

### 1. Create Railway Account
- Go to https://railway.app
- Sign up with GitHub (recommended) or email

### 2. Create New Project
- Click "New Project"
- Choose "Deploy from GitHub repo" (if connected) or "Empty Project"

### 3. Add PostgreSQL Database
- In your project, click "+ New"
- Select "Database" → "Add PostgreSQL"
- Railway automatically creates the database
- The `DATABASE_URL` environment variable is automatically set

### 4. Deploy Backend Service

**Option A: Deploy from GitHub (Recommended)**
1. Click "+ New" → "GitHub Repo"
2. Select your repository
3. Railway will detect the `API` folder and Dockerfile
4. It will automatically build and deploy

**Option B: Deploy from Local Machine**
1. Install Railway CLI: `npm i -g @railway/cli`
2. Login: `railway login`
3. Initialize: `cd API && railway init`
4. Link to project: `railway link`
5. Deploy: `railway up`

### 5. Configure Environment Variables

Go to your service → Variables tab and add:

| Variable | Value | Notes |
|----------|-------|-------|
| `JWT_SECRET` | Generate with: `openssl rand -hex 32` | Required, min 32 chars |
| `ASPNETCORE_ENVIRONMENT` | `Production` | Required |
| `DATABASE_URL` | Auto-set by Railway | Don't modify |
| `PORT` | Auto-set by Railway | Don't modify |

**Optional Variables:**
- `OPENAI_API_KEY` - If using AI features
- `IMGBB_API_KEY` - For image uploads (already in config)

### 6. Get Your Railway URL

1. After deployment completes, go to your service
2. Click "Settings" → "Generate Domain"
3. Railway will provide a URL like: `https://your-app-name.railway.app`
4. Copy this URL

### 7. Update Flutter App

1. Open `Flutter/lib/services/api_client.dart`
2. Find: `static const String productionBaseUrl = 'https://YOUR-RAILWAY-APP-NAME.railway.app';`
3. Replace with your actual Railway URL
4. Example: `static const String productionBaseUrl = 'https://instaprop-api.railway.app';`

### 8. Test Your Deployment

1. Visit: `https://your-app-name.railway.app/swagger`
2. You should see the Swagger API documentation
3. Test an endpoint to verify it's working

### 9. View Logs

- In Railway dashboard, click on your service
- Go to "Deployments" tab
- Click on a deployment to see logs
- Or use CLI: `railway logs`

## Troubleshooting

### Build Fails
- Check Railway logs for errors
- Verify Dockerfile is in `API` folder
- Ensure all dependencies are in `InstapropAPI.csproj`

### Database Connection Issues
- Verify `DATABASE_URL` is set (should be automatic)
- Check PostgreSQL service is running in Railway
- Review connection string format in logs

### App Not Connecting
- Verify Railway URL is correct in Flutter app
- Check CORS settings (should allow all for mobile)
- Test API endpoint in browser first
- Check Railway service is running (not paused)

### Environment Variables Not Working
- Ensure variables are set in Railway dashboard
- Restart service after adding variables
- Check variable names match exactly (case-sensitive)

## Railway CLI Commands

```bash
# Login
railway login

# Link to project
railway link

# View logs
railway logs

# Deploy
railway up

# Open dashboard
railway open

# Set environment variable
railway variables set JWT_SECRET=your-secret-here
```

## Next Steps

After Railway deployment:
1. ✅ Update Flutter app with Railway URL
2. ✅ Build Android APK
3. ✅ Build iOS IPA
4. ✅ Test on devices
5. ✅ Distribute to users

See `DEPLOYMENT_GUIDE.md` for complete instructions.

