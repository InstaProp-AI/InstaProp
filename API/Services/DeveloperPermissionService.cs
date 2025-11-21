using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Extensions;
using Microsoft.EntityFrameworkCore;

namespace InstapropAPI.Services
{
    public class DeveloperPermissionService
    {
        private readonly AppDbContext _context;

        public DeveloperPermissionService(AppDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Get all permissions for a developer (including default always-enabled features)
        /// </summary>
        public async Task<Dictionary<string, bool>> GetDeveloperPermissions(long developerId)
        {
            var permissions = new Dictionary<string, bool>();

            // Default features are always enabled for developers
            permissions[FeaturePermission.Projects] = true;
            permissions[FeaturePermission.Properties] = true;
            permissions[FeaturePermission.Analytics] = true;

            // Get optional features from database
            var optionalPermissions = await _context.DeveloperPermissions
                .Where(p => p.DeveloperId == developerId)
                .ToDictionaryAsync(p => p.FeatureName, p => p.IsEnabled);

            // Add optional features (default to false if not found)
            foreach (var feature in FeaturePermission.OptionalFeatures)
            {
                permissions[feature] = optionalPermissions.ContainsKey(feature) 
                    ? optionalPermissions[feature] 
                    : false;
            }

            return permissions;
        }

        /// <summary>
        /// Get default permissions (used for new developers)
        /// </summary>
        public Dictionary<string, bool> GetDefaultPermissions()
        {
            var permissions = new Dictionary<string, bool>();

            // Default features always enabled
            permissions[FeaturePermission.Projects] = true;
            permissions[FeaturePermission.Properties] = true;
            permissions[FeaturePermission.Analytics] = true;

            // Optional features default to disabled
            foreach (var feature in FeaturePermission.OptionalFeatures)
            {
                permissions[feature] = false;
            }

            return permissions;
        }

        /// <summary>
        /// Update a single permission for a developer
        /// </summary>
        public async Task UpdatePermission(long developerId, string featureName, bool isEnabled)
        {
            // Cannot update default features
            if (!FeaturePermission.IsOptionalFeature(featureName))
            {
                throw new InvalidOperationException($"Cannot update default feature: {featureName}");
            }

            var permission = await _context.DeveloperPermissions
                .FirstOrDefaultAsync(p => p.DeveloperId == developerId && p.FeatureName == featureName);

            if (permission == null)
            {
                permission = new DeveloperPermission
                {
                    DeveloperId = developerId,
                    FeatureName = featureName,
                    IsEnabled = isEnabled,
                    CreatedAt = DateTime.UtcNow
                };
                _context.DeveloperPermissions.Add(permission);
            }
            else
            {
                permission.IsEnabled = isEnabled;
                permission.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Bulk update permissions for a developer
        /// </summary>
        public async Task BulkUpdatePermissions(long developerId, Dictionary<string, bool> permissions)
        {
            foreach (var kvp in permissions)
            {
                // Skip default features
                if (!FeaturePermission.IsOptionalFeature(kvp.Key))
                {
                    continue;
                }

                await UpdatePermission(developerId, kvp.Key, kvp.Value);
            }
        }

        /// <summary>
        /// Check if a developer has permission for a specific feature
        /// </summary>
        public async Task<bool> HasPermission(long developerId, string featureName)
        {
            // Default features are always enabled for developers
            if (!FeaturePermission.IsOptionalFeature(featureName))
            {
                return true; // Default features always accessible
            }

            // For optional features, check database
            var permission = await _context.DeveloperPermissions
                .FirstOrDefaultAsync(p => p.DeveloperId == developerId && p.FeatureName == featureName);

            // If no permission record exists, default to false
            return permission?.IsEnabled ?? false;
        }

        /// <summary>
        /// Initialize permissions for a new developer (seed default permissions)
        /// </summary>
        public async Task InitializeDeveloperPermissions(long developerId)
        {
            // Get current permissions
            var existingPermissions = await _context.DeveloperPermissions
                .Where(p => p.DeveloperId == developerId)
                .Select(p => p.FeatureName)
                .ToListAsync();

            // Add missing optional features with default value (false)
            foreach (var feature in FeaturePermission.OptionalFeatures)
            {
                if (!existingPermissions.Contains(feature))
                {
                    var permission = new DeveloperPermission
                    {
                        DeveloperId = developerId,
                        FeatureName = feature,
                        IsEnabled = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    _context.DeveloperPermissions.Add(permission);
                }
            }

            await _context.SaveChangesAsync();
        }

        /// <summary>
        /// Check if account is a developer
        /// </summary>
        public async Task<bool> IsDeveloper(long accountId)
        {
            var account = await _context.Accounts.FindAsync(accountId);
            return account != null && account.IsDeveloperOrAdmin() && !account.IsAdmin();
        }
    }
}

