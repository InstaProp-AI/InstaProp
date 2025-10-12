using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Services;
using PropertyFlipperAPI.Middleware;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add DB Context with SQLite
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));
   // options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
// "DefaultConnection": "Host=metro.proxy.rlwy.net;Port=20873;Database=railway;Username=postgres;Password=wXQPZyZfdnrcYMrZCpXEcPJnJXQUUPmv;SslMode=Require"
// Add Services
builder.Services.AddScoped<SeedDataService>();
builder.Services.AddSingleton<FirestoreService>(); // Replaces WebSocketManager
builder.Services.AddScoped<EmailVerificationService>();
builder.Services.AddScoped<PhoneVerificationService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddScoped<NotificationHelperService>();
builder.Services.AddSingleton<ErrorTrackingService>();
builder.Services.AddScoped<FcmPushNotificationService>();

// Add HttpClient for FCM
builder.Services.AddHttpClient();

// Add Background Services
builder.Services.AddHostedService<AuctionExpirationService>();
builder.Services.AddHostedService<NotificationCleanupService>();

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
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AppCors", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// JWT Auth
var jwtSection = builder.Configuration.GetSection("Jwt");
var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"] ?? "insecure"));
builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}).AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
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

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AppCors");

// Middleware temporarily disabled for development
// Uncomment when needed:

// Global error handling middleware (catches all unhandled exceptions)
// app.UseErrorHandling();

// Rate limiting middleware (protects against DDoS and abuse)
// app.UseRateLimiting(maxRequestsPerWindow: 1000, timeWindowSeconds: 60);

app.UseStaticFiles(); // Enable serving static files from wwwroot
app.UseAuthentication();
app.UseAuthorization();

// Seed data - DISABLED (notifications successfully seeded!)
// Uncomment below to re-seed the database
// using (var scope = app.Services.CreateScope())
// {
//     var seedService = scope.ServiceProvider.GetRequiredService<SeedDataService>();
//     await seedService.SeedDataAsync();
// }

app.MapControllers();

// Note: WebSocket endpoint removed - now using Firebase Firestore for real-time updates
// Real-time data synchronization is handled by Firestore on the client side

await app.RunAsync();