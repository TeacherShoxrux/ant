using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Models;

namespace StudentPlatform.Backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users { get; set; }
    public DbSet<FaceRecord> FaceRecords { get; set; }
    public DbSet<Role> Roles { get; set; }
    public DbSet<Subject> Subjects { get; set; }
    public DbSet<Topic> Topics { get; set; }
    public DbSet<TopicQuiz> Quizzes { get; set; }
    public DbSet<TopicVideo> TopicVideos { get; set; }
    public DbSet<TopicDocument> TopicDocuments { get; set; }
    public DbSet<TestQuestion> TestQuestions { get; set; }
    public DbSet<TestOption> TestOptions { get; set; }
    public DbSet<Assignment> Assignments { get; set; }
    public DbSet<AssignmentSubmission> AssignmentSubmissions { get; set; }
    public DbSet<TestResult> TestResults { get; set; }
    public DbSet<Group> Groups { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Seed Roles
        modelBuilder.Entity<Role>().HasData(
            new Role { Id = 1, Name = "Admin" },
            new Role { Id = 2, Name = "Student" }
        );

        // Seed Admin User (Default: admin / admin123)
        // In a real app, use hashing. For this demo, we'll implement hashing in the service layer.
        modelBuilder.Entity<User>().HasData(
            new User { Id = 1, Username = "admin", PasswordHash = "admin123", FullName = "System Administrator", RoleId = 1 }
        );
        modelBuilder.Entity<FaceRecord>().HasOne<User>()
            .WithOne(u => u.FaceRecord)
            .HasForeignKey<FaceRecord>(f => f.UserId);
    }
}
