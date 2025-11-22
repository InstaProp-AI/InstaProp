<!-- 1302dbc9-8c78-4ab5-b7b7-42be84321a0b 2a6aad26-1ce0-4809-81ce-cdeb72b5d778 -->
# Communities Page Enhancement and Permissions System

## Overview

Enhance the Communities page with full functionality including detail views, member management, post management, analytics, and implement a comprehensive permission system for developers to control community access and actions.

## Part 1: Community Detail Page

### 1.1 Create Community Detail Page Component

- **File**: `dashboard/src/pages/CommunityDetailPage.tsx`
- **Features**:
- Full-page detail view (similar to Sales team detail page)
- Dashboard-style layout with statistics cards at top
- Sections for Posts, Members, and Analytics
- Navigation breadcrumbs (Communities > [Community Name])
- Back button to return to communities list

### 1.2 Update CommunitiesPage

- **File**: `dashboard/src/pages/CommunitiesPage.tsx`
- **Changes**:
- Make community cards clickable
- Navigate to detail page on click
- Add hover effects and better visual feedback
- Display community cover images if available

### 1.3 Add API Functions

- **File**: `dashboard/src/services/api.ts`
- **New functions**:
- `getCommunityMembers(communityId)` - Get members list
- `getCommunityStats(communityId)` - Get statistics
- `getCommunityPosts(communityId, page, pageSize)` - Get posts with pagination
- `inviteMemberByEmail(communityId, email)` - Invite by email
- `inviteMemberByUserId(communityId, userId)` - Invite existing user
- `removeMember(communityId, userId)` - Remove member
- `createPost(communityId, data)` - Create post
- `updatePost(postId, data)` - Update post
- `deletePost(postId)` - Delete post

## Part 2: Community Detail Page Sections

### 2.1 Statistics Dashboard Section

- **Location**: Top of CommunityDetailPage
- **Display**:
- Member count card
- Post count card
- New members this month
- Active members count
- Activity rate percentage
- Property count (if project-based)
- Total property value (if applicable)
- Charts: Member growth over time, Post activity timeline

### 2.2 Posts Section

- **Features**:
- List/grid view toggle
- Pagination
- Create new post button (opens modal)
- Post cards showing: author, content, images, likes, comments, reactions
- Edit/Delete buttons on own posts
- Filter by date, author, or search
- Sort by newest, most liked, most commented

### 2.3 Members Section

- **Features**:
- Member list with avatars, names, roles, join date
- Search/filter members
- Invite member button (opens modal)
- Remove member action (for moderators/admins)
- Role badges (Creator, Moderator, Member)
- Member statistics (posts count, comments count)

### 2.4 Modals

- **Create Post Modal**: Form with content, image upload, categories
- **Edit Post Modal**: Pre-filled form for editing
- **Invite Member Modal**: 
- Tab 1: Search existing users by email/name
- Tab 2: Invite by email (for non-users)
- Display pending invitations

## Part 3: Backend - Community Permissions System

### 3.1 Create CommunityPermission Model

- **File**: `API/Models/CommunityPermission.cs`
- **Properties**:
- `PermissionId` (long, primary key)
- `DeveloperId` (long, foreign key to Account)
- `CommunityId` (long, foreign key to Community)
- `CanViewPosts` (bool)
- `CanCreatePosts` (bool)
- `CanEditPosts` (bool)
- `CanDeletePosts` (bool)
- `CanViewMembers` (bool)
- `CanInviteMembers` (bool)
- `CanRemoveMembers` (bool)
- `CanManageCommunity` (bool) - Full admin access
- `CreatedAt` (DateTime)
- `UpdatedAt` (DateTime?)

### 3.2 Update AppDbContext

- **File**: `API/Data/AppDbContext.cs`
- **Changes**:
- Add `DbSet<CommunityPermission> CommunityPermissions`
- Configure entity relationships and indexes
- Add unique constraint on (DeveloperId, CommunityId)

### 3.3 Create Migration

- **Command**: `dotnet ef migrations add AddCommunityPermissions`
- **Apply**: `dotnet ef database update`

### 3.4 Create CommunityPermissionController

- **File**: `API/Controllers/CommunityPermissionController.cs`
- **Endpoints**:
- `GET /api/admin/developers/{developerId}/community-permissions` - Get all community permissions for a developer
- `PUT /api/admin/developers/{developerId}/community-permissions` - Update community permissions for a developer
- `GET /api/admin/communities/{communityId}/permissions` - Get all developer permissions for a community
- `POST /api/admin/community-permissions` - Create new permission assignment
- `DELETE /api/admin/community-permissions/{id}` - Remove permission assignment

### 3.5 Update CommunityController

- **File**: `API/Controllers/CommunityController.cs`
- **Changes**:
- Filter communities in `GetCommunities()` based on developer permissions
- Add permission checks in all community actions:
- `GetCommunityPosts()` - Check `CanViewPosts`
- `CreatePost()` - Check `CanCreatePosts`
- `UpdatePost()` - Check `CanEditPosts` or allow if own post
- `DeletePost()` - Check `CanDeletePosts` or allow if own post
- `GetCommunityMembers()` - Check `CanViewMembers`
- `InviteMember()` - Check `CanInviteMembers`
- `RemoveMember()` - Check `CanRemoveMembers`
- Helper method: `CheckCommunityPermission(long developerId, long communityId, string permission)`

### 3.6 Permission Helper Service

- **File**: `API/Services/CommunityPermissionService.cs`
- **Methods**:
- `GetDeveloperCommunityPermissions(long developerId)` - Get all permissions
- `HasPermission(long developerId, long communityId, string permission)` - Check specific permission
- `GetAccessibleCommunityIds(long developerId)` - Get list of community IDs developer can access

## Part 4: Frontend - Permissions Management UI

### 4.1 Update DevelopersPage

- **File**: `dashboard/src/pages/DevelopersPage.tsx`
- **Changes**:
- Add "Community" tab alongside existing "Permissions" tab
- Community tab shows:
- List of all communities
- For each community, checkboxes for permissions:
- View Posts
- Create Posts
- Edit Posts
- Delete Posts
- View Members
- Invite Members
- Remove Members
- Manage Community (full access)
- Save button to update all community permissions for selected developer

### 4.2 Add API Functions for Permissions

- **File**: `dashboard/src/services/api.ts`
- **New functions**:
- `getDeveloperCommunityPermissions(developerId)` - Get permissions
- `updateDeveloperCommunityPermissions(developerId, permissions)` - Update permissions
- `getCommunityDeveloperPermissions(communityId)` - Get all developers with permissions for a community

### 4.3 Add TypeScript Types

- **File**: `dashboard/src/types/index.ts`
- **New interfaces**:
- `CommunityPermission`
- `CommunityPermissionUpdate`
- `DeveloperCommunityPermissions`

## Part 5: Permission Enforcement

### 5.1 Update Community Detail Page

- **File**: `dashboard/src/pages/CommunityDetailPage.tsx`
- **Changes**:
- Check permissions before showing action buttons
- Hide/disable features based on permissions
- Show permission-denied messages when needed
- Fetch developer's permissions on page load

### 5.2 Update Community API Calls

- **File**: `dashboard/src/services/api.ts`
- **Changes**:
- All community actions should handle 403 Forbidden responses
- Show appropriate error messages for permission denials

## Implementation Order

1. **Phase 1**: Backend permission system (Models, Migration, Controller, Service)
2. **Phase 2**: Update CommunityController with permission checks
3. **Phase 3**: Frontend permissions management UI (DevelopersPage Community tab)
4. **Phase 4**: Community detail page (statistics, posts, members sections)
5. **Phase 5**: Permission enforcement in frontend (hide/disable based on permissions)
6. **Phase 6**: Testing and refinement

## Key Files to Modify

**Backend**:

- `API/Models/CommunityPermission.cs` (new)
- `API/Data/AppDbContext.cs`
- `API/Controllers/CommunityPermissionController.cs` (new)
- `API/Controllers/CommunityController.cs`
- `API/Services/CommunityPermissionService.cs` (new)

**Frontend**:

- `dashboard/src/pages/CommunitiesPage.tsx`
- `dashboard/src/pages/CommunityDetailPage.tsx` (new)
- `dashboard/src/pages/DevelopersPage.tsx`
- `dashboard/src/services/api.ts`
- `dashboard/src/types/index.ts`

### To-dos

- [ ] Update api.ts to send 'Permissions' (capital P) instead of 'permissions' in the updateDeveloperPermissions function