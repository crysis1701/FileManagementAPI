using Minio;
using Minio.DataModel.Args;
using FileManagementAPI.Models;

namespace FileManagementAPI.Services
{
    public interface IMinioService
    {
        Task<MinioUploadResult> UploadFileAsync(IFormFile file, string bucketName, string objectName);
        Task<string> GetFileUrlAsync(string bucketName, string objectName);
        Task<bool> DeleteFileAsync(string bucketName, string objectName);
        Task<bool> BucketExistsAsync(string bucketName);
        Task CreateBucketAsync(string bucketName);
    }

    public class MinioService : IMinioService
    {
        private readonly IMinioClient _minioClient;
        private readonly ILogger<MinioService> _logger;
        private readonly IConfiguration _configuration;

        public MinioService(IMinioClient minioClient, ILogger<MinioService> logger, IConfiguration configuration)
        {
            _minioClient = minioClient;
            _logger = logger;
            _configuration = configuration;
        }

        public async Task<MinioUploadResult> UploadFileAsync(IFormFile file, string bucketName, string objectName)
        {
            try
            {
                // Ensure bucket exists
                if (!await BucketExistsAsync(bucketName))
                {
                    await CreateBucketAsync(bucketName);
                }

                // Upload file
                using var stream = file.OpenReadStream();
                var putObjectArgs = new PutObjectArgs()
                    .WithBucket(bucketName)
                    .WithObject(objectName)
                    .WithStreamData(stream)
                    .WithObjectSize(file.Length)
                    .WithContentType(file.ContentType);

                await _minioClient.PutObjectAsync(putObjectArgs);

                // Generate URL
                var minioUrl = await GetFileUrlAsync(bucketName, objectName);

                _logger.LogInformation($"File uploaded successfully: {bucketName}/{objectName}");

                return new MinioUploadResult
                {
                    Success = true,
                    MinioUrl = minioUrl,
                    BucketName = bucketName,
                    ObjectName = objectName
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error uploading file to MinIO: {bucketName}/{objectName}");
                return new MinioUploadResult
                {
                    Success = false,
                    ErrorMessage = ex.Message
                };
            }
        }

        public async Task<string> GetFileUrlAsync(string bucketName, string objectName)
        {
            try
            {
                var reqParams = new Dictionary<string, string>(StringComparer.Ordinal);
                var presignedGetObjectArgs = new PresignedGetObjectArgs()
                    .WithBucket(bucketName)
                    .WithObject(objectName)
                    .WithExpiry(60 * 60 * 24 * 7) // 7 days
                    .WithHeaders(reqParams);

                var url = await _minioClient.PresignedGetObjectAsync(presignedGetObjectArgs);
                return url;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting file URL from MinIO: {bucketName}/{objectName}");
                return string.Empty;
            }
        }

        public async Task<bool> DeleteFileAsync(string bucketName, string objectName)
        {
            try
            {
                var removeObjectArgs = new RemoveObjectArgs()
                    .WithBucket(bucketName)
                    .WithObject(objectName);

                await _minioClient.RemoveObjectAsync(removeObjectArgs);
                _logger.LogInformation($"File deleted successfully: {bucketName}/{objectName}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error deleting file from MinIO: {bucketName}/{objectName}");
                return false;
            }
        }

        public async Task<bool> BucketExistsAsync(string bucketName)
        {
            try
            {
                var bucketExistsArgs = new BucketExistsArgs()
                    .WithBucket(bucketName);

                return await _minioClient.BucketExistsAsync(bucketExistsArgs);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error checking bucket existence: {bucketName}");
                return false;
            }
        }

        public async Task CreateBucketAsync(string bucketName)
        {
            try
            {
                var makeBucketArgs = new MakeBucketArgs()
                    .WithBucket(bucketName);

                await _minioClient.MakeBucketAsync(makeBucketArgs);
                _logger.LogInformation($"Bucket created successfully: {bucketName}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating bucket: {bucketName}");
                throw;
            }
        }
    }
}
