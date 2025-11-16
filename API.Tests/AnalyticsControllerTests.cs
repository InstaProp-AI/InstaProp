using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using InstapropAPI.Controllers;
using InstapropAPI.Data;
using InstapropAPI.Models;
using Xunit;

namespace InstapropAPI.Tests;

public class AnalyticsControllerTests
{
    private static AppDbContext BuildContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new AppDbContext(options);
    }

    [Fact]
    public async Task GetMarketOverview_ShouldProvideFallbackMessage_WhenNoData()
    {
        await using var context = BuildContext();
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var controller = new AnalyticsController(context, cache);

        var result = await controller.GetMarketOverview();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<MarketOverviewResponse>(okResult.Value);

        Assert.False(payload.HasData);
        Assert.False(string.IsNullOrWhiteSpace(payload.Message));
        Assert.NotEqual(default, payload.GeneratedAtUtc);
    }

    [Fact]
    public async Task GetGoldComparison_ShouldIncludeMessage_WhenInsufficientData()
    {
        await using var context = BuildContext();
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var controller = new AnalyticsController(context, cache);

        var result = await controller.GetGoldComparison();

        var okResult = Assert.IsType<OkObjectResult>(result.Result);
        var payload = Assert.IsType<GoldComparisonResponse>(okResult.Value);

        Assert.NotNull(payload.Message);
        Assert.Equal("Tied", payload.BetterInvestment);
        Assert.NotEqual(default, payload.GeneratedAtUtc);
    }
}

