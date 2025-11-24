# Dashboard (Frontend) Migration Plan

## Overview
Complete migration of the TypeScript/React dashboard to work with UUID-based backend and updated account structure.

## Part 1: Type System Updates

### Update Type Definitions (types/index.ts)
1. **Change all ID fields** from `number` to `string`:
   - `Account.accountId: number` → `string`
   - `Project.projectId: number` → `string`
   - `Property.propertyId: number` → `string`
   - `Auction.auctionId: number` → `string`
   - `Bid.bidId: number` → `string`
   - All other ID fields

2. **Update Account Interface**:
   - Change `roleId: number` → `roleId: string` (UUID)
   - Update `ROLE_IDS` constants to string UUIDs
   - Add account type discriminator if needed

3. **Update all interfaces**:
   - `SalesTeam.teamId: number` → `string`
   - `UserDocument.docId: number` → `string`
   - `PropertyDocument.docId: number` → `string`
   - `PropertyImage.propertyImageId: number` → `string`
   - All nested ID references

## Part 2: API Service Updates (services/api.ts)

### Update All API Methods
1. **usersApi**:
   - `getUser(id: number)` → `getUser(id: string)`
   - `verifyUser(id: number)` → `verifyUser(id: string)`
   - `rejectUser(id: number)` → `rejectUser(id: string)`
   - `banUser(id: number)` → `banUser(id: string)`
   - `suspendUser(id: number, ...)` → `suspendUser(id: string, ...)`

2. **propertiesApi**:
   - `getProperty(id: number)` → `getProperty(id: string)`
   - `approveProperty(propertyId: number, ...)` → `approveProperty(propertyId: string, ...)`
   - `rejectProperty(propertyId: number, ...)` → `rejectProperty(propertyId: string, ...)`
   - `deleteProperty(id: number)` → `deleteProperty(id: string)`
   - All other property methods

3. **auctionsApi**:
   - `getAuction(id: number)` → `getAuction(id: string)`
   - `getAuctionBids(auctionId: number)` → `getAuctionBids(auctionId: string)`
   - All other auction methods

4. **projectsApi**:
   - `getProject(id: number)` → `getProject(id: string)`
   - `getProjectsByDeveloper(developerId: number)` → `getProjectsByDeveloper(developerId: string)`
   - All other project methods

5. **salesApi**:
   - `getTeam(teamId: number)` → `getTeam(teamId: string)`
   - `getTeamMembers(teamId: number)` → `getTeamMembers(teamId: string)`
   - `getTeamStats(teamId: number)` → `getTeamStats(teamId: string)`
   - `getDeveloperTeams(developerId: number)` → `getDeveloperTeams(developerId: string)`
   - All other sales methods

6. **bidsApi**:
   - `getBidsForAuction(auctionId: number)` → `getBidsForAuction(auctionId: string)`
   - All other bid methods

## Part 3: Page Component Updates

### Update All Page Components (15+ files)

1. **PropertiesPage.tsx**:
   - Update `handleApproveProperty(propertyId: number)` → `string`
   - Update `handleRejectProperty(propertyId: number)` → `string`
   - Update `handleDeleteProperty(id: number)` → `string`
   - Update all property ID references
   - Update route parameters handling

2. **AuctionsPage.tsx**:
   - Update `auctionId: number` → `string`
   - Update `propertyId: number` → `string`
   - Update all auction ID references
   - Update bid fetching logic

3. **UsersPage.tsx**:
   - Update `handleVerifyUser(id: number)` → `string`
   - Update `handleRejectUser(id: number)` → `string`
   - Update `handleBanUser(id: number)` → `string`
   - Update `handleSuspendUser(id: number, ...)` → `string`
   - Update all user ID references

4. **ProjectsPage.tsx**:
   - Update all project ID references
   - Update create/edit/delete operations

5. **SalesPage.tsx**:
   - Update team ID references
   - Update developer ID references
   - Update member management

6. **ChatsPage.tsx**:
   - Update chat ID references
   - Update user ID references

7. **CommunitiesPage.tsx**:
   - Update community ID references
   - Update post ID references

8. **NotificationDashboardPage.tsx**:
   - Update notification ID references

9. **All other pages**:
   - Review and update ID references

## Part 4: Utility Updates

### Update Converters (utils/converters.ts)
1. Update `convertAccount` function:
   - Handle UUID strings
   - Handle account type discriminator
   - Convert roleId to string

2. Update `convertProperty` function:
   - Handle UUID strings for all IDs
   - Update nested object conversions

3. Add UUID validation helpers if needed

## Part 5: Role Constants Update

### Update ROLE_IDS (types/index.ts)
```typescript
// OLD:
export const ROLE_IDS = {
  USER: 8923748923748923,
  DEVELOPER: 7823647823647823,
  ADMIN: 9823749823749823,
} as const;

// NEW:
export const ROLE_IDS = {
  USER: "uuid-for-user-role",
  DEVELOPER: "uuid-for-developer-role",
  ADMIN: "uuid-for-admin-role",
} as const;
```

### Update Role Checks
- Update all role comparisons to use string UUIDs
- Update `currentUser.roleId === ROLE_IDS.ADMIN` checks

## Part 6: API Response Handling

### Update Response Interceptors
1. Update `api.ts` interceptors:
   - Handle UUID strings in responses
   - Update conversion logic
   - Ensure all IDs are strings

2. Update error handling:
   - Handle UUID validation errors
   - Update error messages

## Implementation Checklist

### Phase 1: Type System
- [ ] Update types/index.ts - All interfaces
- [ ] Update ROLE_IDS constants
- [ ] Update all type references

### Phase 2: API Services
- [ ] Update usersApi methods
- [ ] Update propertiesApi methods
- [ ] Update auctionsApi methods
- [ ] Update projectsApi methods
- [ ] Update salesApi methods
- [ ] Update bidsApi methods
- [ ] Update all other API methods

### Phase 3: Components
- [ ] Update PropertiesPage.tsx
- [ ] Update AuctionsPage.tsx
- [ ] Update UsersPage.tsx
- [ ] Update ProjectsPage.tsx
- [ ] Update SalesPage.tsx
- [ ] Update ChatsPage.tsx
- [ ] Update CommunitiesPage.tsx
- [ ] Update NotificationDashboardPage.tsx
- [ ] Update all other page components

### Phase 4: Utilities
- [ ] Update converters.ts
- [ ] Update any utility functions using IDs

### Phase 5: Testing
- [ ] Test all API calls
- [ ] Test all page interactions
- [ ] Verify UUID handling
- [ ] Test role-based access

## Files to Modify

### Core Files
- `src/types/index.ts` - All type definitions
- `src/services/api.ts` - All API methods
- `src/utils/converters.ts` - Type conversions

### Page Components (15+ files)
- `src/pages/PropertiesPage.tsx`
- `src/pages/AuctionsPage.tsx`
- `src/pages/UsersPage.tsx`
- `src/pages/ProjectsPage.tsx`
- `src/pages/SalesPage.tsx`
- `src/pages/ChatsPage.tsx`
- `src/pages/CommunitiesPage.tsx`
- `src/pages/NotificationDashboardPage.tsx`
- `src/pages/DashboardPage.tsx`
- `src/pages/AnalyticsPage.tsx`
- `src/pages/DevelopersPage.tsx`
- `src/pages/DocumentsPage.tsx`
- `src/pages/LeaderboardPage.tsx`
- `src/pages/NewsPage.tsx`
- `src/pages/RewardsPage.tsx`
- `src/pages/SettingsPage.tsx`
- `src/pages/ValuationPage.tsx`

### Components
- Any component files using IDs

## Notes
- All ID comparisons must use string comparison
- UUIDs are 36 characters with dashes, 32 without
- Ensure proper UUID validation in forms
- Update any hardcoded numeric IDs in tests

