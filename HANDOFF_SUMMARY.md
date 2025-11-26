## Project Handoff Summary

### Context
- Goal: migrate entire stack (backend, dashboard, Flutter) from numeric IDs to UUIDs, refactor the account domain to use `IAccount`/`AccountBase` hierarchy, and remove all community-related functionality.
- Data reset allowed; dashboards and Flutter must be updated alongside backend.
- Latest directive: ensure `dotnet build` is clean, regenerate migrations, drop/recreate DB, and strip all traces of community features.

### Work Completed
- Replaced `long/int` IDs with GUIDs across backend models, DTOs, controllers, and services.
- Created `IAccount` interface + `AccountBase` abstract class with concrete `UserAccount`, `DeveloperAccount`, `AdminAccount`, and `SalesAccount`.
- Removed community features (controllers, models, services) across backend, dashboard (React), and Flutter app; deleted related widgets/services/pages/models.
- Updated dashboard types/services/pages to use string GUIDs; removed community nav/routes.
- Updated Flutter models/services/widgets to use String IDs and removed community views/services.
- Ensured backend build is clean (`dotnet build` succeeds with 0 warnings).
- Generated new EF Core migration `RemoveCommunityFeatures` after fixing lingering `IAccount` entity references.

### Current State
- Backend compiles; migration file exists but **not applied** (`dotnet ef database update` still pending).
- EF tools warn about shadow property `AccountBase.RoleId1` (double-check `Role` FK mapping before applying migration).
- Flutter/dashboard code compiles locally (not re-built in this session—recommend running `flutter analyze` / `npm test`).
- Database currently untouched after migration creation; existing tables still old schema until update runs.

### Outstanding Tasks / Next Steps
1. Inspect `Migrations/<timestamp>_RemoveCommunityFeatures.cs` + `AppDbContextModelSnapshot` to verify the `RoleId` warning cause; adjust model builder if necessary (likely duplicate FK definition) before updating DB.
2. Drop DB and apply the new migration sequence (`dotnet ef database drop --force`, `dotnet ef database update`) per earlier request.
3. Run backend tests / smoke endpoints to ensure removal of community code didn’t affect other modules.
4. Rebuild dashboard (`npm run build`) and Flutter app (`flutter build apk`) to ensure GUID changes compile.
5. Confirm no remaining references to community entities or numeric IDs across repo via targeted `rg`.

### Notes
- Role GUID constants defined in `API/Models/Role.cs`; double-check seeding aligns with migration.
- All `IAccount` navigation properties now point to `AccountBase`; keep this consistent for new entities.
- Migration tool mismatch warning (`tools 9.0.1` vs runtime `9.0.9`) is informational; update tools when convenient.






