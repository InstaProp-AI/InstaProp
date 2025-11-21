# Fix 403 Forbidden Error - Dashboard Access

## 🔍 Problem

You're getting `403 Forbidden` errors when trying to access:
- `/api/admin/properties`
- `/api/project`

This happens because **your account has a `User` role** instead of `Admin` or `Developer` role.

## ✅ Solution

You need to update your account's `RoleId` in the database to either:
- **Admin** (RoleId: `9823749823749823`) - Full access to all dashboard features
- **Developer** (RoleId: `7823647823647823`) - Access to dashboard with limited permissions

## 🔧 Method 1: Using SQL Script (Recommended)

1. **Open your PostgreSQL database** (using psql, pgAdmin, or your preferred tool)

2. **Run this SQL command** (replace `your-email@example.com` with your actual email):

```sql
-- Make user Admin (recommended for full access)
UPDATE "Accounts" 
SET "RoleId" = 9823749823749823  -- ADMIN_ROLE_ID
WHERE "Email" = 'your-email@example.com';

-- OR make user Developer (limited access)
-- UPDATE "Accounts" 
-- SET "RoleId" = 7823647823647823  -- DEVELOPER_ROLE_ID
-- WHERE "Email" = 'your-email@example.com';

-- Verify the update
SELECT "AccountId", "Email", "FirstName", "LastName", "RoleId" 
FROM "Accounts" 
WHERE "Email" = 'your-email@example.com';
```

3. **Logout and login again** in the dashboard to get a new JWT token with the updated role.

## 🔧 Method 2: Using Entity Framework Migration

1. **Create a migration** to update the user:
```bash
cd API
dotnet ef migrations add UpdateUserToAdmin
```

2. **Edit the migration file** to add:
```csharp
migrationBuilder.Sql(@"
    UPDATE ""Accounts"" 
    SET ""RoleId"" = 9823749823749823 
    WHERE ""Email"" = 'your-email@example.com';
");
```

3. **Apply the migration**:
```bash
dotnet ef database update
```

## 🔧 Method 3: Using Admin API (If you have admin access elsewhere)

If you have access to an admin account via another method (like Swagger), you can use the admin API:

```bash
# First, get your account ID
GET /api/admin/users

# Then update your role (requires admin token)
PUT /api/admin/users/{yourAccountId}/change-role
{
  "roleId": 9823749823749823  // Admin role
}
```

## 📊 Role IDs Reference

| Role | RoleId | Access Level |
|------|--------|--------------|
| **User** | `8923748923748923` | No dashboard access |
| **Developer** | `7823647823647823` | Limited dashboard access |
| **Admin** | `9823749823749823` | Full dashboard access |

## ✅ After Fixing

1. **Logout** from the dashboard
2. **Login again** to get a new JWT token with the updated role
3. **Verify** you can now access `/projects` and `/properties` pages

## 🐛 Troubleshooting

### Still getting 403 after update?
1. **Clear browser cache** and localStorage:
   - Open DevTools (F12)
   - Go to Application tab → Local Storage
   - Clear all items
   - Refresh the page

2. **Verify the RoleId in database**:
   ```sql
   SELECT "AccountId", "Email", "RoleId" FROM "Accounts" WHERE "Email" = 'your-email@example.com';
   ```

3. **Check the JWT token** (optional):
   - Go to DevTools → Application → Local Storage → `authToken`
   - Decode the token at https://jwt.io
   - Verify the `roleId` claim matches the database value

### Need to create a new Admin account?

Use the signup endpoint:
```bash
POST /api/account/signup
{
  "firstName": "Admin",
  "lastName": "User",
  "email": "admin@propertyflipper.com",
  "phoneNumber": "+1234567890",
  "password": "SecurePassword123!",
  "roleId": 9823749823749823  // Admin role
}
```

**Note**: The signup endpoint might require manual database update if it doesn't accept `roleId` directly.

---

**Quick Fix SQL** (replace email):
```sql
UPDATE "Accounts" SET "RoleId" = 9823749823749823 WHERE "Email" = 'YOUR_EMAIL_HERE';
```

