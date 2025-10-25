using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using PropertyFlipperAPI.Attributes;
using System.Security.Claims;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class NewsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public NewsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/news?page=1&pageSize=10
        [HttpGet]
        public async Task<ActionResult<PaginatedNewsResponse>> GetNews([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
        {
            var query = _context.NewsArticles
                .Where(n => n.IsPublished)
                .Include(n => n.Images)
                .OrderByDescending(n => n.PublishedDate);

            var totalCount = await query.CountAsync();
            var items = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NewsArticleDto
                {
                    NewsArticleId = n.NewsArticleId,
                    Title = n.Title,
                    Content = n.Content,
                    Category = n.Category,
                    PublishedDate = n.PublishedDate,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt,
                    IsPublished = n.IsPublished,
                    Images = n.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImageUrl).ToList()
                })
                .ToListAsync();

            return Ok(new PaginatedNewsResponse
            {
                Items = items,
                TotalCount = totalCount,
                CurrentPage = page,
                PageSize = pageSize,
                HasMore = (page * pageSize) < totalCount
            });
        }

        // GET: api/news/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<NewsArticleDto>> GetNewsById(long id)
        {
            var news = await _context.NewsArticles
                .Where(n => n.NewsArticleId == id && n.IsPublished)
                .Include(n => n.Images)
                .Select(n => new NewsArticleDto
                {
                    NewsArticleId = n.NewsArticleId,
                    Title = n.Title,
                    Content = n.Content,
                    Category = n.Category,
                    PublishedDate = n.PublishedDate,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt,
                    IsPublished = n.IsPublished,
                    Images = n.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImageUrl).ToList()
                })
                .FirstOrDefaultAsync();

            if (news == null)
                return NotFound("News article not found");

            return Ok(news);
        }

        // GET: api/news/latest?count=3
        [HttpGet("latest")]
        public async Task<ActionResult<List<NewsArticleDto>>> GetLatestNews([FromQuery] int count = 3)
        {
            var news = await _context.NewsArticles
                .Where(n => n.IsPublished)
                .Include(n => n.Images)
                .OrderByDescending(n => n.PublishedDate)
                .Take(count)
                .Select(n => new NewsArticleDto
                {
                    NewsArticleId = n.NewsArticleId,
                    Title = n.Title,
                    Content = n.Content,
                    Category = n.Category,
                    PublishedDate = n.PublishedDate,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt,
                    IsPublished = n.IsPublished,
                    Images = n.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImageUrl).ToList()
                })
                .ToListAsync();

            return Ok(news);
        }

        // GET: api/news/search?query=&category=&dateFrom=&dateTo=&page=1&pageSize=10
        [HttpGet("search")]
        public async Task<ActionResult<PaginatedNewsResponse>> SearchNews(
            [FromQuery] string? query = null,
            [FromQuery] string? category = null,
            [FromQuery] DateTime? dateFrom = null,
            [FromQuery] DateTime? dateTo = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var newsQuery = _context.NewsArticles
                .Where(n => n.IsPublished)
                .Include(n => n.Images)
                .AsQueryable();

            // Apply filters
            if (!string.IsNullOrEmpty(query))
            {
                newsQuery = newsQuery.Where(n => n.Title.Contains(query) || n.Content.Contains(query));
            }

            if (!string.IsNullOrEmpty(category))
            {
                newsQuery = newsQuery.Where(n => n.Category == category);
            }

            if (dateFrom.HasValue)
            {
                newsQuery = newsQuery.Where(n => n.PublishedDate >= dateFrom.Value);
            }

            if (dateTo.HasValue)
            {
                newsQuery = newsQuery.Where(n => n.PublishedDate <= dateTo.Value);
            }

            newsQuery = newsQuery.OrderByDescending(n => n.PublishedDate);

            var totalCount = await newsQuery.CountAsync();
            var items = await newsQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(n => new NewsArticleDto
                {
                    NewsArticleId = n.NewsArticleId,
                    Title = n.Title,
                    Content = n.Content,
                    Category = n.Category,
                    PublishedDate = n.PublishedDate,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt,
                    IsPublished = n.IsPublished,
                    Images = n.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImageUrl).ToList()
                })
                .ToListAsync();

            return Ok(new PaginatedNewsResponse
            {
                Items = items,
                TotalCount = totalCount,
                CurrentPage = page,
                PageSize = pageSize,
                HasMore = (page * pageSize) < totalCount
            });
        }

        // POST: api/news
        [HttpPost]
        [Authorize]
        [AdminAuthorize]
        public async Task<ActionResult<NewsArticleDto>> CreateNews([FromBody] CreateNewsDto createNewsDto)
        {
            var newsArticle = new NewsArticle
            {
                Title = createNewsDto.Title,
                Content = createNewsDto.Content,
                Category = createNewsDto.Category,
                PublishedDate = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                IsPublished = createNewsDto.IsPublished
            };

            _context.NewsArticles.Add(newsArticle);
            await _context.SaveChangesAsync();

            // Add images
            if (createNewsDto.ImageUrls != null && createNewsDto.ImageUrls.Any())
            {
                for (int i = 0; i < createNewsDto.ImageUrls.Count; i++)
                {
                    var newsImage = new NewsImage
                    {
                        NewsArticleId = newsArticle.NewsArticleId,
                        ImageUrl = createNewsDto.ImageUrls[i],
                        DisplayOrder = i
                    };
                    _context.NewsImages.Add(newsImage);
                }
                await _context.SaveChangesAsync();
            }

            // Return the created news with images
            var createdNews = await _context.NewsArticles
                .Where(n => n.NewsArticleId == newsArticle.NewsArticleId)
                .Include(n => n.Images)
                .Select(n => new NewsArticleDto
                {
                    NewsArticleId = n.NewsArticleId,
                    Title = n.Title,
                    Content = n.Content,
                    Category = n.Category,
                    PublishedDate = n.PublishedDate,
                    CreatedAt = n.CreatedAt,
                    UpdatedAt = n.UpdatedAt,
                    IsPublished = n.IsPublished,
                    Images = n.Images.OrderBy(i => i.DisplayOrder).Select(i => i.ImageUrl).ToList()
                })
                .FirstOrDefaultAsync();

            return CreatedAtAction(nameof(GetNewsById), new { id = newsArticle.NewsArticleId }, createdNews);
        }

        // PUT: api/news/{id}
        [HttpPut("{id}")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> UpdateNews(long id, [FromBody] UpdateNewsDto updateNewsDto)
        {
            var newsArticle = await _context.NewsArticles
                .Include(n => n.Images)
                .FirstOrDefaultAsync(n => n.NewsArticleId == id);

            if (newsArticle == null)
                return NotFound("News article not found");

            // Update basic properties
            newsArticle.Title = updateNewsDto.Title;
            newsArticle.Content = updateNewsDto.Content;
            newsArticle.Category = updateNewsDto.Category;
            newsArticle.IsPublished = updateNewsDto.IsPublished;
            newsArticle.UpdatedAt = DateTime.UtcNow;

            // Replace images
            _context.NewsImages.RemoveRange(newsArticle.Images);
            if (updateNewsDto.ImageUrls != null && updateNewsDto.ImageUrls.Any())
            {
                for (int i = 0; i < updateNewsDto.ImageUrls.Count; i++)
                {
                    var newsImage = new NewsImage
                    {
                        NewsArticleId = newsArticle.NewsArticleId,
                        ImageUrl = updateNewsDto.ImageUrls[i],
                        DisplayOrder = i
                    };
                    _context.NewsImages.Add(newsImage);
                }
            }

            await _context.SaveChangesAsync();
            return NoContent();
        }

        // DELETE: api/news/{id}
        [HttpDelete("{id}")]
        [Authorize]
        [AdminAuthorize]
        public async Task<IActionResult> DeleteNews(long id)
        {
            var newsArticle = await _context.NewsArticles
                .Include(n => n.Images)
                .FirstOrDefaultAsync(n => n.NewsArticleId == id);

            if (newsArticle == null)
                return NotFound("News article not found");

            _context.NewsArticles.Remove(newsArticle); // Images will be deleted due to cascade
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }

    // DTOs
    public class CreateNewsDto
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? Category { get; set; }
        public List<string>? ImageUrls { get; set; }
        public bool IsPublished { get; set; } = true;
    }

    public class UpdateNewsDto
    {
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? Category { get; set; }
        public List<string>? ImageUrls { get; set; }
        public bool IsPublished { get; set; } = true;
    }

    public class NewsArticleDto
    {
        public long NewsArticleId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? Category { get; set; }
        public DateTime PublishedDate { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsPublished { get; set; }
        public List<string> Images { get; set; } = new();
    }

    public class PaginatedNewsResponse
    {
        public List<NewsArticleDto> Items { get; set; } = new();
        public int TotalCount { get; set; }
        public int CurrentPage { get; set; }
        public int PageSize { get; set; }
        public bool HasMore { get; set; }
    }
}
