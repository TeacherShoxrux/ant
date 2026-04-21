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
public class TopicsController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly IWebHostEnvironment _env;

    public TopicsController(AppDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
    }

    [HttpGet("subject/{subjectId}")]
    public async Task<ActionResult<IEnumerable<TopicDto>>> GetTopicsBySubject(int subjectId)
    {
        var topics = await _context.Topics
            .Where(t => t.SubjectId == subjectId)
            .Select(t => new TopicDto
            {
                Id = t.Id,
                SubjectId = t.SubjectId,
                Title = t.Title,
                Content = t.Content,
                IsDisabled = t.IsDisabled,
                CreatedByName = t.CreatedBy != null ? t.CreatedBy.FullName : null
            })
            .ToListAsync();
        return Ok(topics);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Topic>> GetTopic(int id)
    {
        var topic = await _context.Topics
            .Include(t => t.CreatedBy)
            .Include(t => t.Videos)
                .ThenInclude(v => v.CreatedBy)
            .Include(t => t.Documents)
            .Include(t => t.Assignments)
                .ThenInclude(a => a.CreatedBy)
            .Include(t => t.Quizzes)
                .ThenInclude(q => q.CreatedBy)
            .Include(t => t.Quizzes)
                .ThenInclude(q => q.Questions)
                    .ThenInclude(qs => qs.Options)
            .FirstOrDefaultAsync(t => t.Id == id);

        if (topic == null) return NotFound();
        return Ok(topic);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult<Topic>> CreateTopic(TopicDto topicDto)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var topic = new Topic
        {
            SubjectId = topicDto.SubjectId,
            Title = topicDto.Title,
            Content = topicDto.Content,
            CreatedById = currentUserId
        };
        _context.Topics.Add(topic);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetTopic), new { id = topic.Id }, topic);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> UpdateTopic(int id, UpdateTopicDto updateDto)
    {
        var topic = await _context.Topics.FindAsync(id);
        if (topic == null) return NotFound();

        topic.Title = updateDto.Title;
        topic.Content = updateDto.Content;
        topic.IsDisabled = updateDto.IsDisabled;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("{id}/toggle-status")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> ToggleTopicStatus(int id)
    {
        var topic = await _context.Topics.FindAsync(id);
        if (topic == null) return NotFound();

        topic.IsDisabled = !topic.IsDisabled;

        await _context.SaveChangesAsync();
        return Ok(new { topic.Id, topic.IsDisabled });
    }

    [HttpPost("{topicId}/videos")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> AddVideo(int topicId, TopicVideoDto videoDto)
    {
        var currentUserId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var video = new TopicVideo
        {
            TopicId = topicId,
            Title = videoDto.Title,
            YoutubeUrl = videoDto.YoutubeUrl,
            CreatedById = currentUserId
        };

        _context.TopicVideos.Add(video);
        await _context.SaveChangesAsync();

        return Ok(video);
    }

    [HttpPost("{topicId}/documents")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> UploadDocument(int topicId, [FromForm] string title, IFormFile file)
    {
        if (file == null || file.Length == 0) return BadRequest("File is empty.");

        var uploadsFolder = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads", "documents");
        if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

        var fileName = $"{Guid.NewGuid()}_{file.FileName}";
        var filePath = Path.Combine(uploadsFolder, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        var document = new TopicDocument
        {
            TopicId = topicId,
            Title = title,
            FileName = file.FileName,
            FilePath = $"/uploads/documents/{fileName}"
        };

        _context.TopicDocuments.Add(document);
        await _context.SaveChangesAsync();

        return Ok(document);
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> DeleteTopic(int id)
    {
        var topic = await _context.Topics.FindAsync(id);
        if (topic == null) return NotFound();

        _context.Topics.Remove(topic);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
