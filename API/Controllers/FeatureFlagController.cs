using Microsoft.AspNetCore.Mvc;
using InstapropAPI.Services;

namespace InstapropAPI.Controllers
{
    /// <summary>
    /// Public endpoint returning current feature flag states.
    /// Flutter reads this on app startup to show/hide navigation items.
    /// Returns an empty object on error — Flutter defaults all flags to true (safe).
    /// </summary>
    [ApiController]
    [Route("api/flags")]
    public class FeatureFlagController : ControllerBase
    {
        private readonly FeatureFlagService _featureFlagService;
        private readonly ILogger<FeatureFlagController> _logger;

        public FeatureFlagController(FeatureFlagService featureFlagService, ILogger<FeatureFlagController> logger)
        {
            _featureFlagService = featureFlagService;
            _logger = logger;
        }

        /// <summary>
        /// GET /api/flags
        /// Returns a flat dictionary of featureKey -> bool for Flutter to consume on startup.
        /// Example: { "News": false, "LiveStreaming": false, "AIBroker": false, "FeedExplore": true, ... }
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetFlags()
        {
            try
            {
                var flags = await _featureFlagService.GetAllFlagsAsync();
                return Ok(flags);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to retrieve feature flags");
                // Return empty object — Flutter will default all missing keys to true
                return Ok(new Dictionary<string, bool>());
            }
        }
    }
}
