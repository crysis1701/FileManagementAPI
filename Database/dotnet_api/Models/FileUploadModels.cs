using System.ComponentModel.DataAnnotations;

namespace FileManagementAPI.Models
{
    public class FileUploadRequest
    {
        [Required]
        public int TabId { get; set; }
        
        [Required]
        public int CategoryId { get; set; }
        
        [Required]
        public IFormFile File { get; set; }
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        [Required]
        public int UploadedBy { get; set; }
        
        [Required]
        public int DepartmentId { get; set; }
    }

    public class FileUploadResponse
    {
        public string Status { get; set; } = "success";
        public string Message { get; set; } = string.Empty;
        public FileUploadData? Data { get; set; }
    }

    public class FileUploadData
    {
        public Guid FileId { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string OriginalFilename { get; set; } = string.Empty;
        public string FileExtension { get; set; } = string.Empty;
        public long FileSize { get; set; }
        public string FileSizeDisplay { get; set; } = string.Empty;
        public string MimeType { get; set; } = string.Empty;
        public string MinioUrl { get; set; } = string.Empty;
        public DateTime UploadDate { get; set; }
        public string UploadDateDisplay { get; set; } = string.Empty;
        public EmployeeInfo UploadedBy { get; set; } = new();
        public DepartmentInfo Department { get; set; } = new();
        public string TabName { get; set; } = string.Empty;
        public string CategoryName { get; set; } = string.Empty;
    }

    public class EmployeeInfo
    {
        public int EmployeeId { get; set; }
        public string EmployeeCode { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Position { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
    }

    public class DepartmentInfo
    {
        public int DepartmentId { get; set; }
        public string DepartmentCode { get; set; } = string.Empty;
        public string DepartmentName { get; set; } = string.Empty;
    }

    public class FileValidationResult
    {
        public bool IsValid { get; set; }
        public string ErrorMessage { get; set; } = string.Empty;
        public List<string> Errors { get; set; } = new();
    }

    public class MinioUploadResult
    {
        public bool Success { get; set; }
        public string MinioUrl { get; set; } = string.Empty;
        public string BucketName { get; set; } = string.Empty;
        public string ObjectName { get; set; } = string.Empty;
        public string ErrorMessage { get; set; } = string.Empty;
    }

    public class ToggleActiveRequest
    {
        public bool IsActive { get; set; }
    }
}
