# Deploy to Production on Railway

## Automatic Deployment

Railway automatically deploys when you push to the **main** branch. Since we just merged dev into main and pushed, Railway should automatically:

1. Detect the new commit on main branch
2. Start a new build using the Dockerfile
3. Deploy the updated application

## Verify Deployment

### 1. Check Railway Dashboard
1. Go to [Railway Dashboard](https://railway.app)
2. Select your project
3. Check the "Deployments" tab
4. You should see a new deployment triggered by the latest commit

### 2. Manual Trigger (if needed)
If automatic deployment didn't trigger:
1. Go to Railway Dashboard
2. Select your project
3. Go to Settings → Source
4. Click "Redeploy" or "Deploy Latest"

### 3. Verify Branch Configuration
Ensure Railway is connected to the **main** branch:
1. Go to Railway Dashboard
2. Select your project
3. Go to Settings → Source
4. Verify "Branch" is set to `main`
5. If not, change it to `main` and save

## What Gets Deployed

The deployment includes:
- ✅ React Dashboard (built and served)
- ✅ .NET API (with all controllers)
- ✅ Swagger UI at `/swagger`
- ✅ All recent updates from dev branch:
  - Developer property restrictions
  - Chat management
  - News page improvements
  - Valuation page enhancements
  - Railway deployment configuration

## Environment Variables

Make sure these are set in Railway:
- `DATABASE_URL` - PostgreSQL connection (Railway auto-provides this)
- `JWT_SECRET` - JWT signing key (set manually)
- `ASPNETCORE_ENVIRONMENT=Production` (set automatically by Dockerfile)

## Access Points After Deployment

Once deployed, your app will be available at:
- **Dashboard**: `https://your-app.railway.app/`
- **API**: `https://your-app.railway.app/api/*`
- **Swagger**: `https://your-app.railway.app/swagger`
- **Health Check**: `https://your-app.railway.app/health`

## Troubleshooting

### Deployment Not Starting
1. Check Railway dashboard for errors
2. Verify branch is set to `main`
3. Check build logs for errors
4. Ensure `railway.json` and `API/Dockerfile` are in the repository

### Build Fails
1. Check Railway build logs
2. Verify Dockerfile syntax
3. Check if all dependencies are available
4. Ensure `dashboard/package.json` is valid

### App Not Working After Deployment
1. Check application logs in Railway
2. Verify environment variables are set
3. Check database connection
4. Verify port configuration (Railway sets PORT automatically)

## Next Steps

After successful deployment:
1. Test the dashboard at your Railway URL
2. Test API endpoints via Swagger
3. Verify database connections
4. Test authentication flow
5. Monitor logs for any errors

