# Railway Deployment - Quick Fix Guide

## The Problem
Railway couldn't detect how to build your app because it was scanning the root directory, but your build files are in the `API/` folder.

## The Solution - Choose ONE Option:

### ✅ Option 1: Set Root Directory in Railway (EASIEST)

1. Go to Railway Dashboard → Your InstaProp service
2. Click **"Settings"** tab
3. Find **"Root Directory"** setting
4. Set it to: `API`
5. Click **"Save"**
6. Trigger a new deployment

Railway will now:
- Use `API/railway.json`
- Use `API/Dockerfile`
- Build from the `API/` directory

### ✅ Option 2: Use Root railway.json (Already Created)

I've created a `railway.json` at the project root that points to `API/Dockerfile`.

1. Make sure Railway is building from root (default)
2. Railway will use the root `railway.json`
3. It will build using `API/Dockerfile`

## Database Setup ✅

**Already configured!** The code automatically:
- ✅ Detects `DATABASE_URL` from Railway
- ✅ Connects to PostgreSQL when deployed
- ✅ Uses SQLite for local development

**Your PostgreSQL is ready:**
- Railway automatically sets `DATABASE_URL` when PostgreSQL service is linked
- Connection string: `postgresql://postgres:HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD@postgres.railway.internal:5432/railway`

## Required Environment Variables

In Railway Dashboard → Your Service → Variables:

```
JWT_SECRET=<generate with: openssl rand -hex 32>
ASPNETCORE_ENVIRONMENT=Production
```

(DATABASE_URL is automatically set by Railway - don't add it manually)

## After Deployment

Check logs for:
```
🗄️ Using PostgreSQL database from DATABASE_URL (Host: postgres.railway.internal, Database: railway)
📦 Applying pending migrations (if any)...
✅ Database schema up to date.
```

If you see these messages, everything is working!

## Recommended: Use Option 1 (Set Root Directory)

This is the cleanest solution and avoids path issues.

