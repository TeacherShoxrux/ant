namespace StudentPlatform.Backend.Embedding.Cached;
public interface IFaceEmbeddingCache
{
    IReadOnlyDictionary<int, float[]> Embeddings { get; }
    public void AddOrUpdate(int userId, float[] embedding);
}