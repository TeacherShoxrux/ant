

using FaceApi.Services.Embedding;
using FaceONNX;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using StudentPlatform.Backend.Embedding.Cached;

namespace StudentPlatform.Backend.Embedding
{
    public class EmbeddingService: IEmbeddingService
    {
        FaceDetector faceDetector;
        Face68LandmarksExtractor faceLandmarksExtractor;
        FaceEmbedder faceEmbedder;
    
        private readonly Embeddings embeddings;
        public EmbeddingService(IFaceEmbeddingCache faces)
        {
            faceDetector= new FaceDetector();
            faceLandmarksExtractor= new Face68LandmarksExtractor();
            faceEmbedder= new FaceEmbedder();

            this.embeddings = new Embeddings(faces);
        }


        public float[]? GenerateEmbedding(string imagePath)
        {
            using var theImage = Image.Load<Rgb24>(imagePath);
            return GetEmbedding(theImage);
        }
        
        float[]? GetEmbedding(Image<Rgb24> image)
        {
            var array = GetImageFloatArray(image);
            var rectangles = faceDetector.Forward(array);
            var rectangle = rectangles.FirstOrDefault()!.Box;
            if (!rectangle.IsEmpty)
            {
                var points = faceLandmarksExtractor.Forward(array, rectangle);
                var angle = points.RotationAngle;
                var aligned = FaceProcessingExtensions.Align(array, rectangle, angle);
                return faceEmbedder.Forward(aligned);
            }
            return new float[512];
        }
        public int? GetMatchedStudentId(float[] embedding)
        {
            try
            {
                
                int? id = embeddings.FromSimilarity(embedding); 
                return id;
            }catch(Exception)
            {
                return null;
            }
                
               
        }
        float[][,] GetImageFloatArray(Image<Rgb24> image)
        {
            var array = new[]
            {
                new float [image.Height,image.Width],
                new float [image.Height,image.Width],
                new float [image.Height,image.Width]
            };
            image.ProcessPixelRows(pixelAccessor =>
            {
                for (var y = 0; y < pixelAccessor.Height; y++)
                {
                    var row = pixelAccessor.GetRowSpan(y);
                    for (var x = 0; x < pixelAccessor.Width; x++)
                    {
                        array[2][y, x] = row[x].R / 255.0F;
                        array[1][y, x] = row[x].G / 255.0F;
                        array[0][y, x] = row[x].B / 255.0F;
                    }
                }
            });
            return array;
        }

    }
}