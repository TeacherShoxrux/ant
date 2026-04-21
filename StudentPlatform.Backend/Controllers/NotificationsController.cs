using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;
using StudentPlatform.Backend.DTOs;
using StudentPlatform.Backend.Models;
using System.Security.Claims;

namespace StudentPlatform.Backend.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly AppDbContext _context;

    public NotificationsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<NotificationsResponseDto>> GetNotifications()
    {
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString)) return Unauthorized();
        int userId = int.Parse(userIdString);

        Console.WriteLine($"Fetching notifications for UserID: {userId}");

        var user = await _context.Users.Include(u => u.Role).FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null) return Unauthorized();

        var query = _context.Notifications.AsQueryable();

        // Filter based on role and target
        if (user.RoleId == 2) // Student
        {
            query = query.Where(n => n.TargetType == "All" || 
                                    (n.TargetType == "Group" && n.TargetGroupId == user.GroupId));
        }
        else // Admin or Moderator
        {
            query = query.Where(n => n.TargetType == "All" || n.TargetType == "Admins");
        }

        // Get IDs of notifications already read by this user
        var readIds = await _context.NotificationReads
            .Where(nr => nr.UserId == userId)
            .Select(nr => nr.NotificationId)
            .ToListAsync();

        var notifications = await query
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                Title = n.Title,
                Message = n.Message,
                CreatedAt = n.CreatedAt,
                SenderName = n.Sender != null ? n.Sender.FullName : "Tizim",
                IsRead = false // Default
            })
            .ToListAsync();

        // Apply IsRead from the readIds set
        foreach (var n in notifications)
        {
            if (readIds.Contains(n.Id))
            {
                n.IsRead = true;
            }
        }

        var unreadCount = notifications.Count(n => !n.IsRead);
        Console.WriteLine($"UserID: {userId} has {unreadCount} unread notifications.");

        return Ok(new NotificationsResponseDto
        {
            Notifications = notifications,
            UnreadCount = unreadCount
        });
    }

    [Authorize(Roles = "Admin,Moderator")]
    [HttpPost]
    public async Task<ActionResult> CreateNotification(CreateNotificationDto dto)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

        var notification = new Notification
        {
            Title = dto.Title,
            Message = dto.Message,
            TargetType = dto.TargetType,
            TargetGroupId = dto.TargetGroupId,
            SenderId = userId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Xabarnoma yuborildi." });
    }

    [HttpPatch("{id}/read")]
    public async Task<ActionResult> MarkAsRead(int id)
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        
        var alreadyRead = await _context.NotificationReads
            .AnyAsync(nr => nr.NotificationId == id && nr.UserId == userId);

        if (!alreadyRead)
        {
            _context.NotificationReads.Add(new NotificationRead
            {
                NotificationId = id,
                UserId = userId,
                ReadAt = DateTime.UtcNow
            });
            await _context.SaveChangesAsync();
        }

        return Ok();
    }

    [HttpPatch("read-all")]
    public async Task<ActionResult> MarkAllAsRead()
    {
        var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return Unauthorized();

        // Find all notifications the user can see
        var query = _context.Notifications.AsQueryable();
        if (user.RoleId == 2)
        {
            query = query.Where(n => n.TargetType == "All" || (n.TargetType == "Group" && n.TargetGroupId == user.GroupId));
        }
        else
        {
            query = query.Where(n => n.TargetType == "All" || n.TargetType == "Admins");
        }

        var visibleIds = await query.Select(n => n.Id).ToListAsync();
        var readIds = await _context.NotificationReads
            .Where(nr => nr.UserId == userId)
            .Select(nr => nr.NotificationId)
            .ToListAsync();

        var unreadIds = visibleIds.Except(readIds);

        foreach (var id in unreadIds)
        {
            _context.NotificationReads.Add(new NotificationRead
            {
                NotificationId = id,
                UserId = userId,
                ReadAt = DateTime.UtcNow
            });
        }

        await _context.SaveChangesAsync();
        return Ok();
    }
}
