# Database Reset Commands

## Commands to Drop and Recreate Database

### Step 1: Drop the Database
```bash
cd API
dotnet ef database drop --force
```

### Step 2: Apply All Migrations
```bash
dotnet ef database update
```

## What Happens

1. **Database is dropped** - All data is removed
2. **Migrations are applied** - Fresh schema is created with:
   - All tables (Accounts, Properties, Auctions, etc.)
   - All indexes and foreign keys
   - **Roles are automatically seeded** (User, Developer, Admin) by the migration

## After Migrations

When you start the API (`dotnet run`), it will:
1. ✅ Seed Roles (if not already present - but they're seeded by migration)
2. ✅ Seed all realistic Egyptian real estate data if database is empty

## Quick Reset Script

You can also use the provided script:
```bash
cd API
./reset-database.sh
```

Or manually run:
```bash
cd API
dotnet ef database drop --force && dotnet ef database update
```

## Migration History

The following migrations are applied in order:
1. `20251116201348_InitialPostgreSQLMigration` - Creates all base tables
2. `20251120231457_AddRolesTableAndUpdateAccounts` - Adds Roles table and seeds 3 roles
3. `20251120235240_AddDeveloperPermissions` - Adds DeveloperPermissions table
4. `20251121020547_AddSalesMemberIdToChat` - Adds SalesMemberId to Chats table

