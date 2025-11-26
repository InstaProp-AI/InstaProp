using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Services;
using InstapropAPI.Middleware;
using InstapropAPI.Filters;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Reflection;
using System.Linq;
using Microsoft.Extensions.FileProviders;

var builder = WebApplication.CreateBuilder(args);

// Add DB Context - Use PostgreSQL only (from DATABASE_URL or connection string)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

// Debug: Log environment check
Console.WriteLine($"🔍 DATABASE_URL is {(string.IsNullOrEmpty(databaseUrl) ? "NOT SET" : "SET")}");
if (!string.IsNullOrEmpty(databaseUrl))
{
    // Don't log full URL for security, just confirm it exists
    try
    {
        var uri = new Uri(databaseUrl);
        Console.WriteLine($"🔍 DATABASE_URL host: {uri.Host}, database: {uri.LocalPath.TrimStart('/')}");
    }
    catch
    {
        Console.WriteLine($"🔍 DATABASE_URL format could not be parsed");
    }
}

string finalConnectionString;

// Railway provides DATABASE_URL in format: postgresql://user:password@host:port/database
// Convert it to Npgsql connection string format if present
if (!string.IsNullOrEmpty(databaseUrl))
{
    try
    {
        // Parse Railway DATABASE_URL format: postgresql://user:password@host:port/database
        var uri = new Uri(databaseUrl);
        var host = uri.Host;
        var port = uri.Port > 0 ? uri.Port : 5432; // Default PostgreSQL port
        var database = uri.LocalPath.TrimStart('/');
        var username = !string.IsNullOrEmpty(uri.UserInfo) ? uri.UserInfo.Split(':')[0] : "";
        var password = !string.IsNullOrEmpty(uri.UserInfo) && uri.UserInfo.Split(':').Length > 1 
            ? uri.UserInfo.Split(':')[1] : "";
        
        finalConnectionString = $"Host={host};Port={port};Database={database};Username={username};Password={password};SslMode=Require";
        Console.WriteLine($"🗄️ Using PostgreSQL from DATABASE_URL: {host}:{port}/{database}");
    }
    catch (Exception ex)
    {
        throw new Exception($"CRITICAL: Failed to parse DATABASE_URL environment variable. Error: {ex.Message}");
    }
}
else if (!string.IsNullOrEmpty(connectionString) && connectionString.Contains("Host="))
{
    // Connection string is already in PostgreSQL format
    finalConnectionString = connectionString;
    Console.WriteLine($"🗄️ Using PostgreSQL from connection string");
}
else
{
    throw new Exception("CRITICAL: No database connection configured. Set DATABASE_URL environment variable or configure PostgreSQL connection string in appsettings.json");
}

// Configure DbContext with PostgreSQL only
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(finalConnectionString);
    // Suppress pending model changes warning
    options.ConfigureWarnings(warnings =>
        warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
});
// Add Services
builder.Services.AddScoped<RoleSeederService>();
builder.Services.AddScoped<GlobalSeedingService>();
builder.Services.AddSingleton<FirestoreService>();
builder.Services.AddScoped<SmtpEmailService>(); // SMTP email sending
builder.Services.AddScoped<EmailTemplateService>(); // HTML email templates
builder.Services.AddScoped<EmailVerificationService>();
builder.Services.AddScoped<AuctionNotificationService>(); // Auction email notifications
builder.Services.AddScoped<PhoneVerificationService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<NotificationHelperService>();
builder.Services.AddSingleton<ErrorTrackingService>();
builder.Services.AddScoped<FcmPushNotificationService>();
builder.Services.AddScoped<FileValidationService>();
builder.Services.AddScoped<ImgBBService>(); // ImgBB image upload service
builder.Services.AddScoped<RewardService>(); // Gamification rewards
builder.Services.AddScoped<LeaderboardService>(); // Leaderboard + cashback engine
builder.Services.AddScoped<OpenAIService>(); // OpenAI Vision API for payment schedule scanning
builder.Services.AddScoped<InstallmentSummaryService>();
builder.Services.AddScoped<ImageFixService>();
builder.Services.AddScoped<DeveloperPermissionService>();

// Add HttpClient for FCM and ImgBB
builder.Services.AddHttpClient();

// Add Background Services
builder.Services.AddHostedService<AuctionExpirationService>();
builder.Services.AddHostedService<NotificationCleanupService>();
builder.Services.AddHostedService<ChatCleanupService>();

// Add Health Checks
builder.Services.AddHealthChecks();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "Instaprop API", Version = "v1" });
    
    // Add JWT Authentication to Swagger
    c.AddSecurityDefinition("Bearer", new()
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    
    // Don't apply security globally - only to specific endpoints
    
    // Handle circular references by using unique schema IDs based on full name
    c.CustomSchemaIds(type =>
    {
        try
        {
            if (type.IsGenericType)
            {
                var name = type.Name.Substring(0, type.Name.IndexOf('`'));
                var args = type.GetGenericArguments().Select(t => t.Name);
                return $"{name}Of{string.Join("And", args)}";
            }
            return type.FullName?.Replace("+", ".") ?? type.Name;
        }
        catch
        {
            // Fallback to simple name if schema ID generation fails
            return type.Name;
        }
    });
    
    // Ignore circular references in navigation properties
    c.IgnoreObsoleteProperties();
    
    // Map types to avoid circular reference issues
    c.MapType<DateTime>(() => new Microsoft.OpenApi.Models.OpenApiSchema
    {
        Type = "string",
        Format = "date-time"
    });
    
    // Map IFormFile to prevent parameter generation errors
    c.MapType<IFormFile>(() => new Microsoft.OpenApi.Models.OpenApiSchema
    {
        Type = "string",
        Format = "binary"
    });
    
    // Filter out problematic schema types that cause generation errors
    c.SchemaFilter<SwaggerSchemaFilter>();
    
    // Add operation filter to handle errors gracefully
    c.OperationFilter<SwaggerOperationFilter>();
    
    // Add filter to handle file upload endpoints (IFormFile)
    c.OperationFilter<SwaggerFileUploadFilter>();
    
    // Suppress schema warnings and errors
    c.IgnoreObsoleteActions();
    c.IgnoreObsoleteProperties();
    
    // Include XML comments if available (optional)
    try
    {
        var xmlFile = $"{Assembly.GetExecutingAssembly().GetName().Name}.xml";
        var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
        if (File.Exists(xmlPath))
        {
            c.IncludeXmlComments(xmlPath);
        }
    }
    catch
    {
        // Ignore if XML file doesn't exist
    }
});

// CORS - Allow all origins for mobile apps (both development and production)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AppCors", policy =>
    {
        var isDevelopment = builder.Environment.IsDevelopment();
        
        if (isDevelopment)
        {
            // Development: Allow all origins for easier testing
            Console.WriteLine("🌍 CORS: Allowing ALL origins (Development Mode)");
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
        else
        {
            // Production: Allow all origins for mobile apps (APK/IPA can come from anywhere)
            // Mobile apps don't have a fixed origin, so we need to allow all
            Console.WriteLine("🌍 CORS: Allowing ALL origins (Production Mode - Mobile Apps)");
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
    });
});

builder.Services.AddMemoryCache();

// JWT Auth - Read from environment variable in production, config file in development
var jwtSection = builder.Configuration.GetSection("Jwt");
var jwtKey = Environment.GetEnvironmentVariable("JWT_SECRET") ?? jwtSection["Key"] ?? "insecure";
if (string.IsNullOrEmpty(jwtKey) || jwtKey == "insecure" || jwtKey.Contains("REPLACE"))
{
    Console.WriteLine("⚠️ WARNING: Using insecure JWT key. Set JWT_SECRET environment variable in production!");
}
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    // Allow HTTP in development, require HTTPS in production
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSection["Issuer"],
        ValidAudience = jwtSection["Audience"],
        IssuerSigningKey = signingKey,
        ClockSkew = TimeSpan.FromMinutes(2)
    };
});

var app = builder.Build();

// Enable Swagger in all environments - MUST come before error handling and SPA fallback
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Instaprop API v1");
    c.RoutePrefix = "swagger"; // Swagger UI will be available at /swagger
    c.ConfigObject.AdditionalItems.Add("syntaxHighlight", false); // Disable syntax highlighting for better compatibility
});
Console.WriteLine("✅ Swagger UI available at /swagger");
Console.WriteLine("✅ Swagger JSON available at /swagger/v1/swagger.json");

app.UseCors("AppCors");

// Production middleware enabled
// Global error handling middleware (catches all unhandled exceptions)
// Note: Swagger paths are handled before this, so Swagger errors will show in browser
app.UseErrorHandling();

// Rate limiting middleware (protects against DDoS and abuse)
// Uncomment when needed:
// app.UseRateLimiting(maxRequestsPerWindow: 1000, timeWindowSeconds: 60);

// Serve React dashboard from dashboard/dist (default web app)
// Try multiple paths: same directory (Docker), parent directory (local dev)
var dashboardPaths = new[]
{
    Path.Combine(builder.Environment.ContentRootPath, "dashboard", "dist"), // Docker container
    Path.Combine(builder.Environment.ContentRootPath, "..", "dashboard", "dist"), // Local development
};

string? dashboardPath = null;
foreach (var path in dashboardPaths)
{
    if (Directory.Exists(path))
    {
        dashboardPath = path;
        break;
    }
}

// Serve other static files from wwwroot (uploads, Flutter web bundle, etc.)
app.UseStaticFiles();
Console.WriteLine("✅ Default static files served from wwwroot");

if (dashboardPath != null)
{
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(dashboardPath),
        RequestPath = ""
    });
    Console.WriteLine($"✅ React Dashboard served from: {dashboardPath}");
}
else
{
    Console.WriteLine($"⚠️ React Dashboard not found. Checked paths:");
    foreach (var path in dashboardPaths)
    {
        Console.WriteLine($"   - {path}");
    }
}
app.UseAuthentication();
app.UseAuthorization();

// Flutter SPA fallback middleware - must be after static files but before routing
var flutterDistPaths = new[]
{
    Path.Combine(builder.Environment.ContentRootPath, "wwwroot", "flutter"), // Published output (Docker)
    Path.Combine(builder.Environment.ContentRootPath, "..", "API", "wwwroot", "flutter"), // Local dev publish
};

string? flutterDistPath = null;
foreach (var path in flutterDistPaths)
{
    if (Directory.Exists(path))
    {
        flutterDistPath = path;
        break;
    }
}

if (flutterDistPath != null)
{
    var flutterIndex = Path.Combine(flutterDistPath, "index.html");
    if (File.Exists(flutterIndex))
    {
        // Add middleware to serve Flutter index.html for SPA routing
        // This runs AFTER static files, so actual files are served first
        app.Use(async (context, next) =>
        {
            var path = context.Request.Path.Value ?? "";
            
            // Only handle /flutter routes that haven't been served by static files
            if (path.StartsWith("/flutter") && !context.Response.HasStarted)
            {
                // Check if this is a direct /flutter request or a route that doesn't match a file
                if (path == "/flutter" || path == "/flutter/")
                {
                    // Direct /flutter request - serve index.html
                    var indexPath = Path.Combine(flutterDistPath, "index.html");
                    if (File.Exists(indexPath))
                    {
                        context.Response.ContentType = "text/html; charset=utf-8";
                        var html = await File.ReadAllTextAsync(indexPath);
                        await context.Response.WriteAsync(html);
                        return; // Don't call next()
                    }
                }
                else if (path.StartsWith("/flutter/"))
                {
                    // Check if the requested file exists
                    var relativePath = path.Substring("/flutter".Length).TrimStart('/');
                    var filePath = Path.Combine(flutterDistPath, relativePath);
                    
                    // If file doesn't exist, serve index.html for SPA
                    if (!File.Exists(filePath) && !Directory.Exists(filePath))
                    {
                        var indexPath = Path.Combine(flutterDistPath, "index.html");
                        if (File.Exists(indexPath))
                        {
                            context.Response.ContentType = "text/html; charset=utf-8";
                            var html = await File.ReadAllTextAsync(indexPath);
                            await context.Response.WriteAsync(html);
                            return; // Don't call next()
                        }
                    }
                }
            }
            
            // Continue to next middleware (static files should have already handled file requests)
            await next();
        });
        
        Console.WriteLine($"✅ Flutter SPA fallback middleware configured from: {flutterDistPath}");
    }
}

// Database Setup: Seed Roles, Run Global Seeding, and Create Admin Account
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var roleSeeder = scope.ServiceProvider.GetRequiredService<RoleSeederService>();
    var globalSeeding = scope.ServiceProvider.GetRequiredService<GlobalSeedingService>();

    try
    {
        // Step 1: Seed Roles (required before any accounts can be created)
        Console.WriteLine("🔐 Seeding Roles...");
        await roleSeeder.SeedRolesAsync();
        
        // Verify roles were created
        var rolesCount = await context.Roles.CountAsync();
        if (rolesCount == 0)
        {
            Console.WriteLine("⚠️ WARNING: Roles table is empty. Make sure migrations are applied first.");
        }
        else
        {
            Console.WriteLine($"✅ Seeded {rolesCount} roles successfully.");
        }

        // Step 2: Check account count before seeding
        // Only seed if there is 1 or fewer accounts (allowing for the admin account)
        var accountCount = await context.Accounts.CountAsync();
        Console.WriteLine($"\n📊 Current account count: {accountCount}");
        
        if (accountCount > 1)
        {
            Console.WriteLine("ℹ️ Skipping global seeding - more than 1 account exists (admin + other accounts).");
            Console.WriteLine("   Seeding will only run when there is 1 or fewer accounts.");
        }
        else
        {
            Console.WriteLine("🌍 Running global seeding (will skip existing entities)...");
            await globalSeeding.PreSeedTestDataAsync(skipClear: true);
            Console.WriteLine("✅ Global seeding completed!");
        }

        // Step 3: Ensure default admin account exists
        var adminConfig = builder.Configuration.GetSection("DefaultAdmin");
        var adminEmail = adminConfig["Email"];
        if (!string.IsNullOrEmpty(adminEmail))
        {
            var adminExists = await context.Accounts.AnyAsync(a => a.Email == adminEmail);
            if (!adminExists)
            {
                Console.WriteLine("👤 Creating default admin account...");
                
                // Verify ADMIN_ROLE_ID exists
                var adminRole = await context.Roles.FindAsync(Role.ADMIN_ROLE_ID);
                if (adminRole == null)
                {
                    Console.WriteLine($"❌ ERROR: Admin role (ID: {Role.ADMIN_ROLE_ID}) does not exist. Cannot create admin account.");
                }
                else
                {
                    var adminAccount = new AdminAccount
                    {
                        Email = adminEmail,
                        FirstName = adminConfig["FirstName"] ?? "Admin",
                        LastName = adminConfig["LastName"] ?? "System",
                        PhoneNumber = adminConfig["PhoneNumber"] ?? "+1234567890",
                        RoleId = Role.ADMIN_ROLE_ID, // Use the constant GUID
                        HashedPassword = BCrypt.Net.BCrypt.HashPassword(adminConfig["Password"] ?? "Admin123!"),
                        Status = VerificationStatus.Verified,
                        EmailVerified = true,
                        PhoneVerified = true,
                        TimeZone = "America/New_York",
                        CreatedAt = DateTime.UtcNow
                    };
                    context.Accounts.Add(adminAccount);
                    await context.SaveChangesAsync();
                    
                    // Verify the admin was created with correct role
                    var createdAdmin = await context.Accounts.FirstOrDefaultAsync(a => a.Email == adminEmail);
                    if (createdAdmin != null)
                    {
                        Console.WriteLine($"✅ Default admin created: {adminEmail}");
                        Console.WriteLine($"   RoleId: {createdAdmin.RoleId}");
                        Console.WriteLine($"   Expected Admin RoleId: {Role.ADMIN_ROLE_ID}");
                        if (createdAdmin.RoleId == Role.ADMIN_ROLE_ID)
                        {
                            Console.WriteLine($"   ✅ RoleId matches correctly!");
                        }
                        else
                        {
                            Console.WriteLine($"   ❌ ERROR: RoleId mismatch! Admin has wrong role.");
                        }
                    }
                }
            }
            else
            {
                Console.WriteLine($"ℹ️ Admin account already exists: {adminEmail}");
                
                // Verify existing admin has correct role
                var existingAdmin = await context.Accounts.FirstOrDefaultAsync(a => a.Email == adminEmail);
                if (existingAdmin != null)
                {
                    Console.WriteLine($"   Current RoleId: {existingAdmin.RoleId}");
                    Console.WriteLine($"   Expected Admin RoleId: {Role.ADMIN_ROLE_ID}");
                    if (existingAdmin.RoleId != Role.ADMIN_ROLE_ID)
                    {
                        Console.WriteLine($"   ⚠️ WARNING: Existing admin has wrong RoleId. Fixing...");
                        existingAdmin.RoleId = Role.ADMIN_ROLE_ID;
                        await context.SaveChangesAsync();
                        Console.WriteLine($"   ✅ Fixed admin RoleId to {Role.ADMIN_ROLE_ID}");
                    }
                    else
                    {
                        Console.WriteLine($"   ✅ Admin RoleId is correct.");
                    }
                }
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Database setup failed: {ex.Message}");
        if (ex.InnerException != null)
        {
            Console.WriteLine($"   Inner Exception: {ex.InnerException.Message}");
        }
        Console.WriteLine($"   Stack Trace: {ex.StackTrace}");
        // Don't throw - allow app to start even if setup fails
    }
}
// Map API controllers - MUST be before fallback to ensure /api/* routes work
app.MapControllers();
Console.WriteLine("✅ API Controllers mapped at /api/*");

// Health check endpoint for monitoring
app.MapHealthChecks("/health");
Console.WriteLine("✅ Health check endpoint available at /health");

// Serve React dashboard for all non-API routes (SPA fallback)
// Use the same path resolution as static files
var dashboardDistPaths = new[]
{
    Path.Combine(builder.Environment.ContentRootPath, "dashboard", "dist"), // Docker container
    Path.Combine(builder.Environment.ContentRootPath, "..", "dashboard", "dist"), // Local development
};

string? dashboardDistPath = null;
foreach (var path in dashboardDistPaths)
{
    if (Directory.Exists(path))
    {
        dashboardDistPath = path;
        break;
    }
}

if (dashboardDistPath != null)
{
    app.MapFallbackToFile("index.html", new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(dashboardDistPath),
        RequestPath = ""
    });
    Console.WriteLine($"✅ React Dashboard fallback configured from: {dashboardDistPath}");
}
else
{
    Console.WriteLine($"❌ ERROR: React Dashboard dist folder not found. Checked paths:");
    foreach (var path in dashboardDistPaths)
    {
        Console.WriteLine($"   - {path}");
    }
    Console.WriteLine($"❌ Application will not serve a frontend. Please ensure the dashboard is built.");
}

await app.RunAsync();