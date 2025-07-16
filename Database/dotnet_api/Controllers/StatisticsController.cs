using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FileManagementAPI.Data;
using System.Net;

namespace FileManagementAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StatisticsController : ControllerBase
    {
        private readonly FileManagementDbContext _context;
        private readonly ILogger<StatisticsController> _logger;

        public StatisticsController(FileManagementDbContext context, ILogger<StatisticsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get general statistics
        /// </summary>
        /// <returns>General statistics</returns>
        [HttpGet]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetStatistics()
        {
            try
            {
                var totalTabs = await _context.Tabs.CountAsync(t => t.IsActive);
                var totalCategories = await _context.Categories.CountAsync(c => c.IsActive);
                var totalFiles = await _context.Files.CountAsync(f => f.IsActive && !f.IsDeleted);
                var totalSize = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .SumAsync(f => f.FileSize);
                var totalDownloads = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .SumAsync(f => f.DownloadCount);

                // Active users (employees who have uploaded files)
                var activeUsers = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .Select(f => f.UploadedBy.EmployeeId)
                    .Distinct()
                    .CountAsync();

                // Statistics by tab
                var tabStats = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .Include(f => f.Tab)
                    .GroupBy(f => f.Tab.TabName)
                    .Select(g => new
                    {
                        tab_name = g.Key,
                        file_count = g.Count(),
                        total_size = g.Sum(f => f.FileSize),
                        total_size_display = FormatFileSize(g.Sum(f => f.FileSize)),
                        download_count = g.Sum(f => f.DownloadCount),
                        latest_upload = g.Max(f => f.UploadDate)
                    })
                    .ToListAsync();

                // Statistics by department
                var departmentStats = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .Include(f => f.Department)
                    .Include(f => f.UploadedBy)
                    .GroupBy(f => f.Department.DepartmentName)
                    .Select(g => new
                    {
                        department_name = g.Key,
                        file_count = g.Count(),
                        total_size = g.Sum(f => f.FileSize),
                        employee_count = g.Select(f => f.UploadedBy.EmployeeId).Distinct().Count(),
                        download_count = g.Sum(f => f.DownloadCount)
                    })
                    .ToListAsync();

                // Recent activities
                var recentActivities = await _context.FileActions
                    .Include(a => a.File)
                    .Include(a => a.PerformedBy)
                    .Where(a => a.File.IsActive && !a.File.IsDeleted)
                    .OrderByDescending(a => a.ActionDate)
                    .Take(10)
                    .Select(a => new
                    {
                        action_type = a.ActionType,
                        action_display = GetActionDisplay(a.ActionType),
                        file_name = a.File.FileName,
                        performed_by = a.PerformedBy.FullName,
                        action_date = a.ActionDate,
                        action_date_display = a.ActionDate.ToString("dd/MM/yyyy HH:mm")
                    })
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        overview = new
                        {
                            total_tabs = totalTabs,
                            total_categories = totalCategories,
                            total_files = totalFiles,
                            total_size = totalSize,
                            total_size_display = FormatFileSize(totalSize),
                            total_downloads = totalDownloads,
                            active_users = activeUsers
                        },
                        by_tab = tabStats,
                        by_department = departmentStats,
                        recent_activities = recentActivities
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting statistics");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get statistics by date range
        /// </summary>
        /// <param name="startDate">Start date</param>
        /// <param name="endDate">End date</param>
        /// <returns>Statistics for the date range</returns>
        [HttpGet("date-range")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetStatisticsByDateRange(
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                // Default to last 30 days if no dates provided
                startDate ??= DateTime.UtcNow.AddDays(-30);
                endDate ??= DateTime.UtcNow;

                var filesInRange = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted && 
                               f.UploadDate >= startDate && f.UploadDate <= endDate)
                    .Include(f => f.Tab)
                    .Include(f => f.Category)
                    .Include(f => f.UploadedBy)
                    .Include(f => f.Department)
                    .ToListAsync();

                var actionsInRange = await _context.FileActions
                    .Where(a => a.ActionDate >= startDate && a.ActionDate <= endDate)
                    .Include(a => a.File)
                    .Include(a => a.PerformedBy)
                    .Where(a => a.File.IsActive && !a.File.IsDeleted)
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        date_range = new
                        {
                            start_date = startDate,
                            end_date = endDate,
                            days = (endDate.Value - startDate.Value).Days
                        },
                        uploads = new
                        {
                            total_files = filesInRange.Count,
                            total_size = filesInRange.Sum(f => f.FileSize),
                            total_size_display = FormatFileSize(filesInRange.Sum(f => f.FileSize)),
                            by_date = filesInRange
                                .GroupBy(f => f.UploadDate.Date)
                                .Select(g => new
                                {
                                    date = g.Key,
                                    date_display = g.Key.ToString("dd/MM/yyyy"),
                                    file_count = g.Count(),
                                    total_size = g.Sum(f => f.FileSize),
                                    total_size_display = FormatFileSize(g.Sum(f => f.FileSize))
                                })
                                .OrderBy(x => x.date)
                        },
                        activities = new
                        {
                            total_actions = actionsInRange.Count,
                            by_type = actionsInRange
                                .GroupBy(a => a.ActionType)
                                .Select(g => new
                                {
                                    action_type = g.Key,
                                    action_display = GetActionDisplay(g.Key),
                                    count = g.Count()
                                }),
                            by_date = actionsInRange
                                .GroupBy(a => a.ActionDate.Date)
                                .Select(g => new
                                {
                                    date = g.Key,
                                    date_display = g.Key.ToString("dd/MM/yyyy"),
                                    action_count = g.Count()
                                })
                                .OrderBy(x => x.date)
                        }
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting statistics by date range");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
            }
        }

        /// <summary>
        /// Get top users by activity
        /// </summary>
        /// <param name="limit">Number of top users to return</param>
        /// <returns>Top users statistics</returns>
        [HttpGet("top-users")]
        [ProducesResponseType(typeof(object), (int)HttpStatusCode.OK)]
        public async Task<IActionResult> GetTopUsers([FromQuery] int limit = 10)
        {
            try
            {
                var topUploaders = await _context.Files
                    .Where(f => f.IsActive && !f.IsDeleted)
                    .Include(f => f.UploadedBy)
                    .Include(f => f.Department)
                    .GroupBy(f => f.UploadedBy)
                    .Select(g => new
                    {
                        employee = g.Key,
                        department = g.First().Department,
                        upload_count = g.Count(),
                        total_size = g.Sum(f => f.FileSize),
                        total_size_display = FormatFileSize(g.Sum(f => f.FileSize)),
                        latest_upload = g.Max(f => f.UploadDate)
                    })
                    .OrderByDescending(x => x.upload_count)
                    .Take(limit)
                    .ToListAsync();

                var topDownloaders = await _context.FileActions
                    .Where(a => a.ActionType == "DOWNLOAD")
                    .Include(a => a.PerformedBy)
                    .Include(a => a.File)
                    .Where(a => a.File.IsActive && !a.File.IsDeleted)
                    .GroupBy(a => a.PerformedBy)
                    .Select(g => new
                    {
                        employee = g.Key,
                        download_count = g.Count(),
                        latest_download = g.Max(a => a.ActionDate)
                    })
                    .OrderByDescending(x => x.download_count)
                    .Take(limit)
                    .ToListAsync();

                var response = new
                {
                    status = "success",
                    data = new
                    {
                        top_uploaders = topUploaders.Select(u => new
                        {
                            employee_id = u.employee.EmployeeId,
                            employee_name = u.employee.FullName,
                            employee_code = u.employee.EmployeeCode,
                            position = u.employee.Position,
                            department_name = u.department.DepartmentName,
                            upload_count = u.upload_count,
                            total_size_display = u.total_size_display,
                            latest_upload = u.latest_upload,
                            latest_upload_display = u.latest_upload.ToString("dd/MM/yyyy HH:mm")
                        }),
                        top_downloaders = topDownloaders.Select(d => new
                        {
                            employee_id = d.employee.EmployeeId,
                            employee_name = d.employee.FullName,
                            employee_code = d.employee.EmployeeCode,
                            position = d.employee.Position,
                            download_count = d.download_count,
                            latest_download = d.latest_download,
                            latest_download_display = d.latest_download.ToString("dd/MM/yyyy HH:mm")
                        })
                    }
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting top users statistics");
                return StatusCode(500, new { status = "error", message = "An internal server error occurred" });
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
    }
}
