# Railway Dockerfile Fix

## Problem
Railway couldn't find the Dockerfile because it was looking in the root directory, but the Dockerfile was in `API/` folder.

## Solution

I've created a **Dockerfile at the project root** that Railway can find. This Dockerfile:
- ✅ Builds from the `API/` directory
- ✅ Uses the correct project file (`InstapropAPI.csproj`)
- ✅ Outputs the correct DLL (`InstapropAPI.dll`)

## What Changed

1. **Created `/Dockerfile`** at project root
2. **Updated `/railway.json`** to point to root Dockerfile
3. **Kept `/API/Dockerfile`** as backup (not used by Railway now)

## Next Steps

1. **Commit and push** these changes to your repository
2. **Redeploy** in Railway - it should now find the Dockerfile
3. **Check logs** for successful build

## Alternative: Set Root Directory (Still Recommended)

If you prefer, you can still:
1. Set **Root Directory** to `API` in Railway Settings
2. Railway will use `API/railway.json` and `API/Dockerfile`
3. This is cleaner but either approach works

## Database Connection

The database is already configured and will automatically connect when Railway sets `DATABASE_URL`.

Your PostgreSQL connection:
```
postgresql://postgres:HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD@postgres.railway.internal:5432/railway
```

Railway will automatically set this when PostgreSQL service is linked.

## After Deployment

Check logs for:
- ✅ Build successful
- ✅ `🗄️ Using PostgreSQL database from DATABASE_URL`
- ✅ `📦 Applying pending migrations`
- ✅ `✅ Database schema up to date`

