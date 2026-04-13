namespace StudentPlatform.Backend.DTOs;

public class TestSubmissionDto
{
    public int TopicId { get; set; }
    public List<TestAnswerDto> Answers { get; set; } = new();
}

public class TestAnswerDto
{
    public int QuestionId { get; set; }
    public string SelectedOption { get; set; } = string.Empty;
}

public class TestResultDto
{
    public int Score { get; set; }
    public int TotalQuestions { get; set; }
}

public class GradeUpdateDto
{
    public int Grade { get; set; }
    public string Feedback { get; set; } = string.Empty;
}
