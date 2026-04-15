using System.Collections.Concurrent;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using StudentPlatform.Backend.Data;

namespace StudentPlatform.Backend.Embedding.Cached;

public sealed class FaceEmbeddingCache : IFaceEmbeddingCache
{
    private readonly ConcurrentDictionary<int, float[]> _embeddings;
    private readonly IServiceScopeFactory _scopeFactory;

    public FaceEmbeddingCache(IServiceScopeFactory scopeFactory)
    {
        _scopeFactory = scopeFactory;
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var data = db.FaceRecords
            .AsNoTracking()
            .ToList();

        _embeddings = new ConcurrentDictionary<int, float[]>(
            db.FaceRecords.AsNoTracking()
              .ToDictionary(x => x.UserId,
                            x => JsonSerializer.Deserialize<float[]>(x.Embedding)!));
    }

    public IReadOnlyDictionary<int, float[]> Embeddings => _embeddings;

    public void AddOrUpdate(int userId, float[] embedding)
    {
        _embeddings[userId] = embedding;
    }

}