using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Services;
using InstapropAPI.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Reflection;
using Microsoft.Extensions.FileProviders;

var builder = WebApplication.CreateBuilder(args);

// Add DB Context - Use PostgreSQL in production (Railway), SQLite in development
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
var databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

// Debug: Log environment check (only once, not during migrations)
var isProduction = builder.Environment.IsProduction();
if (isProduction)
{
    Console.WriteLine($"🔍 Environment: Production");
    Console.WriteLine($"🔍 DATABASE_URL is {(string.IsNullOrEmpty(databaseUrl) ? "NOT SET" : "SET")}");
    if (!string.IsNullOrEmpty(databaseUrl))
    {
        // Don't log full URL for security, just confirm it exists
        var uri = new Uri(databaseUrl);
        Console.WriteLine($"🔍 DATABASE_URL host: {uri.Host}, database: {uri.LocalPath.TrimStart('/')}");
    }
}

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
        
        connectionString = $"Host={host};Port={port};Database={database};Username={username};Password={password};SslMode=Require";
        Console.WriteLine($"🗄️ Using PostgreSQL: {host}:{port}/{database}");
        
        builder.Services.AddDbContext<AppDbContext>(options =>
        {
            options.UseNpgsql(connectionString);
            // Suppress pending model changes warning in production
            options.ConfigureWarnings(warnings =>
                warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
        });
    }
    catch (Exception ex)
    {
        Console.WriteLine($"⚠️ Failed to parse DATABASE_URL: {ex.Message}");
        if (!isProduction)
        {
            Console.WriteLine($"⚠️ Falling back to SQLite for local development");
            builder.Services.AddDbContext<AppDbContext>(options =>
                options.UseSqlite(connectionString ?? "Data Source=mydb.db"));
        }
        else
        {
            throw new Exception($"CRITICAL: DATABASE_URL is set but invalid in production. Error: {ex.Message}");
        }
    }
}
else if (!string.IsNullOrEmpty(connectionString) && connectionString.Contains("Host="))
{
    // Connection string is already in PostgreSQL format
    Console.WriteLine($"🗄️ Using PostgreSQL from connection string");
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseNpgsql(connectionString));
}
else
{
    // Default to SQLite for local development only
    if (isProduction)
    {
        throw new Exception("CRITICAL: DATABASE_URL environment variable is not set in production. Railway PostgreSQL service must be linked.");
    }
    Console.WriteLine($"🗄️ Using SQLite for local development");
    builder.Services.AddDbContext<AppDbContext>(options =>
        options.UseSqlite(connectionString ?? "Data Source=mydb.db"));
}
// Add Services
//builder.Services.AddScoped<SeedDataService>();
builder.Services.AddScoped<CompleteEgyptianSeedingService>();
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
        if (type.IsGenericType)
        {
            var name = type.Name.Substring(0, type.Name.IndexOf('`'));
            var args = type.GetGenericArguments().Select(t => t.Name);
            return $"{name}Of{string.Join("And", args)}";
        }
        return type.FullName?.Replace("+", ".") ?? type.Name;
    });
    
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
    
    // Ignore obsolete properties
    c.IgnoreObsoleteProperties();
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

// Enable Swagger in all environments - MUST come before error handling
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Instaprop API v1");
    c.RoutePrefix = "swagger"; // Swagger UI will be available at /swagger
    c.ConfigObject.AdditionalItems.Add("syntaxHighlight", false); // Disable syntax highlighting for better compatibility
});

app.UseCors("AppCors");

// Production middleware enabled
// Global error handling middleware (catches all unhandled exceptions)
// Note: Swagger paths are handled before this, so Swagger errors will show in browser
app.UseErrorHandling();

// Rate limiting middleware (protects against DDoS and abuse)
// Uncomment when needed:
// app.UseRateLimiting(maxRequestsPerWindow: 1000, timeWindowSeconds: 60);

// Serve Flutter web app from wwwroot/app
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(
        Path.Combine(builder.Environment.ContentRootPath, "wwwroot", "app")),
    RequestPath = ""
});

// Serve other static files from wwwroot (uploads, etc.)
app.UseStaticFiles(); // Enable serving static files from wwwroot
app.UseAuthentication();
app.UseAuthorization();

// Seed data - Complete Egyptian Real Estate Data
// Seed the database if it's empty
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var seedService = scope.ServiceProvider.GetRequiredService<CompleteEgyptianSeedingService>();

    try
    {
        Console.WriteLine("📦 Applying migrations...");
        // Suppress detailed migration logging to avoid Railway rate limits
        await context.Database.MigrateAsync();
        Console.WriteLine("✅ Migrations completed.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Migration failed: {ex.Message}");
        if (ex.InnerException != null)
        {
            Console.WriteLine($"   Inner: {ex.InnerException.Message}");
        }
        throw;
    }
    
    // Check if database is empty (no accounts)
    var hasAccounts = await context.Accounts.AnyAsync();
    if (!hasAccounts)
    {
        Console.WriteLine("🌱 Database is empty. Starting seeding process...");
        await seedService.SeedAllDataAsync();
        Console.WriteLine("✅ Seeding completed!");
    }
    else
    {
        Console.WriteLine("ℹ️ Database already contains data. Skipping seeding.");
    }
}
app.MapControllers();

// Health check endpoint for monitoring
app.MapHealthChecks("/health");

// Serve Flutter web app for all non-API routes (SPA fallback)
app.MapFallbackToFile("index.html", new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(builder.Environment.ContentRootPath, "wwwroot", "app")),
    RequestPath = ""
});

await app.RunAsync();