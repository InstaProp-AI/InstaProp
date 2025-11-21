#!/bin/bash

# Quick Database Reset Script
# Drops and recreates the Railway PostgreSQL database using EF Core

echo "⚠️  WARNING: This will DELETE ALL DATA in the Railway database!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

cd "$(dirname "$0")/.."

echo "📋 Step 1: Dropping database..."
dotnet ef database drop --force

echo ""
echo "📋 Step 2: Recreating database with migrations..."
dotnet ef database update

echo ""
echo "✅ Database reset complete!"
echo ""
echo "📋 Next steps:"
echo "   - Verify connection: dotnet ef migrations list"
echo "   - (Optional) Run seeding service if needed"

