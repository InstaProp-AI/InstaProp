# Railway Deployment Configuration

## Overview
This application is configured to deploy the React Dashboard and .NET API together on Railway. Both are served from the same domain, allowing seamless communication.

## Architecture

### Dockerfile Structure
- **Stage 1**: Builds React Dashboard (Node.js)
- **Stage 2**: Builds .NET API
- **Stage 3**: Runtime combines both in a single container

### API Communication

#### Development Mode
- Dashboard API calls: `http://localhost:5284/api`
- Uses Vite proxy for development server

#### Production Mode (Railway)
- Dashboard API calls: `/api` (relative URL)
- Both dashboard and API served from same domain
- No CORS issues since same origin

## Configuration Files

### `API/Dockerfile`
- Builds React dashboard and .NET API
- Serves dashboard from `/dashboard/dist`
- API runs on port 8080 (Railway sets PORT env var)

### `railway.json`
- Uses Dockerfile builder
- Start command: `dotnet InstapropAPI.dll`
- Restart policy: ON_FAILURE (max 10 retries)

### `dashboard/src/services/api.ts`
- Automatically detects environment
- Development: Uses `VITE_API_BASE_URL` or defaults to `http://localhost:5284/api`
- Production: Uses relative URL `/api`

## Route Configuration

### API Routes
- All controllers use `[Route("api/[controller]")]`
- Examples:
  - `/api/account`
  - `/api/project`
  - `/api/property`
  - `/api/chat`

### Dashboard Routes
- Served at root `/`
- SPA fallback: All non-API routes serve `index.html`
- React Router handles client-side routing

## Middleware Order (Critical)
1. Swagger UI (`/swagger`)
2. CORS (allows all origins)
3. Error handling
4. Static files (dashboard)
5. Static files (wwwroot/uploads)
6. Authentication/Authorization
7. **API Controllers** (`/api/*`)
8. Health check (`/health`)
9. **SPA Fallback** (all other routes → `index.html`)

## Environment Variables

### Required for Railway
- `DATABASE_URL` - PostgreSQL connection string (Railway provides this)
- `JWT_SECRET` - JWT signing key (set in Railway dashboard)
- `ASPNETCORE_ENVIRONMENT=Production` (set automatically by Dockerfile)

### Optional
- `VITE_API_BASE_URL` - Override API URL in development (dashboard)

## Verification

### Check API is working
```bash
curl https://your-app.railway.app/api/health
```

### Check Dashboard is served
```bash
curl https://your-app.railway.app/
```

### Check API endpoints
```bash
curl https://your-app.railway.app/api/account/me
```

### Check Swagger UI
- **Swagger UI**: `https://your-app.railway.app/swagger`
- **Swagger JSON**: `https://your-app.railway.app/swagger/v1/swagger.json`

Swagger is enabled in all environments (development and production) and is accessible at `/swagger`.

## Troubleshooting

### Dashboard can't reach API
1. Check browser console for API errors
2. Verify API base URL is `/api` in production
3. Check CORS configuration (should allow all origins)
4. Verify controllers are mapped before fallback

### Static files not loading
1. Verify `dashboard/dist` exists in Docker container
2. Check console logs for dashboard path
3. Ensure build completed successfully

### API routes return 404
1. Verify `app.MapControllers()` is called
2. Check controller route attributes (`[Route("api/[controller]")]`)
3. Ensure middleware order is correct (controllers before fallback)

## Notes
- Flutter app has been removed from deployment
- Only React Dashboard is served as frontend
- API and Dashboard communicate via same-origin requests (no CORS needed in production)

