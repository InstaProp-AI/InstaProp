# Railway Database Setup Guide

## Automatic Configuration (Recommended)

Railway automatically sets the `DATABASE_URL` environment variable when you add a PostgreSQL service to your project. The backend code automatically detects and uses this.

### Your Railway PostgreSQL Details

- **Host (Internal)**: `postgres.railway.internal:5432`
- **Host (Public)**: Check Railway dashboard for public hostname
- **Database**: `railway`
- **User**: `postgres`
- **Password**: `HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD`

### Connection String Format

Railway provides the connection string in this format:
```
postgresql://postgres:HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD@postgres.railway.internal:5432/railway
```

## How It Works

1. **In Railway**: When you deploy, Railway automatically sets `DATABASE_URL` environment variable
2. **Backend Code**: The `Program.cs` automatically detects `DATABASE_URL` and parses it
3. **Connection**: The code converts Railway's format to Npgsql format automatically

## Manual Configuration (If Needed)

### For Railway Deployment

Railway automatically sets `DATABASE_URL`, so you don't need to do anything. The backend will:
- Detect `DATABASE_URL` environment variable
- Parse the connection string
- Connect to PostgreSQL automatically

### For Local Development/Testing

If you want to test with Railway's PostgreSQL from your local machine:

1. **Get Public Hostname**:
   - Go to Railway dashboard
   - Click on your PostgreSQL service
   - Go to "Connect" or "Variables" tab
   - Copy the public hostname (not `postgres.railway.internal`)

2. **Set Environment Variable Locally**:
   ```bash
   export DATABASE_URL="postgresql://postgres:HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD@PUBLIC_HOSTNAME:5432/railway"
   ```

   Or create a `.env` file in the `API` folder (if using dotenv):
   ```
   DATABASE_URL=postgresql://postgres:HBTSCgKSqPkVINVjFCYYZRvXLMgpSiSD@PUBLIC_HOSTNAME:5432/railway
   ```

3. **Run Locally**:
   ```bash
   cd API
   dotnet run
   ```

## Verification

### Check if DATABASE_URL is Set

In Railway dashboard:
1. Go to your backend service
2. Click "Variables" tab
3. Look for `DATABASE_URL` - it should be automatically set

### Test Connection

1. Deploy your backend to Railway
2. Check logs for: `🗄️ Using PostgreSQL database from DATABASE_URL`
3. If you see this message, the connection is working!

## Troubleshooting

### Connection Failed

**Issue**: `postgres.railway.internal` hostname not found
- **Solution**: This hostname only works within Railway's internal network
- For local testing, use the public hostname from Railway dashboard

### DATABASE_URL Not Set

**Issue**: Backend falls back to SQLite
- **Solution**: 
  1. In Railway, ensure PostgreSQL service is added to your project
  2. Railway should automatically link it and set `DATABASE_URL`
  3. If not, manually add `DATABASE_URL` in Variables tab

### Migration Issues

**Issue**: Database migrations fail
- **Solution**: 
  ```bash
  # The backend automatically runs migrations on startup
  # Check Railway logs for migration errors
  ```

## Security Notes

⚠️ **Important**: 
- The password shown here is for your Railway database
- Never commit passwords to git
- Railway automatically manages credentials
- For production, use Railway's environment variables (already configured)

## Next Steps

1. ✅ PostgreSQL service is added to Railway
2. ✅ Backend code is configured to use `DATABASE_URL`
3. ✅ Deploy backend to Railway
4. ✅ Backend will automatically connect to PostgreSQL
5. ✅ Migrations will run automatically on first deployment

The backend is already configured to handle Railway's PostgreSQL automatically!

