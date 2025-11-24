# Auth Gaps After UUID Refactor

Comparison against the baseline in `AUTH_BASELINE.md` reveals the following discrepancies that must be fixed:

| Controller | Baseline Expectation | Current Issue (identified during audit) | Status |
| --- | --- | --- | --- |
| `AccountController` | Mix of `[AllowAnonymous]` (login/signup/check endpoints) with `[Authorize]` for account management. | Controller lost the class-level guard; all endpoints were anonymous. | ✅ Restored `[Authorize]` at class level and re-added `[AllowAnonymous]` to public endpoints. |
| `AIBrokerController` | `[Authorize]` + `[AdminAuthorize]` + `[FeaturePermission("AI Insights")]`. | Controller only used `[Authorize]`, letting any authenticated user access AI broker. | ✅ Reinstated admin + feature guards. |
| `AnalyticsController` | Admin-only. | No authorization attributes. | ✅ Added `[Authorize][AdminAuthorize]`. |
| `DashboardController` | Public summary plus admin-only stats. | Admin stats endpoints were anonymous. | ✅ Added explicit `[Authorize][AdminAuthorize]` to protected endpoints (analytics/stats) while keeping public stats open. |
| `DeveloperController` | Developer/admin only except profile lookup. | Class lacked auth attributes, exposing sensitive actions. | ✅ Added `[Authorize][DeveloperOrAdminAuthorize]` + `[AllowAnonymous]` on the public profile route. |
| `DeveloperPermissionController` | Developer/admin only. | Only `[Authorize]`, so any user could access developer permission APIs. | ✅ Added `[DeveloperOrAdminAuthorize]` at class level. |
| `DiscoveryController` | Public discovery/search. | Mixed `[Authorize]` and anonymous logic after community removal. | ✅ Made controller explicitly `[AllowAnonymous]` and removed leftover `[Authorize]`. |
| `FeedController`, `GoldPriceController`, `HelpController` | Intended to stay public. | Missing explicit `[AllowAnonymous]` which led to confusion and future regressions. | ✅ Added `[AllowAnonymous]` (with necessary `using`) to document intent. |
| `ParentPropertyController` | Public browsing, restricted creation. | `find-or-create` endpoint was anonymous. | ✅ Added `[Authorize][DeveloperOrAdminAuthorize]` to the creation endpoint only. |

Controllers such as `AuctionController`, `BidsController`, `ChatController`, `NewsController`, `ProjectController`, `PropertyController`, `RedemptionController`, `SalesTeamController`, `ValuationController`, etc., already matched the baseline expectations (class-level guards and/or method-level attributes) and did not require changes beyond confirming the GUID-based role checks still work.

Additional notes:

- Controllers that were intentionally removed in the UUID branch (Communities, Polls, Reactions, etc.) are excluded.
- Helper layers (`AdminAuthorizeAttribute`, `FeaturePermissionAttribute`, `AccountExtensions`, JWT claim helpers) still expect long-based role IDs and must be updated to GUID-based constants alongside controller fixes.


