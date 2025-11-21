using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Attributes;
using Microsoft.AspNetCore.Authorization;
using System.Text.Json;
using System.Diagnostics;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    [AdminAuthorize]
    public class SettingsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;
        private static Dictionary<string, object> _settings = new Dictionary<string, object>();

        public SettingsController(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
            
            // Initialize default settings if not exists
            if (_settings.Count == 0)
            {
                _settings = new Dictionary<string, object>
                {
                    { "siteName", "Instaprop" },
                    { "siteEmail", "admin@propertyflipper.com" },
                    { "currency", "USD" },
                    { "timezone", "UTC" },
                    { "emailNotifications", true },
                    { "smsNotifications", false },
                    { "bidAlerts", true },
                    { "userRegistration", true },
                    { "autoApproval", false },
                    { "maintenanceMode", false },
                    { "twoFactorAuth", true }
                };
            }
        }

        // GET: api/Settings
        [HttpGet]
        public ActionResult<object> GetSettings()
        {
            try
            {
                return Ok(_settings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // PUT: api/Settings
        [HttpPut]
        public ActionResult UpdateSettings([FromBody] Dictionary<string, object> newSettings)
        {
            try
            {
                foreach (var setting in newSettings)
                {
                    _settings[setting.Key] = setting.Value;
                }

                return Ok(new { message = "Settings updated successfully", settings = _settings });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // POST: api/Settings/backup-database
        [HttpPost("backup-database")]
        public ActionResult BackupDatabase()
        {
            // PostgreSQL database backups should be handled by your hosting provider (e.g., Railway, Heroku)
            // This endpoint is disabled as we no longer use SQLite file-based databases
            return BadRequest(new { error = "Database backups are managed by your hosting provider. PostgreSQL databases cannot be backed up via file copy." });
        }

        // POST: api/Settings/clear-cache
        [HttpPost("clear-cache")]
        public ActionResult ClearCache()
        {
            try
            {
                // Clear any cached data (implement based on your caching strategy)
                GC.Collect();
                GC.WaitForPendingFinalizers();
                GC.Collect();

                return Ok(new { message = "Cache cleared successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }

        // GET: api/Settings/system-info
        [HttpGet("system-info")]
        public ActionResult<object> GetSystemInfo()
        {
            try
            {
                var systemInfo = new
                {
                    Environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production",
                    OSVersion = Environment.OSVersion.ToString(),
                    MachineName = Environment.MachineName,
                    ProcessorCount = Environment.ProcessorCount,
                    WorkingSet = Environment.WorkingSet,
                    DotNetVersion = Environment.Version.ToString(),
                    Uptime = DateTime.UtcNow - Process.GetCurrentProcess().StartTime.ToUniversalTime()
                };

                return Ok(systemInfo);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}

