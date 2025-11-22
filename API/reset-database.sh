#!/bin/bash

# Database Reset Script
# This script drops the database and applies all migrations

echo "🗑️  Dropping database..."
dotnet ef database drop --force

echo "📦 Applying migrations..."
dotnet ef database update

echo "✅ Database reset complete!"
echo ""
echo "Next steps:"
echo "1. Start the API: dotnet run"
echo "2. The app will automatically seed roles and data on startup"

