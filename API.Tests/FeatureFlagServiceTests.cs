using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging.Abstractions;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Services;
using Xunit;

namespace InstapropAPI.Tests;

public class FeatureFlagServiceTests
{
    private static AppDbContext BuildContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static (AppDbContext db, FeatureFlagService svc, IMemoryCache cache) Build()
    {
        var db = BuildContext();
        var cache = new MemoryCache(new MemoryCacheOptions());
        var svc = new FeatureFlagService(db, cache, NullLogger<FeatureFlagService>.Instance);
        return (db, svc, cache);
    }

    // ─── GetAllFlags ─────────────────────────────────────────────────────────

    [Fact]
    public async Task GetAllFlags_Returns_Correct_Values_From_DB()
    {
        var (db, svc, _) = Build();

        db.FeatureFlags.AddRange(
            new FeatureFlag { FeatureFlagId = Guid.NewGuid(), FeatureKey = "News",         IsEnabled = false, Description = "News" },
            new FeatureFlag { FeatureFlagId = Guid.NewGuid(), FeatureKey = "FeedExplore",  IsEnabled = true,  Description = "Feed" }
        );
        await db.SaveChangesAsync();

        var flags = await svc.GetAllFlagsAsync();

        Assert.False(flags["News"]);
        Assert.True(flags["FeedExplore"]);
    }

    [Fact]
    public async Task GetAllFlags_Returns_Empty_Dict_On_DB_Error()
    {
        // Use a disposed context to simulate a DB failure
        var db = BuildContext();
        var cache = new MemoryCache(new MemoryCacheOptions());
        var svc = new FeatureFlagService(db, cache, NullLogger<FeatureFlagService>.Instance);

        await db.DisposeAsync(); // Force failure

        var flags = await svc.GetAllFlagsAsync();

        // Must return empty dict (not throw), so Flutter defaults all to true
        Assert.Empty(flags);
    }

    [Fact]
    public async Task GetAllFlags_Uses_Cache_On_Second_Call()
    {
        var (db, svc, cache) = Build();

        db.FeatureFlags.Add(new FeatureFlag
        {
            FeatureFlagId = Guid.NewGuid(),
            FeatureKey = "AIBroker",
            IsEnabled = false,
            Description = "AI Broker"
        });
        await db.SaveChangesAsync();

        var first = await svc.GetAllFlagsAsync();

        // Manually change DB after first call
        var flag = await db.FeatureFlags.FirstAsync(f => f.FeatureKey == "AIBroker");
        flag.IsEnabled = true;
        await db.SaveChangesAsync();

        // Second call should still return cached (false)
        var second = await svc.GetAllFlagsAsync();
        Assert.False(second["AIBroker"]); // Cache was not invalidated
    }

    // ─── SetFlag ─────────────────────────────────────────────────────────────

    [Fact]
    public async Task SetFlag_Updates_Value_And_Invalidates_Cache()
    {
        var (db, svc, cache) = Build();

        var flagId = Guid.NewGuid();
        var adminId = Guid.NewGuid();

        db.FeatureFlags.Add(new FeatureFlag
        {
            FeatureFlagId = flagId,
            FeatureKey = "LiveStreaming",
            IsEnabled = false,
            Description = "Live streaming"
        });
        await db.SaveChangesAsync();

        // Prime the cache
        await svc.GetAllFlagsAsync();

        // Toggle on
        await svc.SetFlagAsync("LiveStreaming", true, adminId);

        // After toggle, cache should be cleared — next call fetches fresh from DB
        var flags = await svc.GetAllFlagsAsync();
        Assert.True(flags["LiveStreaming"]);
    }

    [Fact]
    public async Task SetFlag_Throws_InvalidOperation_For_Unknown_Key()
    {
        var (db, svc, _) = Build();

        await Assert.ThrowsAsync<InvalidOperationException>(
            () => svc.SetFlagAsync("NonExistentFeature", true, Guid.NewGuid()));
    }

    // ─── Default behavior ────────────────────────────────────────────────────

    [Fact]
    public async Task GetAllFlags_Empty_Result_Means_Flutter_Defaults_To_True()
    {
        // When flags returns empty, Flutter's isFeatureEnabled defaults to true
        // This test documents the contract: empty dict = all features enabled
        var (db, svc, _) = Build();
        // No flags seeded in DB

        var flags = await svc.GetAllFlagsAsync();

        Assert.Empty(flags);
        // Flutter code: featureFlags[key] ?? true => true for any missing key
        var mockFlutterCheck = flags.TryGetValue("News", out var val) ? val : true;
        Assert.True(mockFlutterCheck);
    }
}
