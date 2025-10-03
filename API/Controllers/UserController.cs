using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PropertyFlipperAPI.Data;
using PropertyFlipperAPI.Models;
using System;
using System.Linq;
using System.Threading.Tasks;
using BCrypt.Net;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public UserController(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
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
            var token = GenerateJwtToken(user);
            return Ok(new AuthResponse { Token = token, User = user });
        }

        // Login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == req.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.HashedPassword))
                return Unauthorized("Invalid credentials.");

            var token = GenerateJwtToken(user);
            return Ok(new AuthResponse { Token = token, User = user });
        }

        // Get user profile
        [HttpGet("{id}")]
        [Authorize]
        public async Task<IActionResult> GetProfile(long id)
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
        [Authorize]
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
        [Authorize]
        public async Task<IActionResult> AddProperty([FromBody] Property property)
        {
            property.CreatedAt = DateTime.UtcNow;
            _context.Properties.Add(property);
            await _context.SaveChangesAsync();
            return Ok(property);
        }

        // Add property doc
        [HttpPost("propertydoc")]
        [Authorize]
        public async Task<IActionResult> AddPropertyDoc([FromBody] PropertyDoc doc)
        {
            doc.UploadedAt = DateTime.UtcNow;
            _context.PropertyDocs.Add(doc);
            await _context.SaveChangesAsync();
            return Ok(doc);
        }

        // Add user doc
        [HttpPost("userdoc")]
        [Authorize]
        public async Task<IActionResult> AddUserDoc([FromBody] UserDoc doc)
        {
            doc.UploadedAt = DateTime.UtcNow;
            _context.UserDocs.Add(doc);
            await _context.SaveChangesAsync();
            return Ok(doc);
        }

        // Create auction
        [HttpPost("auction")]
        [Authorize]
        public async Task<IActionResult> CreateAuction([FromBody] Auction auction)
        {
            auction.CreatedAt = DateTime.UtcNow;
            auction.Status = "Pending";
            _context.Auctions.Add(auction);
            await _context.SaveChangesAsync();
            return Ok(auction);
        }

        private string GenerateJwtToken(User user)
        {
            var jwtSection = _config.GetSection("Jwt");
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"] ?? "insecure"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
                new Claim(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
                new Claim("uid", user.UserId.ToString()),
            };

            var token = new JwtSecurityToken(
                issuer: jwtSection["Issuer"],
                audience: jwtSection["Audience"],
                claims: claims,
                expires: DateTime.UtcNow.AddDays(7),
                signingCredentials: creds
            );
            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }

    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }

    public class AuthResponse
    {
        public string Token { get; set; }
        public User User { get; set; }
    }
}