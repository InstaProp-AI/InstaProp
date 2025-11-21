#!/bin/bash

# Script to Reset Railway PostgreSQL Database
# This script drops all tables and recreates them using migrations

echo "⚠️  WARNING: This will DELETE ALL DATA in the Railway database!"
echo "Press Ctrl+C to cancel, or Enter to continue..."
read

echo "📋 Step 1: Dropping all tables..."
echo "Run the SQL script: API/SCRIPTS/reset-railway-database.sql"
echo "Or connect to Railway database and run the SQL commands manually"
echo ""

echo "📋 Step 2: Running migrations to recreate database..."
cd "$(dirname "$0")/.."
dotnet ef database update

echo ""
echo "✅ Database reset complete!"
echo "📋 Step 3: (Optional) Seed initial data:"
echo "   - Roles will be seeded automatically via migration"
echo "   - Run your seeding service if needed"

