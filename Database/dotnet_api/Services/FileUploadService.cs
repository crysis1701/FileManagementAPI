using Microsoft.EntityFrameworkCore;
using FileManagementAPI.Data;
using FileManagementAPI.Models;
using FileManagementAPI.Services;

namespace FileManagementAPI.Services
{
    public interface IFileUploadService
    {
        Task<FileUploadResponse> UploadFileAsync(FileUploadRequest request, string ipAddress, string userAgent);
        Task<FileEntity?> GetFileByIdAsync(Guid fileId);
        Task LogFileActionAsync(Guid fileId, string actionType, int performedBy, string? ipAddress = null, string? userAgent = null, string? notes = null);
        Task<bool> ValidateUploadPermissionsAsync(int tabId, int categoryId, int employeeId);
        string GenerateUniqueFileName(string originalFileName);
        string GetBucketName(int tabId, int categoryId);
    }

    public class FileUploadService : IFileUploadService
    {
        private readonly FileManagementDbContext _context;
        private readonly IMinioService _minioService;
        private readonly IFileValidationService _fileValidationService;
        private readonly ILogger<FileUploadService> _logger;
        private readonly IConfiguration _configuration;

        public FileUploadService(
            FileManagementDbContext context,
            IMinioService minioService,
            IFileValidationService fileValidationService,
            ILogger<FileUploadService> logger,
            IConfiguration configuration)
        {
            _context = context;
            _minioService = minioService;
            _fileValidationService = fileValidationService;
            _logger = logger;
            _configuration = configuration;
        }

        public async Task<FileUploadResponse> UploadFileAsync(FileUploadRequest request, string ipAddress, string userAgent)
        {
            try
            {
                // 1. Validate file
                var validationResult = _fileValidationService.ValidateFile(request.File);
                if (!validationResult.IsValid)
                {
                    return new FileUploadResponse
                    {
                        Status = "error",
                        Message = validationResult.ErrorMessage
                    };
                }

                // 2. Validate permissions
                var hasPermission = await ValidateUploadPermissionsAsync(request.TabId, request.CategoryId, request.UploadedBy);
                if (!hasPermission)
                {
                    return new FileUploadResponse
                    {
                        Status = "error",
                        Message = "You don't have permission to upload files to this category"
                    };
                }

                // 3. Get tab, category, employee, and department info
                var tabInfo = await _context.Tabs.FirstOrDefaultAsync(t => t.TabId == request.TabId && t.IsActive);
                var categoryInfo = await _context.Categories.FirstOrDefaultAsync(c => c.CategoryId == request.CategoryId && c.IsActive);
                var employeeInfo = await _context.Employees
                    .Include(e => e.Department)
                    .FirstOrDefaultAsync(e => e.EmployeeId == request.UploadedBy && e.IsActive);

                if (tabInfo == null || categoryInfo == null || employeeInfo == null)
                {
                    return new FileUploadResponse
                    {
                        Status = "error",
                        Message = "Invalid tab, category, or employee information"
                    };
                }

                // 4. Generate unique file name and bucket
                var uniqueFileName = GenerateUniqueFileName(request.File.FileName);
                var bucketName = GetBucketName(request.TabId, request.CategoryId);

                // 5. Upload to MinIO
                var uploadResult = await _minioService.UploadFileAsync(request.File, bucketName, uniqueFileName);
                if (!uploadResult.Success)
                {
                    return new FileUploadResponse
                    {
                        Status = "error",
                        Message = $"Failed to upload file to storage: {uploadResult.ErrorMessage}"
                    };
                }

                // 6. Save file info to database
                var fileEntity = new FileEntity
                {
                    TabId = request.TabId,
                    CategoryId = request.CategoryId,
                    FileName = Path.GetFileNameWithoutExtension(request.File.FileName),
                    OriginalFilename = request.File.FileName,
                    FileExtension = _fileValidationService.GetFileExtension(request.File.FileName),
                    FileSize = request.File.Length,
                    MimeType = request.File.ContentType,
                    FilePath = uploadResult.MinioUrl,
                    UploadedBy = request.UploadedBy,
                    DepartmentId = request.DepartmentId,
                    Description = request.Description,
                    UploadDate = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                };

                _context.Files.Add(fileEntity);
                await _context.SaveChangesAsync();

                // 7. Log upload action
                await LogFileActionAsync(fileEntity.FileId, "UPLOAD", request.UploadedBy, ipAddress, userAgent, "File uploaded via API");

                // 8. Return response
                var response = new FileUploadResponse
                {
                    Status = "success",
                    Message = "File uploaded successfully",
                    Data = new FileUploadData
                    {
                        FileId = fileEntity.FileId,
                        FileName = fileEntity.FileName,
                        OriginalFilename = fileEntity.OriginalFilename,
                        FileExtension = fileEntity.FileExtension,
                        FileSize = fileEntity.FileSize,
                        FileSizeDisplay = _fileValidationService.FormatFileSize(fileEntity.FileSize),
                        MimeType = fileEntity.MimeType,
                        MinioUrl = uploadResult.MinioUrl,
                        UploadDate = fileEntity.UploadDate,
                        UploadDateDisplay = fileEntity.UploadDate.ToString("dd/MM/yyyy HH:mm"),
                        UploadedBy = new EmployeeInfo
                        {
                            EmployeeId = employeeInfo.EmployeeId,
                            EmployeeCode = employeeInfo.EmployeeCode,
                            FullName = employeeInfo.FullName,
                            Position = employeeInfo.Position,
                            Email = employeeInfo.Email
                        },
                        Department = new DepartmentInfo
                        {
                            DepartmentId = employeeInfo.Department!.DepartmentId,
                            DepartmentCode = employeeInfo.Department.DepartmentCode,
                            DepartmentName = employeeInfo.Department.DepartmentName
                        },
                        TabName = tabInfo.TabName,
                        CategoryName = categoryInfo.CategoryName
                    }
                };

                _logger.LogInformation($"File uploaded successfully: {fileEntity.FileId} - {fileEntity.FileName}");
                return response;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading file");
                return new FileUploadResponse
                {
                    Status = "error",
                    Message = "An error occurred while uploading the file"
                };
            }
        }

        public async Task<FileEntity?> GetFileByIdAsync(Guid fileId)
        {
            return await _context.Files
                .Include(f => f.Tab)
                .Include(f => f.Category)
                .Include(f => f.Employee)
                .Include(f => f.Department)
                .FirstOrDefaultAsync(f => f.FileId == fileId && !f.IsDeleted);
        }

        public async Task LogFileActionAsync(Guid fileId, string actionType, int performedBy, string? ipAddress = null, string? userAgent = null, string? notes = null)
        {
            try
            {
                var fileAction = new FileActionEntity
                {
                    FileId = fileId,
                    ActionType = actionType,
                    PerformedBy = performedBy,
                    ActionDate = DateTime.UtcNow,
                    IpAddress = ipAddress,
                    UserAgent = userAgent,
                    Notes = notes
                };

                _context.FileActions.Add(fileAction);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error logging file action: {actionType} for file {fileId}");
            }
        }

        public async Task<bool> ValidateUploadPermissionsAsync(int tabId, int categoryId, int employeeId)
        {
            // Check if employee exists and is active
            var employee = await _context.Employees
                .Include(e => e.Department)
                .FirstOrDefaultAsync(e => e.EmployeeId == employeeId && e.IsActive);

            if (employee == null)
                return false;

            // Check if tab and category exist and are active
            var tab = await _context.Tabs.FirstOrDefaultAsync(t => t.TabId == tabId && t.IsActive);
            var category = await _context.Categories.FirstOrDefaultAsync(c => c.CategoryId == categoryId && c.IsActive);

            if (tab == null || category == null)
                return false;

            // Check if category belongs to the tab
            if (category.TabId != tabId)
                return false;

            // For now, all active employees can upload files
            // You can extend this logic to check specific permissions
            return true;
        }

        public string GenerateUniqueFileName(string originalFileName)
        {
            var extension = Path.GetExtension(originalFileName);
            var fileName = Path.GetFileNameWithoutExtension(originalFileName);
            var timestamp = DateTime.UtcNow.ToString("yyyyMMdd_HHmmss");
            var uniqueId = Guid.NewGuid().ToString("N")[..8];
            
            return $"{fileName}_{timestamp}_{uniqueId}{extension}";
        }

        public string GetBucketName(int tabId, int categoryId)
        {
            var bucketPrefix = _configuration.GetValue<string>("MinIO:BucketPrefix", "file-management");
            return $"{bucketPrefix}-tab{tabId}-cat{categoryId}".ToLowerInvariant();
        }
    }
}
