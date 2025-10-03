using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System;
using System.Linq;
using System.Threading.Tasks;
using BCrypt.Net;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UserController(AppDbContext context)
        {
            _context = context;
        }

        // Signup
        [HttpPost("signup")]
        public async Task<IActionResult> Signup([FromBody] User user)
        {
            if (await _context.Users.AnyAsync(u => u.Email == user.Email))
                return BadRequest("Email already exists.");

            user.HashedPassword = BCrypt.Net.BCrypt.HashPassword(user.HashedPassword);
            user.CreatedAt = DateTime.UtcNow;
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return Ok(user);
        }

        // Login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == req.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.HashedPassword))
                return Unauthorized("Invalid credentials.");

            return Ok(user);
        }

        // Get user profile
        [HttpGet("{id}")]
        public async Task<IActionResult> GetProfile(int id)
        {
            var user = await _context.Users
                .Include(u => u.Properties)
                .Include(u => u.Bids)
                .Include(u => u.UserDocs)
                .FirstOrDefaultAsync(u => u.UserId == id);

            if (user == null) return NotFound();
            return Ok(user);
        }

        // Place a bid
        [HttpPost("bid")]
        public async Task<IActionResult> PlaceBid([FromBody] Bid bid)
        {
            var auction = await _context.Auctions.FindAsync(bid.AuctionId);
            if (auction == null || auction.Status != "Active")
                return BadRequest("Auction not found or not active.");

            bid.CreatedAt = DateTime.UtcNow;
            _context.Bids.Add(bid);
            await _context.SaveChangesAsync();
            return Ok(bid);
        }

        // Add property
        [HttpPost("property")]
        public async Task<IActionResult> AddProperty([FromBody] Property property)
        {
            property.CreatedAt = DateTime.UtcNow;
            _context.Properties.Add(property);
            await _context.SaveChangesAsync();
            return Ok(property);
        }

        // Add property doc
        [HttpPost("propertydoc")]
        public async Task<IActionResult> AddPropertyDoc([FromBody] PropertyDoc doc)
        {
            doc.UploadedAt = DateTime.UtcNow;
            _context.PropertyDocs.Add(doc);
            await _context.SaveChangesAsync();
            return Ok(doc);
        }

        // Add user doc
        [HttpPost("userdoc")]
        public async Task<IActionResult> AddUserDoc([FromBody] UserDoc doc)
        {
            doc.UploadedAt = DateTime.UtcNow;
            _context.UserDocs.Add(doc);
            await _context.SaveChangesAsync();
            return Ok(doc);
        }

        // Create auction
        [HttpPost("auction")]
        public async Task<IActionResult> CreateAuction([FromBody] Auction auction)
        {
            auction.CreatedAt = DateTime.UtcNow;
            auction.Status = "Pending";
            _context.Auctions.Add(auction);
            await _context.SaveChangesAsync();
            return Ok(auction);
        }
    }

    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }
}