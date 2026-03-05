# Instaprop API — Code Refactor Brief

**Project:** Instaprop (Property Flipper)
**Stack:** ASP.NET Core 8, EF Core 9, PostgreSQL, JWT Bearer Auth
**Scope:** Backend API (`/API` folder only)
**Goal:** Improve code structure, maintainability, and reliability before production launch.
**Do NOT change:** Business logic, endpoint contracts (routes/DTOs/status codes), database schema, or auth rules.

---

## 1. No Business Logic in Controllers

**Priority: HIGH**

Several controllers contain inline business logic that belongs in a service layer.

**What to do:**
- Create `IPropertyService`, `IAuctionService`, `IRewardService`, `INotificationService`, etc.
- Move all multi-step operations (DB reads + writes + side effects) from controllers into services
- Controllers should only: validate input → call service → return response

**Key offenders to check:**
- `AuctionsController.cs` — auction approval/rejection logic inlined
- `PropertyController.cs` — property approval, image upload logic
- `RewardController.cs` — points calculation and badge awarding
- `AccountController.cs` — registration multi-step flow

**Pattern to follow:**
```csharp
// Controller (after refactor):
[HttpPost("{id}/approve")]
public async Task<IActionResult> ApproveAuction(Guid id)
{
    var result = await _auctionService.ApproveAsync(id, adminId);
    return result.Success ? Ok(result) : BadRequest(result);
}

// Service (after refactor):
public async Task<ServiceResult> ApproveAsync(Guid auctionId, Guid adminId)
{
    // All the logic here
}
```

---

## 2. Repository / Service Separation

**Priority: HIGH**

Some controllers inject `AppDbContext` directly. All database access should go through a service layer.

**What to do:**
- Remove direct `AppDbContext` injection from controllers that have a corresponding service
- If no service exists yet, create one
- Exception: `AdminController` may keep direct DB access for simple admin queries (by design)

**Note:** The `FinancialService` (added in the production-readiness commits) is the reference implementation. It has no controller-level DB access — use it as the pattern.

---

## 3. Async/Await Consistency

**Priority: MEDIUM**

Check for synchronous blocking calls that can deadlock under load.

**What to look for:**
```csharp
// BAD — blocks thread pool
var result = someAsyncCall().Result;
someAsyncCall().Wait();

// BAD — fire and forget without error handling
_ = SomeAsyncMethod();

// GOOD
var result = await someAsyncCall();
```

**Run this search:**
```bash
rg "\.Result\b|\.Wait\(\)" API/Controllers/ API/Services/
```

---

## 4. Remove Dead / Duplicate Code

**Priority: MEDIUM**

**Known dead code to remove:**
- `SavedSearches` DbSet was removed from `AppDbContext` — check for any orphaned `SavedSearchService.cs` or references
- `_buildNewsPreviewSection` in `Flutter/lib/pages/home_page.dart` is defined but never called
- Check `SeedController.cs` — remove if it was only used for development seeding (confirm with team first)
- Any commented-out endpoint or service registration in `Program.cs`

**Duplicate patterns:**
- Error handling: some controllers use `try/catch` returning `StatusCode(500, ...)` and some use the global `ErrorHandlingMiddleware`. Standardize on the middleware approach (remove redundant try/catch from controllers)
- Authentication claim parsing: `User.Claims.FirstOrDefault(c => c.Type == "uid")?.Value` is duplicated in 10+ controllers. Extract to a base controller method or extension method:
```csharp
// In a BaseController or extension:
protected Guid CurrentUserId =>
    Guid.TryParse(User.Claims.FirstOrDefault(c => c.Type == "uid")?.Value, out var id) ? id : Guid.Empty;
```

---

## 5. Standardize API Response Format

**Priority: MEDIUM**

The API currently returns inconsistent response shapes:

```json
// Some endpoints return raw objects:
{ "auctionId": "...", "status": "Active" }

// Some return wrappers:
{ "success": true, "data": {...}, "message": "..." }

// Some return just strings:
"Auction approved successfully"
```

**What to do:**
- Define a standard `ApiResult<T>` response class:
```csharp
public class ApiResult<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Message { get; set; }
    public string? Error { get; set; }
}
```
- Apply consistently to all 200+ endpoints
- **Important:** Coordinate with the Flutter team before changing — any response format change requires Flutter app update. Either update both simultaneously or version the API.

---

## 6. Error Messages — No Stack Traces in Production

**Priority: HIGH (security)**

Some controllers return exception details to the client:
```csharp
// BAD — leaks internals:
return StatusCode(500, new { error = ex.Message, stackTrace = ex.StackTrace });
```

**What to do:**
- Remove all `stackTrace = ex.StackTrace` from responses
- Remove all `error = ex.Message` from 500 responses (log it, don't return it)
- The `ErrorHandlingMiddleware` already handles this globally — ensure it's active and covers all unhandled exceptions
- Verify no controller bypasses the middleware with its own broad catch-all

---

## 7. Migration History Cleanup

**Priority: LOW (before first production deploy)**

Currently only 2 migrations exist in `API/Migrations/`:
- `InitialGlobalMigration` — the original everything-in-one migration
- `AddWinPreservingPriceAndFeatureFlags` — from production readiness
- `AddPerformanceIndexes` — from production readiness

And in `API/Migrations/Financial/`:
- `AddFinancialDatabase` — financial DB schema

**What to do:**
- Squash the main DB migrations into a single clean initial migration before going live (only safe to do before first production deploy)
- After squash, verify `dotnet ef database update` on a fresh DB works end-to-end

---

## 8. appsettings.json — Secret Removal (Pre-Launch Only)

**Priority: HIGH (must do before production deploy)**

This is intentionally deferred until pre-launch. The following secrets are currently in `appsettings.json` and MUST be moved to Railway environment variables before production:

- `ConnectionStrings.DefaultConnection` — move to `DATABASE_URL` env var (already supported)
- `ConnectionStrings.FinancialConnection` — move to `FINANCIAL_DATABASE_URL` env var (already supported)
- `Jwt.Key` — move to `JWT_SECRET` env var
- `Email.Password` — move to `EMAIL_PASSWORD` env var
- `GoogleOAuth.ClientSecret` — move to `GOOGLE_CLIENT_SECRET` env var
- `SMS.AuthToken` — move to `TWILIO_AUTH_TOKEN` env var
- `OpenAI.ApiKey` — move to `OPENAI_API_KEY` env var
- `ImgBB.ApiKey` — move to `IMGBB_API_KEY` env var

**How to move:** Replace hardcoded values with `builder.Configuration["ENV_VAR_NAME"]` or use `Environment.GetEnvironmentVariable()`. Railway env vars are set in the Railway dashboard and override any values in the config file.

---

## Files to Focus On (Estimated Effort)

| File | Issues | Effort |
|------|--------|--------|
| `Controllers/AuctionsController.cs` | Logic in controller, direct DB, inconsistent responses | High |
| `Controllers/PropertyController.cs` | Logic in controller, direct DB | High |
| `Controllers/AccountController.cs` | Logic in controller, some stack traces | High |
| `Controllers/AdminController.cs` | Acceptable as-is (admin queries) | Low |
| `Controllers/RewardController.cs` | Logic in controller | Medium |
| `Controllers/BidsController.cs` | Minor cleanup only | Low |
| `Services/AuctionExpirationService.cs` | OK after Commit 2 changes | Low |
| `Services/FinancialService.cs` | Reference implementation — no changes | None |
| `Program.cs` | Secret cleanup (pre-launch) | Low |

---

## What NOT to Touch

- `FinancialService.cs` / `FinancialDbContext.cs` — correct pattern already implemented
- `FeatureFlagService.cs` — correct pattern
- `ErrorHandlingMiddleware.cs` — keep as-is
- All EF migrations — do not edit migration files, only add new ones
- Auth configuration in `Program.cs` — keep JWT setup as-is
- All test files in `API.Tests/`
- Flutter app code (separate concern for UI/UX designer phase)

---

## Testing After Refactor

Run the existing unit tests after each refactoring step:

```bash
cd API.Tests && dotnet test
```

All 31 tests must continue to pass. If a test fails, the refactor broke something — fix before continuing.

---

*Written as part of the production readiness roadmap. Questions: contact the engineering lead.*
