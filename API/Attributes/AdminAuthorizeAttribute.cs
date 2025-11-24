using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System.Security.Claims;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Services;
using InstapropAPI.Extensions;

namespace InstapropAPI.Attributes
{
    public class AdminAuthorizeAttribute : Attribute, IAuthorizationFilter
    {
        public void OnAuthorization(AuthorizationFilterContext context)
        {
            // Check if user is authenticated
            if (!context.HttpContext.User.Identity?.IsAuthenticated ?? true)
            {
                context.Result = new UnauthorizedObjectResult(new { message = "Authentication required" });
                return;
            }

            // SECURITY: Check RoleId instead of type string - non-guessable GUID
            var roleIdClaim = context.HttpContext.User.FindFirst("roleId");
            if (roleIdClaim == null || !Guid.TryParse(roleIdClaim.Value, out Guid roleId) || roleId != Models.Role.ADMIN_ROLE_ID)
            {
                context.Result = new ForbidResult();
                return;
            }
        }
    }

    public class DeveloperOrAdminAuthorizeAttribute : Attribute, IAuthorizationFilter
    {
        public void OnAuthorization(AuthorizationFilterContext context)
        {
            // Check if user is authenticated
            if (!context.HttpContext.User.Identity?.IsAuthenticated ?? true)
            {
                context.Result = new UnauthorizedObjectResult(new { message = "Authentication required" });
                return;
            }

            // SECURITY: Check RoleId instead of type string - non-guessable GUIDs
            var roleIdClaim = context.HttpContext.User.FindFirst("roleId");
            if (roleIdClaim == null || !Guid.TryParse(roleIdClaim.Value, out Guid roleId))
            {
                context.Result = new ForbidResult();
                return;
            }

            // Allow Developer or Admin roles
            if (roleId != Models.Role.DEVELOPER_ROLE_ID && roleId != Models.Role.ADMIN_ROLE_ID)
            {
                context.Result = new ForbidResult();
                return;
            }
        }
    }

    /// <summary>
    /// Authorization attribute to check if developer has permission for a specific feature
    /// Admins always have access, developers need explicit permission
    /// Default features (Projects, Properties, Analytics) are always allowed for developers
    /// </summary>
    public class FeaturePermissionAttribute : Attribute, IAuthorizationFilter
    {
        private readonly string _featureName;

        public FeaturePermissionAttribute(string featureName)
        {
            _featureName = featureName;
        }

        public void OnAuthorization(AuthorizationFilterContext context)
        {
            // Check if user is authenticated
            if (!context.HttpContext.User.Identity?.IsAuthenticated ?? true)
            {
                context.Result = new UnauthorizedObjectResult(new { message = "Authentication required" });
                return;
            }

            // Get account ID from claims
            var accountIdClaim = context.HttpContext.User.FindFirst("uid");
            if (accountIdClaim == null || !Guid.TryParse(accountIdClaim.Value, out Guid accountId))
            {
                context.Result = new UnauthorizedObjectResult(new { message = "Invalid user ID" });
                return;
            }

            // Get role ID from claims
            var roleIdClaim = context.HttpContext.User.FindFirst("roleId");
            if (roleIdClaim == null || !Guid.TryParse(roleIdClaim.Value, out Guid roleId))
            {
                context.Result = new ForbidResult();
                return;
            }

            // Admins always have access
            if (roleId == Role.ADMIN_ROLE_ID)
            {
                return;
            }

            // For developers, check permissions
            if (roleId == Role.DEVELOPER_ROLE_ID)
            {
                // Default features are always accessible
                if (!FeaturePermission.IsOptionalFeature(_featureName))
                {
                    return; // Allow access to default features
                }

                // For optional features, check database
                var dbContext = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var permissionService = context.HttpContext.RequestServices.GetRequiredService<DeveloperPermissionService>();

                // Check if developer has permission (async check in sync method - need to handle differently)
                // Use Task.Run to check permission synchronously
                var hasPermission = Task.Run(async () => await permissionService.HasPermission(accountId, _featureName)).Result;

                if (!hasPermission)
                {
                    context.Result = new ObjectResult(new { 
                        message = $"Access denied. You do not have permission to access {_featureName}." 
                    })
                    {
                        StatusCode = 403
                    };
                    return;
                }

                return;
            }

            // Regular users should have access to chats
            if (roleId == Role.USER_ROLE_ID && _featureName == "Chats")
            {
                return; // Allow regular users to access chats
            }

            // Sales members should have access to chats
            if (roleId == Role.SALES_ROLE_ID && _featureName == "Chats")
            {
                return; // Allow sales members to access chats
            }

            // Other roles are not allowed
            context.Result = new ForbidResult();
        }
    }
}
