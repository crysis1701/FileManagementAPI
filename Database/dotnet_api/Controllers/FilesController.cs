using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FileManagementAPI.Models;
using FileManagementAPI.Services;
using FileManagementAPI.Data;
using System.Net;

namespace FileManagementAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FilesController : ControllerBase
    {
        private readonly IFileUploadService _fileUploadService;
        private readonly FileManagementDbContext _context;
        private readonly ILogger<FilesController> _logger;

        public FilesController(IFileUploadService fileUploadService, FileManagementDbContext context, ILogger<FilesController> logger)
        {
            _fileUploadService = fileUploadService;
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get all files (general API for all file types)
        /// </summary>
        /// <param name="page">Page number</param>
        /// <param name="pageSize">Page size</param>
        /// <returns>List of all files</returns>
        [HttpGet]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetAllFiles(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            try
            {
                var query = _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .Include(f => f.Tab)
                    .Include(f => f.Category)
                    .Include(f => f.UploadedBy)
                    .Include(f => f.Department);

                var totalFiles = await query.CountAsync();
                var files = await query
                    .OrderByDescending(f => f.UploadDate)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(f => new
                    {
                        file_id = f.FileId,
                        file_name = f.FileName,
                        original_filename = f.OriginalFilename,
                        file_extension = f.FileExtension,
                        file_size = f.FileSize,
                        file_size_display = FormatFileSize(f.FileSize),
                        mime_type = f.MimeType,
                        uploaded_by = f.UploadedBy.FullName,
                        employee_code = f.UploadedBy.EmployeeCode,
                        department_name = f.Department.DepartmentName,
                        upload_date = f.UploadDate,
                        upload_date_display = f.UploadDate.ToString("dd/MM/yyyy HH:mm"),
                        description = f.Description,
                        download_count = f.DownloadCount,
                        version = f.Version,
                        is_current_version = f.IsCurrentVersion,
                        is_active = f.IsActive,
                        tab_name = f.Tab.TabName,
                        category_name = f.Category.CategoryName
                    })
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        files = files,
                        pagination = new
                        {
                            page = page,
                            page_size = pageSize,
                            total_files = totalFiles,
                            total_pages = (int)Math.Ceiling((double)totalFiles / pageSize)
                        }
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all files");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Upload a file to the specified tab and category
        /// </summary>
        /// <param name="request">File upload request</param>
        /// <returns>Upload result</returns>
        [HttpPost("upload")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(FileUploadResponse), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(FileUploadResponse), (int)HttpStatusCode.BadRequest)]
        [ProducesResponseType(typeof(FileUploadResponse), (int)HttpStatusCode.InternalServerError)]
        public async Task<IActionResult> UploadFile([FromForm] FileUploadRequest request)
        {
            try
            {
                // Validate model
                if (!ModelState.IsValid)
                {
                    var errors = ModelState.Values
                        .SelectMany(v => v.Errors)
                        .Select(e => e.ErrorMessage)
                        .ToList();

                    return BadRequest(new FileUploadResponse
                    {
                        Status = "error",
                        Message = string.Join(", ", errors)
                    });
                }

                // Get client IP and User Agent
                var ipAddress = GetClientIpAddress();
                var userAgent = Request.Headers["User-Agent"].ToString();

                // Upload file
                var result = await _fileUploadService.UploadFileAsync(request, ipAddress, userAgent);

                if (result.Status == "success")
                {
                    _logger.LogInformation($"File uploaded successfully: {result.Data?.FileId}");
                    return Ok(result);
                }
                else
                {
                    _logger.LogWarning($"File upload failed: {result.Message}");
                    return BadRequest(result);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in file upload endpoint");
                return StatusCode(500, new FileUploadResponse
                {
                    Status = "error",
                    Message = "An internal server error occurred"
                });
            }
        }

        /// <summary>
        /// Get file details by ID
        /// </summary>
        /// <param name="fileId">File ID</param>
        /// <returns>File details</returns>
        [HttpGet("{fileId}")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> GetFileById(Guid fileId)
        {
            try
            {
                var file = await _fileUploadService.GetFileByIdAsync(fileId);
                if (file == null)
                {
                    return NotFound(new { status = "error", message = "File not found" });
                }

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        file_id = file.FileId,
                        file_name = file.FileName,
                        original_filename = file.OriginalFilename,
                        file_extension = file.FileExtension,
                        file_size = file.FileSize,
                        file_size_display = FormatFileSize(file.FileSize),
                        mime_type = file.MimeType,
                        file_path = file.FilePath,
                        upload_date = file.UploadDate,
                        upload_date_display = file.UploadDate.ToString("dd/MM/yyyy HH:mm"),
                        description = file.Description,
                        version = file.Version,
                        is_current_version = file.IsCurrentVersion,
                        is_active = file.IsActive,
                        download_count = file.DownloadCount,
                        tab_name = file.Tab?.TabName,
                        category_name = file.Category?.CategoryName,
                        uploaded_by = new
                        {
                            employee_id = file.Employee?.EmployeeId,
                            employee_code = file.Employee?.EmployeeCode,
                            full_name = file.Employee?.FullName,
                            position = file.Employee?.Position,
                            email = file.Employee?.Email
                        },
                        department = new
                        {
                            department_id = file.Department?.DepartmentId,
                            department_code = file.Department?.DepartmentCode,
                            department_name = file.Department?.DepartmentName
                        }
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting file {fileId}");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Download file
        /// </summary>
        /// <param name="fileId">File ID</param>
        /// <returns>File download URL</returns>
        [HttpGet("{fileId}/download")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> DownloadFile(Guid fileId)
        {
            try
            {
                var file = await _fileUploadService.GetFileByIdAsync(fileId);
                if (file == null)
                {
                    return NotFound(new { status = "error", message = "File not found" });
                }

                if (!file.IsActive)
                {
                    return BadRequest(new { status = "error", message = "File is not active" });
                }

                // Log download action
                // You might want to get the current user ID from JWT token or session
                var currentUserId = 1; // Replace with actual user ID from authentication
                await _fileUploadService.LogFileActionAsync(
                    fileId, 
                    "DOWNLOAD", 
                    currentUserId, 
                    GetClientIpAddress(), 
                    Request.Headers["User-Agent"].ToString(),
                    "File downloaded via API"
                );

                // Update download count
                // You might want to implement this in the service
                
                var response = new
                {
                    status = "success",
                    data = new
                    {
                        file_id = file.FileId,
                        file_name = file.FileName,
                        original_filename = file.OriginalFilename,
                        mime_type = file.MimeType,
                        file_size = file.FileSize,
                        download_url = file.FilePath,
                        expires_at = DateTime.UtcNow.AddDays(1) // URL expires in 1 day
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error downloading file {fileId}");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Upload multiple files
        /// </summary>
        /// <param name="tabId">Tab ID</param>
        /// <param name="categoryId">Category ID</param>
        /// <param name="employeeId">Employee ID</param>
        /// <param name="files">Files to upload</param>
        /// <param name="description">Description</param>
        /// <returns>Upload results</returns>
        [HttpPost("upload-multiple")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.BadRequest)]
        public async Task<IActionResult> UploadMultipleFiles(
            [FromForm] int tabId,
            [FromForm] int categoryId,
            [FromForm] int employeeId,
            [FromForm] IFormFileCollection files,
            [FromForm] string? description = null)
        {
            try
            {
                if (files == null || files.Count == 0)
                {
                    return BadRequest(new { status = "error", message = "No files provided" });
                }

                var results = new List<object>();
                var ipAddress = GetClientIpAddress();
                var userAgent = Request.Headers["User-Agent"].ToString();

                foreach (var file in files)
                {
                    try
                    {
                        var request = new FileUploadRequest
                        {
                            File = file,
                            TabId = tabId,
                            CategoryId = categoryId,
                            EmployeeId = employeeId,
                            Description = description
                        };

                        var result = await _fileUploadService.UploadFileAsync(request, ipAddress, userAgent);
                        results.Add(new
                        {
                            file_name = file.FileName,
                            status = result.Status,
                            message = result.Message,
                            data = result.Data
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error uploading file: {FileName}", file.FileName);
                        results.Add(new
                        {
                            file_name = file.FileName,
                            status = "error",
                            message = "Upload failed",
                            data = (object?)null
                        });
                    }
                }

                var successCount = results.Count(r => ((dynamic)r).status == "success");
                var errorCount = results.Count - successCount;

                return Ok(new
                {
                    status = errorCount == 0 ? "success" : "partial",
                    message = $"Uploaded {successCount} files successfully, {errorCount} failed",
                    data = new
                    {
                        total_files = files.Count,
                        success_count = successCount,
                        error_count = errorCount,
                        results = results
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in multiple file upload");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Delete file (soft delete)
        /// </summary>
        /// <param name="fileId">File ID</param>
        /// <param name="deletedBy">Employee ID who deleted the file</param>
        /// <returns>Delete result</returns>
        [HttpDelete("{fileId}")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> DeleteFile(Guid fileId, [FromQuery] int deletedBy)
        {
            try
            {
                var file = await _context.Files
                    .Where(f => f.FileId == fileId && !f.IsDeleted)
                    .FirstOrDefaultAsync();

                if (file == null)
                {
                    return NotFound(new { status = "error", message = "File not found" });
                }

                // Soft delete
                file.IsDeleted = true;
                file.IsActive = false;
                file.DeletedAt = DateTime.UtcNow;
                file.DeletedBy = deletedBy;
                file.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                // Log delete action
                await _fileUploadService.LogFileActionAsync(
                    fileId,
                    "DELETE",
                    deletedBy,
                    GetClientIpAddress(),
                    Request.Headers["User-Agent"].ToString(),
                    "File deleted"
                );

                return Ok(new
                {
                    status = "success",
                    message = "File deleted successfully",
                    data = new { file_id = fileId }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting file: {FileId}", fileId);
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get file actions/audit log
        /// </summary>
        /// <param name="fileId">File ID</param>
        /// <param name="page">Page number</param>
        /// <param name="pageSize">Page size</param>
        /// <returns>File actions</returns>
        [HttpGet("{fileId}/actions")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> GetFileActions(
            Guid fileId,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 50)
        {
            try
            {
                var file = await _context.Files
                    .Where(f => f.FileId == fileId)
                    .FirstOrDefaultAsync();

                if (file == null)
                {
                    return NotFound(new { status = "error", message = "File not found" });
                }

                var query = _context.FileActions
                    .Where(a => a.FileId == fileId)
                    .Include(a => a.PerformedBy);

                var totalActions = await query.CountAsync();
                var actions = await query
                    .OrderByDescending(a => a.ActionDate)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(a => new
                    {
                        action_id = a.ActionId,
                        action_type = a.ActionType,
                        action_display = GetActionDisplay(a.ActionType),
                        performed_by = a.PerformedBy.FullName,
                        employee_code = a.PerformedBy.EmployeeCode,
                        action_date = a.ActionDate,
                        action_date_display = a.ActionDate.ToString("dd/MM/yyyy HH:mm"),
                        ip_address = a.IpAddress,
                        user_agent = a.UserAgent,
                        notes = a.Notes
                    })
                    .ToListAsync();

                return Ok(new
                {
                    status = "success",
                    data = new
                    {
                        file_id = fileId,
                        actions = actions,
                        pagination = new
                        {
                            page = page,
                            page_size = pageSize,
                            total_actions = totalActions,
                            total_pages = (int)Math.Ceiling((double)totalActions / pageSize)
                        }
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting file actions: {FileId}", fileId);
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Search files
        /// </summary>
        /// <param name="q">Search query</param>
        /// <param name="tabId">Tab ID filter</param>
        /// <param name="categoryId">Category ID filter</param>
        /// <param name="uploadedBy">Employee ID filter</param>
        /// <param name="dateFrom">Date from filter</param>
        /// <param name="dateTo">Date to filter</param>
        /// <param name="page">Page number</param>
        /// <param name="pageSize">Page size</param>
        /// <returns>Search results</returns>
        [HttpGet("search")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> SearchFiles(
            [FromQuery] string q,
            [FromQuery] int? tabId = null,
            [FromQuery] int? categoryId = null,
            [FromQuery] int? uploadedBy = null,
            [FromQuery] DateTime? dateFrom = null,
            [FromQuery] DateTime? dateTo = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var query = _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .Include(f => f.Tab)
                    .Include(f => f.Category)
                    .Include(f => f.UploadedBy)
                    .Include(f => f.Department)
                    .AsQueryable();

                // Apply search filter
                if (!string.IsNullOrEmpty(q))
                {
                    query = query.Where(f => f.FileName.Contains(q) || 
                                           f.Description.Contains(q) || 
                                           f.OriginalFilename.Contains(q));
                }

                // Apply filters
                if (tabId.HasValue)
                    query = query.Where(f => f.TabId == tabId.Value);

                if (categoryId.HasValue)
                    query = query.Where(f => f.CategoryId == categoryId.Value);

                if (uploadedBy.HasValue)
                    query = query.Where(f => f.UploadedBy.EmployeeId == uploadedBy.Value);

                if (dateFrom.HasValue)
                    query = query.Where(f => f.UploadDate >= dateFrom.Value);

                if (dateTo.HasValue)
                    query = query.Where(f => f.UploadDate <= dateTo.Value);

                var totalItems = await query.CountAsync();
                var files = await query
                    .OrderByDescending(f => f.UploadDate)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        query = q,
                        filters = new
                        {
                            tab_id = tabId,
                            category_id = categoryId,
                            uploaded_by = uploadedBy,
                            date_from = dateFrom,
                            date_to = dateTo
                        },
                        results = files.Select(file => new
                        {
                            file_id = file.FileId,
                            file_name = file.FileName,
                            tab_name = file.Tab.TabName,
                            category_name = file.Category.CategoryName,
                            uploaded_by = new
                            {
                                full_name = file.UploadedBy.FullName
                            },
                            department = new
                            {
                                department_name = file.Department.DepartmentName
                            },
                            upload_date = file.UploadDate,
                            upload_date_display = file.UploadDate.ToString("dd/MM/yyyy HH:mm"),
                            file_size_display = FormatFileSize(file.FileSize),
                            relevance_score = CalculateRelevanceScore(file, q)
                        }).OrderByDescending(f => f.relevance_score),
                        pagination = new
                        {
                            current_page = page,
                            per_page = pageSize,
                            total_items = totalItems,
                            total_pages = (int)Math.Ceiling((double)totalItems / pageSize)
                        }
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching files");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Toggle file active status
        /// </summary>
        /// <param name="fileId">File ID</param>
        /// <param name="request">Toggle request</param>
        /// <returns>Updated file status</returns>
        [HttpPut("{fileId}/toggle-active")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> ToggleFileActive(Guid fileId, [FromBody] ToggleActiveRequest request)
        {
            try
            {
                var file = await _context.Files.FindAsync(fileId);
                if (file == null)
                {
                    return NotFound(new { status = "error", message = "File not found" });
                }

                file.IsActive = request.IsActive;
                file.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                var response = new
                {
                    status = "success",
                    message = file.IsActive ? "File đã được kích hoạt" : "File đã được hủy kích hoạt",
                    data = new
                    {
                        file_id = file.FileId,
                        file_name = file.FileName,
                        is_active = file.IsActive,
                        updated_at = file.UpdatedAt
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error toggling file active status: {FileId}", fileId);
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get files by status
        /// </summary>
        /// <param name="isActive">Active status filter</param>
        /// <param name="tabId">Tab ID filter</param>
        /// <param name="categoryId">Category ID filter</param>
        /// <param name="page">Page number</param>
        /// <param name="pageSize">Page size</param>
        /// <returns>Files filtered by status</returns>
        [HttpGet("status")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetFilesByStatus(
            [FromQuery] bool? isActive = null,
            [FromQuery] int? tabId = null,
            [FromQuery] int? categoryId = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var query = _context.Files
                    .Where(f => !f.IsDeleted)
                    .Include(f => f.Tab)
                    .Include(f => f.Category)
                    .Include(f => f.UploadedBy)
                    .Include(f => f.Department)
                    .AsQueryable();

                // Apply filters
                if (isActive.HasValue)
                    query = query.Where(f => f.IsActive == isActive.Value);

                if (tabId.HasValue)
                    query = query.Where(f => f.TabId == tabId.Value);

                if (categoryId.HasValue)
                    query = query.Where(f => f.CategoryId == categoryId.Value);

                var totalItems = await query.CountAsync();
                var files = await query
                    .OrderByDescending(f => f.UploadDate)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                // Calculate statistics
                var allFiles = await _context.Files.Where(f => !f.IsDeleted).ToListAsync();
                var totalFiles = allFiles.Count;
                var activeFiles = allFiles.Count(f => f.IsActive);
                var inactiveFiles = totalFiles - activeFiles;

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        filters = new
                        {
                            is_active = isActive,
                            tab_id = tabId,
                            category_id = categoryId
                        },
                        files = files.Select(file => new
                        {
                            file_id = file.FileId,
                            file_name = file.FileName,
                            is_active = file.IsActive,
                            status_display = file.IsActive ? "Đang hoạt động" : "Không hoạt động",
                            status_code = file.IsActive ? "active" : "inactive",
                            tab_name = file.Tab.TabName,
                            category_name = file.Category.CategoryName,
                            uploaded_by = file.UploadedBy.FullName,
                            department_name = file.Department.DepartmentName,
                            upload_date = file.UploadDate,
                            upload_date_display = file.UploadDate.ToString("dd/MM/yyyy HH:mm"),
                            file_size_display = FormatFileSize(file.FileSize),
                            download_count = file.DownloadCount
                        }),
                        statistics = new
                        {
                            total_files = totalFiles,
                            active_files = activeFiles,
                            inactive_files = inactiveFiles,
                            active_percentage = totalFiles > 0 ? Math.Round((double)activeFiles / totalFiles * 100, 2) : 0
                        }
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting files by status");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get file status statistics
        /// </summary>
        /// <returns>File status statistics</returns>
        [HttpGet("status/statistics")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetFileStatusStatistics()
        {
            try
            {
                var allFiles = await _context.Files
                    .Where(f => !f.IsDeleted)
                    .Include(f => f.Tab)
                    .Include(f => f.Department)
                    .ToListAsync();

                var totalFiles = allFiles.Count;
                var activeFiles = allFiles.Count(f => f.IsActive);
                var inactiveFiles = totalFiles - activeFiles;

                // Statistics by tab
                var tabStats = allFiles
                    .GroupBy(f => f.Tab.TabName)
                    .Select(g => new
                    {
                        tab_name = g.Key,
                        total_files = g.Count(),
                        active_files = g.Count(f => f.IsActive),
                        inactive_files = g.Count(f => !f.IsActive),
                        active_percentage = g.Count() > 0 ? Math.Round((double)g.Count(f => f.IsActive) / g.Count() * 100, 2) : 0
                    });

                // Statistics by department
                var departmentStats = allFiles
                    .GroupBy(f => f.Department.DepartmentName)
                    .Select(g => new
                    {
                        department_name = g.Key,
                        total_files = g.Count(),
                        active_files = g.Count(f => f.IsActive),
                        inactive_files = g.Count(f => !f.IsActive),
                        active_percentage = g.Count() > 0 ? Math.Round((double)g.Count(f => f.IsActive) / g.Count() * 100, 2) : 0
                    });

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        overview = new
                        {
                            total_files = totalFiles,
                            active_files = activeFiles,
                            inactive_files = inactiveFiles,
                            active_percentage = totalFiles > 0 ? Math.Round((double)activeFiles / totalFiles * 100, 2) : 0
                        },
                        by_tab = tabStats,
                        by_department = departmentStats
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting file status statistics");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        #region Helper Methods

        private string GetClientIpAddress()
        {
            if (Request.Headers.ContainsKey("X-Forwarded-For"))
            {
                return Request.Headers["X-Forwarded-For"].ToString();
            }
            else if (Request.Headers.ContainsKey("X-Real-IP"))
            {
                return Request.Headers["X-Real-IP"].ToString();
            }
            else
            {
                return Request.HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
            }
        }

        private string FormatFileSize(long bytes)
        {
            if (bytes == 0) return "0 B";
            
            string[] sizes = { "B", "KB", "MB", "GB", "TB" };
            int i = 0;
            double size = bytes;
            
            while (size >= 1024 && i < sizes.Length - 1)
            {
                size /= 1024;
                i++;
            }
            
            return $"{size:0.##} {sizes[i]}";
        }

        private string GetActionDisplay(string actionType)
        {
            return actionType switch
            {
                "UPLOAD" => "Tải lên",
                "DOWNLOAD" => "Tải xuống",
                "DELETE" => "Xóa",
                "UPDATE" => "Cập nhật",
                "VIEW" => "Xem",
                _ => actionType
            };
        }

        private double CalculateRelevanceScore(FileEntity file, string query)
        {
            if (string.IsNullOrEmpty(query))
                return 1.0;

            double score = 0.0;
            var lowerQuery = query.ToLower();

            // Check filename
            if (file.FileName.ToLower().Contains(lowerQuery))
                score += 0.5;

            // Check description
            if (!string.IsNullOrEmpty(file.Description) && file.Description.ToLower().Contains(lowerQuery))
                score += 0.3;

            // Check original filename
            if (file.OriginalFilename.ToLower().Contains(lowerQuery))
                score += 0.2;

            return Math.Min(score, 1.0);
        }

        #endregion
    }
}
