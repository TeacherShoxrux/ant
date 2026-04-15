

using StudentPlatform.Backend.Embedding.Cached;
using UMapx.Distance;

namespace FaceApi.Services.Embedding;
public class Embeddings
{
    private readonly IFaceEmbeddingCache _cache;
    private readonly Cosine cosine;
    public Embeddings(IFaceEmbeddingCache cache)
        {

            _cache = cache;
            cosine = new Cosine(true);
        }
   

    // public FaceRecords FromDistance(float[] vector)
    //     {
    //         var euclidean = new Euclidean();
    //         var length = Count;
    //         var min = float.MaxValue;
    //         var index = -1;
    //         // do job
    //         for (var i = 0; i < length; i++)
    //         {
    //             var storedEncoding = Vectors[i]?.Encoding?
    //                     .Split(',')
    //                 .Select(x => float.TryParse(x, out var val) ? val : 0)
    //                     .ToArray();
    //             var d = euclidean.Compute(storedEncoding, vector);

    //             if (d < min)
    //             {
    //                 index = i;
    //                 min = d;
    //             }
    //         }
    //        return Vectors[index];
    //     }
    public int? FromSimilarity(float[] vector)
        {
            
            var index = -1;
            foreach (var i in _cache.Embeddings)
            {
                var d = cosine.Compute(i.Value, vector);

                if (d > 0.6)
                {
                    index = i.Key;
                    
                }
            }
            if (index == -1)
                return null;
            return index;
        }
}

