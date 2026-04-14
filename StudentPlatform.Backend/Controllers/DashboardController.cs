using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;
using StudentPlatform.Backend.Models;
using System.Security.Claims;

namespace StudentPlatform.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _context;

    public DashboardController(AppDbContext context)
    {
        _context = context;
        
        // Manual schema synchronization for SQLite (Fix for 'no such table: Groups')
        try 
        {
            var conn = _context.Database.GetDbConnection();
            if (conn.State != System.Data.ConnectionState.Open) conn.Open();
            
            using var cmd = conn.CreateCommand();
            
            // Create Groups table
            cmd.CommandText = "CREATE TABLE IF NOT EXISTS Groups (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL);";
            cmd.ExecuteNonQuery();
            
            // Add missing columns to Users (try-catch each because they might already exist)
            try { cmd.CommandText = "ALTER TABLE Users ADD COLUMN Patronymic TEXT;"; cmd.ExecuteNonQuery(); } catch {}
            try { cmd.CommandText = "ALTER TABLE Users ADD COLUMN PhoneNumber TEXT;"; cmd.ExecuteNonQuery(); } catch {}
            try { cmd.CommandText = "ALTER TABLE Users ADD COLUMN ImagePath TEXT;"; cmd.ExecuteNonQuery(); } catch {}
            try { cmd.CommandText = "ALTER TABLE Users ADD COLUMN GroupId INTEGER;"; cmd.ExecuteNonQuery(); } catch {}
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Database Init Error: {ex.Message}");
        }
    }

    [HttpGet("stats")]
    public async Task<ActionResult> GetStats()
    {
        var stats = new
        {
            TotalSubjects = await _context.Subjects.CountAsync(),
            TotalTopics = await _context.Topics.CountAsync(),
            TotalQuizzes = await _context.Quizzes.CountAsync(),
            TotalAssignments = await _context.Assignments.CountAsync(),
            TotalStudents = await _context.Users.Where(u => u.Role != null && u.Role.Name == "Student").CountAsync()
        };
        return Ok(stats);
    }

    [HttpGet("students")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> GetStudents()
    {
        var students = await _context.Users
            .Where(u => u.Role != null && u.Role.Name == "Student")
            .Select(u => new {
                u.Id,
                u.Username,
                u.FullName,
                u.PhoneNumber,
                u.ImagePath
            })
            .ToListAsync();
        return Ok(students);
    }

    [HttpGet("grades/{subjectId}")]
    public async Task<ActionResult> GetSubjectGrades(int subjectId)
    {
        var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var assignmentGrades = await _context.AssignmentSubmissions
            .Include(s => s.Assignment)
            .Where(s => s.StudentId == userId && s.Assignment!.Topic!.SubjectId == subjectId)
            .Select(s => new {
                Title = s.Assignment!.Title,
                Type = "Assignment",
                Grade = s.Grade,
                MaxScore = s.Assignment.MaxScore,
                Date = s.SubmittedAt
            })
            .ToListAsync();

        var quizGrades = await _context.TestResults
            .Include(r => r.Quiz)
            .Where(r => r.StudentId == userId && r.Quiz!.Topic!.SubjectId == subjectId)
            .Select(r => new {
                Title = r.Quiz!.Title,
                Type = "Quiz",
                Grade = (int?)r.Score,
                MaxScore = (int?)r.TotalQuestions,
                Date = r.TakenAt
            })
            .ToListAsync();

        var result = assignmentGrades.Cast<object>().Concat(quizGrades.Cast<object>()).ToList();
        return Ok(result);
    }

    // Groups management
    [HttpGet("groups")]
    public async Task<ActionResult> GetGroups()
    {
        return Ok(await _context.Groups.ToListAsync());
    }

    [HttpPost("groups")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> CreateGroup([FromBody] GroupRequest request)
    {
        if (string.IsNullOrEmpty(request.Name)) return BadRequest("Guruh nomi bo'sh bo'lishi mumkin emas.");
        
        var group = new Group { Name = request.Name };
        _context.Groups.Add(group);
        await _context.SaveChangesAsync();
        return Ok(group);
    }

    [HttpPost("students")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> CreateStudent([FromForm] string fullName, [FromForm] string? patronymic, [FromForm] string username, [FromForm] string password, [FromForm] string? phoneNumber, [FromForm] int? groupId, IFormFile? faceImage)
    {
        if (groupId == null) return BadRequest("Guruhni tanlash majburiy!");
        if (faceImage == null || faceImage.Length == 0) return BadRequest("Talaba yuz rasmini yuklash majburiy!");

        var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "students");
        if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
        var fileName = $"{Guid.NewGuid()}_{faceImage.FileName}";
        var filePath = Path.Combine(uploadsFolder, fileName);
        using (var stream = new FileStream(filePath, FileMode.Create)) await faceImage.CopyToAsync(stream);
        var imagePath = $"/uploads/students/{fileName}";

        var student = new User
        {
            FullName = fullName,
            Patronymic = patronymic,
            Username = username,
            PasswordHash = password, // Simplified for demo
            PhoneNumber = phoneNumber,
            GroupId = groupId,
            ImagePath = imagePath,
            RoleId = 2 // Student
        };

        _context.Users.Add(student);
        await _context.SaveChangesAsync();
        return Ok(student);
    }

    [HttpPut("students/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> UpdateStudent(int id, [FromForm] string fullName, [FromForm] string? patronymic, [FromForm] string username, [FromForm] string? phoneNumber, [FromForm] int? groupId, IFormFile? faceImage)
    {
        var student = await _context.Users.FindAsync(id);
        if (student == null || student.RoleId != 2) return NotFound("Talaba topilmadi.");

        student.FullName = fullName;
        student.Patronymic = patronymic;
        student.Username = username;
        student.PhoneNumber = phoneNumber;
        
        if (groupId != null) student.GroupId = groupId;

        if (faceImage != null && faceImage.Length > 0)
        {
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "students");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
            var fileName = $"{Guid.NewGuid()}_{faceImage.FileName}";
            var filePath = Path.Combine(uploadsFolder, fileName);
            using (var stream = new FileStream(filePath, FileMode.Create)) await faceImage.CopyToAsync(stream);
            student.ImagePath = $"/uploads/students/{fileName}";
        }

        await _context.SaveChangesAsync();
        return Ok(student);
    }

    [HttpPatch("students/{id}/toggle-status")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> ToggleStudentStatus(int id)
    {
        var student = await _context.Users.FindAsync(id);
        if (student == null || student.RoleId != 2) return NotFound("Talaba topilmadi.");

        student.IsDisabled = !student.IsDisabled;
        await _context.SaveChangesAsync();
        return Ok(new { student.Id, student.IsDisabled });
    }

    [HttpDelete("students/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> DeleteStudent(int id)
    {
        var student = await _context.Users.FindAsync(id);
        if (student == null || student.RoleId != 2) return NotFound("Talaba topilmadi.");

        _context.Users.Remove(student);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}

public class GroupRequest
{
    public string Name { get; set; } = string.Empty;
}
