using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;
using StudentPlatform.Backend.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using StudentPlatform.Backend.DTOs;

namespace StudentPlatform.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QuizzesController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IWebHostEnvironment _env;

    public QuizzesController(AppDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpGet("topic/{topicId}")]
    public async Task<ActionResult> GetQuizzesByTopic(int topicId)
    {
        bool isAdmin = User.IsInRole("Admin");

        var query = _context.Quizzes.Where(q => q.TopicId == topicId);

        if (isAdmin)
        {
            var quizzes = await query
                .Include(q => q.CreatedBy)
                .Include(q => q.Questions)
                    .ThenInclude(qs => qs.Options)
                .ToListAsync();
            return Ok(quizzes);
        }
        else 
        {
            // For students, only return quiz metadata.
            var quizzes = await query
                .Include(q => q.CreatedBy)
                .Select(q => new {
                    q.Id,
                    q.TopicId,
                    q.Title,
                    q.Content,
                    q.TimeLimitMinutes,
                    q.ImagePath,
                    CreatedByName = q.CreatedBy != null ? q.CreatedBy.FullName : null
                })
                .ToListAsync();
            return Ok(quizzes);
        }
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> CreateQuiz([FromForm] int topicId, [FromForm] string title, [FromForm] string content, [FromForm] int timeLimitMinutes, IFormFile? image)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        string? imagePath = null;
        // ... (rest of image logic remains same)
        if (image != null && image.Length > 0)
        {
            var uploadsFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "quizzes");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

            var fileName = $"{Guid.NewGuid()}_{image.FileName}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await image.CopyToAsync(stream);
            }
            imagePath = $"/uploads/quizzes/{fileName}";
        }

        var quiz = new TopicQuiz
        {
            TopicId = topicId,
            Title = title,
            Content = content,
            TimeLimitMinutes = timeLimitMinutes,
            ImagePath = imagePath,
            CreatedById = currentUserId
        };

        _context.Quizzes.Add(quiz);
        await _context.SaveChangesAsync();

        return Ok(quiz);
    }

    [HttpPost("submit")]
    public async Task<ActionResult> SubmitQuiz([FromBody] QuizSubmissionDto submission)
    {
        var studentIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        if (studentIdClaim == null) return Unauthorized("User ID not found in token.");
        int studentId = int.Parse(studentIdClaim.Value);

        var quiz = await _context.Quizzes
            .Include(q => q.Questions)
                .ThenInclude(qs => qs.Options)
            .FirstOrDefaultAsync(q => q.Id == submission.QuizId);

        if (quiz == null) return NotFound("Quiz not found.");
        if (!quiz.Questions.Any()) return BadRequest("No questions found for this quiz.");

        int correctCount = 0;
        foreach (var answer in submission.Answers)
        {
            var question = quiz.Questions.FirstOrDefault(q => q.Id == answer.QuestionId);
            if (question != null)
            {
                var selectedOption = question.Options.FirstOrDefault(o => o.Id == answer.SelectedOptionId);
                if (selectedOption != null && selectedOption.IsCorrect)
                {
                    correctCount++;
                }
            }
        }

        double scorePercentage = 0;
        if (quiz.Questions.Count > 0)
        {
            scorePercentage = (double)correctCount / quiz.Questions.Count * 100;
        }

        int scoreInt = (int)Math.Round(scorePercentage);

        var result = new TestResult
        {
            StudentId = studentId,
            QuizId = quiz.Id,
            Score = scoreInt,
            TotalQuestions = quiz.Questions.Count,
            TakenAt = DateTime.UtcNow
        };

        _context.TestResults.Add(result);
        try 
        {
            await _context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Ma'lumotlar bazasiga saqlashda xatolik: {ex.Message}");
        }

        return Ok(new 
        {
            Score = scoreInt,
            CorrectCount = correctCount,
            TotalQuestions = quiz.Questions.Count
        });
    }

    [HttpPost("{quizId}/questions")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> AddQuestion(int quizId, [FromForm] string title, [FromForm] string question, [FromForm] string optionsJson, IFormFile? image)
    {
        string? imagePath = null;
        if (image != null && image.Length > 0)
        {
            var uploadsFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "questions");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
            var fileName = $"{Guid.NewGuid()}_{image.FileName}";
            var filePath = Path.Combine(uploadsFolder, fileName);
            using (var stream = new FileStream(filePath, FileMode.Create)) await image.CopyToAsync(stream);
            imagePath = $"/uploads/questions/{fileName}";
        }

        var options = System.Text.Json.JsonSerializer.Deserialize<List<TestOptionDto>>(optionsJson, new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        if (options == null || !options.Any()) return BadRequest("At least one option is required.");

        var q = new TestQuestion
        {
            QuizId = quizId,
            Title = title,
            Question = question,
            ImagePath = imagePath,
            Options = options.Select(o => new TestOption { OptionText = o.OptionText, IsCorrect = o.IsCorrect }).ToList()
        };

        _context.TestQuestions.Add(q);
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            return StatusCode(500, $"Savolni saqlashda xatolik: {ex.Message}");
        }
        return Ok(q);
    }

    [HttpGet("{quizId}/questions")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult> GetQuizQuestions(int quizId)
    {
        var questions = await _context.TestQuestions
            .Where(q => q.QuizId == quizId)
            .Include(q => q.Options)
            .ToListAsync();
        return Ok(questions);
    }

    [HttpGet("{quizId}/results")]
    public async Task<ActionResult> GetQuizResults(int quizId)
    {
        var results = await _context.TestResults
            .Where(r => r.QuizId == quizId)
            .Include(r => r.Student)
            .Select(r => new {
                StudentName = r.Student != null ? r.Student.FullName : "Nomalum",
                Score = r.Score,
                TotalQuestions = r.TotalQuestions,
                TakenAt = r.TakenAt
            })
            .OrderByDescending(r => r.TakenAt)
            .ToListAsync();
        return Ok(results);
    }
}

public class QuizSubmissionDto
{
    public int QuizId { get; set; }
    public List<QuizAnswerDto> Answers { get; set; } = new();
}

public class QuizAnswerDto
{
    public int QuestionId { get; set; }
    public int SelectedOptionId { get; set; }
}

public class TestOptionDto
{
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
}
