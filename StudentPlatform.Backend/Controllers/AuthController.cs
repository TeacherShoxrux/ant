using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using StudentPlatform.Backend.Data;
using StudentPlatform.Backend.DTOs;
using StudentPlatform.Backend.Embedding;
using StudentPlatform.Backend.Embedding.Cached;
using StudentPlatform.Backend.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace StudentPlatform.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly IEmbeddingService _embeddingService;
    private readonly IFaceEmbeddingCache _faceEmbeddingCache;

    public AuthController(AppDbContext context, IConfiguration configuration, IEmbeddingService embeddingService, IFaceEmbeddingCache faceEmbeddingCache)
    {
        _context = context;
        _configuration = configuration;
        _embeddingService = embeddingService;
        _faceEmbeddingCache = faceEmbeddingCache;
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponseDto>> Login(LoginDto loginDto)
    {
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.Username == loginDto.Username);

        if (user == null || user.IsDisabled || (user.PasswordHash != loginDto.Password)) 
        {
            return Unauthorized("Login yoki parol xato, yoki profil bloklangan.");
        }

        var token = GenerateJwtToken(user);

        return Ok(new AuthResponseDto
        {
            Token = token,
            Username = user.Username,
            FullName = user.FullName,
            Role = user.Role?.Name ?? "Student"
        });
    }

    [HttpPost("face-login")]
    public async Task<ActionResult<AuthResponseDto>> FaceLogin(IFormFile faceImage)
    {
        if (faceImage == null || faceImage.Length == 0) return BadRequest("Rasm yuborilmadi.");
        var fileName = Guid.NewGuid() + faceImage.FileName;
        var imagePath = Path.Combine("wwwroot/temp/uploads", fileName);
         if (!Directory.Exists("wwwroot/temp/uploads"))
            {
                Directory.CreateDirectory("wwwroot/temp/uploads");
            }
         using (var stream = new FileStream(imagePath, FileMode.Create))
            {
                await faceImage.CopyToAsync(stream);
            }
            var embedding = _embeddingService.GenerateEmbedding(imagePath);
            if (embedding == null)
                return BadRequest("Yuzni aniqlashda xatolik yuz berdi.");
            var matchedStudentId = _embeddingService.GetMatchedStudentId(embedding);
            if (matchedStudentId == null)
                return BadRequest("Yuz bazada topilmadi.");
        // Real Face Recognition would happen here using a library.
        // For project demo, we simulate matching by looking for students who have images.
        // We look for a student whose image is stored.
        
        var studentsWithImages = await _context.Users
            .Include(u => u.Role)
            .Where(u =>  u.RoleId == 2 && !string.IsNullOrEmpty(u.ImagePath) && !u.IsDisabled)
            .ToListAsync();

        if (studentsWithImages.Count == 0) return Unauthorized("Tizimda rasmli talabalar topilmadi.");
        

        // Logic simulation: In a real app we'd compare faceImage with u.ImagePath files.
        // Here we'll match the first one for the demo purpose, or implement a basic size-based heuristic
        // but for now, we'll return the first authenticated student to show the flow works.
        var user = studentsWithImages.FirstOrDefault(u => u.Id == matchedStudentId);

        if (user == null) return Unauthorized("Yuz aniqlanmadi.");

        var token = GenerateJwtToken(user);

        return Ok(new AuthResponseDto
        {
            Token = token,
            Username = user.Username,
            FullName = user.FullName,
            Role = user.Role?.Name ?? "Student"
        });
    }

    [HttpPost("register")]
    public async Task<ActionResult> Register(RegisterDto registerDto)
    {
        if (await _context.Users.AnyAsync(u => u.Username == registerDto.Username))
        {
            return BadRequest("Username already exists.");
        }

        var user = new User
        {
            Username = registerDto.Username,
            PasswordHash = registerDto.Password, // Simple for demo
            FullName = registerDto.FullName,
            RoleId = 2 // Student by default
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok("Registration successful.");
    }

    private string GenerateJwtToken(User user)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.Role?.Name ?? "Student")
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"] ?? "superSecretKey123!@#4567890ReallyLongSecretKeyForJwtAuthentication"));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddDays(1),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
