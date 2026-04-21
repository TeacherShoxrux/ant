using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace StudentPlatform.Backend.Models;

public class Role
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class Group
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Patronymic { get; set; } // Sharifi
    public string? PhoneNumber { get; set; }
    public string? ImagePath { get; set; }
    public int FaceRecordId { get; set; }
    public virtual FaceRecord? FaceRecord { get; set; }
    public int? GroupId { get; set; }
    public Group? Group { get; set; }
    
    public int RoleId { get; set; }
    public Role? Role { get; set; }
    
    public bool IsDisabled { get; set; } = false;
}

public class Subject
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public bool IsDisabled { get; set; } = false;
    public int? CreatedById { get; set; }
    public User? CreatedBy { get; set; }
    public List<Topic> Topics { get; set; } = new();
    public List<SubjectGroup> SubjectGroups { get; set; } = new();
}

public class SubjectGroup
{
    public int SubjectId { get; set; }
    [JsonIgnore]
    public Subject? Subject { get; set; }
    
    public int GroupId { get; set; }
    [JsonIgnore]
    public Group? Group { get; set; }
}

public class Topic
{
    public int Id { get; set; }
    public int SubjectId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public bool IsDisabled { get; set; } = false;
    
    public List<TopicQuiz> Quizzes { get; set; } = new();
    public List<Assignment> Assignments { get; set; } = new();
    public List<TopicDocument> Documents { get; set; } = new();
    public List<TopicVideo> Videos { get; set; } = new();
    public int? CreatedById { get; set; }
    public User? CreatedBy { get; set; }
}

public class TopicVideo
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    [JsonIgnore]
    public Topic? Topic { get; set; }
    public string Title { get; set; } = string.Empty;
    public string YoutubeUrl { get; set; } = string.Empty;
    public int? CreatedById { get; set; }
    public User? CreatedBy { get; set; }
}

public class TopicDocument
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    [JsonIgnore]
    public Topic? Topic { get; set; }
    public string Title { get; set; } = string.Empty;
    public string FilePath { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
}

public class TopicQuiz
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    [JsonIgnore]
    public Topic? Topic { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public int TimeLimitMinutes { get; set; }
    public string? ImagePath { get; set; }
    
    public List<TestQuestion> Questions { get; set; } = new();
    public int? CreatedById { get; set; }
    public User? CreatedBy { get; set; }
}

public class TestQuestion
{
    public int Id { get; set; }
    [ForeignKey("Quiz")]
    public int QuizId { get; set; }
    [JsonIgnore]
    public TopicQuiz? Quiz { get; set; }
    
    public string Title { get; set; } = string.Empty;
    public string Question { get; set; } = string.Empty;
    public string? ImagePath { get; set; }
    
    public List<TestOption> Options { get; set; } = new();
}

public class TestOption
{
    public int Id { get; set; }
    [ForeignKey("Question")]
    public int QuestionId { get; set; }
    [JsonIgnore]
    public TestQuestion? Question { get; set; }
    
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
}

public class Assignment
{
    public int Id { get; set; }
    public int TopicId { get; set; }
    [JsonIgnore]
    public Topic? Topic { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int MaxScore { get; set; }
    public DateTime? Deadline { get; set; }
    public string? FilePath { get; set; } // Path to the task file uploaded by admin
    public int? CreatedById { get; set; }
    public User? CreatedBy { get; set; }
}

public class AssignmentSubmission
{
    public int Id { get; set; }
    public int AssignmentId { get; set; }
    public int StudentId { get; set; }
    public string FilePath { get; set; } = string.Empty;
    public string? StudentComment { get; set; }
    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    public int? Grade { get; set; }
    public string? Feedback { get; set; }
    public int? GradedById { get; set; }
    
    public User? Student { get; set; }
    public Assignment? Assignment { get; set; }
    public User? GradedBy { get; set; }
}

public class TestResult
{
    public int Id { get; set; }
    public int StudentId { get; set; }
    public int QuizId { get; set; }
    public int Score { get; set; }
    public int TotalQuestions { get; set; }
    public DateTime TakenAt { get; set; } = DateTime.UtcNow;
    
    public User? Student { get; set; }
    public TopicQuiz? Quiz { get; set; }
}

public class UserSession
{
    public int Id { get; set; }
    public int StudentId { get; set; }
    [JsonIgnore]
    public User? Student { get; set; }
    
    public DateTime LoginTime { get; set; } = DateTime.UtcNow;
    public string? IpAddress { get; set; }
    public string? DeviceInfo { get; set; }
    public string? LocationInfo { get; set; }
    public string? FaceImagePath { get; set; }
}
