using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;

namespace StudentPlatform.Backend.Services;

public class SessionCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<SessionCleanupService> _logger;
    private readonly IWebHostEnvironment _env;

    public SessionCleanupService(IServiceProvider serviceProvider, ILogger<SessionCleanupService> logger, IWebHostEnvironment env)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _env = env;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Session Cleanup Service is starting.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await DoWork(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred executing session cleanup.");
            }

            // Run once a day
            await Task.Delay(TimeSpan.FromDays(1), stoppingToken);
        }
    }

    private async Task DoWork(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Checking for expired sessions to clean up...");

        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Find sessions older than 30 days
        var cutoffDate = DateTime.UtcNow.AddDays(-30);
        var oldSessions = await context.UserSessions
            .Where(s => s.LoginTime < cutoffDate)
            .ToListAsync(stoppingToken);

        if (oldSessions.Count > 0)
        {
            var webRootPath = _env.WebRootPath ?? "wwwroot";

            foreach (var session in oldSessions)
            {
                // Try deleting the associated face image
                if (!string.IsNullOrEmpty(session.FaceImagePath))
                {
                    try
                    {
                        // Path stored in DB is "/temp/uploads/fileName"
                        // Absolute path is wwwroot/temp/uploads/fileName
                        var filePath = Path.Combine(webRootPath, session.FaceImagePath.TrimStart('/'));
                        if (File.Exists(filePath))
                        {
                            File.Delete(filePath);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, $"Could not delete session image: {session.FaceImagePath}");
                    }
                }
            }

            // Delete rows from DB
            context.UserSessions.RemoveRange(oldSessions);
            await context.SaveChangesAsync(stoppingToken);
            
            _logger.LogInformation($"Successfully cleaned up {oldSessions.Count} old sessions.");
        }
    }
}
