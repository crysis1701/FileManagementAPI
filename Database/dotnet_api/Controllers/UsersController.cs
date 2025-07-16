using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FileManagementAPI.Data;
using System.Net;

namespace FileManagementAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly FileManagementDbContext _context;
        private readonly ILogger<UsersController> _logger;

        public UsersController(FileManagementDbContext context, ILogger<UsersController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get user permissions
        /// </summary>
        /// <param name="userId">User ID (Employee ID)</param>
        /// <returns>User permissions</returns>
        [HttpGet("{userId}/permissions")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> GetUserPermissions(int userId)
        {
            try
            {
                var user = await _context.Employees
                    .Include(e => e.Department)
                    .FirstOrDefaultAsync(e => e.EmployeeId == userId && e.IsActive);

                if (user == null)
                {
                    return NotFound(new { status = "error", message = "User not found" });
                }

                // Get department permissions
                var departmentPermissions = await _context.FilePermissions
                    .Where(p => p.DepartmentId == user.DepartmentId && p.IsActive)
                    .Include(p => p.Department)
                    .GroupBy(p => p.Department)
                    .Select(g => new
                    {
                        department_name = g.Key.DepartmentName,
                        permission_type = g.OrderByDescending(p => GetPermissionLevel(p.PermissionType)).First().PermissionType
                    })
                    .ToListAsync();

                // Get specific file permissions
                var filePermissions = await _context.FilePermissions
                    .Where(p => p.EmployeeId == userId && p.IsActive)
                    .Include(p => p.File)
                    .Include(p => p.GrantedBy)
                    .Select(p => new
                    {
                        file_id = p.File.FileId,
                        file_name = p.File.FileName,
                        permission_type = p.PermissionType,
                        granted_by = p.GrantedBy.FullName,
                        granted_at = p.GrantedAt
                    })
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        user_info = new
                        {
                            user_id = user.EmployeeId,
                            user_name = user.FullName,
                            role = user.Position,
                            department = user.Department.DepartmentName
                        },
                        global_permissions = new
                        {
                            can_upload = true, // Default permissions
                            can_manage_permissions = user.Position?.Contains("Admin") == true,
                            can_delete_files = user.Position?.Contains("Admin") == true,
                            can_view_all_files = user.Position?.Contains("Admin") == true
                        },
                        department_permissions = departmentPermissions,
                        file_permissions = filePermissions
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user permissions for user: {UserId}", userId);
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get all users
        /// </summary>
        /// <returns>List of all users</returns>
        [HttpGet]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetAllUsers()
        {
            try
            {
                var users = await _context.Employees
                    .Where(e => e.IsActive)
                    .Include(e => e.Department)
                    .Select(e => new
                    {
                        employee_id = e.EmployeeId,
                        employee_code = e.EmployeeCode,
                        full_name = e.FullName,
                        email = e.Email,
                        position = e.Position,
                        department = new
                        {
                            department_id = e.Department.DepartmentId,
                            department_name = e.Department.DepartmentName
                        },
                        is_active = e.IsActive,
                        created_at = e.CreatedAt
                    })
                    .OrderBy(e => e.full_name)
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        users = users,
                        total_users = users.Count
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all users");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get user activity
        /// </summary>
        /// <param name="userId">User ID</param>
        /// <param name="limit">Number of activities to return</param>
        /// <returns>User activity history</returns>
        [HttpGet("{userId}/activity")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.NotFound)]
        public async Task<IActionResult> GetUserActivity(int userId, [FromQuery] int limit = 20)
        {
            try
            {
                var user = await _context.Employees
                    .Include(e => e.Department)
                    .FirstOrDefaultAsync(e => e.EmployeeId == userId && e.IsActive);

                if (user == null)
                {
                    return NotFound(new { status = "error", message = "User not found" });
                }

                // Get file actions by user
                var activities = await _context.FileActions
                    .Where(a => a.PerformedBy.EmployeeId == userId)
                    .Include(a => a.File)
                    .Include(a => a.File.Tab)
                    .Include(a => a.File.Category)
                    .OrderByDescending(a => a.ActionDate)
                    .Take(limit)
                    .Select(a => new
                    {
                        action_id = a.ActionId,
                        action_type = a.ActionType,
                        action_display = GetActionDisplay(a.ActionType),
                        file_id = a.File.FileId,
                        file_name = a.File.FileName,
                        tab_name = a.File.Tab.TabName,
                        category_name = a.File.Category.CategoryName,
                        action_date = a.ActionDate,
                        action_date_display = a.ActionDate.ToString("dd/MM/yyyy HH:mm"),
                        ip_address = a.IpAddress,
                        notes = a.Notes
                    })
                    .ToListAsync();

                // Get uploaded files by user
                var uploadedFiles = await _context.Files
                    .Where(f => f.UploadedBy.EmployeeId == userId && f.IsActive && !f.IsDeleted)
                    .Include(f => f.Tab)
                    .Include(f => f.Category)
                    .Select(f => new
                    {
                        file_id = f.FileId,
                        file_name = f.FileName,
                        tab_name = f.Tab.TabName,
                        category_name = f.Category.CategoryName,
                        upload_date = f.UploadDate,
                        upload_date_display = f.UploadDate.ToString("dd/MM/yyyy HH:mm"),
                        file_size_display = FormatFileSize(f.FileSize),
                        download_count = f.DownloadCount
                    })
                    .OrderByDescending(f => f.upload_date)
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        user_info = new
                        {
                            user_id = user.EmployeeId,
                            user_name = user.FullName,
                            department = user.Department.DepartmentName
                        },
                        activities = activities,
                        uploaded_files = uploadedFiles,
                        statistics = new
                        {
                            total_activities = activities.Count,
                            total_uploads = uploadedFiles.Count,
                            total_downloads = activities.Count(a => a.action_type == "DOWNLOAD"),
                            last_activity = activities.FirstOrDefault()?.action_date
                        }
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user activity for user: {UserId}", userId);
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        private int GetPermissionLevel(string permissionType)
        {
            return permissionType switch
            {
                "FULL" => 4,
                "DELETE" => 3,
                "WRITE" => 2,
                "READ" => 1,
                _ => 0
            };
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
    }
}
