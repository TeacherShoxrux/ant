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
    public async Task<ActionResult<IEnumerable<SubjectDto>>> GetSubjects()
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdString)) return Unauthorized();
        
        int userId = int.Parse(userIdString);
        var role = User.FindFirstValue(ClaimTypes.Role);
        
        var query = _context.Subjects.AsQueryable();

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
            if (student?.GroupId == null) return Ok(new List<SubjectDto>()); // No assigned group
            
            // Only subjects that are assigned to student's group
            query = query.Where(s => s.SubjectGroups.Any(sg => sg.GroupId == student.GroupId));
        }

        var subjects = await query
            .Select(s => new SubjectDto
            {
                Id = s.Id,
                Name = s.Name,
                Description = s.Description,
                IsDisabled = s.IsDisabled
            })
            .ToListAsync();
            
        return Ok(subjects);
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
}
