# Multi-stage build for React Dashboard + .NET API
# Build context: Repository root directory
# This Dockerfile builds ONLY the React Dashboard (Flutter is not included)

# ============================================
# Stage 1: Build React Dashboard
# ============================================
FROM node:20-alpine AS dashboard-build
WORKDIR /app/dashboard

# Copy dashboard package files
COPY dashboard/package*.json ./

# Install dependencies
RUN npm ci

# Copy dashboard source code
COPY dashboard/ ./

# Build the dashboard
RUN npm run build

# ============================================
# Stage 2: Build .NET API
# ============================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS api-build
WORKDIR /app

# Copy csproj and restore dependencies
COPY API/*.csproj ./
RUN dotnet restore

# Copy API source code
COPY API/ ./

# Build and publish the API
RUN dotnet publish -c Release -o /app/publish

# ============================================
# Stage 3: Runtime - Combine everything
# ============================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copy published .NET API from build stage
COPY --from=api-build /app/publish .

# Copy built React dashboard from dashboard-build stage
# The dashboard dist folder will be accessible at /app/dashboard/dist
COPY --from=dashboard-build /app/dashboard/dist ./dashboard/dist

# Create wwwroot/uploads directory for file uploads
RUN mkdir -p ./wwwroot/uploads

# Expose port (Railway will set PORT environment variable)
EXPOSE 8080

# Set environment to Production
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://0.0.0.0:8080

# Run the API
ENTRYPOINT ["dotnet", "InstapropAPI.dll"]
