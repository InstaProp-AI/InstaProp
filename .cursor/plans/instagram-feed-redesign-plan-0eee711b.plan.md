<!-- 0eee711b-e3e3-45c3-b1df-ac2570d44008 7dd9dbe9-f353-4bf7-969b-730c9fb8670d -->
# Complete Missing Backend Endpoints and Frontend Integration

## Problem

Many post interaction endpoints are missing from the backend, causing frontend features to fail:

- Post bookmark/save - Model exists but no endpoint
- Post share - No endpoint exists
- Post delete - Frontend service exists but endpoint missing
- Post update/edit - Frontend service exists but endpoint missing  
- Post report - No functionality at all
- Comment endpoints may be incomplete

## Missing Endpoints to Implement

### 1. Post Bookmark/Save Endpoints

**Backend**: `API/Controllers/CommunityPostController.cs`

- `POST /api/posts/{postId}/bookmark` - Toggle bookmark
- `GET /api/posts/{postId}/bookmark/status` - Check if bookmarked
- `GET /api/posts/bookmarked` - Get user's bookmarked posts

### 2. Post Share Endpoint

**Backend**: `API/Controllers/CommunityPostController.cs`

- `POST /api/posts/{postId}/share` - Share post to another community

### 3. Post Delete Endpoint

**Backend**: `API/Controllers/CommunityPostController.cs`

- `DELETE /api/posts/{postId}` - Delete post (author only, with proper checks)

### 4. Post Update/Edit Endpoint

**Backend**: `API/Controllers/CommunityPostController.cs`

- `PUT /api/posts/{postId}` - Update post content/image (author only)

### 5. Post Report Endpoint

**Backend**: Create `API/Controllers/ReportController.cs` or add to CommunityPostController

- `POST /api/posts/{postId}/report` - Report post with reason

### 6. Verify/Comment Endpoints

**Backend**: Check `PostCommentController.cs` has all needed endpoints

- Verify comment creation, update, delete, like all work
- Ensure proper authorization checks

## Frontend Service Updates Needed

### 1. Update `community_post_service.dart`

- Add `toggleBookmark(postId)` method
- Add `getBookmarkStatus(postId)` method  
- Add `getBookmarkedPosts()` method
- Add `sharePost(postId, targetCommunityId)` method
- Verify `deletePost(postId)` connects to correct endpoint
- Verify `updatePost()` connects to correct endpoint

### 2. Update `post_card.dart`

- Connect save/bookmark button to service
- Connect share button to service with community selector
- Connect three dots menu delete to service
- Add report functionality to three dots menu

### 3. Fix Reaction Service

- Ensure it properly handles both PostLike and PostReaction
- Verify remove/add work correctly

## Implementation Details

### Post Bookmark Endpoint

```csharp
[HttpPost("{postId}/bookmark")]
[Authorize]
public async Task<ActionResult> ToggleBookmark(long postId)
{
    // Check if bookmark exists
    // Toggle: Add if not exists, remove if exists
    // Return bookmark status
}
```

### Post Share Endpoint

```csharp
[HttpPost("{postId}/share")]
[Authorize]
public async Task<ActionResult> SharePost(long postId, [FromBody] SharePostDto dto)
{
    // Verify user is member of target community
    // Create shared post or reference
    // Notify original author (optional)
}
```

### Post Delete Endpoint

```csharp
[HttpDelete("{postId}")]
[Authorize]
public async Task<ActionResult> DeletePost(long postId)
{
    // Verify user is author
    // Check if post has important replies (optional warning)
    // Soft delete or hard delete
    // Update community post count
}
```

### Post Update Endpoint  

```csharp
[HttpPut("{postId}")]
[Authorize]
public async Task<ActionResult> UpdatePost(long postId, [FromBody] UpdatePostDto dto)
{
    // Verify user is author
    // Update content and/or image
    // Update UpdatedAt timestamp
}
```

### Post Report Endpoint

```csharp
[HttpPost("{postId}/report")]
[Authorize]
public async Task<ActionResult> ReportPost(long postId, [FromBody] ReportPostDto dto)
{
    // Create report record
    // Notify moderators/admins
    // Optional: Auto-hide if multiple reports
}
```

## Security & Aut