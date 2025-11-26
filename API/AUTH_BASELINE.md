# Authentication Baseline (Commit `ab7996c58b71607ba9fcffa716b8a31bb979d64b`)

This file captures the controller-level authorization attributes that existed in the last known-good commit before the UUID refactor. It will be used as the reference while restoring authentication/authorization behavior.

- **Source commit:** `ab7996c58b71607ba9fcffa716b8a31bb979d64b`
- **Generated on:** 2025-11-24

## Attribute Summary Per Controller

```
== API/Controllers/AIBrokerController.cs ==
14:[Authorize]
15:[AdminAuthorize]
16:[FeaturePermission("AI Insights")]

== API/Controllers/AccountController.cs ==
16:[AllowAnonymous]
47:[AllowAnonymous]
103:[Authorize]
157:[Authorize]
214:[Authorize]
260:[Authorize]
347:[Authorize]
402:[Authorize]

== API/Controllers/AdminController.cs ==
15:[Authorize]
16:[AdminAuthorize]

== API/Controllers/AnalyticsController.cs ==
15:[Authorize]
16:[AdminAuthorize]

== API/Controllers/AuctionController.cs ==
21:[Authorize]
22:[DeveloperOrAdminAuthorize]
31:[AllowAnonymous]
71:[Authorize]
125:[Authorize]

== API/Controllers/BidsController.cs ==
15:[Authorize]

== API/Controllers/ChatController.cs ==
39:[Authorize]
40:[FeaturePermission("Chats")]

== API/Controllers/CommunityController.cs ==
17:[Authorize]
18:[FeaturePermission("Communities")]
27:[AllowAnonymous]
40:[AllowAnonymous]
63:[Authorize]
91:[Authorize]
132:[Authorize]

== API/Controllers/CommunityPostController.cs ==
17:[Authorize]
18:[FeaturePermission("Communities")]
28:[AllowAnonymous]
58:[Authorize]
90:[Authorize]
133:[Authorize]

== API/Controllers/DeveloperController.cs ==
19:[Authorize]
20:[DeveloperOrAdminAuthorize]

== API/Controllers/DeveloperPermissionController.cs ==
16:[Authorize]
17:[DeveloperOrAdminAuthorize]

== API/Controllers/DiscoveryController.cs ==
16:[AllowAnonymous]

== API/Controllers/DocumentController.cs ==
19:[Authorize]
20:[DeveloperOrAdminAuthorize]

== API/Controllers/EventController.cs ==
18:[Authorize]

== API/Controllers/FeedController.cs ==
18:[AllowAnonymous]

== API/Controllers/GoldPriceController.cs ==
16:[AllowAnonymous]

== API/Controllers/HelpChatController.cs ==
20:[Authorize]

== API/Controllers/HelpController.cs ==
16:[AllowAnonymous]

== API/Controllers/LeaderboardController.cs ==
16:[AllowAnonymous]

== API/Controllers/LiveStreamController.cs ==
20:[Authorize]
21:[FeaturePermission("Live Streams")]
30:[AllowAnonymous]
77:[AllowAnonymous]

== API/Controllers/NewsController.cs ==
18:[AllowAnonymous]
51:[Authorize]
52:[DeveloperOrAdminAuthorize]

== API/Controllers/NotificationController.cs ==
18:[Authorize]

== API/Controllers/ParentPropertyController.cs ==
18:[Authorize]
19:[DeveloperOrAdminAuthorize]

== API/Controllers/PollController.cs ==
16:[Authorize]
17:[FeaturePermission("Polls")]

== API/Controllers/PollsController.cs ==
18:[Authorize]
19:[FeaturePermission("Polls")]

== API/Controllers/PostCommentController.cs ==
17:[Authorize]
18:[FeaturePermission("Communities")]

== API/Controllers/PriceHistoryController.cs ==
20:[Authorize]
21:[DeveloperOrAdminAuthorize]

== API/Controllers/ProjectController.cs ==
21:[Authorize]
22:[DeveloperOrAdminAuthorize]
45:[AllowAnonymous]

== API/Controllers/PropertyController.cs ==
31:[Authorize]
32:[DeveloperOrAdminAuthorize]
88:[AllowAnonymous]

== API/Controllers/ReactionController.cs ==
17:[Authorize]
18:[FeaturePermission("Communities")]

== API/Controllers/RedemptionController.cs ==
17:[Authorize]

== API/Controllers/SalesTeamController.cs ==
17:[Authorize]
18:[AdminAuthorize]

== API/Controllers/ValuationController.cs ==
22:[Authorize]
23:[FeaturePermission("Valuations")]
44:[AllowAnonymous]
```

> **Note:** Public/anonymous endpoints (e.g., discovery, feed, listings, FAQs) must remain accessible without authentication.







