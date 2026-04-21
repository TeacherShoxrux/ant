using Microsoft.AspNetCore.Mvc;
using StudentPlatform.Backend.Data;
using System.Linq;

namespace StudentPlatform.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly AppDbContext _context;
        public TestController(AppDbContext context) { _context = context; }

        [HttpGet("users")]
        public ActionResult GetUsers()
        {
            return Ok(_context.Users.Select(u => new { u.Id, u.Username, u.PasswordHash, u.IsDisabled }).ToList());
        }
    }
}
