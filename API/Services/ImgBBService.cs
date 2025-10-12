using System;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace PropertyFlipperAPI.Services
{
    public class ImgBBService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ImgBBService> _logger;
        private readonly string _apiKey;
        private const string API_BASE_URL = "https://api.imgbb.com/1/upload";

        public ImgBBService(
            IHttpClientFactory httpClientFactory, 
            IConfiguration configuration,
            ILogger<ImgBBService> logger)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
            _apiKey = _configuration["ImgBB:ApiKey"] ?? throw new InvalidOperationException("ImgBB API Key not configured");
        }

        /// <summary>
        /// Upload an image file to ImgBB
        /// </summary>
        /// <param name="imageBytes">Image file bytes</param>
        /// <param name="fileName">Optional file name</param>
        /// <param name="expirationSeconds">Optional expiration time in seconds (60-15552000, 0 for no expiration)</param>
        /// <returns>ImgBBUploadResponse containing URLs and metadata</returns>
        public async Task<ImgBBUploadResponse> UploadImageAsync(byte[] imageBytes, string? fileName = null, int expirationSeconds = 0)
        {
            try
            {
                var base64Image = Convert.ToBase64String(imageBytes);
                return await UploadBase64ImageAsync(base64Image, fileName, expirationSeconds);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image to ImgBB");
                throw new Exception($"Failed to upload image: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Upload a base64 encoded image to ImgBB
        /// </summary>
        /// <param name="base64Image">Base64 encoded image string</param>
        /// <param name="fileName">Optional file name</param>
        /// <param name="expirationSeconds">Optional expiration time in seconds (60-15552000, 0 for no expiration)</param>
        /// <returns>ImgBBUploadResponse containing URLs and metadata</returns>
        public async Task<ImgBBUploadResponse> UploadBase64ImageAsync(string base64Image, string? fileName = null, int expirationSeconds = 0)
        {
            try
            {
                var client = _httpClientFactory.CreateClient();
                
                // Build URL with API key and optional expiration
                var url = $"{API_BASE_URL}?key={_apiKey}";
                if (expirationSeconds > 0)
                {
                    // Validate expiration range
                    if (expirationSeconds < 60 || expirationSeconds > 15552000)
                    {
                        throw new ArgumentException("Expiration must be between 60 and 15552000 seconds");
                    }
                    url += $"&expiration={expirationSeconds}";
                }

                // Create form data
                var formData = new MultipartFormDataContent();
                formData.Add(new StringContent(base64Image), "image");
                
                if (!string.IsNullOrEmpty(fileName))
                {
                    formData.Add(new StringContent(fileName), "name");
                }

                // Send POST request
                var response = await client.PostAsync(url, formData);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("ImgBB API error: {StatusCode} - {Response}", response.StatusCode, responseContent);
                    throw new HttpRequestException($"ImgBB API returned {response.StatusCode}: {responseContent}");
                }

                // Parse response
                var apiResponse = JsonSerializer.Deserialize<ImgBBApiResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (apiResponse == null || !apiResponse.Success)
                {
                    throw new Exception("ImgBB API returned unsuccessful response");
                }

                return new ImgBBUploadResponse
                {
                    Id = apiResponse.Data.Id,
                    Title = apiResponse.Data.Title,
                    Url = apiResponse.Data.Url,
                    DisplayUrl = apiResponse.Data.DisplayUrl ?? apiResponse.Data.Url,
                    DeleteUrl = apiResponse.Data.DeleteUrl,
                    Width = apiResponse.Data.Width,
                    Height = apiResponse.Data.Height,
                    Size = apiResponse.Data.Size,
                    Time = apiResponse.Data.Time,
                    Expiration = apiResponse.Data.Expiration,
                    FileName = apiResponse.Data.Image?.Filename ?? fileName,
                    Extension = apiResponse.Data.Image?.Extension
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading base64 image to ImgBB");
                throw new Exception($"Failed to upload image: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Upload an image from URL to ImgBB
        /// </summary>
        /// <param name="imageUrl">URL of the image to upload</param>
        /// <param name="fileName">Optional file name</param>
        /// <param name="expirationSeconds">Optional expiration time in seconds</param>
        /// <returns>ImgBBUploadResponse containing URLs and metadata</returns>
        public async Task<ImgBBUploadResponse> UploadImageFromUrlAsync(string imageUrl, string? fileName = null, int expirationSeconds = 0)
        {
            try
            {
                var client = _httpClientFactory.CreateClient();
                
                // Build URL with API key and optional expiration
                var url = $"{API_BASE_URL}?key={_apiKey}";
                if (expirationSeconds > 0)
                {
                    if (expirationSeconds < 60 || expirationSeconds > 15552000)
                    {
                        throw new ArgumentException("Expiration must be between 60 and 15552000 seconds");
                    }
                    url += $"&expiration={expirationSeconds}";
                }

                // Create form data
                var formData = new MultipartFormDataContent();
                formData.Add(new StringContent(imageUrl), "image");
                
                if (!string.IsNullOrEmpty(fileName))
                {
                    formData.Add(new StringContent(fileName), "name");
                }

                // Send POST request
                var response = await client.PostAsync(url, formData);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("ImgBB API error: {StatusCode} - {Response}", response.StatusCode, responseContent);
                    throw new HttpRequestException($"ImgBB API returned {response.StatusCode}: {responseContent}");
                }

                // Parse response
                var apiResponse = JsonSerializer.Deserialize<ImgBBApiResponse>(responseContent, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (apiResponse == null || !apiResponse.Success)
                {
                    throw new Exception("ImgBB API returned unsuccessful response");
                }

                return new ImgBBUploadResponse
                {
                    Id = apiResponse.Data.Id,
                    Title = apiResponse.Data.Title,
                    Url = apiResponse.Data.Url,
                    DisplayUrl = apiResponse.Data.DisplayUrl ?? apiResponse.Data.Url,
                    DeleteUrl = apiResponse.Data.DeleteUrl,
                    Width = apiResponse.Data.Width,
                    Height = apiResponse.Data.Height,
                    Size = apiResponse.Data.Size,
                    Time = apiResponse.Data.Time,
                    Expiration = apiResponse.Data.Expiration,
                    FileName = apiResponse.Data.Image?.Filename ?? fileName,
                    Extension = apiResponse.Data.Image?.Extension
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading image from URL to ImgBB");
                throw new Exception($"Failed to upload image from URL: {ex.Message}", ex);
            }
        }
    }

    // Response models
    public class ImgBBUploadResponse
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
        public string DisplayUrl { get; set; } = string.Empty;
        public string? DeleteUrl { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int Size { get; set; }
        public long Time { get; set; }
        public int Expiration { get; set; }
        public string? FileName { get; set; }
        public string? Extension { get; set; }
    }

    // Internal API response models
    internal class ImgBBApiResponse
    {
        public ImgBBData Data { get; set; } = new ImgBBData();
        public bool Success { get; set; }
        public int Status { get; set; }
    }

    internal class ImgBBData
    {
        public string Id { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
        public string? DisplayUrl { get; set; }
        public string? DeleteUrl { get; set; }
        public int Width { get; set; }
        public int Height { get; set; }
        public int Size { get; set; }
        public long Time { get; set; }
        public int Expiration { get; set; }
        public ImgBBImageInfo? Image { get; set; }
    }

    internal class ImgBBImageInfo
    {
        public string? Filename { get; set; }
        public string? Name { get; set; }
        public string? Mime { get; set; }
        public string? Extension { get; set; }
        public string? Url { get; set; }
    }
}


