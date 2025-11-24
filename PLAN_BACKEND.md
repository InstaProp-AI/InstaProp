# Backend Structure Refactoring Plan

## Overview
Complete backend refactoring including UUID migration and Account interface architecture. This ensures professional, maintainable, and scalable code structure.

## Part 1: Account Interface Architecture

### Current State
- Account is a single class with all properties
- Properties like `SalesTeamId`, `GoogleId`, `AuthProvider` are nullable and used conditionally
- No clear separation between account types

### Target Architecture
- **Account** becomes an **interface** (IAccount)
- Separate implementations for each account type:
  - `UserAccount` - Implements IAccount (has GoogleId, AuthProvider)
  - `DeveloperAccount` - Implements IAccount
  - `AdminAccount` - Implements IAccount
  - `SalesAccount` - Implements IAccount (has SalesTeamId, AssignedDeveloperId)

### Implementation Steps

#### Step 1: Create IAccount Interface
```csharp
public interface IAccount
{
    Guid AccountId { get; set; }
    string FirstName { get; set; }
    string LastName { get; set; }
    string PhoneNumber { get; set; }
    string Email { get; set; }
    Guid RoleId { get; set; }
    Role? Role { get; set; }
    string? HashedPassword { get; set; }
    VerificationStatus Status { get; set; }
    bool EmailVerified { get; set; }
    bool PhoneVerified { get; set; }
    // ... all shared properties (rewards, verification, suspension, etc.)
}
```

#### Step 2: Create Account Type Implementations
- **UserAccount**: Implements IAccount
  - Properties: `GoogleId`, `AuthProvider` (OAuth support)
  - No SalesTeamId, No AssignedDeveloperId
  
- **DeveloperAccount**: Implements IAccount
  - No GoogleId, No AuthProvider
  - No SalesTeamId, No AssignedDeveloperId
  
- **AdminAccount**: Implements IAccount
  - No GoogleId, No AuthProvider
  - No SalesTeamId, No AssignedDeveloperId
  
- **SalesAccount**: Implements IAccount
  - Properties: `SalesTeamId`, `AssignedDeveloperId`
  - No GoogleId, No AuthProvider

#### Step 3: Update DbContext Configuration
- Use Table-Per-Hierarchy (TPH) or Table-Per-Type (TPT) strategy
- Configure discriminator column for account type
- Update all entity configurations

#### Step 4: Update All References
- Controllers: Update to use IAccount
- Services: Update to use IAccount
- DTOs: Create separate DTOs or use IAccount
- Queries: Update LINQ queries to handle account types

## Part 2: UUID Migration

### Phase 1: Models Migration
1. **Change all primary keys** from `int`/`long` to `Guid` in 63 model files
2. **Update all foreign keys** to `Guid` or `Guid?`
3. **Update Role constants** to `Guid` values
4. **Update FAQ seed data** to use UUIDs

### Phase 2: DbContext Updates
1. Configure UUID generation: `ValueGeneratedOnAdd()` with `Guid.NewGuid()`
2. Update all entity configurations
3. Update foreign key relationships
4. Create new migration (drops all tables, recreates with UUIDs)

### Phase 3: Controllers Migration (30+ files)
1. Update route parameters: `[HttpGet("{id}")]` → `Guid id`
2. Update query parameters: `int? id` → `Guid? id`
3. Update request DTOs
4. Update response DTOs
5. Update all ID comparisons and queries

### Phase 4: Services Migration (24 files)
1. Update all service methods to use `Guid` parameters
2. Update database queries
3. Update business logic using IDs
4. Update extension methods (AccountExtensions)

### Phase 5: DTOs Migration
1. Update all DTO classes
2. Update property mappings
3. Update validation attributes if needed

## Part 3: Code Quality & Professional Structure

### Code Review Checklist
1. **Naming Conventions**
   - ✅ PascalCase for classes, methods, properties
   - ✅ camelCase for parameters, local variables
   - ✅ Meaningful names (no abbreviations)

2. **Separation of Concerns**
   - ✅ Controllers: Only handle HTTP requests/responses
   - ✅ Services: Business logic
   - ✅ Data Access: Only in DbContext/Repositories

3. **Error Handling**
   - ✅ Consistent error responses
   - ✅ Proper exception handling
   - ✅ Logging for errors

4. **Validation**
   - ✅ Data annotations on models
   - ✅ FluentValidation where appropriate
   - ✅ Input validation in controllers

5. **Documentation**
   - ✅ XML comments on public APIs
   - ✅ Clear method names
   - ✅ README updates

6. **Dependency Injection**
   - ✅ All services registered in Program.cs
   - ✅ Constructor injection (no service locator pattern)

7. **Database Design**
   - ✅ Proper indexes
   - ✅ Foreign key constraints
   - ✅ Cascade delete behaviors

## Implementation Order

### Step 1: Account Interface Refactoring
1. Create IAccount interface
2. Create account type classes (UserAccount, DeveloperAccount, AdminAccount, SalesAccount)
3. Update DbContext configuration
4. Create migration for account structure
5. Update all controllers/services to use IAccount

### Step 2: UUID Migration
1. Update all models (63 files)
2. Update DbContext
3. Create UUID migration
4. Update all controllers (30+ files)
5. Update all services (24 files)
6. Update all DTOs

### Step 3: Code Quality Pass
1. Review all controllers
2. Review all services
3. Add missing validations
4. Improve error handling
5. Add XML documentation
6. Review and optimize database queries

## Files to Modify

### Models (63 files)
- Create `IAccount.cs` interface
- Create `UserAccount.cs`, `DeveloperAccount.cs`, `AdminAccount.cs`, `SalesAccount.cs`
- Update all 63 model files for UUIDs

### Controllers (30+ files)
- AccountController.cs
- AdminController.cs
- PropertyController.cs
- AuctionController.cs
- ... (all controllers)

### Services (24 files)
- All service files
- AccountExtensions.cs

### Data
- AppDbContext..cs
- New migration file

### DTOs
- All DTO classes

## Testing Strategy
- Unit tests for account type logic
- Integration tests for API endpoints
- Database migration testing
- Verify all foreign key relationships

