# Verify Railway Setup - Complete Checklist

## Step 1: Verify Local Files Are Correct ✅

Your local files are correct:
- ✅ `API/Dockerfile` - Fixed to work from API directory
- ✅ `API/railway.json` - Points to `Dockerfile`
- ✅ `API/InstapropAPI.csproj` - Correct project name
- ✅ Branch: `main`

## Step 2: Commit and Push Changes

If you have uncommitted changes:

```bash
cd "/home/abraam/Desktop/Business/Proerty Flipper"
git add API/Dockerfile API/railway.json
git commit -m "Fix Railway Dockerfile for API directory build"
git push origin main
```

## Step 3: Verify Railway Configuration

In Railway Dashboard:

1. **Check Branch**:
   - Go to your service → Settings
   - Verify "Branch" is set to `main`
   - If not, change it to `main`

2. **Check Root Directory**:
   - Settings → "Root Directory"
   - Should be: `API`
   - If empty or different, set it to `API`

3. **Check railway.json**:
   - Railway should be using `API/railway.json`
   - Should show: `"dockerfilePath": "Dockerfile"`

## Step 4: Force Redeploy

After pushing changes:

1. Go to Railway Dashboard → Your service
2. Click "Deployments" tab
3. Click "Redeploy" or trigger a new deployment
4. Railway will pull latest from `main` branch

## Step 5: Check Build Logs

After redeploy, check logs for:

✅ **Success indicators:**
```
Restored /app/*.csproj
dotnet publish -c Release -o /app/publish
Build succeeded
```

❌ **If you still see errors:**
- Check which Dockerfile Railway is using
- Verify Root Directory is `API`
- Check that branch is `main`

## Step 6: Environment Variables

Make sure these are set in Railway → Variables:

```
JWT_SECRET=<your-secret-here>
ASPNETCORE_ENVIRONMENT=Production
```

(DATABASE_URL is auto-set by Railway)

## Quick Fix Commands

If you need to force push:

```bash
# Make sure you're on main
git checkout main

# Verify Dockerfile is correct
cat API/Dockerfile | head -10
# Should show: COPY *.csproj ./

# Commit if needed
git add -A
git commit -m "Fix Railway deployment"
git push origin main
```

## Common Issues

### Issue: Railway still using old Dockerfile
**Solution**: 
1. Check branch is `main` in Railway Settings
2. Force redeploy
3. Check Root Directory is `API`

### Issue: Still getting "Dockerfile not found"
**Solution**:
1. Verify Root Directory is `API` (not empty)
2. Verify `API/Dockerfile` exists in repository
3. Check Railway is pulling from `main` branch

### Issue: Build fails with wrong project name
**Solution**:
1. Verify `InstapropAPI.csproj` exists
2. Check Dockerfile uses correct DLL name: `InstapropAPI.dll`

