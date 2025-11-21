# Database Reset Scripts

## Overview
These scripts help you reset the Railway PostgreSQL database completely.

## ⚠️ WARNING
**These scripts will DELETE ALL DATA in your database!** Use with caution.

## Available Scripts

### 1. `reset-railway-database.sql`
SQL script to drop all tables and sequences in the Railway database.

**Usage:**
1. Connect to your Railway PostgreSQL database using any PostgreSQL client (psql, pgAdmin, DBeaver, etc.)
2. Run the SQL commands from this file
3. After dropping tables, run migrations to recreate them

**Connection Info:**
- Host: `metro.proxy.rlwy.net`
- Port: `11995`
- Database: `railway`
- Username: `postgres`
- Password: (from Railway dashboard)

### 2. `reset-database.sh` (Linux/Mac)
Bash script that automates the reset process.

**Usage:**
```bash
cd API/SCRIPTS
./reset-database.sh
```

### 3. `reset-database.ps1` (Windows)
PowerShell script for Windows users.

**Usage:**
```powershell
cd API/SCRIPTS
.\reset-database.ps1
```

## Manual Reset Steps

### Step 1: Drop All Tables
Connect to Railway database and run:
```sql
-- Copy and paste all commands from reset-railway-database.sql
```

### Step 2: Run Migrations
```bash
cd API
dotnet ef database update
```

### Step 3: (Optional) Seed Data
If you have seeding services, run them after migrations.

## Quick Reset Command

**Using psql:**
```bash
# Connect to Railway database
psql -h metro.proxy.rlwy.net -p 11995 -U postgres -d railway

# Then run the SQL script
\i API/SCRIPTS/reset-railway-database.sql

# Exit psql
\q

# Run migrations
cd API
dotnet ef database update
```

## Verification

After reset, verify the database:
```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check migrations applied
SELECT * FROM "__EFMigrationsHistory" ORDER BY "MigrationId";
```

## Troubleshooting

### Error: "database is being accessed by other users"
- Make sure no active connections to the database
- Check Railway dashboard for active connections
- Wait a few seconds and try again

### Error: "relation does not exist"
- This is normal if tables were already dropped
- Continue with migrations

### Error: "migration already applied"
- Drop the `__EFMigrationsHistory` table first
- Or use `dotnet ef database update --force`

## Notes

- **Backup First**: Always backup your data before resetting!
- **Production**: Never run these scripts on production without proper backups
- **Railway**: Railway provides automatic backups, but manual backup is recommended

