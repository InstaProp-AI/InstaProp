# Flutter Navigation Map

## Entry Stack
- `lib/main.dart` boots Firebase, wraps the app, and launches `PropertyFlipperApp`.
- `lib/app.dart` wires `MaterialApp` with `home: HomePage`, injects providers, and attaches `AppRouter.onGenerateRoute`.
- `lib/core/router/app_router.dart` defines named routes used across the app (`/home`, `/auth`, `/profile`, `/valuate`, `/all-news`, `/news/{id}`) and helper navigation utilities.

## Home Shell (`lib/pages/home_page.dart`)
- Bottom navigation tabs:
  - `Market` (`index 0`) → `MarketHubPage` (`lib/pages/market_hub_page.dart`).
  - `Portfolio` (`index 1`) → `PropertiesManagementPage` (`lib/pages/properties_management_page.dart`) with analytics, quick actions (Auctions, Add Property, Calendar, Valuate), and `PortfolioAnalyticsPage`.
  - `Explore` (`index 2`, default) → `ExplorePage` (`lib/pages/explore_page.dart`; legacy variants in `explore_page_new.dart` and `explore_page_old.dart`).
  - `Chats` (`index 3`) → `ChatListPage` (`lib/pages/chat_list_page.dart`).
  - `Profile` (`index 4`) → `ProfilePage` (`lib/pages/profile_page.dart`) containing user details, KYC status, verification triggers, security settings, and direct access to `RewardsPage`.
- `FloatingAIBrokerButton` is globally stacked on every screen.

## Explore Flow
- `ExplorePage` currently presents infinite mixed content (auctions, projects, community posts, notifications, developers, members) with pagination and pull-to-refresh.
- Backend feed now surfaces premium card types:
  - **Deal highlights** spotlight hot auctions with ROI, bid momentum, and countdowns, navigating to `AuctionDetailsPage`.
  - **Project stories** recap active projects, milestone progress, and aggregated performance, linking to `ProjectDetailsPage`.
  - **Investor milestones** celebrate community achievements with portfolio stats and engagement badges.
- Navigation hooks from Explore:
  - Community elements push `CommunityFeedPage` (`lib/pages/community_feed_page.dart`) or `CommunityDetailsPage`.
  - Auctions open `AuctionDetailsPage`.
  - Projects open `ProjectDetailsPage`.
  - Posts and notifications push `PostDetailsPage`.
- App bar presently only shows the `Explore` title; top-right buttons for Community / Help / Rewards are not yet wired in this file.
- `CommunityFeedPage` provides two tabs (All Feed / My Feed) with quick access to `CommunityListPage`.
- `CommunityListPage` lists all and recommended communities; selecting one navigates to `CommunityDetailsPage`.
- `CommunityDetailsPage` manages members, welcome banner, post feed, and join actions.

## Portfolio & Profile Stack
- `PropertiesManagementPage` (current Portfolio tab) surfaces:
  - Portfolio financial summary via `AnalyticsService` and the `PortfolioSummary` model.
  - Quick action cards linking to `AuctionActivityPage`, `AddPropertyPage`, `CalendarPage`, and `ValuatePage`.
  - `My Properties` preview with navigation to `MyPropertiesPage`.
  - Button to `PortfolioAnalyticsPage` for detailed charts.
- `ProfilePage` (current bottom-nav Profile tab) handles:
  - Personal information edit forms, verification prompts, password management, KYC banner, and logout.
  - Rewards card (`Navigator.push` to `RewardsPage`).
  - Email and phone verification flows (`EmailVerificationPage`, `PhoneVerificationPage`) and KYC (`KycVerificationPage`).
  - This page is the best candidate to repurpose as **Settings** per the requested navigation redesign.

## Rewards & Achievements
- `RewardsPage` (`lib/pages/rewards_page.dart`) manages tabbed content for codes, activity, badges, and redeem options. It relies on `RewardService` and `AppState` to fetch points/badges and includes redemption dialogs.
- Multiple surfaces (Profile quick action, `auctions_page.dart`) already navigate here via `MaterialPageRoute`.

## Other Notable Routes
- `lib/pages/auth_page.dart` for login/signup flows (`/auth`, `/login`).
- `lib/pages/valuate_page.dart` for property valuation (`/valuate`).
- `lib/pages/all_news_page.dart` and `lib/pages/news_detail_page.dart` for news listing and detail screens (available through Explore feed and named routes).

## Navigation Change Checklist (per new requirements)
1. **Bottom Nav Profile → Portfolio:** In `HomePage`, swap the `Profile` tab body to use `PropertiesManagementPage` so tapping Profile opens the portfolio dashboard by default.
2. **Settings Entry:** Convert `ProfilePage` into a dedicated `SettingsPage` (rename file/class or expose via new route) and adjust references (`AppRouter.profile`, edit flows).
3. **Portfolio Header Actions:** Add top-right icons inside `PropertiesManagementPage` SliverAppBar for:
   - `Settings` → push the refactored settings screen (old profile).
   - `Help` → create a new placeholder `HelpPage` under `lib/pages/help_page.dart`.
   - `Rewards` → push `RewardsPage` (gift icon).
4. **Explore App Bar Actions:** Wire Explore app bar buttons for quick navigation to Communities (`CommunityListPage`), Help (placeholder for now)
5. **Routing Updates:** Ensure `AppRouter` (or explicit `MaterialPageRoute` pushes) expose new `SettingsPage` and `HelpPage` routes so navigation works from both portfolio header and future entry points.
6. **UI Cleanup:** Remove rewards card duplication from the new settings screen so rewards live on the portfolio header action as requested.

Use this map as the source of truth before refactoring navigation; the sections above call out the files to touch for each flow.

