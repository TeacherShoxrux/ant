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
public class SubjectsController : ControllerBase
{
    private readonly AppDbContext _context;

    public SubjectsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    [Authorize]
    public async Task<ActionResult> GetSubjects([FromQuery] int pageNumber = 1, [FromQuery] int pageSize = 10, [FromQuery] string? searchTerm = null)
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdString)) return Unauthorized();
        
        int userId = int.Parse(userIdString);
        var role = User.FindFirstValue(ClaimTypes.Role);
        
        var query = _context.Subjects.AsQueryable();

        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            var search = searchTerm.ToLower().Trim();
            query = query.Where(s => 
                (s.Name != null && s.Name.ToLower().Contains(search)) || 
                (s.Description != null && s.Description.ToLower().Contains(search))
            );
        }

        if (role == "Admin")
        {
            // Admin sees all subjects
        }
        else if (role == "Moderator")
        {
            query = query.Where(s => s.CreatedById == userId);
        }
        else // Student
        {
            var student = await _context.Users.FindAsync(userId);
            if (student?.GroupId == null) return Ok(new { Items = new List<SubjectDto>(), TotalCount = 0 }); // No assigned group
            
            // Only subjects that are assigned to student's group
            query = query.Where(s => s.SubjectGroups.Any(sg => sg.GroupId == student.GroupId));
        }

        var totalCount = await query.CountAsync();
        var subjects = await query
            .OrderByDescending(s => s.Id)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(s => new SubjectDto
            {
                Id = s.Id,
                Name = s.Name,
                Description = s.Description,
                IsDisabled = s.IsDisabled
            })
            .ToListAsync();
            
        return Ok(new {
            Items = subjects,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
        });
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Subject>> GetSubject(int id)
    {
        var subject = await _context.Subjects
            .Include(s => s.Topics)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (subject == null) return NotFound();
        return Ok(subject);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult<Subject>> CreateSubject(SubjectDto subjectDto)
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdString)) return Unauthorized();

        var subject = new Subject
        {
            Name = subjectDto.Name,
            Description = subjectDto.Description,
            CreatedById = int.Parse(userIdString)
        };

        _context.Subjects.Add(subject);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetSubject), new { id = subject.Id }, subject);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> UpdateSubject(int id, UpdateSubjectDto updateDto)
    {
        var subject = await _context.Subjects.FindAsync(id);
        if (subject == null) return NotFound();

        subject.Name = updateDto.Name;
        subject.Description = updateDto.Description;
        subject.IsDisabled = updateDto.IsDisabled;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPatch("{id}/toggle-status")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> ToggleSubjectStatus(int id)
    {
        var subject = await _context.Subjects.FindAsync(id);
        if (subject == null) return NotFound();

        subject.IsDisabled = !subject.IsDisabled;

        await _context.SaveChangesAsync();
        return Ok(new { subject.Id, subject.IsDisabled });
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> DeleteSubject(int id)
    {
        var subject = await _context.Subjects.FindAsync(id);
        if (subject == null) return NotFound();

        _context.Subjects.Remove(subject);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpGet("{id}/groups")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult<IEnumerable<int>>> GetSubjectGroups(int id)
    {
        var groupIds = await _context.SubjectGroups
            .Where(sg => sg.SubjectId == id)
            .Select(sg => sg.GroupId)
            .ToListAsync();
            
        return Ok(groupIds);
    }

    [HttpPost("{id}/groups")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> AttachGroups(int id, [FromBody] List<int> groupIds)
    {
        var subject = await _context.Subjects.FindAsync(id);
        if (subject == null) return NotFound();

        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        int userId = int.Parse(userIdString!);
        var role = User.FindFirstValue(ClaimTypes.Role);
        if (role != "Admin" && subject.CreatedById != userId) return Forbid("Siz faqat o'zingiz yaratgan fanlarga guruh biriktira olasiz.");

        // Remove old associations
        var oldAssoc = _context.SubjectGroups.Where(sg => sg.SubjectId == id);
        _context.SubjectGroups.RemoveRange(oldAssoc);

        // Add new associations
        foreach (var gid in groupIds)
        {
            _context.SubjectGroups.Add(new SubjectGroup { SubjectId = id, GroupId = gid });
        }

        await _context.SaveChangesAsync();
        return Ok();
    }

    // --- Online Meetings ---

    [HttpGet("{id}/meetings")]
    [Authorize]
    public async Task<ActionResult<IEnumerable<OnlineMeetingDto>>> GetMeetings(int id)
    {
        var meetings = await _context.OnlineMeetings
            .Include(m => m.CreatedBy)
            .Where(m => m.SubjectId == id)
            .OrderBy(m => m.StartTime)
            .Select(m => new OnlineMeetingDto
            {
                Id = m.Id,
                SubjectId = m.SubjectId,
                Title = m.Title,
                MeetingUrl = m.MeetingUrl,
                StartTime = m.StartTime,
                CreatedByName = m.CreatedBy != null ? m.CreatedBy.FullName : null
            })
            .ToListAsync();

        return Ok(meetings);
    }

    [HttpPost("{id}/meetings")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<ActionResult<OnlineMeetingDto>> CreateMeeting(int id, CreateOnlineMeetingDto dto)
    {
        try 
        {
            Console.WriteLine($"Creating meeting for subject {id}. Title: {dto.Title}");
            var subject = await _context.Subjects.FindAsync(id);
            if (subject == null) return NotFound("Fan topilmadi.");

            var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdString)) return Unauthorized("User ID topilmadi.");
            
            var userId = int.Parse(userIdString);

            var meeting = new OnlineMeeting
            {
                SubjectId = id,
                Title = dto.Title,
                MeetingUrl = dto.MeetingUrl,
                StartTime = dto.StartTime,
                CreatedById = userId
            };

            _context.OnlineMeetings.Add(meeting);
            await _context.SaveChangesAsync();
            
            Console.WriteLine("Meeting created successfully.");

            return Ok(new OnlineMeetingDto
            {
                Id = meeting.Id,
                SubjectId = meeting.SubjectId,
                Title = meeting.Title,
                MeetingUrl = meeting.MeetingUrl,
                StartTime = meeting.StartTime
            });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating meeting: {ex.Message}");
            return StatusCode(500, ex.Message);
        }
    }

    [HttpPut("meetings/{meetingId}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> UpdateMeeting(int meetingId, CreateOnlineMeetingDto dto)
    {
        var meeting = await _context.OnlineMeetings.FindAsync(meetingId);
        if (meeting == null) return NotFound("Uchrashuv topilmadi.");

        meeting.Title = dto.Title;
        meeting.MeetingUrl = dto.MeetingUrl;
        meeting.StartTime = dto.StartTime;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("meetings/{meetingId}")]
    [Authorize(Roles = "Admin,Moderator")]
    public async Task<IActionResult> DeleteMeeting(int meetingId)
    {
        var meeting = await _context.OnlineMeetings.FindAsync(meetingId);
        if (meeting == null) return NotFound("Uchrashuv topilmadi.");

        _context.OnlineMeetings.Remove(meeting);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
