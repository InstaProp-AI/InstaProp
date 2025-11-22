using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System;
using System.Linq;
using System.Collections.Generic;

namespace InstapropAPI.Filters
{
    /// <summary>
    /// Swagger schema filter to handle problematic types and prevent generation errors
    /// </summary>
    public class SwaggerSchemaFilter : ISchemaFilter
    {
        private static readonly HashSet<string> ProblematicTypes = new HashSet<string>
        {
            "System.Object",
            "System.Delegate",
            "System.MulticastDelegate"
        };

        public void Apply(OpenApiSchema schema, SchemaFilterContext context)
        {
            try
            {
                // Skip problematic types that cause circular reference issues
                var type = context.Type;
                
                // Skip known problematic types
                if (type != null && ProblematicTypes.Contains(type.FullName ?? ""))
                {
                    schema.Type = "object";
                    schema.Properties = null;
                    return;
                }
                
                // Handle circular references by removing self-referencing properties
                if (schema.Properties != null)
                {
                    var keysToRemove = new List<string>();
                    
                    foreach (var property in schema.Properties)
                    {
                        // Remove null properties
                        if (property.Value == null)
                        {
                            keysToRemove.Add(property.Key);
                            continue;
                        }
                        
                        // Check for circular references (properties that reference the same type)
                        if (property.Value.Reference != null && 
                            property.Value.Reference.Id == context.SchemaRepository.Schemas.Keys.LastOrDefault())
                        {
                            // This is a circular reference - simplify it
                            property.Value.Reference = null;
                            property.Value.Type = "object";
                            property.Value.Properties = null;
                        }
                    }
                    
                    foreach (var key in keysToRemove)
                    {
                        schema.Properties.Remove(key);
                    }
                }
                
                // Ensure required properties list is valid
                if (schema.Required != null)
                {
                    var validRequired = schema.Required
                        .Where(r => !string.IsNullOrEmpty(r) && 
                                    (schema.Properties == null || schema.Properties.ContainsKey(r)))
                        .ToList();
                    schema.Required.Clear();
                    foreach (var req in validRequired)
                    {
                        schema.Required.Add(req);
                    }
                }
            }
            catch (Exception ex)
            {
                // If schema filtering fails, just continue - don't break Swagger generation
                // Log the error for debugging but don't throw
                Console.WriteLine($"Swagger schema filter error for type {context.Type?.Name}: {ex.Message}");
            }
        }
    }
}

