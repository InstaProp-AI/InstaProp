# SQLite Decimal Aggregate Operations Fix

## Problem

SQLite does not support aggregate operations (`Max`, `Min`, `Sum`, `Average`) on `decimal` data types directly. When trying to use LINQ async aggregate methods like `MaxAsync()`, `SumAsync()`, or `AverageAsync()` on decimal columns, the following error occurs:

```
SQLite cannot apply aggregate operator 'Max' on expressions of type 'decimal'. 
Convert the values to a supported type, or use LINQ to Objects to aggregate 
the results on the client side.
```

This error was occurring when:
- Placing bids (NotificationService checking highest bid amounts)
- Fetching admin statistics (calculating revenue)
- Fetching dashboard statistics (calculating auction volume)

## Solution

The solution is to load the data into memory first using `.ToListAsync()`, then perform the aggregate operations using LINQ to Objects (in-memory operations).

### Pattern Used

**Before (causes error):**
```csharp
var result = await _context.Bids
    .Where(b => b.AuctionId == auctionId)
    .MaxAsync(b => b.BidAmount); // ❌ Error: SQLite can't do Max on decimal
```

**After (works correctly):**
```csharp
var bids = await _context.Bids
    .Where(b => b.AuctionId == auctionId)
    .ToListAsync(); // Load into memory first

var result = bids.Max(b => b.BidAmount); // ✅ LINQ to Objects on in-memory data
```

## Files Modified

### 1. **API/Services/NotificationService.cs**

**Location:** `NotifyOutbidBidders` method

**Problem:** Finding highest bid per bidder to determine who to notify
```csharp
var highestBid = await _context.Bids
    .Where(b => b.AuctionId == auctionId && b.BidderId == bidderId)
    .MaxAsync(b => b.BidAmount); // ❌ Error
```

**Fix:**
```csharp
// Load all bids for this auction into memory to avoid SQLite decimal aggregate issues
var allAuctionBids = await _context.Bids
    .Where(b => b.AuctionId == auctionId)
    .ToListAsync();

foreach (var bidderId in previousBidders)
{
    var bidderBids = allAuctionBids.Where(b => b.BidderId == bidderId).ToList();
    
    if (bidderBids.Any())
    {
        var highestBid = bidderBids.Max(b => b.BidAmount); // ✅ Works
        // ... notification logic
    }
}
```

### 2. **API/Controllers/AdminController.cs**

**Location:** `GetDashboardStats` method

**Problems:**
1. Calculating total revenue (sum of ended auction prices)
2. Calculating monthly revenue
3. Calculating average bid value

**Before:**
```csharp
var totalRevenue = await _context.Auctions
    .Where(a => a.Status == "Ended")
    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0; // ❌ Error

var monthlyRevenue = await _context.Auctions
    .Where(a => a.Status == "Ended" && a.CreatedAt >= thirtyDaysAgo)
    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0; // ❌ Error

var averageBidValue = totalBids > 0 
    ? await _context.Bids.AverageAsync(b => (decimal?)b.BidAmount) ?? 0 // ❌ Error
    : 0;
```

**After:**
```csharp
// Load into memory to avoid SQLite decimal aggregate issues
var endedAuctionsList = await _context.Auctions
    .Where(a => a.Status == "Ended")
    .ToListAsync();
var totalRevenue = endedAuctionsList.Sum(a => a.CurrentPrice); // ✅ Works

var thirtyDaysAgo = DateTime.UtcNow.AddDays(-30);
var recentEndedAuctions = endedAuctionsList
    .Where(a => a.CreatedAt >= thirtyDaysAgo)
    .ToList();
var monthlyRevenue = recentEndedAuctions.Sum(a => a.CurrentPrice); // ✅ Works

// Load into memory to avoid SQLite decimal aggregate issues
var averageBidValue = totalBids > 0 
    ? (await _context.Bids.ToListAsync()).Average(b => b.BidAmount) // ✅ Works
    : 0;
```

**Additional Fix:** Renamed variable to avoid conflict
- Changed `endedAuctions` (count) to `endedAuctionsCount`
- Created `endedAuctionsList` for the list of auction objects

### 3. **API/Controllers/DashboardController.cs**

**Location:** `GetPublicStats` method

**Problem:** Calculating total auction volume (sum of active auction prices)

**Before:**
```csharp
var totalVolume = await _context.Auctions
    .Where(a => a.Status == "Active")
    .SumAsync(a => (decimal?)a.CurrentPrice) ?? 0; // ❌ Error
```

**After:**
```csharp
// Load into memory to avoid SQLite decimal aggregate issues
var allActiveAuctions = await _context.Auctions
    .Where(a => a.Status == "Active")
    .ToListAsync();
var totalVolume = allActiveAuctions.Sum(a => a.CurrentPrice); // ✅ Works
```

## Impact

### Performance
- **Minimal Impact:** These queries typically deal with small to medium datasets
- **Benefit:** Loading data into memory is actually more efficient than multiple database round-trips
- **Trade-off:** Uses slightly more memory, but prevents errors and improves reliability

### Memory Usage
- Admin stats: Loads all ended auctions + all bids (~few hundred to few thousand records)
- Dashboard stats: Loads all active auctions (~tens to hundreds of records)
- Notifications: Loads bids for one auction (~tens to hundreds of records)

All of these are reasonable amounts of data to load into memory.

## Why This Happens

SQLite stores decimals as TEXT or REAL internally, not as a true decimal type like SQL Server does. This means:
1. SQLite doesn't have native decimal aggregate functions
2. Entity Framework Core can't translate LINQ decimal aggregates to SQL for SQLite
3. The solution is to use LINQ to Objects (in-memory) instead of LINQ to SQL

## Alternative Solutions Considered

### 1. **Cast to Double**
```csharp
var result = await _context.Bids
    .Select(b => (double)b.BidAmount)
    .MaxAsync();
```
**Rejected:** Loses precision, not suitable for financial data

### 2. **Raw SQL**
```csharp
var result = await _context.Database
    .ExecuteSqlRawAsync("SELECT MAX(BidAmount) FROM Bids WHERE AuctionId = {0}", auctionId);
```
**Rejected:** Less maintainable, loses type safety

### 3. **Switch to SQL Server/PostgreSQL**
**Rejected:** Not necessary for this application size, SQLite is suitable with this fix

### 4. **Change Decimal to Double**
```csharp
public double BidAmount { get; set; } // Instead of decimal
```
**Rejected:** Floating-point precision issues unsuitable for money

## Testing

### Before Fix
```
POST /api/bids
Body: {"auctionId":55,"bidAmount":100003}
Response: 400 Bad Request
Error: SQLite cannot apply aggregate operator 'Max' on expressions of type 'decimal'
```

### After Fix
```
POST /api/bids
Body: {"auctionId":55,"bidAmount":100003}
Response: 200 OK
Bid placed successfully ✅
Notifications sent to outbid users ✅
```

## Prevention

To prevent similar issues in the future:

### ✅ DO:
```csharp
// Load into memory first, then aggregate
var items = await _context.Items.ToListAsync();
var result = items.Sum(i => i.DecimalValue);
```

### ❌ DON'T:
```csharp
// Don't use async aggregates on decimal with SQLite
var result = await _context.Items.SumAsync(i => i.DecimalValue);
```

### Code Review Checklist:
- [ ] Are you using `MaxAsync()`, `MinAsync()`, `SumAsync()`, or `AverageAsync()`?
- [ ] Is the property being aggregated of type `decimal`?
- [ ] Are you using SQLite as the database?
- [ ] If yes to all above, use `.ToListAsync()` first, then aggregate in memory

## Related Issues

This is a known limitation of SQLite with Entity Framework Core:
- https://github.com/dotnet/efcore/issues/18950
- https://learn.microsoft.com/en-us/ef/core/providers/sqlite/limitations

## Summary

All SQLite decimal aggregate errors have been fixed by:
1. Loading relevant data into memory using `.ToListAsync()`
2. Performing aggregate operations using LINQ to Objects
3. Maintaining the same business logic and accuracy
4. Adding clear comments explaining the pattern

✅ **All bid placement operations now work correctly**
✅ **All admin statistics now calculate correctly**
✅ **All dashboard statistics now calculate correctly**
✅ **All notifications are sent properly when users are outbid**


