using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;

namespace StudentPlatform.Backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = "Admin,Moderator")]
public class SessionsController : ControllerBase
{
    private readonly AppDbContext _context;

    public SessionsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetSessions([FromQuery] int page = 1, [FromQuery] int limit = 10, [FromQuery] string? search = null, [FromQuery] DateTime? startDate = null, [FromQuery] DateTime? endDate = null)
    {
        var query = _context.UserSessions
            .Include(s => s.Student)
                .ThenInclude(u => u.Role)
            .AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            var lowerSearch = search.ToLower();
            query = query.Where(s => 
                (s.Student != null && (s.Student.FullName.ToLower().Contains(lowerSearch) || s.Student.Username.ToLower().Contains(lowerSearch))) ||
                (s.IpAddress != null && s.IpAddress.Contains(lowerSearch)) ||
                (s.LocationInfo != null && s.LocationInfo.ToLower().Contains(lowerSearch))
            );
        }

        if (startDate.HasValue)
        {
            query = query.Where(s => s.LoginTime >= startDate.Value);
        }

        if (endDate.HasValue)
        {
            // Set to end of day to include all hours of the selected end date
            var adjustedEndDate = endDate.Value.Date.AddDays(1).AddTicks(-1);
            query = query.Where(s => s.LoginTime <= adjustedEndDate);
        }

        var totalCount = await query.CountAsync();

        var sessions = await query
            .OrderByDescending(s => s.LoginTime)
            .Skip((page - 1) * limit)
            .Take(limit)
            .Select(s => new
            {
                s.Id,
                s.StudentId,
                StudentName = s.Student != null ? s.Student.FullName : "Noma'lum",
                Username = s.Student != null ? s.Student.Username : "Noma'lum",
                Phone = s.Student != null ? s.Student.PhoneNumber : "Kiritilmagan",
                RoleName = s.Student != null && s.Student.Role != null ? s.Student.Role.Name : "Foydalanuvchi",
                s.LoginTime,
                s.IpAddress,
                s.DeviceInfo,
                s.LocationInfo,
                s.FaceImagePath
            })
            .ToListAsync();

        return Ok(new
        {
            Sessions = sessions,
            TotalCount = totalCount,
            Page = page,
            Limit = limit
        });
    }
}
