# Property Flipper Backend Documentation

## Overview

The Property Flipper backend is built with **.NET Core 8.0** using a **RESTful API** architecture. It provides a comprehensive real estate auction platform with real-time updates via **Firebase Firestore** and **FCM push notifications**.

## Architecture

### Technology Stack
- **Framework**: ASP.NET Core 8.0
- **Database**: SQLite (Development) / PostgreSQL (Production Ready)
- **Real-time**: Firebase Firestore
- **Authentication**: JWT Bearer Tokens
- **Notifications**: Firebase Cloud Messaging (FCM)
- **File Storage**: ImgBB (Images)
- **Email**: SMTP

### Project Structure
```
API/
├── Controllers/          # API endpoints (15 controllers)
├── Services/            # Business logic (17 services)
├── Models/              # Data models and entities
├── Data/                # Database context
├── Migrations/          # EF Core migrations
├── Middleware/          # Custom middleware
├── Attributes/          # Custom attributes
└── wwwroot/uploads/     # Static file storage
```

## Database Schema

### Core Entities

#### Account
User account with authentication and verification.
```csharp
- AccountId (PK)
- FirstName, LastName
- Email, PhoneNumber
- Type (User=0, Developer=1, Admin=2)
- HashedPassword (nullable for OAuth)
- GoogleId, AuthProvider
- Status (NotVerified=0, Pending=1, Verified=2)
- EmailVerified, PhoneVerified
- EmailVerificationPin, PhoneVerificationPin
- CreatedAt, UpdatedAt
```

#### Property
Real estate property listing.
```csharp
- PropertyId (PK)
- OwnerId (FK -> Account)
- ProjectId (FK -> Project, nullable)
- Name, Description, Location
- Type (Resale=0, Primary=1)
- Status (NotApproved=0, Pending=1, Approved=2)
- Bedrooms, Bathrooms, SquareFeet, YearBuilt
- Category
- ImageUrl
- CreatedAt, UpdatedAt
Relations: PropertyImages[], PropertyDocs[], Auctions[]
```

#### Auction
Property auction with bidding.
```csharp
- AuctionId (PK)
- PropertyId (FK -> Property)
- StartPrice, CurrentPrice
- BuyNowPrice (nullable)
- StartAt, Duration (hours)
- Status (Requested, Active, Cancelled, Sold)
- BidCount
- CreatedAt
Relations: Bids[]
```

#### Bid
Bid placed on an auction.
```csharp
- BidId (PK)
- AuctionId (FK -> Auction)
- BidderId (FK -> Account)
- BidAmount
- CreatedAt
```

#### Project
Developer project containing multiple properties.
```csharp
- ProjectId (PK)
- DeveloperId (FK -> Account)
- Name, Description, Location
- Status, Budget, StartDate, EndDate
- CreatedAt, UpdatedAt
Relations: Properties[], ProjectMilestones[], ProjectUpdates[]
```

#### Chat & Messages
```csharp
Chat:
- ChatId (PK)
- User1Id, User2Id (FK -> Account)
- LastMessageAt, CreatedAt

ChatMessage:
- MessageId (PK)
- ChatId (FK -> Chat)
- SenderId (FK -> Account)
- MessageText
- IsRead, CreatedAt
```

#### Notifications
```csharp
- NotificationId (PK)
- UserId (FK -> Account)
- Title, Message
- Type (enum)
- AuctionId, PropertyId (nullable references)
- IsRead
- CreatedAt
```

#### Gamification Entities
```csharp
UserReward:
- RewardId, UserId
- RewardType, Points, Description

UserBadge:
- BadgeId, UserId
- BadgeType, EarnedAt

Referral:
- ReferralId
- ReferrerId, ReferredId
- RewardClaimed

SavedSearch:
- SearchId, UserId
- SearchCriteria, CreatedAt

PropertyView:
- ViewId
- PropertyId, UserId, ViewedAt
```

## API Endpoints

### Authentication & Account Management

#### AccountController (`/api/Account`)

**POST /signup**
- Register new user account
- Body: `{ firstName, lastName, phoneNumber, email, password }`
- Returns: Account object

**POST /login**
- Authenticate user
- Body: `{ email, password }`
- Returns: `{ token, account }`

**POST /google-signin**
- OAuth Google sign-in
- Body: `{ googleId, email, firstName, lastName, photoUrl }`
- Returns: `{ token, account }`

**GET /current** 🔒
- Get current authenticated user
- Returns: Account object

**POST /verify-email**
- Verify email with PIN
- Body: `{ email, pin }`

**POST /verify-phone**
- Verify phone with PIN
- Body: `{ phoneNumber, pin }`

**POST /resend-email-pin**
- Resend email verification PIN

**POST /resend-phone-pin**
- Resend phone verification PIN

**POST /forgot-password**
- Request password reset
- Body: `{ email }`

**POST /change-password** 🔒
- Change user password
- Body: `{ currentPassword, newPassword }`

### Property Management

#### PropertyController (`/api/Property`)

**GET /**
- Get all approved properties (public)
- Returns: Property[]

**GET /my-properties** 🔒
- Get properties owned by current user
- Returns: Property[]

**GET /{id}**
- Get property by ID (public)
- Returns: Property

**POST /** 🔒
- Create new property
- Body: Property object
- Returns: Property

**PUT /{id}** 🔒
- Update property (owner only)
- Body: Property object

**DELETE /{id}** 🔒
- Delete property (owner only)

**POST /upload-image** 🔒
- Upload property images (multipart/form-data)
- Files: images[]
- Fields: propertyId
- Returns: `{ propertyImages }`

### Auction Management

#### AuctionController (`/api/Auction`)

**GET /**
- Get all auctions (public)
- Returns: AuctionDto[]

**GET /active**
- Get active auctions only (public)
- Returns: AuctionDto[]

**GET /{id}**
- Get auction details (public)
- Returns: AuctionDto

**POST /request** 🔒
- Request auction for owned property
- Body: `{ propertyId, startPrice, startAt, duration, buyNowPrice? }`
- Returns: `{ message, auctionId }`

**POST /** 🔒👑
- Create auction directly (Admin only)
- Body: CreateAuctionDto
- Returns: Auction

**PUT /{id}/status** 🔒👑
- Approve/Reject auction request (Admin only)
- Body: `{ status: "Approved" | "Rejected" }`

**POST /{id}/relist** 🔒👑
- Relist ended auction (Admin only)
- Body: `{ startAt?, duration, resetPrice, resetBids }`

**POST /{id}/buynow** 🔒
- Purchase auction using Buy Now price
- Returns: `{ message, auctionId, purchasePrice, propertyName }`

**GET /requests** 🔒👑
- Get pending auction requests (Admin only)
- Returns: AuctionDto[]

### Bidding

#### BidsController (`/api/Bids`)

**POST /place** 🔒
- Place bid on auction
- Body: `{ auctionId, bidAmount }`
- Returns: `{ message, bid }`

**GET /user** 🔒
- Get bids placed by current user
- Returns: Bid[]

**GET /auction/{auctionId}**
- Get all bids for an auction (public)
- Returns: Bid[]

### Chat System

#### ChatController (`/api/Chat`)

**POST /create** 🔒
- Create or get existing chat
- Body: `{ otherUserId }`
- Returns: Chat

**GET /** 🔒
- Get all chats for current user
- Returns: Chat[]

**GET /{id}** 🔒
- Get chat by ID
- Returns: Chat

**GET /{chatId}/messages** 🔒
- Get messages in a chat
- Returns: ChatMessage[]

**POST /{chatId}/send** 🔒
- Send message in chat
- Body: `{ messageText }`
- Returns: ChatMessage

### Developer Features

#### DeveloperController (`/api/Developer`)

**POST /create-profile** 🔒
- Create developer profile
- Body: `{ companyName, description, website, phoneNumber }`
- Returns: DeveloperProfile

**GET /**
- Get all developer profiles (public)
- Returns: DeveloperProfile[]

**GET /{id}**
- Get developer profile by ID (public)
- Returns: DeveloperProfile with ratings

**POST /{id}/rate** 🔒
- Rate a developer
- Body: `{ rating (1-5), comment }`
- Returns: DeveloperRating

### Project Management

#### ProjectController (`/api/Project`)

**POST /** 🔒
- Create new project (Developer only)
- Body: Project object
- Returns: Project

**GET /**
- Get all projects (public)
- Returns: Project[]

**GET /{id}**
- Get project details (public)
- Returns: Project with properties and milestones

**PUT /{id}** 🔒
- Update project (owner only)
- Body: Project object

**POST /{id}/milestones** 🔒
- Add milestone to project
- Body: ProjectMilestone
- Returns: ProjectMilestone

**POST /{id}/updates** 🔒
- Add update to project
- Body: ProjectUpdate
- Returns: ProjectUpdate

### Notifications

#### NotificationController (`/api/Notification`)

**GET /** 🔒
- Get notifications for current user
- Returns: Notification[]

**PUT /{id}/read** 🔒
- Mark notification as read

**PUT /read-all** 🔒
- Mark all notifications as read

**DELETE /{id}** 🔒
- Delete notification

**POST /send** 🔒👑
- Send notification (Admin only)
- Body: `{ userId, title, message, type }`

### Dashboard & Analytics

#### DashboardController (`/api/Dashboard`)

**GET /public-stats**
- Get public dashboard statistics
- Returns: `{ activeAuctionsCount, totalPropertiesCount, totalUsersCount }`

**GET /user-stats** 🔒
- Get user-specific statistics
- Returns: User stats

**GET /admin-stats** 🔒👑
- Get admin dashboard statistics (Admin only)
- Returns: Comprehensive stats

### Events

#### EventController (`/api/Event`)

**GET /**
- Get all events (public)
- Returns: Event[]

**POST /** 🔒
- Create event
- Body: Event object
- Returns: Event

**GET /{id}**
- Get event details
- Returns: Event

**PUT /{id}** 🔒
- Update event (creator only)

**DELETE /{id}** 🔒
- Delete event (creator only)

### Documents & KYC

#### DocumentController (`/api/Document`)

**POST /upload-kyc** 🔒
- Upload KYC document
- Files: document (multipart)

**POST /upload-property** 🔒
- Upload property document
- Files: document
- Fields: propertyId

**POST /upload-user** 🔒
- Upload user document
- Files: document

### Valuation

#### ValuationController (`/api/Valuation`)

**POST /valuate**
- Get property valuation estimate
- Body: `{ location, bedrooms, bathrooms, squareFeet, yearBuilt }`
- Returns: `{ estimatedValue, confidence }`

## Services Layer

### Core Services

#### AuthService (Implicit in AccountController)
- JWT token generation and validation
- Password hashing (BCrypt)
- Session management

#### EmailVerificationService
- Generate and send verification PINs
- Validate PINs
- Expiry management (5 minutes)

#### PhoneVerificationService
- SMS verification (Twilio integration ready)
- PIN generation and validation

#### SmtpEmailService
- Send emails via SMTP
- Configurable SMTP settings

#### EmailTemplateService
- HTML email templates
- Welcome emails
- Verification emails
- Password reset emails

### Auction Services

#### AuctionNotificationService
- Notify users about new auctions
- Auction status updates
- Winner notifications

#### AuctionExpirationService (Background Service)
- Monitors auction end times
- Auto-closes expired auctions
- Notifies auction winners
- Runs every 5 minutes

### Notification Services

#### NotificationService
- Create and manage in-app notifications
- Notification types (Auction, Bid, Chat, System)

#### NotificationHelperService
- Helper methods for notifications
- Notification formatting

#### FcmPushNotificationService
- Send Firebase Cloud Messages
- Topic-based messaging
- Direct device messaging

#### NotificationCleanupService (Background Service)
- Delete old notifications (90+ days)
- Runs daily at 2 AM

### Firebase Integration

#### FirestoreService
- Real-time data synchronization
- Auction updates to Firestore
- Bid updates to Firestore
- Notification streaming
- Chat message sync

### Chat Services

#### ChatCleanupService (Background Service)
- Mark old messages as inactive
- Runs daily at 3 AM

### Gamification

#### RewardService
- Award points for actions
- Badge management
- Referral tracking

### File Management

#### FileValidationService
- Validate file uploads
- Size and type checking
- Security validation

#### ImgBBService
- Upload images to ImgBB
- Get public image URLs
- Image hosting

### Error Tracking

#### ErrorTrackingService
- Log errors to file
- Error analytics
- Debug information

## Middleware

### ErrorHandlingMiddleware
- Global exception handling
- Consistent error responses
- Error logging

### RateLimitingMiddleware
- Request throttling
- DDoS protection
- Configurable limits

## Authentication & Authorization

### JWT Authentication
```
Header: Authorization: Bearer {token}
```

Claims included:
- `uid`: Account ID
- `email`: User email
- `type`: Account type (0=User, 1=Developer, 2=Admin)

### Authorization Levels
- 🔒 **Authenticated**: Requires valid JWT token
- 👑 **Admin**: Requires JWT token with AccountType.Admin

### AdminAuthorizeAttribute
Custom attribute for admin-only endpoints.
```csharp
[Authorize]
[AdminAuthorize]
public async Task<IActionResult> AdminOnlyEndpoint()
```

## Firebase Integration

### Firestore Collections

**auctions**
- Real-time auction data
- Synced on create/update/bid

**bids/{auctionId}/bids**
- Real-time bid updates per auction

**notifications/{userId}/notifications**
- User-specific notification stream

**chats/{chatId}/messages**
- Real-time chat messages

### FCM Topics
- `all_users`: Broadcast to all
- `new_auctions`: New auction alerts
- `auction_updates`: Auction status changes

## Configuration

### appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=mydb.db"
  },
  "Jwt": {
    "Key": "your-secret-key-min-32-chars",
    "Issuer": "PropertyFlipperAPI",
    "Audience": "PropertyFlipperApp"
  },
  "Smtp": {
    "Host": "smtp.gmail.com",
    "Port": 587,
    "Username": "your-email",
    "Password": "app-password",
    "FromEmail": "noreply@propertyflipper.com",
    "FromName": "Property Flipper"
  },
  "Firebase": {
    "ProjectId": "your-project-id",
    "ServerKey": "your-fcm-server-key"
  },
  "ImgBB": {
    "ApiKey": "your-imgbb-api-key"
  }
}
```

### Environment Variables
- Use `appsettings.Production.json` for production
- Store sensitive keys in Azure Key Vault or similar

## Background Services

### Registered Hosted Services
1. **AuctionExpirationService**
   - Interval: 5 minutes
   - Monitors and closes expired auctions

2. **NotificationCleanupService**
   - Interval: Daily at 2 AM
   - Removes notifications older than 90 days

3. **ChatCleanupService**
   - Interval: Daily at 3 AM
   - Archives old chat messages

## Error Handling

### Standard Error Response
```json
{
  "success": false,
  "error": "Error message",
  "statusCode": 400
}
```

### Common Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `500`: Internal Server Error

## Deployment

### Prerequisites
- .NET 8.0 SDK
- SQLite (dev) or PostgreSQL (prod)
- Firebase project with Firestore and FCM
- SMTP server access
- ImgBB API key (optional)

### Setup Steps
1. Clone repository
2. Update `appsettings.json` with your credentials
3. Add `firebase-credentials.json` to API root
4. Run migrations: `dotnet ef database update`
5. Run: `dotnet run`

### Production Checklist
- ✅ Switch to PostgreSQL
- ✅ Enable HTTPS
- ✅ Configure CORS for your domain
- ✅ Set secure JWT key (32+ chars)
- ✅ Enable rate limiting
- ✅ Set up error monitoring
- ✅ Configure backup strategy
- ✅ Set up CI/CD pipeline
- ✅ Enable health checks monitoring

## API Testing

### Swagger UI
Available at: `http://localhost:5000/swagger` (Development only)

### Health Check
```
GET /health
Returns: Healthy/Unhealthy
```

## Performance Considerations

- Firestore sync is async and doesn't block API responses
- Background services run on separate threads
- Database queries use EF Core with eager loading
- JWT validation is fast (in-memory)
- File uploads are streamed to prevent memory issues

## Security Best Practices

1. **Authentication**: JWT tokens with expiration
2. **Password Hashing**: BCrypt with salt
3. **SQL Injection**: EF Core parameterized queries
4. **XSS**: Input validation and sanitization
5. **CORS**: Restricted origins in production
6. **Rate Limiting**: Prevent abuse
7. **File Upload**: Type and size validation
8. **HTTPS**: Enforced in production

## Support & Maintenance

### Logging
- Errors logged to `api.log`
- Console logging in development
- Structured logging recommended for production

### Monitoring
- Health check endpoint: `/health`
- Background service status in logs
- Firebase sync status in logs

## Version History

**Version 2.0.0** (Current)
- Feature-complete auction platform
- Real-time updates via Firestore
- Chat system with real-time messaging
- Developer profiles and project management
- Gamification (rewards, badges, referrals)
- KYC verification system
- Property comparison and valuation
- Admin dashboard
- Multi-platform support (Web, iOS, Android)

---

**Documentation Last Updated**: October 14, 2025
**API Version**: 2.0.0
**Framework**: .NET Core 8.0




