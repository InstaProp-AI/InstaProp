using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using InstapropAPI.Data;
using InstapropAPI.Models;
using InstapropAPI.Attributes;
using System.Security.Claims;

namespace InstapropAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [FeaturePermissionAttribute("News")]
    public class NewsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public NewsController(AppDbContext context)
        {
            _context = context;
        }

        private Guid? GetCurrentAccountId()
        {
            var accountIdClaim = User.FindFirst("uid");
            if (accountIdClaim != null && Guid.TryParse(accountIdClaim.Value, out var accountId))
            {
                return accountId;
            }
            return null;
        }

        private async Task<AccountBase?> GetCurrentAccountAsync()
        {
            var accountId = GetCurrentAccountId();
            if (accountId == null) return null;
            return await _context.Accounts.FindAsync(accountId.Value);
        }

        // GET: api/news?page=1&pageSize=10&developerId=
        [HttpGet]
        [Authorize]
        public async Task<ActionResult<PaginatedNewsResponse>> GetNews(
            [FromQuery] int page = 1, 
            [FromQuery] int pageSize = 10,
            [FromQuery] string? developerId = null)
        {
            var account = await GetCurrentAccountAsync();
            if (account == null)
                return Unauthorized("User not authenticated");

            var query = _context.NewsArticles
                .Include(n => n.Images)
                .AsQueryable();

            // Filter by developer if specified (for admin folder view)
            // Handle special values: "-1" or empty GUID string means "show admin posts" (DeveloperId = null)
            if (!string.IsNullOrEmpty(developerId))
            {
                // Special value: "-1" means show only admin posts (DeveloperId = null)
                if (developerId == "-1" || developerId == "00000000-0000-0000-0000-000000000000")
                {
                    query = query.Where(n => n.DeveloperId == null);
                }
                else if (Guid.TryParse(developerId, out var developerGuid))
                {
                    // Valid GUID: Admin viewing specific developer's folder
                    query = query.Where(n => n.DeveloperId == developerGuid);
                }
                else
                {
                    // Invalid GUID format - return bad request
                    return BadRequest(new { error = "Invalid developerId format. Expected GUID or '-1' for admin posts." });
                }
            }
            // If developer, only show their own news
            else if (account.RoleId == Role.DEVELOPER_ROLE_ID)
            {
                var currentAccountId = GetCurrentAccountId();
                query = query.Where(n => n.DeveloperId == currentAccountId);
            }
            // If admin and no developerId specified, show all news (including admin posts)
            // This is the default view for admin

            // For published/unpublished filtering
            if (account.RoleId == Role.DEVELOPER_ROLE_ID)
            {
                // Developers see all their news (published and unpublished)
                // Already filtered above
            }
            else if (account.RoleId == Role.ADMIN_ROLE_ID)
            {
                // Admins see all news (no published filter)
            }
            else
            {
                // Other users only see published news
                query = query.Where(n => n.IsPublished);
            }

            query = query.OrderByDescending(n => n.PublishedDate);

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
                    DeveloperId = n.DeveloperId,
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
        public async Task<ActionResult<NewsArticleDto>> GetNewsById(Guid id)
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
        public async Task<ActionResult<NewsArticleDto>> CreateNews([FromBody] CreateNewsDto createNewsDto)
        {
            var account = await GetCurrentAccountAsync();
            if (account == null)
                return Unauthorized("User not authenticated");

            // Only admins and developers can create news
            if (account.RoleId != Role.ADMIN_ROLE_ID && account.RoleId != Role.DEVELOPER_ROLE_ID)
                return Forbid();

            var accountId = GetCurrentAccountId();
            var newsArticle = new NewsArticle
            {
                Title = createNewsDto.Title,
                Content = createNewsDto.Content,
                Category = createNewsDto.Category,
                PublishedDate = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                IsPublished = createNewsDto.IsPublished,
                // Set DeveloperId: null for admin, accountId for developer
                DeveloperId = account.RoleId == Role.ADMIN_ROLE_ID ? null : accountId
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
        public async Task<IActionResult> UpdateNews(Guid id, [FromBody] UpdateNewsDto updateNewsDto)
        {
            var account = await GetCurrentAccountAsync();
            if (account == null)
                return Unauthorized("User not authenticated");

            var newsArticle = await _context.NewsArticles
                .Include(n => n.Images)
                .FirstOrDefaultAsync(n => n.NewsArticleId == id);

            if (newsArticle == null)
                return NotFound("News article not found");

            // Check permissions: Admin can edit any, Developer can only edit their own
            var accountId = GetCurrentAccountId();
            if (account.RoleId == Role.DEVELOPER_ROLE_ID && newsArticle.DeveloperId != accountId)
                return Forbid("You can only edit your own news articles");

            if (account.RoleId != Role.ADMIN_ROLE_ID && account.RoleId != Role.DEVELOPER_ROLE_ID)
                return Forbid();

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
        public async Task<IActionResult> DeleteNews(Guid id)
        {
            var account = await GetCurrentAccountAsync();
            if (account == null)
                return Unauthorized("User not authenticated");

            var newsArticle = await _context.NewsArticles
                .Include(n => n.Images)
                .FirstOrDefaultAsync(n => n.NewsArticleId == id);

            if (newsArticle == null)
                return NotFound("News article not found");

            // Check permissions: Admin can delete any, Developer can only delete their own
            var accountId = GetCurrentAccountId();
            if (account.RoleId == Role.DEVELOPER_ROLE_ID && newsArticle.DeveloperId != accountId)
                return Forbid("You can only delete your own news articles");

            if (account.RoleId != Role.ADMIN_ROLE_ID && account.RoleId != Role.DEVELOPER_ROLE_ID)
                return Forbid();

            _context.NewsArticles.Remove(newsArticle); // Images will be deleted due to cascade
            await _context.SaveChangesAsync();
            return NoContent();
        }

        // GET: api/news/developers - Get developers with news counts (for admin folder view)
        [HttpGet("developers")]
        [Authorize]
        public async Task<ActionResult<List<DeveloperNewsCountDto>>> GetDevelopersWithNewsCounts()
        {
            var account = await GetCurrentAccountAsync();
            if (account == null)
                return Unauthorized("User not authenticated");

            // Only admins can see this
            if (account.RoleId != Role.ADMIN_ROLE_ID)
                return Forbid();

            // Get all developers with their news counts
            var allDevelopers = await _context.Accounts
                .Where(a => a.RoleId == Role.DEVELOPER_ROLE_ID)
                .ToListAsync();

            var newsCounts = await _context.NewsArticles
                .Where(n => n.DeveloperId.HasValue)
                .GroupBy(n => n.DeveloperId.Value)
                .Select(g => new { DeveloperId = g.Key, Count = g.Count() })
                .ToListAsync();

            var countLookup = newsCounts.ToDictionary(x => x.DeveloperId, x => x.Count);

            var developers = allDevelopers.Select(a => new DeveloperNewsCountDto
            {
                DeveloperId = a.AccountId,
                DeveloperName = $"{a.FirstName} {a.LastName}",
                Email = a.Email,
                NewsCount = countLookup.TryGetValue(a.AccountId, out var count) ? count : 0
            })
            .OrderBy(d => d.DeveloperName)
            .ToList();

            return Ok(developers);
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
        public Guid NewsArticleId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Content { get; set; } = string.Empty;
        public string? Category { get; set; }
        public DateTime PublishedDate { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsPublished { get; set; }
        public Guid? DeveloperId { get; set; }
        public List<string> Images { get; set; } = new();
    }

    public class DeveloperNewsCountDto
    {
        public Guid DeveloperId { get; set; }
        public string DeveloperName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public int NewsCount { get; set; }
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
