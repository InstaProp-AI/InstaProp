using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Services;
using PropertyFlipperAPI.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

// Add DB Context with SQLite
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));
   // options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
// "DefaultConnection": "Host=metro.proxy.rlwy.net;Port=20873;Database=railway;Username=postgres;Password=wXQPZyZfdnrcYMrZCpXEcPJnJXQUUPmv;SslMode=Require"
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
    c.SwaggerDoc("v1", new() { Title = "Property Flipper API", Version = "v1" });
    
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

// CORS - Allow all origins in development, restricted in production
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
            // Production: Use configured allowed origins
            var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() 
                ?? new[] { "https://yourdomain.com" };
            
            Console.WriteLine($"🔒 CORS: Allowing specific origins (Production Mode): {string.Join(", ", allowedOrigins)}");
            policy.WithOrigins(allowedOrigins)
                  .AllowCredentials()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
    });
});

builder.Services.AddMemoryCache();

// JWT Auth
var jwtSection = builder.Configuration.GetSection("Jwt");
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"] ?? "insecure"));
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
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Property Flipper API v1");
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
        Console.WriteLine("📦 Applying pending migrations (if any)...");
        await context.Database.MigrateAsync();
        Console.WriteLine("✅ Database schema up to date.");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"❌ Failed to apply migrations: {ex.Message}");
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

await app.RunAsync();