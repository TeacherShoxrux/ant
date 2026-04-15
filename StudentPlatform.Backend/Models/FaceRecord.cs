namespace StudentPlatform.Backend.Models;
public class FaceRecord 
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public virtual User? User { get; set; }
    public string Embedding { get; set; } = string.Empty;
    public string? Image { get; set; }
}