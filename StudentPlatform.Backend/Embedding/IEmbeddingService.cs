
namespace StudentPlatform.Backend.Embedding;
public interface IEmbeddingService
{
    float[]? GenerateEmbedding(string imagePath);
    int? GetMatchedStudentId(float[] embedding);

}