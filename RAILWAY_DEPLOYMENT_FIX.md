# Railway Deployment Fix

## Problem
Railway was failing to build because it couldn't detect the build configuration. The error showed:
```
⚠ Script start.sh not found
✖ Railpack could not determine how to build the app.
```

## Solution

I've created multiple configuration files to ensure Railway can build your app:

### 1. Root `railway.json` (Primary)
Located at project root, tells Railway to:
- Use Dockerfile builder
- Use Dockerfile at `API/Dockerfile`
- Start command: `dotnet InstapropAPI.dll`

### 2. Updated `API/Dockerfile`
Modified to work when Railway builds from repository root:
- Copies files from `API/` directory
- Builds the .NET project correctly
- Outputs to `/app/publish`

### 3. `nixpacks.toml` (Fallback)
Alternative build configuration if Docker doesn't work

## Database Configuration ✅

The database is **already configured correctly**:
- ✅ Code automatically detects `DATABASE_URL` from Railway
- ✅ Parses Railway's PostgreSQL connection string format
- ✅ Connects to PostgreSQL when `DATABASE_URL` is set
- ✅ Falls back to SQLite for local development

**Your Railway PostgreSQL connection:**
```
postgresql://postgres:HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD@postgres.railway.internal:5432/railway
```

Railway will automatically set `DATABASE_URL` when you link the PostgreSQL service.

## Next Steps

### 1. In Railway Dashboard

1. **Set Root Directory** (Important!):
   - Go to your InstaProp service
   - Click "Settings"
   - Find "Root Directory" setting
   - Set it to: `API`
   - OR keep it as root and Railway will use the root `railway.json`

2. **Link PostgreSQL Service**:
   - In your Railway project
   - Make sure PostgreSQL service is added
   - Railway automatically sets `DATABASE_URL` when services are linked

3. **Set Environment Variables**:
   Go to your service → Variables tab:
   ```
   JWT_SECRET=<generate with: openssl rand -hex 32>
   ASPNETCORE_ENVIRONMENT=Production
   ```
   (DATABASE_URL is auto-set by Railway)

4. **Redeploy**:
   - Railway should now detect the Dockerfile
   - Or manually trigger a new deployment

### 2. Verify Database Connection

After deployment, check logs for:
```
🗄️ Using PostgreSQL database from DATABASE_URL (Host: postgres.railway.internal, Database: railway)
```

If you see this, the database connection is working!

### 3. Run Migrations

The backend automatically runs migrations on startup. Check logs for:
```
📦 Applying pending migrations (if any)...
✅ Database schema up to date.
```

## Troubleshooting

### Still Getting Build Error?

**Option A: Set Root Directory to API/**
1. In Railway dashboard → Service Settings
2. Set "Root Directory" to `API`
3. Railway will use `API/railway.json` and `API/Dockerfile`

**Option B: Use Railway CLI**
```bash
cd API
railway link
railway up
```

### Database Connection Issues?

1. **Check DATABASE_URL is set**:
   - Railway dashboard → Service → Variables
   - Should see `DATABASE_URL` automatically set

2. **Check PostgreSQL service is running**:
   - Railway dashboard → PostgreSQL service
   - Should show "Deployment successful"

3. **Check logs for connection errors**:
   - Look for PostgreSQL connection errors
   - Verify hostname is `postgres.railway.internal` (internal) or public hostname

### Migration Issues?

The backend runs migrations automatically. If they fail:
- Check logs for migration errors
- Verify database user has CREATE TABLE permissions
- Check PostgreSQL service is accessible

## Summary

✅ Database code is ready - automatically uses Railway's DATABASE_URL
✅ Railway configuration files created
✅ Dockerfile updated for root-level builds
✅ Ready to deploy!

The main thing to do in Railway is either:
- Set Root Directory to `API`, OR
- Keep root and Railway will use the root `railway.json` pointing to `API/Dockerfile`

