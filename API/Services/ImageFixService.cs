using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using System.Net.Http;

namespace InstapropAPI.Services
{
    public class ImageFixService
    {
        private readonly AppDbContext _context;
        private readonly HttpClient _httpClient;
        private readonly ILogger<ImageFixService> _logger;

        // Placeholder image URLs (using reliable CDN services)
        private const string PlaceholderPropertyImage = "https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800&h=600&fit=crop";
        private const string PlaceholderDocumentImage = "https://images.unsplash.com/photo-1450101499163-c8848c66ca85?w=800&h=600&fit=crop";
        private const string PlaceholderProfileImage = "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop";
        private const string PlaceholderNewsImage = "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=600&fit=crop";
        private const string PlaceholderCommunityImage = "https://images.unsplash.com/photo-1521737711867-e3b97375f902?w=800&h=600&fit=crop";

        public ImageFixService(AppDbContext context, IHttpClientFactory httpClientFactory, ILogger<ImageFixService> logger)
        {
            _context = context;
            _httpClient = httpClientFactory.CreateClient();
            _httpClient.Timeout = TimeSpan.FromSeconds(5); // Quick timeout for broken links
            _logger = logger;
        }

        public async Task<ImageFixResult> FixAllBrokenImagesAsync()
        {
            var result = new ImageFixResult();
            _logger.LogInformation("🔍 Starting image fix process...");

            try
            {
                // Fix ChildProperty images
                await FixChildPropertyImagesAsync(result);

                // Fix PropertyImage records
                await FixPropertyImagesAsync(result);

                // Fix PropertyDoc images
                await FixPropertyDocsAsync(result);

                // Fix UserDoc images
                await FixUserDocsAsync(result);

                // Fix ProjectUpdate images
                await FixProjectUpdatesAsync(result);

                // Fix NewsImage records
                await FixNewsImagesAsync(result);

                // Fix CommunityPost images
                await FixCommunityPostsAsync(result);

                // Fix DeveloperProfile images
                await FixDeveloperProfilesAsync(result);

                // Fix Event schedule images
                await FixEventScheduleImagesAsync(result);

                await _context.SaveChangesAsync();
                _logger.LogInformation($"✅ Image fix completed. Fixed {result.TotalFixed} images, {result.TotalChecked} checked, {result.TotalBroken} broken.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Error during image fix process");
                result.ErrorMessage = ex.Message;
            }

            return result;
        }

        private async Task FixChildPropertyImagesAsync(ImageFixResult result)
        {
            var properties = await _context.ChildProperties
                .Where(p => !string.IsNullOrEmpty(p.ImageUrl))
                .ToListAsync();

            foreach (var property in properties)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(property.ImageUrl))
                {
                    result.TotalBroken++;
                    property.ImageUrl = PlaceholderPropertyImage;
                    result.FixedProperties++;
                    _logger.LogWarning($"Fixed broken image for Property {property.PropertyId}: {property.Name}");
                }
            }
        }

        private async Task FixPropertyImagesAsync(ImageFixResult result)
        {
            var images = await _context.PropertyImages
                .Where(img => !string.IsNullOrEmpty(img.ImageUrl))
                .ToListAsync();

            foreach (var image in images)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(image.ImageUrl))
                {
                    result.TotalBroken++;
                    image.ImageUrl = PlaceholderPropertyImage;
                    result.FixedPropertyImages++;
                    _logger.LogWarning($"Fixed broken PropertyImage {image.PropertyImageId}");
                }
            }
        }

        private async Task FixPropertyDocsAsync(ImageFixResult result)
        {
            var docs = await _context.PropertyDocs
                .Where(doc => !string.IsNullOrEmpty(doc.ImgUrl))
                .ToListAsync();

            foreach (var doc in docs)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(doc.ImgUrl))
                {
                    result.TotalBroken++;
                    doc.ImgUrl = PlaceholderDocumentImage;
                    result.FixedPropertyDocs++;
                    _logger.LogWarning($"Fixed broken PropertyDoc {doc.DocId}");
                }
            }
        }

        private async Task FixUserDocsAsync(ImageFixResult result)
        {
            var docs = await _context.UserDocs
                .Where(doc => !string.IsNullOrEmpty(doc.ImgUrl))
                .ToListAsync();

            foreach (var doc in docs)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(doc.ImgUrl))
                {
                    result.TotalBroken++;
                    doc.ImgUrl = PlaceholderDocumentImage;
                    result.FixedUserDocs++;
                    _logger.LogWarning($"Fixed broken UserDoc {doc.DocId}");
                }
            }
        }

        private async Task FixProjectUpdatesAsync(ImageFixResult result)
        {
            var updates = await _context.ProjectUpdates
                .Where(u => !string.IsNullOrEmpty(u.ImageUrl))
                .ToListAsync();

            foreach (var update in updates)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(update.ImageUrl))
                {
                    result.TotalBroken++;
                    update.ImageUrl = PlaceholderPropertyImage;
                    result.FixedProjectUpdates++;
                    _logger.LogWarning($"Fixed broken ProjectUpdate {update.UpdateId}");
                }
            }
        }

        private async Task FixNewsImagesAsync(ImageFixResult result)
        {
            var images = await _context.NewsImages
                .Where(img => !string.IsNullOrEmpty(img.ImageUrl))
                .ToListAsync();

            foreach (var image in images)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(image.ImageUrl))
                {
                    result.TotalBroken++;
                    image.ImageUrl = PlaceholderNewsImage;
                    result.FixedNewsImages++;
                    _logger.LogWarning($"Fixed broken NewsImage {image.NewsImageId}");
                }
            }
        }

        private async Task FixCommunityPostsAsync(ImageFixResult result)
        {
            var posts = await _context.CommunityPosts
                .Where(p => !string.IsNullOrEmpty(p.ImageUrl))
                .ToListAsync();

            foreach (var post in posts)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(post.ImageUrl))
                {
                    result.TotalBroken++;
                    post.ImageUrl = PlaceholderCommunityImage;
                    result.FixedCommunityPosts++;
                    _logger.LogWarning($"Fixed broken CommunityPost {post.PostId}");
                }
            }
        }

        private async Task FixDeveloperProfilesAsync(ImageFixResult result)
        {
            var profiles = await _context.DeveloperProfiles
                .Where(p => !string.IsNullOrEmpty(p.ProfileImageUrl))
                .ToListAsync();

            foreach (var profile in profiles)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(profile.ProfileImageUrl))
                {
                    result.TotalBroken++;
                    profile.ProfileImageUrl = PlaceholderProfileImage;
                    result.FixedDeveloperProfiles++;
                    _logger.LogWarning($"Fixed broken DeveloperProfile {profile.ProfileId}");
                }
            }
        }

        private async Task FixEventScheduleImagesAsync(ImageFixResult result)
        {
            var events = await _context.Events
                .Where(e => !string.IsNullOrEmpty(e.ScheduleImageUrl))
                .ToListAsync();

            foreach (var evt in events)
            {
                result.TotalChecked++;
                if (!await IsImageAccessibleAsync(evt.ScheduleImageUrl))
                {
                    result.TotalBroken++;
                    evt.ScheduleImageUrl = PlaceholderDocumentImage;
                    result.FixedEventImages++;
                    _logger.LogWarning($"Fixed broken Event schedule image {evt.EventId}");
                }
            }
        }

        private async Task<bool> IsImageAccessibleAsync(string url)
        {
            if (string.IsNullOrEmpty(url))
                return false;

            // Skip placeholder URLs (they're already fixed)
            if (url.Contains("unsplash.com") || url.Contains("placeholder"))
                return true;

            try
            {
                var response = await _httpClient.GetAsync(url, HttpCompletionOption.ResponseHeadersRead);
                return response.IsSuccessStatusCode && 
                       response.Content.Headers.ContentType?.MediaType?.StartsWith("image/") == true;
            }
            catch
            {
                return false;
            }
        }
    }

    public class ImageFixResult
    {
        public int TotalChecked { get; set; }
        public int TotalBroken { get; set; }
        public int TotalFixed { get; set; }
        public int FixedProperties { get; set; }
        public int FixedPropertyImages { get; set; }
        public int FixedPropertyDocs { get; set; }
        public int FixedUserDocs { get; set; }
        public int FixedProjectUpdates { get; set; }
        public int FixedNewsImages { get; set; }
        public int FixedCommunityPosts { get; set; }
        public int FixedDeveloperProfiles { get; set; }
        public int FixedEventImages { get; set; }
        public string? ErrorMessage { get; set; }
    }
}

