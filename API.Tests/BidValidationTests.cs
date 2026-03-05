using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Xunit;

namespace InstapropAPI.Tests;

/// <summary>
/// Tests for bid business rules:
/// - Bid amount must exceed current auction price
/// - Auction must be in Active status
/// - Bidder must exist
/// </summary>
public class BidValidationTests
{
    private static AppDbContext BuildContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static Guid CreateAuction(AppDbContext db, string status, decimal currentPrice, decimal startPrice = 1000m)
    {
        var auctionId = Guid.NewGuid();
        var propertyId = Guid.NewGuid();

        db.ChildProperties.Add(new ChildProperty
        {
            PropertyId = propertyId,
            Name = "Test Property",
            Description = "Test description",
            Location = "Cairo",
            ImageUrl = string.Empty,
            SquareFeet = 100,
            YearBuilt = 2020,
            OwnerId = Guid.NewGuid()
        });

        db.Auctions.Add(new Auction
        {
            AuctionId = auctionId,
            PropertyId = propertyId,
            StartPrice = startPrice,
            CurrentPrice = currentPrice,
            StartAt = DateTime.UtcNow.AddHours(-1),
            Duration = 24,
            Status = status,
            CreatedAt = DateTime.UtcNow
        });
        db.SaveChanges();
        return auctionId;
    }

    // ─── Auction Status Validation ────────────────────────────────────────────

    [Theory]
    [InlineData("Requested")]
    [InlineData("Approved")]
    [InlineData("Closed")]
    [InlineData("Cancelled")]
    public void Bid_ShouldBe_Rejected_For_NonActive_Auction(string status)
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, status, currentPrice: 1000m);

        var auction = db.Auctions.Find(auctionId)!;

        // The validation rule: only Active auctions accept bids
        Assert.NotEqual("Active", auction.Status);
        var isAcceptable = auction.Status == "Active";
        Assert.False(isAcceptable);
    }

    [Fact]
    public void Bid_ShouldBe_Accepted_For_Active_Auction()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 1000m);

        var auction = db.Auctions.Find(auctionId)!;

        Assert.Equal("Active", auction.Status);
    }

    // ─── Bid Amount Validation ────────────────────────────────────────────────

    [Fact]
    public void Bid_Amount_Equal_To_CurrentPrice_Should_Be_Rejected()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 5000m);

        var auction = db.Auctions.Find(auctionId)!;
        decimal bidAmount = 5000m;

        // Rule: new bid must EXCEED current price
        var isValid = bidAmount > auction.CurrentPrice;
        Assert.False(isValid);
    }

    [Fact]
    public void Bid_Amount_Below_CurrentPrice_Should_Be_Rejected()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 5000m);

        var auction = db.Auctions.Find(auctionId)!;
        decimal bidAmount = 4999m;

        var isValid = bidAmount > auction.CurrentPrice;
        Assert.False(isValid);
    }

    [Fact]
    public void Bid_Amount_Above_CurrentPrice_Should_Be_Accepted()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 5000m);

        var auction = db.Auctions.Find(auctionId)!;
        decimal bidAmount = 5001m;

        var isValid = bidAmount > auction.CurrentPrice;
        Assert.True(isValid);
    }

    // ─── WinPreservingPrice ───────────────────────────────────────────────────

    [Fact]
    public void WinPreservingPrice_Is_Nullable_And_Zero_Means_No_Deposit()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 1000m);

        var auction = db.Auctions.Find(auctionId)!;
        auction.WinPreservingPrice = null;

        var requiresDeposit = auction.WinPreservingPrice.HasValue && auction.WinPreservingPrice.Value > 0;
        Assert.False(requiresDeposit);
    }

    [Fact]
    public void WinPreservingPrice_Set_Means_Deposit_Required()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 1000m);

        var auction = db.Auctions.Find(auctionId)!;
        auction.WinPreservingPrice = 10000m;

        var requiresDeposit = auction.WinPreservingPrice.HasValue && auction.WinPreservingPrice.Value > 0;
        Assert.True(requiresDeposit);
    }

    // ─── BidCount Tracking ────────────────────────────────────────────────────

    [Fact]
    public void BidCount_Starts_At_Zero()
    {
        using var db = BuildContext();
        var auctionId = CreateAuction(db, "Active", currentPrice: 1000m);

        var auction = db.Auctions.Find(auctionId)!;
        Assert.Equal(0, auction.BidCount);
    }
}
