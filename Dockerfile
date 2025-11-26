# Multi-stage build for React dashboard, Flutter web, and .NET API
# Build context: Repository root directory

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
# Stage 2: Build Flutter Web App
# ============================================
FROM ghcr.io/cirruslabs/flutter:3.38.3 AS flutter-build
WORKDIR /app/flutter

# Copy Flutter pubspec files first to leverage Docker layer caching
COPY Flutter/pubspec.* ./
RUN flutter pub get

# Copy the entire Flutter project
COPY Flutter/ ./

# Ensure web support is enabled (safe to run repeatedly)
RUN flutter config --enable-web

# Build Flutter for the /flutter route with offline-first PWA strategy
RUN flutter build web --release --base-href=/flutter/ --pwa-strategy=offline-first

# Ensure the Flutter web bundle uses the correct base href (fallback if flag fails)
RUN sed -i 's#<base href="/">#<base href="/flutter/">#' build/web/index.html

# ============================================
# Stage 3: Build .NET API
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
# Stage 4: Runtime - Combine everything
# ============================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Copy published .NET API from build stage
COPY --from=api-build /app/publish .

# Copy built React dashboard from dashboard-build stage
# The dashboard dist folder will be accessible at /app/dashboard/dist
COPY --from=dashboard-build /app/dashboard/dist ./dashboard/dist

# Copy Flutter web build into wwwroot for serving at /flutter
COPY --from=flutter-build /app/flutter/build/web ./wwwroot/flutter

# Create directories expected at runtime
RUN mkdir -p ./wwwroot/uploads

# Expose port (Railway will set PORT environment variable)
EXPOSE 8080

# Set environment to Production
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://0.0.0.0:8080

# Run the API
ENTRYPOINT ["dotnet", "InstapropAPI.dll"]

