using FileManagementAPI.Models;

namespace FileManagementAPI.Services
{
    public interface IFileValidationService
    {
        FileValidationResult ValidateFile(IFormFile file);
        bool IsAllowedFileType(string fileName, string mimeType);
        bool IsFileSizeValid(long fileSize);
        string GetFileExtension(string fileName);
        string FormatFileSize(long bytes);
    }

    public class FileValidationService : IFileValidationService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<FileValidationService> _logger;

        // Allowed file types and their MIME types
        private static readonly Dictionary<string, List<string>> AllowedFileTypes = new()
        {
            { ".pdf", new List<string> { "application/pdf" } },
            { ".doc", new List<string> { "application/msword" } },
            { ".docx", new List<string> { "application/vnd.openxmlformats-officedocument.wordprocessingml.document" } },
            { ".xls", new List<string> { "application/vnd.ms-excel" } },
            { ".xlsx", new List<string> { "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" } },
            { ".ppt", new List<string> { "application/vnd.ms-powerpoint" } },
            { ".pptx", new List<string> { "application/vnd.openxmlformats-officedocument.presentationml.presentation" } },
            { ".txt", new List<string> { "text/plain" } },
            { ".jpg", new List<string> { "image/jpeg" } },
            { ".jpeg", new List<string> { "image/jpeg" } },
            { ".png", new List<string> { "image/png" } },
            { ".gif", new List<string> { "image/gif" } },
            { ".zip", new List<string> { "application/zip" } },
            { ".rar", new List<string> { "application/x-rar-compressed" } },
            { ".7z", new List<string> { "application/x-7z-compressed" } },
            { ".dwg", new List<string> { "application/acad", "image/vnd.dwg" } },
            { ".sql", new List<string> { "text/plain", "application/sql" } }
        };

        public FileValidationService(IConfiguration configuration, ILogger<FileValidationService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public FileValidationResult ValidateFile(IFormFile file)
        {
            var result = new FileValidationResult { IsValid = true };
            var errors = new List<string>();

            // Check if file is null or empty
            if (file == null || file.Length == 0)
            {
                errors.Add("File is required and cannot be empty");
                result.IsValid = false;
            }
            else
            {
                // Check file size
                if (!IsFileSizeValid(file.Length))
                {
                    var maxSizeMB = _configuration.GetValue<int>("FileUpload:MaxFileSizeMB", 50);
                    errors.Add($"File size exceeds maximum limit of {maxSizeMB} MB");
                    result.IsValid = false;
                }

                // Check file type
                if (!IsAllowedFileType(file.FileName, file.ContentType))
                {
                    errors.Add("File type is not allowed");
                    result.IsValid = false;
                }

                // Check file name
                if (string.IsNullOrWhiteSpace(file.FileName))
                {
                    errors.Add("File name is required");
                    result.IsValid = false;
                }
                else if (file.FileName.Length > 255)
                {
                    errors.Add("File name is too long (maximum 255 characters)");
                    result.IsValid = false;
                }

                // Check for malicious file names
                if (HasMaliciousFileName(file.FileName))
                {
                    errors.Add("File name contains invalid characters");
                    result.IsValid = false;
                }
            }

            result.Errors = errors;
            result.ErrorMessage = string.Join(", ", errors);

            if (!result.IsValid)
            {
                _logger.LogWarning($"File validation failed: {result.ErrorMessage}");
            }

            return result;
        }

        public bool IsAllowedFileType(string fileName, string mimeType)
        {
            if (string.IsNullOrWhiteSpace(fileName) || string.IsNullOrWhiteSpace(mimeType))
                return false;

            var extension = GetFileExtension(fileName).ToLowerInvariant();
            
            if (!AllowedFileTypes.ContainsKey(extension))
                return false;

            return AllowedFileTypes[extension].Contains(mimeType.ToLowerInvariant());
        }

        public bool IsFileSizeValid(long fileSize)
        {
            var maxSizeBytes = _configuration.GetValue<long>("FileUpload:MaxFileSizeBytes", 50 * 1024 * 1024); // 50MB default
            return fileSize > 0 && fileSize <= maxSizeBytes;
        }

        public string GetFileExtension(string fileName)
        {
            return Path.GetExtension(fileName).ToLowerInvariant();
        }

        public string FormatFileSize(long bytes)
        {
            if (bytes >= 1073741824) // GB
                return $"{bytes / 1073741824.0:F2} GB";
            if (bytes >= 1048576) // MB
                return $"{bytes / 1048576.0:F2} MB";
            if (bytes >= 1024) // KB
                return $"{bytes / 1024.0:F2} KB";
            return $"{bytes} bytes";
        }

        private bool HasMaliciousFileName(string fileName)
        {
            // Check for path traversal attacks
            if (fileName.Contains("..") || fileName.Contains("/") || fileName.Contains("\\"))
                return true;

            // Check for null bytes
            if (fileName.Contains('\0'))
                return true;

            // Check for control characters
            if (fileName.Any(c => char.IsControl(c)))
                return true;

            // Check for reserved Windows file names
            var reservedNames = new[] { "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9" };
            var fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName).ToUpperInvariant();
            if (reservedNames.Contains(fileNameWithoutExtension))
                return true;

            return false;
        }
    }
}
