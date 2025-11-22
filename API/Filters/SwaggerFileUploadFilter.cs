using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace InstapropAPI.Filters
{
    /// <summary>
    /// Swagger filter to handle file upload endpoints with IFormFile parameters
    /// </summary>
    public class SwaggerFileUploadFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            var fileParameters = context.MethodInfo.GetParameters()
                .Where(p => p.ParameterType == typeof(Microsoft.AspNetCore.Http.IFormFile) ||
                           p.ParameterType == typeof(Microsoft.AspNetCore.Http.IFormFileCollection) ||
                           (p.ParameterType.IsGenericType && 
                            p.ParameterType.GetGenericTypeDefinition() == typeof(List<>) &&
                            p.ParameterType.GetGenericArguments()[0] == typeof(Microsoft.AspNetCore.Http.IFormFile)))
                .ToList();

            if (fileParameters.Any())
            {
                // Clear all existing parameters to avoid conflicts
                operation.Parameters.Clear();

                // Add proper file upload schema
                operation.RequestBody = new OpenApiRequestBody
                {
                    Content = new Dictionary<string, OpenApiMediaType>
                    {
                        ["multipart/form-data"] = new OpenApiMediaType
                        {
                            Schema = new OpenApiSchema
                            {
                                Type = "object",
                                Properties = new Dictionary<string, OpenApiSchema>(),
                                Required = new HashSet<string>()
                            }
                        }
                    }
                };

                // Add all form parameters (file and other form fields)
                foreach (var param in context.MethodInfo.GetParameters())
                {
                    var fromFormAttribute = param.GetCustomAttributes(typeof(FromFormAttribute), false).FirstOrDefault();
                    if (fromFormAttribute != null)
                    {
                        if (param.ParameterType == typeof(Microsoft.AspNetCore.Http.IFormFile))
                        {
                            // Add file parameter
                            operation.RequestBody.Content["multipart/form-data"].Schema.Properties[param.Name] = new OpenApiSchema
                            {
                                Type = "string",
                                Format = "binary",
                                Description = "File to upload"
                            };
                            
                            // Ensure Required list exists
                            if (operation.RequestBody.Content["multipart/form-data"].Schema.Required == null)
                            {
                                operation.RequestBody.Content["multipart/form-data"].Schema.Required = new HashSet<string>();
                            }
                            
                            if (!operation.RequestBody.Content["multipart/form-data"].Schema.Required.Contains(param.Name))
                            {
                                operation.RequestBody.Content["multipart/form-data"].Schema.Required.Add(param.Name);
                            }
                        }
                        else if (param.ParameterType == typeof(Microsoft.AspNetCore.Http.IFormFileCollection))
                        {
                            // Add file collection parameter
                            operation.RequestBody.Content["multipart/form-data"].Schema.Properties[param.Name] = new OpenApiSchema
                            {
                                Type = "array",
                                Items = new OpenApiSchema
                                {
                                    Type = "string",
                                    Format = "binary"
                                },
                                Description = "Files to upload"
                            };
                        }
                        else
                        {
                            // Add regular form field
                            var schema = new OpenApiSchema
                            {
                                Type = param.ParameterType == typeof(string) ? "string" :
                                       param.ParameterType == typeof(int) || param.ParameterType == typeof(int?) ? "integer" :
                                       param.ParameterType == typeof(bool) || param.ParameterType == typeof(bool?) ? "boolean" :
                                       "string"
                            };

                            operation.RequestBody.Content["multipart/form-data"].Schema.Properties[param.Name] = schema;
                            
                            // Add to required if parameter is not nullable
                            if (!param.IsOptional && param.ParameterType != typeof(string))
                            {
                                // Ensure Required list exists
                                if (operation.RequestBody.Content["multipart/form-data"].Schema.Required == null)
                                {
                                    operation.RequestBody.Content["multipart/form-data"].Schema.Required = new HashSet<string>();
                                }
                                
                                if (!operation.RequestBody.Content["multipart/form-data"].Schema.Required.Contains(param.Name))
                                {
                                    operation.RequestBody.Content["multipart/form-data"].Schema.Required.Add(param.Name);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

