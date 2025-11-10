# Explore Feed Presentation Blueprint

## Objective
Make the Explore tab feel curated and bingeable by giving every feed type a distinctive, high-density presentation while reusing the existing backend payload. The page should read like a magazine front page: high-impact hero content at the top, contextual groupings in the middle, and a continuous discovery stream that never feels repetitive.

---

## Experience Principles
- **Curated first impression:** Lead with premium “Featured” content (deals, stories, milestones) before dropping into the mixed stream.
- **Distinct visual identity per type:** Each card communicates what it is at a glance through color, iconography, and stat layout.
- **Scroll momentum:** Alternate dense card stacks with lighter list rows so the feed keeps its rhythm.
- **Zero dead ends:** Every card exposes at least one meaningful action (view, save, share, join, bid).
- **Resilient states:** Empty data slices degrade gracefully with aspirational placeholders and CTA(s) to explore elsewhere.
- **Progressive visuals:** Network imagery loads with a soft pixelated blur that sharpens as bytes arrive—no more spinners interrupting flow.

---

## Section Order & Grouping
1. **Hero Rail — Featured Deals**
   - Horizontal pager with 1.25-card peeks.
   - Source: top `deal_highlight` items (fallback to hottest auctions).
   - Overlay metadata: ROI chip, bid momentum, countdown badge.

2. **Project Stories Carousel**
   - Snap-scrolling cards, each summarizing a project’s momentum.
   - Key stats: active auctions, milestones completed/upcoming, avg ROI.
   - CTA: `View project story`.

3. **Investor Spotlight**
   - Vertical stacked cards for `investor_milestone`.
   - Highlights total portfolio value, achievements, reputation points.
   - Supporting action: `View portfolio snapshot`.

4. **Endless Discovery Stream**
   - Everything beyond hero experiences (posts, communities, news, members, etc.) flows into a single stream that keeps the original infinite pagination.
   - Each item inherits its revamped card styling so the list still feels varied and rich.

If a section has no items, it collapses cleanly and the next section slides up with no extra padding.

---

## Card Design Guidelines by Type

### Deal Highlight
- Full-bleed hero image with corner ROI badge and gradient wash.
- Primary stat pill row: Current Bid, ROI, Bid Count.
- Secondary row: countdown + “Ending soon” badge for urgent lots.
- CTA: “View auction” (navigates to `AuctionDetailsPage`).

### Project Story
- Split layout: summary column + milestone capsule.
- Visual motif: top accent bar in brand gradient, milestone icons.
- Stats grid (4-up): Units, Active Auctions, Avg ROI, Milestones.
- CTA: “View project story”.

### Investor Milestone
- Avatar initials + badge ring that reflects points tier.
- Stat tiles: Portfolio (count), Buy-in value (formatted), Reputation.
- Timeline flourish showing when the milestone was unlocked.
- CTA: “View portfolio snapshot” (future deep link placeholder).

### Community Post
- Masonry-inspired card with edge-to-edge media (if available).
- Header chips (community, author badge) over translucent scrim.
- Inline action row (like/comment/share/save) with haptic feedback.
- Hashtag ribbon collapsed to “+N tags” after 2 lines.

### Notification Card
- Icon badges colored by notification type (auction, achievement, reminder).
- Message block with optional action button (e.g., “Bid +EGP 5k”).
- Timestamp in subdued tertiary text; indicates if already handled.

### Community Recommendation
- Pill-shaped card with gradient background.
- Member count + trending delta, highlight latest pinned post.
- CTA: “View community” and secondary “Join” if user not a member.

### News Article
- Landscape thumbnail left, text block right (mobile collapses to top).
- Secondary metadata: published time, category chip.
- CTA: “Open article” (currently snackbar placeholder).

### Auction (non-highlight)
- Compact card using `FeedAuctionCard` visual language but tightened:
  - Reduced hero height, emphasis on bid summary strip.
  - “Save”/“Share” affordances surfaced on hover/long press.

### Developer Feature
- Business card style with gradient border and rating stars.
- Highlights company focus, average project ROI, active listings.
- CTA: “View developer profile”.

### Member Highlight
- Compact follow card with stat pair (posts, reputation).
- Includes micro accolades (badges earned) as inline chips.
- CTA: “Follow” or “Message” (if already following).

### Feed Notification (System Achievements)
- Uses a milestone ribbon motif consistent with investor spotlight.
- Action button aligns left (unlike legacy right alignment) for reachability.

---

## Visual Language & Tokens
- **Typography:** 
  - Headers: `Inter 20/24 Bold`
  - Body: `Inter 14/20 Medium`
  - Meta text: `Inter 12/16 Regular` with 60% opacity.
- **Colors:**
  - Primary gradient: `#3557FF → #00C2FF`
  - Success: `#10B981`, Warning: `#F59E0B`, Critical: `#EF4444`
  - Backgrounds use tiered surfaces: base `#FFFFFF`, raised cards `#F7F9FC`.
- **Elevation:**
  - Hero cards: elevation 6, with soft shadow.
  - List items: elevation 2; hover/press lifts to 4 (web/tablet).
- **Spacing:**
  - Section margin top: 24, bottom: 16.
  - Card padding: 16 outer, 12 inner for stat pills.
  - Masonry gutter: 12.

---

## Interaction Patterns
- Horizontal carousels use PageView with fractional viewport (0.88) and snap physics.
- Masonry implemented via `SliverMasonryGrid` (or `StaggeredGrid.count` fallback).
- Section headers pin when the section is in view to aid navigation.
- Light haptic feedback on primary CTA taps.
- Graceful fallback:
  - If hero rail empty, promote Project Stories to first position.
  - If no premium sections, fall back to original infinite list but use redesigned cards.

---

## Empty & Loading States
- Each section defines:
  - **Loading skeleton:** shimmer cards with same dimensions as final cards.
  - **Empty messaging:** aspirational copy + CTA (e.g., “No investor milestones yet. Track your portfolio progress in Analytics.”).
  - **Error banner:** inline toast if card rendering fails; log with existing error handling.

---

## Implementation Notes
- No backend or DTO changes required; grouping happens after `_feedItems` resolve.
- Use dedicated mappers per section (e.g., `_extractDealHighlights`) to keep `build` lean.
- Maintain `_scrollController` behavior; sections are just composed as slivers prior to the legacy list.
- Analytics: keep existing impressions/tap logging; add events for new CTAs if/when backend supports them.

---

## QA Checklist
- Verify each section displays correctly on:
  - Small phone (360px), large phone (414px), tablet (768px).
- Confirm pagination still loads additional items when scrolled past re-grouped sections.
- Validate empty state handling by stubbing data arrays to zero items.
- Regression test Explore variants (`explore_page_new.dart`, `explore_page_old.dart`) if still routable.

---

## Appendix
- `explore_page.dart` wireframe references (Figma link TBD).
- Theme token map aligning new colors to `AppColors`.
- Future enhancements backlog (e.g., quick filters using backend params, deep links for investor portfolios).

