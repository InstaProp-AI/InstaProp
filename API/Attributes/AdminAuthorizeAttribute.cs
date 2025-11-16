using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Security.Claims;

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

            // Check if user has admin role claim
            var accountTypeClaim = context.HttpContext.User.FindFirst("type");
            if (accountTypeClaim == null || accountTypeClaim.Value != "Admin")
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

            // Check if user has developer or admin role
            var accountTypeClaim = context.HttpContext.User.FindFirst("type");
            if (accountTypeClaim == null || 
                (accountTypeClaim.Value != "Developer" && accountTypeClaim.Value != "Admin"))
            {
                context.Result = new ForbidResult();
                return;
            }
        }
    }
}
