using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FileManagementAPI.Models
{
    [Table("files")]
    public class FileEntity
    {
        [Key]
        [Column("file_id")]
        public Guid FileId { get; set; } = Guid.NewGuid();

        [Column("tab_id")]
        public int TabId { get; set; }

        [Column("category_id")]
        public int CategoryId { get; set; }

        [Column("file_name")]
        [MaxLength(255)]
        public string FileName { get; set; } = string.Empty;

        [Column("original_filename")]
        [MaxLength(255)]
        public string OriginalFilename { get; set; } = string.Empty;

        [Column("file_extension")]
        [MaxLength(10)]
        public string FileExtension { get; set; } = string.Empty;

        [Column("file_size")]
        public long FileSize { get; set; }

        [Column("mime_type")]
        [MaxLength(100)]
        public string MimeType { get; set; } = string.Empty;

        [Column("file_path")]
        [MaxLength(1000)]
        public string FilePath { get; set; } = string.Empty;

        [Column("uploaded_by")]
        public int UploadedBy { get; set; }

        [Column("department_id")]
        public int DepartmentId { get; set; }

        [Column("upload_date")]
        public DateTime UploadDate { get; set; } = DateTime.UtcNow;

        [Column("description")]
        [MaxLength(500)]
        public string? Description { get; set; }

        [Column("version")]
        public int Version { get; set; } = 1;

        [Column("is_current_version")]
        public bool IsCurrentVersion { get; set; } = true;

        [Column("parent_file_id")]
        public Guid? ParentFileId { get; set; }

        [Column("download_count")]
        public int DownloadCount { get; set; } = 0;

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        [Column("is_deleted")]
        public bool IsDeleted { get; set; } = false;

        [Column("deleted_at")]
        public DateTime? DeletedAt { get; set; }

        [Column("deleted_by")]
        public int? DeletedBy { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Column("updated_at")]
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        // Navigation properties
        [ForeignKey("TabId")]
        public virtual TabEntity? Tab { get; set; }

        [ForeignKey("CategoryId")]
        public virtual CategoryEntity? Category { get; set; }

        [ForeignKey("UploadedBy")]
        public virtual EmployeeEntity? Employee { get; set; }

        [ForeignKey("DepartmentId")]
        public virtual DepartmentEntity? Department { get; set; }
    }

    [Table("tabs")]
    public class TabEntity
    {
        [Key]
        [Column("tab_id")]
        public int TabId { get; set; }

        [Column("tab_code")]
        [MaxLength(50)]
        public string TabCode { get; set; } = string.Empty;

        [Column("tab_name")]
        [MaxLength(100)]
        public string TabName { get; set; } = string.Empty;

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        public virtual ICollection<FileEntity> Files { get; set; } = new List<FileEntity>();
    }

    [Table("categories")]
    public class CategoryEntity
    {
        [Key]
        [Column("category_id")]
        public int CategoryId { get; set; }

        [Column("tab_id")]
        public int TabId { get; set; }

        [Column("category_code")]
        [MaxLength(50)]
        public string CategoryCode { get; set; } = string.Empty;

        [Column("category_name")]
        [MaxLength(100)]
        public string CategoryName { get; set; } = string.Empty;

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        public virtual ICollection<FileEntity> Files { get; set; } = new List<FileEntity>();
    }

    [Table("employees")]
    public class EmployeeEntity
    {
        [Key]
        [Column("employee_id")]
        public int EmployeeId { get; set; }

        [Column("employee_code")]
        [MaxLength(50)]
        public string EmployeeCode { get; set; } = string.Empty;

        [Column("full_name")]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Column("email")]
        [MaxLength(255)]
        public string Email { get; set; } = string.Empty;

        [Column("position")]
        [MaxLength(100)]
        public string Position { get; set; } = string.Empty;

        [Column("department_id")]
        public int DepartmentId { get; set; }

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        [ForeignKey("DepartmentId")]
        public virtual DepartmentEntity? Department { get; set; }

        public virtual ICollection<FileEntity> Files { get; set; } = new List<FileEntity>();
    }

    [Table("departments")]
    public class DepartmentEntity
    {
        [Key]
        [Column("department_id")]
        public int DepartmentId { get; set; }

        [Column("department_code")]
        [MaxLength(50)]
        public string DepartmentCode { get; set; } = string.Empty;

        [Column("department_name")]
        [MaxLength(100)]
        public string DepartmentName { get; set; } = string.Empty;

        [Column("is_active")]
        public bool IsActive { get; set; } = true;

        public virtual ICollection<EmployeeEntity> Employees { get; set; } = new List<EmployeeEntity>();
        public virtual ICollection<FileEntity> Files { get; set; } = new List<FileEntity>();
    }

    [Table("file_actions")]
    public class FileActionEntity
    {
        [Key]
        [Column("action_id")]
        public Guid ActionId { get; set; } = Guid.NewGuid();

        [Column("file_id")]
        public Guid FileId { get; set; }

        [Column("action_type")]
        [MaxLength(50)]
        public string ActionType { get; set; } = string.Empty;

        [Column("performed_by")]
        public int PerformedBy { get; set; }

        [Column("action_date")]
        public DateTime ActionDate { get; set; } = DateTime.UtcNow;

        [Column("ip_address")]
        [MaxLength(45)]
        public string? IpAddress { get; set; }

        [Column("user_agent")]
        [MaxLength(500)]
        public string? UserAgent { get; set; }

        [Column("notes")]
        [MaxLength(500)]
        public string? Notes { get; set; }

        [ForeignKey("FileId")]
        public virtual FileEntity? File { get; set; }

        [ForeignKey("PerformedBy")]
        public virtual EmployeeEntity? Employee { get; set; }
    }
}
