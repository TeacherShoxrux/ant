using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;
using StudentPlatform.Backend.DTOs;
using StudentPlatform.Backend.Models;
using System.Security.Claims;

namespace StudentPlatform.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AssignmentsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IWebHostEnvironment _env;

    public AssignmentsController(AppDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpGet("topic/{topicId}")]
    public async Task<ActionResult> GetAssignmentsByTopic(int topicId)
    {
        var assignments = await _context.Assignments
            .Where(a => a.TopicId == topicId)
            .ToListAsync();

        var studentIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (studentIdClaim != null)
        {
            var studentId = int.Parse(studentIdClaim);
            var submissions = await _context.AssignmentSubmissions
                .Where(s => s.StudentId == studentId)
                .Include(s => s.GradedBy)
                .ToListAsync();

            var result = assignments.Select(a => {
                var sub = submissions.FirstOrDefault(s => s.AssignmentId == a.Id);
                return new
                {
                    a.Id,
                    a.TopicId,
                    a.Title,
                    a.Description,
                    a.MaxScore,
                    a.Deadline,
                    a.FilePath,
                    IsSubmitted = sub != null,
                    Grade = sub?.Grade,
                    Feedback = sub?.Feedback,
                    GradedByName = sub?.GradedBy?.FullName
                };
            });
            return Ok(result);
        }

        return Ok(assignments);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult<Assignment>> CreateAssignment([FromForm] int topicId, [FromForm] string title, [FromForm] string description, [FromForm] int maxScore, [FromForm] DateTime? deadline, IFormFile? file)
    {
        if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(description) || maxScore <= 0)
        {
            return BadRequest("Sarlavha, tavsif va maksimal ball majburiy.");
        }

        if (deadline.HasValue && deadline.Value < DateTime.UtcNow)
        {
            return BadRequest("Topshiriq muddati o'tmishda bo'lishi mumkin emas.");
        }

        string? filePath = null;
        if (file != null && file.Length > 0)
        {
            var uploadsFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "assignments");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{Guid.NewGuid()}_{file.FileName}";
            var fullPath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }
            filePath = $"/uploads/assignments/{fileName}";
        }

        var assignment = new Assignment
        {
            TopicId = topicId,
            Title = title,
            Description = description,
            MaxScore = maxScore,
            Deadline = deadline,
            FilePath = filePath
        };

        _context.Assignments.Add(assignment);
        await _context.SaveChangesAsync();

        return Ok(assignment);
    }

    [HttpPost("update/{id}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> UpdateAssignment([FromRoute] int id, [FromForm] string title, [FromForm] string description, [FromForm] int maxScore, [FromForm] DateTime? deadline, IFormFile? file)
    {
        Console.WriteLine($"Backend: Updating assignment ID {id}");
        var assignment = await _context.Assignments.FindAsync(id);
        if (assignment == null) 
        {
            Console.WriteLine($"Backend: Assignment {id} NOT FOUND");
            return NotFound($"Topshiriq topilmadi (ID: {id})");
        }

        if (string.IsNullOrWhiteSpace(title) || string.IsNullOrWhiteSpace(description) || maxScore <= 0)
        {
            return BadRequest("Sarlavha, tavsif va maksimal ball majburiy.");
        }

        if (deadline.HasValue && assignment.Deadline != deadline.Value)
        {
            // Only validate if it's actually changing to a new date
            // Use a 1-minute buffer to avoid issues with current time passing while request is processing
            if (deadline.Value < DateTime.UtcNow.AddMinutes(-1))
            {
                return BadRequest("Topshiriq muddati o'tmishda bo'lishi mumkin emas.");
            }
        }

        if (file != null && file.Length > 0)
        {
            var uploadsFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "assignments");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{Guid.NewGuid()}_{file.FileName}";
            var fullPath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(fullPath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }
            assignment.FilePath = $"/uploads/assignments/{fileName}";
        }

        assignment.Title = title;
        assignment.Description = description;
        assignment.MaxScore = maxScore;
        assignment.Deadline = deadline;

        await _context.SaveChangesAsync();
        return Ok(assignment);
    }

    [HttpPost("submit/{assignmentId}")]
    public async Task<IActionResult> SubmitAssignment(int assignmentId, [FromForm] string? studentComment, IFormFile file)
    {
        var assignment = await _context.Assignments.FindAsync(assignmentId);
        if (assignment == null) return NotFound();

        if (assignment.Deadline.HasValue && assignment.Deadline.Value < DateTime.UtcNow)
        {
            return BadRequest("Ushbu topshiriqni topshirish muddati o'tgan.");
        }

        if (file == null || file.Length == 0) return BadRequest("File is empty.");

        var studentId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        
        var uploadsFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "submissions");
        if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

        var fileName = $"{Guid.NewGuid()}_{file.FileName}";
        var filePath = Path.Combine(uploadsFolder, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var submission = await _context.AssignmentSubmissions
            .FirstOrDefaultAsync(s => s.AssignmentId == assignmentId && s.StudentId == studentId);

        if (submission != null)
        {
            submission.FilePath = $"/uploads/submissions/{fileName}";
            submission.StudentComment = studentComment;
            submission.SubmittedAt = DateTime.UtcNow;
            // Optionally reset grade if it was already graded? 
            // Usually if they resubmit, the previous grade might be invalid.
            submission.Grade = null; 
            submission.Feedback = null;
        }
        else
        {
            submission = new AssignmentSubmission
            {
                AssignmentId = assignmentId,
                StudentId = studentId,
                FilePath = $"/uploads/submissions/{fileName}",
                StudentComment = studentComment,
                SubmittedAt = DateTime.UtcNow
            };
            _context.AssignmentSubmissions.Add(submission);
        }

        await _context.SaveChangesAsync();

        return Ok(new { submission.Id, submission.FilePath });
    }

    [HttpGet("submissions")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> GetAllSubmissions()
    {
        var submissions = await _context.AssignmentSubmissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
            .Include(s => s.GradedBy)
            .ToListAsync();
        return Ok(submissions);
    }

    [HttpGet("my-submissions")]
    public async Task<ActionResult> GetMySubmissions()
    {
        var studentId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var submissions = await _context.AssignmentSubmissions
            .Where(s => s.StudentId == studentId)
            .Include(s => s.Assignment)
            .Include(s => s.GradedBy)
            .ToListAsync();
        return Ok(submissions);
    }

    [HttpGet("topic/{topicId}/all-submissions")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> GetSubmissionsByTopic(int topicId)
    {
        var submissions = await _context.AssignmentSubmissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
            .Include(s => s.GradedBy)
            .Where(s => s.Assignment!.TopicId == topicId)
            .ToListAsync();
        return Ok(submissions);
    }

    [HttpPost("grade/{submissionId}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> GradeSubmission(int submissionId, GradeUpdateDto gradeDto)
    {
        var submission = await _context.AssignmentSubmissions
            .Include(s => s.Assignment)
            .FirstOrDefaultAsync(s => s.Id == submissionId);
            
        if (submission == null) return NotFound();
        if (submission.Assignment == null) return BadRequest("Tegishli topshiriq topilmadi.");

        if (gradeDto.Grade > submission.Assignment.MaxScore)
        {
            return BadRequest($"Baho maksimal balldan ({submission.Assignment.MaxScore}) yuqori bo'lishi mumkin emas.");
        }

        submission.Grade = gradeDto.Grade;
        submission.Feedback = gradeDto.Feedback;
        submission.GradedById = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        await _context.SaveChangesAsync();
        return Ok("Graded successfully.");
    }
}
