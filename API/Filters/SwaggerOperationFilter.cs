using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Authorization;

namespace InstapropAPI.Filters
{
    /// <summary>
    /// Swagger operation filter to handle errors gracefully during schema generation
    /// and apply security requirements to authorized endpoints
    /// </summary>
    public class SwaggerOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            try
            {
                // Remove any null responses that might cause issues
                if (operation.Responses != null)
                {
                    var keysToRemove = operation.Responses
                        .Where(kvp => kvp.Value == null)
                        .Select(kvp => kvp.Key)
                        .ToList();
                    
                    foreach (var key in keysToRemove)
                    {
                        operation.Responses.Remove(key);
                    }
                }
                
                // Ensure all parameters are valid
                if (operation.Parameters != null)
                {
                    operation.Parameters = operation.Parameters
                        .Where(p => p != null)
                        .ToList();
                }

                // Apply security requirement for endpoints with [Authorize] attribute
                // This makes the lock icon appear in Swagger UI
                var hasAuthorize = context.MethodInfo.DeclaringType != null &&
                    (context.MethodInfo.GetCustomAttributes(true).OfType<AuthorizeAttribute>().Any() ||
                     context.MethodInfo.DeclaringType.GetCustomAttributes(true).OfType<AuthorizeAttribute>().Any());

                if (hasAuthorize)
                {
                    // Add security requirement - this enables the lock icon in Swagger UI
                    operation.Security = new List<OpenApiSecurityRequirement>
                    {
                        new OpenApiSecurityRequirement
                        {
                            {
                                new OpenApiSecurityScheme
                                {
                                    Reference = new OpenApiReference
                                    {
                                        Type = ReferenceType.SecurityScheme,
                                        Id = "Bearer"
                                    }
                                },
                                Array.Empty<string>()
                            }
                        }
                    };
                }
            }
            catch
            {
                // If operation filtering fails, just continue - don't break Swagger generation
            }
        }
    }
}


