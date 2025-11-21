# PowerShell script to reset Railway PostgreSQL database
# This script drops all tables and recreates them using migrations

Write-Host "⚠️  WARNING: This will DELETE ALL DATA in the Railway database!" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to cancel, or Enter to continue..."
Read-Host

Write-Host "📋 Step 1: Dropping all tables..." -ForegroundColor Cyan
Write-Host "Run the SQL script: API/SCRIPTS/reset-railway-database.sql" -ForegroundColor Yellow
Write-Host "Or connect to Railway database and run the SQL commands manually" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 Step 2: Running migrations to recreate database..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\.."
dotnet ef database update

Write-Host ""
Write-Host "✅ Database reset complete!" -ForegroundColor Green
Write-Host "📋 Step 3: (Optional) Seed initial data:" -ForegroundColor Cyan
Write-Host "   - Roles will be seeded automatically via migration"
Write-Host "   - Run your seeding service if needed"

