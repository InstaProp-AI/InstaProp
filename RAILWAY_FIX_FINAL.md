# Railway Deployment - Final Fix

## The Problem
Railway was using Nixpacks (auto-detection) instead of Docker, and it was looking for the old `PropertyFlipperAPI.csproj` file.

## What I Fixed

1. ✅ **Deleted `nixpacks.toml`** - Forces Railway to use Docker instead of Nixpacks
2. ✅ **Updated `railway.json`** - Explicitly tells Railway to use Docker
3. ✅ **Fixed `API/Dockerfile`** - Now works when Railway builds from root directory
4. ✅ **Created `.railwayignore`** - Excludes unnecessary files from build

## IMPORTANT: Set Root Directory in Railway

**You MUST do this in Railway Dashboard:**

1. Go to Railway Dashboard → Your "InstaProp" service
2. Click **"Settings"** tab  
3. Find **"Root Directory"** setting
4. Set it to: `API`
5. Click **"Save"**
6. **Trigger a new deployment**

This is the **most important step**. Railway needs to build from the `API/` directory.

## Alternative: If Root Directory Setting Doesn't Work

If Railway still builds from root, the Dockerfile is now configured to handle that. But setting Root Directory to `API` is still recommended.

## Environment Variables

Make sure these are set in Railway Dashboard → Your Service → Variables:

```
JWT_SECRET=<generate with: openssl rand -hex 32>
ASPNETCORE_ENVIRONMENT=Production
```

**Note:** `DATABASE_URL` is automatically set by Railway when PostgreSQL service is linked - don't add it manually.

## After Deployment

Check logs for:
- ✅ `🗄️ Using PostgreSQL database from DATABASE_URL` - Database connected
- ✅ `📦 Applying pending migrations` - Migrations running  
- ✅ `✅ Database schema up to date` - Ready!

## Summary

The key fix: **Set Root Directory to `API` in Railway Settings**

This ensures Railway:
- Uses the correct Dockerfile
- Finds `InstapropAPI.csproj` (not the old PropertyFlipperAPI)
- Builds from the correct directory
- Uses Docker (not Nixpacks)

