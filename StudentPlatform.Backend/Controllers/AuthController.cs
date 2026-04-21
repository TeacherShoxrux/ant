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
using Microsoft.AspNetCore.Authorization;

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
        var phoneInput = loginDto.PhoneNumber.Trim();
        var user = await _context.Users
            .Include(u => u.Role)
            .FirstOrDefaultAsync(u => u.PhoneNumber == phoneInput || u.Username == phoneInput);

        if (user == null || user.IsDisabled || (user.PasswordHash.Trim() != loginDto.Password.Trim())) 
        {
            return Unauthorized("Telefon raqami yoki parol xato, yoki profil bloklangan.");
        }

        // Create Session Record
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();
        string location = "Noma'lum";

        if (!string.IsNullOrEmpty(ip) && ip != "::1" && ip != "127.0.0.1")
        {
            try
            {
                using var client = new HttpClient();
                var response = await client.GetStringAsync($"http://ip-api.com/json/{ip}");
                using var jsonDoc = System.Text.Json.JsonDocument.Parse(response);
                if (jsonDoc.RootElement.TryGetProperty("status", out var statusProp) && statusProp.GetString() == "success")
                {
                    var city = jsonDoc.RootElement.GetProperty("city").GetString();
                    var country = jsonDoc.RootElement.GetProperty("country").GetString();
                    location = $"{city}, {country}";
                }
            } catch {}
        }

        var session = new UserSession
        {
            StudentId = user.Id,
            IpAddress = ip,
            DeviceInfo = userAgent,
            LocationInfo = location,
            LoginTime = DateTime.UtcNow
        };
        _context.UserSessions.Add(session);
        await _context.SaveChangesAsync();

        var token = GenerateJwtToken(user);
        return Ok(new AuthResponseDto
        {
            Token = token,
            Username = user.Username,
            FullName = user.FullName,
            Role = user.Role?.Name ?? "Student",
            ImagePath = user.ImagePath,
            PhoneNumber = user.PhoneNumber ?? ""
        });
    }

    [HttpPost("face-login")]
    public async Task<ActionResult<AuthResponseDto>> FaceLogin(IFormFile faceImage)
    {
        if (faceImage == null || faceImage.Length == 0) return BadRequest("Rasm yuborilmadi.");
        
        var ext = Path.GetExtension(faceImage.FileName);
        if (string.IsNullOrEmpty(ext)) ext = ".jpg";
        var fileName = Guid.NewGuid().ToString() + ext;
        
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

        // Create Session Record
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var userAgent = Request.Headers.UserAgent.ToString();
        string location = "Noma'lum";

        if (!string.IsNullOrEmpty(ip) && ip != "::1" && ip != "127.0.0.1")
        {
            try
            {
                using var client = new HttpClient();
                var response = await client.GetStringAsync($"http://ip-api.com/json/{ip}");
                using var jsonDoc = System.Text.Json.JsonDocument.Parse(response);
                if (jsonDoc.RootElement.TryGetProperty("status", out var statusProp) && statusProp.GetString() == "success")
                {
                    var city = jsonDoc.RootElement.GetProperty("city").GetString();
                    var country = jsonDoc.RootElement.GetProperty("country").GetString();
                    location = $"{city}, {country}";
                }
            }
            catch { /* Ignore ip-api errors */ }
        }
        else if (ip == "::1" || ip == "127.0.0.1")
        {
            location = "Local Network (Localhost)";
        }

        var session = new UserSession
        {
            StudentId = user.Id,
            IpAddress = ip,
            DeviceInfo = string.IsNullOrEmpty(userAgent) ? "Noma'lum" : (userAgent.Length > 200 ? userAgent.Substring(0, 200) : userAgent), // Truncate just in case
            LocationInfo = location,
            FaceImagePath = $"/temp/uploads/{fileName}"
        };
        _context.UserSessions.Add(session);
        await _context.SaveChangesAsync();

        var token = GenerateJwtToken(user);

        return Ok(new AuthResponseDto
        {
            Token = token,
            Username = user.Username,
            FullName = user.FullName,
            Role = user.Role?.Name ?? "Student",
            ImagePath = user.ImagePath
        });
    }

    [HttpPost("change-password")]
    [Authorize]
    public async Task<ActionResult> ChangePassword(ChangePasswordDto changePasswordDto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("id") ?? User.FindFirst("sub");
        if (userIdClaim == null) 
        {
            // For debugging, let's see what claims we DO have
            // var allClaims = string.Join(", ", User.Claims.Select(c => c.Type + "=" + c.Value));
            return Unauthorized("Foydalanuvchi identifikatori topilmadi.");
        }
        
        var userId = int.Parse(userIdClaim.Value);
        var user = await _context.Users.FindAsync(userId);
        
        if (user == null) return NotFound("Foydalanuvchi topilmadi.");
        
        // Trim passwords to avoid whitespace issues
        var oldPwd = changePasswordDto.OldPassword.Trim();
        var newPwd = changePasswordDto.NewPassword.Trim();

        if (user.PasswordHash != oldPwd) 
            return BadRequest("Eski parol noto'g'ri.");
        
        user.PasswordHash = newPwd;
        await _context.SaveChangesAsync();
        
        return Ok("Parol muvaffaqiyatli o'zgartirildi.");
    }

    [HttpPost("register")]
    public async Task<ActionResult> Register(RegisterDto registerDto)
    {
        if (await _context.Users.AnyAsync(u => u.PhoneNumber == registerDto.PhoneNumber))
        {
            return BadRequest("Ushbu telefon raqami allaqachon ro'yxatdan o'tgan.");
        }

        var user = new User
        {
            PhoneNumber = registerDto.PhoneNumber,
            Username = string.IsNullOrEmpty(registerDto.Username) ? registerDto.PhoneNumber : registerDto.Username,
            PasswordHash = registerDto.Password,
            FullName = registerDto.FullName,
            RoleId = 2 // Student by default
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok("Muvaffaqiyatli ro'yxatdan o'tdingiz.");
    }

    private string GenerateJwtToken(User user)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim("phoneNumber", user.PhoneNumber ?? ""),
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

    [HttpPost("update-profile-image")]
    [Authorize]
    public async Task<ActionResult> UpdateProfileImage([FromForm] IFormFile image)
    {
        if (image == null || image.Length == 0) return BadRequest("Rasm yuborilmadi.");
        
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?? User.FindFirst("id") ?? User.FindFirst("sub");
        if (userIdClaim == null) return Unauthorized("Foydalanuvchi identifikatori topilmadi.");
        
        var userId = int.Parse(userIdClaim.Value);
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound("Foydalanuvchi topilmadi.");

        var roleFolder = user.RoleId == 2 ? "students" : "admins";
        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", roleFolder);
        if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
        
        var fileName = $"{Guid.NewGuid()}_{image.FileName}";
        var filePath = Path.Combine(uploadsFolder, fileName);
        
        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await image.CopyToAsync(stream);
        }

        user.ImagePath = $"/uploads/{roleFolder}/{fileName}";
        await _context.SaveChangesAsync();

        return Ok(new { imagePath = user.ImagePath });
    }
}
