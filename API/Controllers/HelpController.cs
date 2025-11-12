using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HelpController : ControllerBase
    {
        private readonly AppDbContext _context;

        public HelpController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet("faq")]
        public async Task<ActionResult<IEnumerable<FaqDto>>> GetFaq([FromQuery] int limit = 10)
        {
            if (limit <= 0)
            {
                limit = 10;
            }

            var faqs = await _context.Faqs
                .OrderBy(f => f.DisplayOrder)
                .ThenBy(f => f.FaqId)
                .Take(limit)
                .Select(f => new FaqDto
                {
                    FaqId = f.FaqId,
                    Question = f.Question,
                    Answer = f.Answer,
                    DisplayOrder = f.DisplayOrder
                })
                .ToListAsync();

            return Ok(faqs);
        }

        [HttpGet("faq/all")]
        public async Task<ActionResult<IEnumerable<FaqDto>>> GetAllFaq()
        {
            var faqs = await _context.Faqs
                .OrderBy(f => f.DisplayOrder)
                .ThenBy(f => f.FaqId)
                .Select(f => new FaqDto
                {
                    FaqId = f.FaqId,
                    Question = f.Question,
                    Answer = f.Answer,
                    DisplayOrder = f.DisplayOrder
                })
                .ToListAsync();

            return Ok(faqs);
        }
    }

    public class FaqDto
    {
        public int FaqId { get; set; }
        public string Question { get; set; } = string.Empty;
        public string Answer { get; set; } = string.Empty;
        public int DisplayOrder { get; set; }
    }
}
