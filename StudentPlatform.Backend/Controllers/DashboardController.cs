using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;
using StudentPlatform.Backend.Embedding;
using StudentPlatform.Backend.Embedding.Cached;
using StudentPlatform.Backend.Models;
using System.Security.Claims;
using ClosedXML.Excel;

namespace StudentPlatform.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IEmbeddingService _embeddingService;
    private readonly IFaceEmbeddingCache _faceEmbeddingCache;
    public DashboardController(AppDbContext context, IEmbeddingService embeddingService, IFaceEmbeddingCache faceEmbeddingCache)
    {
        _context = context;
        _embeddingService = embeddingService;
        _faceEmbeddingCache = faceEmbeddingCache;

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
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> GetStudents(int pageNumber = 1, int pageSize = 10, string? searchTerm = null, int? groupId = null)
    {
        var query = _context.Users
            .Where(u => u.Role != null && u.Role.Name == "Student");

        if (!string.IsNullOrEmpty(searchTerm))
        {
            var search = searchTerm.ToLower();
            query = query.Where(u => u.FullName.ToLower().Contains(search) || u.Username.ToLower().Contains(search));
        }

        if (groupId != null)
        {
            query = query.Where(u => u.GroupId == groupId);
        }

        var totalCount = await query.CountAsync();
        var students = await query
            .OrderByDescending(u => u.Id)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(u => new {
                u.Id,
                u.Username,
                u.FullName,
                u.PhoneNumber,
                u.ImagePath,
                u.GroupId,
                u.IsDisabled
            })
            .ToListAsync();

        return Ok(new {
            Items = students,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
        });
    }

    [HttpGet("admins")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> GetAdmins(string? searchTerm = null)
    {
        var query = _context.Users.Where(u => u.Role != null && (u.Role.Name == "Admin" || u.Role.Name == "Moderator"));

        if (!string.IsNullOrEmpty(searchTerm))
        {
            var search = searchTerm.ToLower();
            query = query.Where(u => u.FullName.ToLower().Contains(search) || u.Username.ToLower().Contains(search));
        }

        var admins = await query
            .OrderByDescending(u => u.Id)
            .Select(u => new {
                u.Id,
                u.Username,
                u.FullName,
                u.PhoneNumber,
                u.ImagePath,
                u.IsDisabled,
                RoleName = u.Role!.Name
            })
            .ToListAsync();

        return Ok(admins);
    }

    [HttpPost("admins")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> CreateAdmin([FromForm] string fullName, [FromForm] string username, [FromForm] string password, [FromForm] string? phoneNumber, [FromForm] int roleId = 1, IFormFile? image = null)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (currentUserId != 1) return Forbid("Sizda adminlar yaratish huquqi yo'q.");

        var admin = new User
        {
            FullName = fullName,
            Username = username,
            PasswordHash = password,
            PhoneNumber = phoneNumber,
            RoleId = roleId
        };

        if (image != null && image.Length > 0)
        {
            var uploadsFolder = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "admins");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
            var fileName = $"{Guid.NewGuid()}_{image.FileName}";
            var filePath = Path.Combine(uploadsFolder, fileName);
            using (var stream = new FileStream(filePath, FileMode.Create)) await image.CopyToAsync(stream);
            admin.ImagePath = $"/uploads/admins/{fileName}";
        }

        _context.Users.Add(admin);
        await _context.SaveChangesAsync();
        return Ok(admin);
    }

    [HttpPatch("admins/{id}/toggle-status")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> ToggleAdminStatus(int id)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (currentUserId != 1) return Forbid("Sizda bu huquq yo'q.");

        if (id == 1) return BadRequest("Asosiy adminni bloklab bo'lmaydi."); // Protect main admin
        var admin = await _context.Users.FindAsync(id);
        if (admin == null || (admin.RoleId != 1 && admin.RoleId != 3)) return NotFound("Foydalanuvchi topilmadi.");

        admin.IsDisabled = !admin.IsDisabled;
        await _context.SaveChangesAsync();
        return Ok(new { admin.Id, admin.IsDisabled });
    }

    [HttpDelete("admins/{id}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> DeleteAdmin(int id)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (currentUserId != 1) return Forbid("Sizda bu huquq yo'q.");

        if (id == 1) return BadRequest("Asosiy adminni o'chirib bo'lmaydi."); // Protect main admin
        var admin = await _context.Users.FindAsync(id);
        if (admin == null || (admin.RoleId != 1 && admin.RoleId != 3)) return NotFound("Foydalanuvchi topilmadi.");

        _context.Users.Remove(admin);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("admins/{id}/reset-password")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> ResetAdminPassword(int id, [FromBody] ResetPasswordRequest req)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (currentUserId != 1) return Forbid("Sizda bu huquq yo'q.");

        var admin = await _context.Users.FindAsync(id);
        if (admin == null || (admin.RoleId != 1 && admin.RoleId != 3)) return NotFound("Foydalanuvchi topilmadi.");

        admin.PasswordHash = req.NewPassword;
        await _context.SaveChangesAsync();
        return Ok(new { message = "Parol muvaffaqiyatli yangilandi." });
    }

    [HttpPatch("admins/{id}/change-role")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> ChangeAdminRole(int id, [FromBody] ChangeRoleRequest req)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (currentUserId != 1) return Forbid("Sizda bu huquq yo'q.");

        if (id == 1) return BadRequest("Asosiy adminning rolini o'zgartirib bo'lmaydi.");
        var admin = await _context.Users.FindAsync(id);
        if (admin == null || (admin.RoleId != 1 && admin.RoleId != 3)) return NotFound("Foydalanuvchi topilmadi.");

        if (req.RoleId != 1 && req.RoleId != 3) return BadRequest("Noto'g'ri rol kiritildi.");

        admin.RoleId = req.RoleId;
        await _context.SaveChangesAsync();
        return Ok(new { message = "Rol muvaffaqiyatli o'zgartirildi." });
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

    [HttpGet("grades/topic/{topicId}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> GetTopicGradesAdmin(int topicId)
    {
        var assignmentGrades = await _context.AssignmentSubmissions
            .Include(s => s.Assignment)
            .Include(s => s.Student)
            .Where(s => s.Assignment!.TopicId == topicId)
            .Select(s => new {
                StudentName = s.Student!.FullName,
                StudentLogin = s.Student.Username,
                Title = s.Assignment!.Title,
                Type = "Assignment",
                Grade = s.Grade,
                MaxScore = s.Assignment.MaxScore,
                Date = s.SubmittedAt
            })
            .ToListAsync();

        var quizGrades = await _context.TestResults
            .Include(r => r.Quiz)
            .Include(r => r.Student)
            .Where(r => r.Quiz!.TopicId == topicId)
            .Select(r => new {
                StudentName = r.Student!.FullName,
                StudentLogin = r.Student.Username,
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

    [HttpGet("reports/excel")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> GetReportsExcel(int subjectId, int groupId)
    {
        var subject = await _context.Subjects.FindAsync(subjectId);
        var group = await _context.Groups.FindAsync(groupId);
        
        if (subject == null || group == null) return NotFound("Fan yoki guruh topilmadi.");

        // 1. Get all students in this group
        var students = await _context.Users
            .Where(u => u.RoleId == 2 && u.GroupId == groupId && !u.IsDisabled)
            .ToListAsync();

        // 2. Get all evaluation headers for this subject (Assignments & Quizzes)
        var assignments = await _context.Assignments
            .Include(a => a.Topic)
            .Where(a => a.Topic!.SubjectId == subjectId && !a.Topic.IsDisabled)
            .OrderBy(a => a.TopicId).ThenBy(a => a.Id)
            .ToListAsync();

        var quizzes = await _context.Quizzes
            .Include(q => q.Topic)
            .Where(q => q.Topic!.SubjectId == subjectId && !q.Topic.IsDisabled)
            .OrderBy(q => q.TopicId).ThenBy(q => q.Id)
            .ToListAsync();

        // 3. Prepare the Excel workbook
        using var workbook = new XLWorkbook();
        var worksheet = workbook.Worksheets.Add("O'zlashtirish Qaydnomasi");

        // --- Title
        worksheet.Cell(1, 1).Value = $"Fan: {subject.Name} | Guruh: {group.Name}";
        worksheet.Range(1, 1, 1, 5).Merge().Style.Font.SetBold().Font.FontSize = 14;

        // --- Headers
        int col = 1;
        worksheet.Cell(3, col++).Value = "T/r";
        worksheet.Cell(3, col++).Value = "Talaba F.I.Sh.";
        worksheet.Cell(3, col++).Value = "Login (ID)";

        // Keep track of column mappings for faster insertion
        var colMapping = new Dictionary<string, int>();

        foreach (var a in assignments)
        {
            worksheet.Cell(3, col).Value = $"{a.Title} (Topshiriq)";
            colMapping.Add($"A_{a.Id}", col);
            col++;
        }
        foreach (var q in quizzes)
        {
            worksheet.Cell(3, col).Value = $"{q.Title} (Test)";
            colMapping.Add($"Q_{q.Id}", col);
            col++;
        }
        
        var totalCol = col;
        worksheet.Cell(3, totalCol).Value = "Jami Ball";

        // Header Styling
        var headerRange = worksheet.Range(3, 1, 3, totalCol);
        headerRange.Style.Font.SetBold();
        headerRange.Style.Fill.BackgroundColor = XLColor.LightGray;
        headerRange.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        headerRange.Style.Border.InsideBorder = XLBorderStyleValues.Thin;

        // --- Data Population
        int row = 4;
        int index = 1;
        foreach (var student in students)
        {
            worksheet.Cell(row, 1).Value = index++;
            worksheet.Cell(row, 2).Value = student.FullName;
            worksheet.Cell(row, 3).Value = student.Username;

            int totalScore = 0;

            // Fill assignments
            foreach (var a in assignments)
            {
                var submission = await _context.AssignmentSubmissions
                    .FirstOrDefaultAsync(s => s.AssignmentId == a.Id && s.StudentId == student.Id);
                
                int score = submission?.Grade ?? 0;
                worksheet.Cell(row, colMapping[$"A_{a.Id}"]).Value = score;
                totalScore += score;
            }

            // Fill quizzes
            foreach (var q in quizzes)
            {
                var result = await _context.TestResults
                    .FirstOrDefaultAsync(r => r.QuizId == q.Id && r.StudentId == student.Id);
                
                int score = result?.Score ?? 0;
                worksheet.Cell(row, colMapping[$"Q_{q.Id}"]).Value = score;
                totalScore += score;
            }

            worksheet.Cell(row, totalCol).Value = totalScore;
            
            row++;
        }

        // Auto-fit columns
        worksheet.Columns().AdjustToContents();

        // Convert to byte array
        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        var content = stream.ToArray();

        var fileName = $"Hisobot_{subject.Name.Replace(" ", "_")}_{group.Name.Replace(" ", "_")}.xlsx";
        
        return File(content, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", fileName);
    }

    // Groups management
    [HttpGet("groups")]
    public async Task<ActionResult> GetGroups()
    {
        return Ok(await _context.Groups.ToListAsync());
    }

    [HttpPost("groups")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> CreateGroup([FromBody] GroupRequest request)
    {
        if (string.IsNullOrEmpty(request.Name)) return BadRequest("Guruh nomi bo'sh bo'lishi mumkin emas.");
        
        var group = new Group { Name = request.Name };
        _context.Groups.Add(group);
        await _context.SaveChangesAsync();
        return Ok(group);
    }

    [HttpPost("students")]
    [Authorize(Roles = "Admin,Moderator")]
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
         var embedding = _embeddingService.GenerateEmbedding(filePath);
        if (embedding == null) return BadRequest("Yuzdan embedding hosil qilishda xatolik yuz berdi. Iltimos, aniq va sifatli rasm yuklang.");
         FaceRecord faceRecord = new FaceRecord()
        {
            Embedding = System.Text.Json.JsonSerializer.Serialize(embedding),
            Image = filePath,
        };
        

        var student = new User
        {
            FaceRecord = faceRecord,
            FullName = fullName,
            Patronymic = patronymic,
            Username = username,
            PasswordHash = password, // Simplified for demo
            PhoneNumber = phoneNumber,
            GroupId = groupId,
            ImagePath = imagePath,
            RoleId = 2 
            
        };

        _context.Users.Add(student);
        await _context.SaveChangesAsync();

        return Ok(student);
    }

    [HttpPut("students/{id}")]
    [Authorize(Roles = "Admin,Moderator")]
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
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> ToggleStudentStatus(int id)
    {
        var student = await _context.Users.FindAsync(id);
        if (student == null || student.RoleId != 2) return NotFound("Talaba topilmadi.");

        student.IsDisabled = !student.IsDisabled;
        await _context.SaveChangesAsync();
        return Ok(new { student.Id, student.IsDisabled });
    }

    [HttpDelete("students/{id}")]
    [Authorize(Roles = "Admin,Moderator")]
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

public class ResetPasswordRequest
{
    public string NewPassword { get; set; } = string.Empty;
}

public class ChangeRoleRequest
{
    public int RoleId { get; set; }
}
