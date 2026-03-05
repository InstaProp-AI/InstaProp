using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using InstapropAPI.Data;
using InstapropAPI.Models;

namespace InstapropAPI.Services
{
    /// <summary>
    /// Reads feature flags from the database and caches them for 5 minutes.
    /// UI-gate only — no backend enforcement. If the DB call fails, every flag defaults to true.
    /// </summary>
    public class FeatureFlagService
    {
        private readonly AppDbContext _context;
        private readonly IMemoryCache _cache;
        private readonly ILogger<FeatureFlagService> _logger;
        private const string CacheKey = "FeatureFlags_All";
        private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(5);

        public FeatureFlagService(AppDbContext context, IMemoryCache cache, ILogger<FeatureFlagService> logger)
        {
            _context = context;
            _cache = cache;
            _logger = logger;
        }

        /// <summary>Returns a dictionary of all feature flag keys to their enabled state.</summary>
        public async Task<Dictionary<string, bool>> GetAllFlagsAsync()
        {
            if (_cache.TryGetValue(CacheKey, out Dictionary<string, bool>? cached) && cached != null)
                return cached;

            try
            {
                var flags = await _context.FeatureFlags
                    .AsNoTracking()
                    .ToDictionaryAsync(f => f.FeatureKey, f => f.IsEnabled);

                _cache.Set(CacheKey, flags, CacheDuration);
                return flags;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load feature flags from DB — defaulting all flags to true");
                return new Dictionary<string, bool>(); // empty = isFeatureEnabled defaults to true for all
            }
        }

        /// <summary>Toggles a single flag and invalidates the cache immediately.</summary>
        public async Task<FeatureFlag> SetFlagAsync(string featureKey, bool isEnabled, Guid updatedByAdminId)
        {
            var flag = await _context.FeatureFlags.FirstOrDefaultAsync(f => f.FeatureKey == featureKey)
                ?? throw new InvalidOperationException($"Feature flag '{featureKey}' not found.");

            flag.IsEnabled = isEnabled;
            flag.LastUpdatedAt = DateTime.UtcNow;
            flag.UpdatedByAdminId = updatedByAdminId;

            await _context.SaveChangesAsync();

            // Invalidate cache so next request picks up the change
            _cache.Remove(CacheKey);
            _logger.LogInformation("Feature flag '{Key}' set to {Value} by admin {AdminId}", featureKey, isEnabled, updatedByAdminId);

            return flag;
        }
    }
}
