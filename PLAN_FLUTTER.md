# Flutter App Migration Plan

## Overview
Complete migration of the Flutter/Dart mobile app to work with UUID-based backend and updated account structure.

## Part 1: Model Updates (207 files)

### Update All Model Classes
Change all ID fields from `int` to `String`:

1. **User/Account Models**:
   - `lib/models/user.dart`: `accountId: int` → `String`
   - `lib/models/user.dart`: `roleId: int` → `String`
   - Update all account-related models

2. **Property Models**:
   - `lib/models/property.dart`: `propertyId: int` → `String`
   - `lib/models/child_property.dart`: `propertyId: int` → `String`
   - `lib/models/parent_property.dart`: `parentPropertyId: int` → `String`
   - `lib/models/property_image.dart`: `propertyImageId: int` → `String`
   - `lib/models/property_doc.dart`: `docId: int` → `String`

3. **Auction Models**:
   - `lib/models/auction.dart`: `auctionId: int` → `String`
   - `lib/models/auction.dart`: `propertyId: int` → `String`
   - `lib/models/bid.dart`: `bidId: int` → `String`
   - `lib/models/bid.dart`: `auctionId: int` → `String`

4. **Project Models**:
   - `lib/models/project.dart`: `projectId: int` → `String`
   - `lib/models/project.dart`: `developerId: int` → `String`

5. **Community Models**:
   - `lib/models/community.dart`: `communityId: int` → `String`
   - `lib/models/community_post.dart`: `postId: int` → `String`
   - `lib/models/post_comment.dart`: `commentId: int` → `String`

6. **Chat Models**:
   - `lib/models/chat.dart`: `chatId: int` → `String`
   - `lib/models/chat_message.dart`: `messageId: int` → `String`

7. **Event Models**:
   - `lib/models/event.dart`: `eventId: int` → `String`

8. **All Other Models**:
   - Review all 207 model files
   - Update all ID fields to `String`
   - Update all foreign key references

### Update JSON Serialization
1. **Update fromJson methods**:
   - Change `json['id'] as int` → `json['id'] as String`
   - Handle UUID string parsing
   - Add null safety checks

2. **Update toJson methods**:
   - Ensure IDs are serialized as strings
   - Handle null IDs properly

3. **Update factory constructors**:
   - Change ID parameter types
   - Update type assertions

## Part 2: API Service Updates

### Update All API Service Files
1. **Update HTTP methods**:
   - Change URL parameters from `/$id` where id is int
   - Ensure UUID strings are properly encoded in URLs
   - Update query parameters

2. **Update request/response handling**:
   - Update DTOs to use String IDs
   - Update request body serialization
   - Update response parsing

3. **Update error handling**:
   - Handle UUID validation errors
   - Update error messages

### Specific Service Files to Update
- `lib/services/api_service.dart`
- `lib/services/auth_service.dart`
- `lib/services/property_service.dart`
- `lib/services/auction_service.dart`
- `lib/services/project_service.dart`
- `lib/services/community_service.dart`
- `lib/services/chat_service.dart`
- All other service files

## Part 3: Screen/Page Updates

### Update All Screen Files
1. **Navigation**:
   - Update route parameters to use String IDs
   - Update deep linking with UUIDs
   - Update navigation arguments

2. **Data Display**:
   - Update ID display (if shown to users)
   - Update list item keys
   - Update detail page IDs

3. **Forms**:
   - Update form field types
   - Update validation for UUIDs
   - Update form submission

### Specific Screens to Update
- All property-related screens
- All auction-related screens
- All user/profile screens
- All project screens
- All community screens
- All chat screens
- All settings screens

## Part 4: State Management Updates

### Update State Classes
1. **Update state models**:
   - Change ID fields to String
   - Update state initialization
   - Update state updates

2. **Update providers/bloc**:
   - Update event classes (if using BLoC)
   - Update state classes
   - Update reducer logic

3. **Update repositories**:
   - Update repository interfaces
   - Update repository implementations

## Part 5: Database/Local Storage Updates

### Update Local Database (if applicable)
1. **Update schema**:
   - Change ID columns to TEXT/VARCHAR
   - Update foreign key constraints
   - Update indexes

2. **Update migrations**:
   - Create migration for ID type change
   - Update seed data

3. **Update queries**:
   - Update SQL queries
   - Update ORM queries (if using)

## Part 6: Constants and Configuration

### Update Constants
1. **Role IDs**:
   - Update role ID constants to UUID strings
   - Update role checks throughout app

2. **API Endpoints**:
   - Ensure endpoints handle UUID strings
   - Update endpoint builders

3. **Validation**:
   - Add UUID validation helpers
   - Update input validators

## Implementation Checklist

### Phase 1: Models
- [ ] Update user.dart
- [ ] Update property.dart
- [ ] Update child_property.dart
- [ ] Update parent_property.dart
- [ ] Update auction.dart
- [ ] Update bid.dart
- [ ] Update project.dart
- [ ] Update community.dart
- [ ] Update all other model files (207 total)

### Phase 2: Services
- [ ] Update api_service.dart
- [ ] Update auth_service.dart
- [ ] Update property_service.dart
- [ ] Update auction_service.dart
- [ ] Update all other service files

### Phase 3: Screens
- [ ] Update all property screens
- [ ] Update all auction screens
- [ ] Update all user screens
- [ ] Update all project screens
- [ ] Update all community screens
- [ ] Update all other screens

### Phase 4: State Management
- [ ] Update state classes
- [ ] Update providers/bloc
- [ ] Update repositories

### Phase 5: Utilities
- [ ] Update constants
- [ ] Update validators
- [ ] Update helpers

### Phase 6: Testing
- [ ] Test all API calls
- [ ] Test navigation
- [ ] Test forms
- [ ] Test data persistence

## Files to Modify

### Models (207 files)
- `lib/models/user.dart`
- `lib/models/property.dart`
- `lib/models/child_property.dart`
- `lib/models/parent_property.dart`
- `lib/models/auction.dart`
- `lib/models/bid.dart`
- `lib/models/project.dart`
- `lib/models/community.dart`
- `lib/models/community_post.dart`
- `lib/models/post_comment.dart`
- `lib/models/chat.dart`
- `lib/models/chat_message.dart`
- `lib/models/event.dart`
- ... (all 207 model files)

### Services
- All service files in `lib/services/`

### Screens
- All screen files in `lib/screens/` or `lib/pages/`

### State Management
- All state management files

### Utilities
- Constants files
- Validator files
- Helper files

## Notes
- UUIDs are 36 characters with dashes in JSON
- Use `String` type for all IDs in Dart
- Ensure proper null safety
- Update all JSON serialization
- Test thoroughly on both iOS and Android
- Update any hardcoded numeric IDs in tests

