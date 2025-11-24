# Master Migration Plan - Complete System Refactoring

## Overview
This is the master plan coordinating three major refactoring efforts:
1. **Backend Structure** - Account interface architecture + UUID migration
2. **Dashboard (Frontend)** - TypeScript/React UUID migration
3. **Flutter App** - Dart UUID migration

## Execution Order

### Phase 1: Backend Foundation (Week 1)
1. **Account Interface Refactoring**
   - Create IAccount interface
   - Create account type implementations
   - Update DbContext
   - Create migration
   - Update all controllers/services

2. **UUID Migration - Models**
   - Update all 63 model files
   - Update DbContext configuration
   - Create UUID migration

### Phase 2: Backend API (Week 1-2)
1. **Controllers Migration**
   - Update all 30+ controllers
   - Update route parameters
   - Update DTOs

2. **Services Migration**
   - Update all 24 services
   - Update business logic
   - Update extension methods

### Phase 3: Frontend Migration (Week 2)
1. **Dashboard Migration**
   - Update types
   - Update API services
   - Update all pages
   - Test thoroughly

2. **Flutter Migration**
   - Update all 207 models
   - Update services
   - Update screens
   - Test thoroughly

### Phase 4: Quality Assurance (Week 2-3)
1. **Code Review**
   - Review all changes
   - Ensure consistency
   - Fix any issues

2. **Testing**
   - Backend API testing
   - Dashboard testing
   - Flutter app testing
   - Integration testing

## Detailed Plans

See separate plan files:
- **PLAN_BACKEND.md** - Complete backend refactoring details
- **PLAN_DASHBOARD.md** - Complete dashboard migration details
- **PLAN_FLUTTER.md** - Complete Flutter app migration details

## Key Principles

### 1. Account Architecture
- Account is an **interface**, not a class
- Each account type (User, Developer, Admin, Sales) is a separate implementation
- Properties are scoped to their account types:
  - `GoogleId`, `AuthProvider` → Only UserAccount
  - `SalesTeamId`, `AssignedDeveloperId` → Only SalesAccount
  - Rewards points → All account types (in interface)

### 2. UUID Migration
- All IDs are UUIDs (Guid in C#, String in TypeScript/Dart)
- Consistent across all layers
- No numeric IDs anywhere

### 3. Code Quality
- Professional structure
- Proper separation of concerns
- Consistent naming
- Good error handling
- Proper validation

## Success Criteria

### Backend
- ✅ Account is an interface with type-specific implementations
- ✅ All models use UUID primary keys
- ✅ All controllers use UUID parameters
- ✅ All services use UUID parameters
- ✅ Database migration successful
- ✅ All tests passing

### Dashboard
- ✅ All types use string IDs
- ✅ All API calls use UUID strings
- ✅ All pages work correctly
- ✅ No numeric ID references

### Flutter
- ✅ All models use String IDs
- ✅ All API calls use UUID strings
- ✅ All screens work correctly
- ✅ No numeric ID references

## Risk Mitigation

### Data Loss
- ✅ All data is demo data - safe to drop/recreate
- ✅ Migration drops all tables and recreates

### Breaking Changes
- ✅ Coordinated deployment required
- ✅ All layers updated simultaneously

### Testing
- ✅ Comprehensive testing in development
- ✅ Verify all endpoints work
- ✅ Verify all UI interactions work

## Timeline Estimate

- **Backend Refactoring**: 3-4 days
- **Dashboard Migration**: 1-2 days
- **Flutter Migration**: 2-3 days
- **Testing & QA**: 1-2 days
- **Total**: ~7-11 days

## Notes

- This is a complete system refactoring
- All changes must be coordinated
- Test thoroughly before production
- Document any deviations from plan

