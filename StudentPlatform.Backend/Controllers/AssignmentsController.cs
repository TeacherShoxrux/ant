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
                    Feedback = sub?.Feedback
                };
            });
            return Ok(result);
        }

        return Ok(assignments);
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Assignment>> CreateAssignment([FromForm] int topicId, [FromForm] string title, [FromForm] string description, [FromForm] int maxScore, [FromForm] DateTime? deadline, IFormFile? file)
    {
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

    [HttpPost("submit/{assignmentId}")]
    public async Task<IActionResult> SubmitAssignment(int assignmentId, [FromForm] string? studentComment, IFormFile file)
    {
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

        var submission = new AssignmentSubmission
        {
            AssignmentId = assignmentId,
            StudentId = studentId,
            FilePath = $"/uploads/submissions/{fileName}",
            StudentComment = studentComment,
            SubmittedAt = DateTime.UtcNow
        };

        _context.AssignmentSubmissions.Add(submission);
        await _context.SaveChangesAsync();

        return Ok(new { submission.Id, submission.FilePath });
    }

    [HttpGet("submissions")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> GetAllSubmissions()
    {
        var submissions = await _context.AssignmentSubmissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
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
            .ToListAsync();
        return Ok(submissions);
    }

    [HttpGet("topic/{topicId}/all-submissions")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult> GetSubmissionsByTopic(int topicId)
    {
        var submissions = await _context.AssignmentSubmissions
            .Include(s => s.Student)
            .Include(s => s.Assignment)
            .Where(s => s.Assignment!.TopicId == topicId)
            .ToListAsync();
        return Ok(submissions);
    }

    [HttpPost("grade/{submissionId}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GradeSubmission(int submissionId, GradeUpdateDto gradeDto)
    {
        var submission = await _context.AssignmentSubmissions.FindAsync(submissionId);
        if (submission == null) return NotFound();

        submission.Grade = gradeDto.Grade;
        submission.Feedback = gradeDto.Feedback;

        await _context.SaveChangesAsync();
        return Ok("Graded successfully.");
    }
}
