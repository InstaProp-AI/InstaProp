using Microsoft.AspNetCore.Mvc;

namespace PropertyFlipperAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok(new { message = "API is working!", timestamp = DateTime.UtcNow });
        }

        [HttpPost("user")]
        public IActionResult CreateTestUser([FromBody] TestUserRequest request)
        {
            // Simulate user creation without database
            var user = new
            {
                id = 1,
                firstName = request.FirstName,
                lastName = request.LastName,
                email = request.Email,
                createdAt = DateTime.UtcNow
            };

            var token = "test-jwt-token-" + Guid.NewGuid().ToString("N")[..8];
            
            return Ok(new { token = token, user = user });
        }
    }

    public class TestUserRequest
    {
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
    }
}

