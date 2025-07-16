-- =============================================
-- Views and Queries for File Management System
-- =============================================

USE FileManagementDB;
GO

-- =============================================
-- VIEWS
-- =============================================

-- 1. View cho hiển thị file với thông tin đầy đủ
CREATE VIEW [v_files_detail] AS
SELECT 
    f.file_id,
    t.tab_name,
    c.category_name,
    f.file_name,
    f.original_filename,
    f.file_extension,
    f.file_size,
    CASE 
        WHEN f.file_size < 1024 THEN CAST(f.file_size AS VARCHAR(20)) + ' B'
        WHEN f.file_size < 1048576 THEN CAST(f.file_size / 1024 AS VARCHAR(20)) + ' KB'
        WHEN f.file_size < 1073741824 THEN CAST(f.file_size / 1048576 AS VARCHAR(20)) + ' MB'
        ELSE CAST(f.file_size / 1073741824 AS VARCHAR(20)) + ' GB'
    END AS file_size_formatted,
    e.full_name AS uploaded_by_name,
    e.employee_code AS uploaded_by_code,
    d.department_name,
    f.upload_date,
    f.description,
    f.download_count,
    f.version,
    f.is_current_version,
    f.is_deleted
FROM [files] f
JOIN [tabs] t ON f.tab_id = t.tab_id
JOIN [categories] c ON f.category_id = c.category_id
JOIN [employees] e ON f.uploaded_by = e.employee_id
JOIN [departments] d ON f.department_id = d.department_id;
GO

-- 2. View cho thống kê file theo tab và category
CREATE VIEW [v_file_statistics] AS
SELECT 
    t.tab_name,
    c.category_name,
    COUNT(f.file_id) AS total_files,
    SUM(f.file_size) AS total_size,
    AVG(f.file_size) AS avg_size,
    SUM(f.download_count) AS total_downloads,
    MAX(f.upload_date) AS latest_upload
FROM [tabs] t
JOIN [categories] c ON t.tab_id = c.tab_id
LEFT JOIN [files] f ON c.category_id = f.category_id AND f.is_deleted = 0
GROUP BY t.tab_name, c.category_name, t.tab_id, c.sort_order
ORDER BY t.tab_id, c.sort_order;
GO

-- 3. View cho hoạt động gần đây
CREATE VIEW [v_recent_activities] AS
SELECT 
    fa.action_date,
    fa.action_type,
    e.full_name AS employee_name,
    d.department_name,
    f.file_name,
    t.tab_name,
    c.category_name,
    fa.notes
FROM [file_actions] fa
JOIN [employees] e ON fa.performed_by = e.employee_id
JOIN [departments] d ON e.department_id = d.department_id
JOIN [files] f ON fa.file_id = f.file_id
JOIN [tabs] t ON f.tab_id = t.tab_id
JOIN [categories] c ON f.category_id = c.category_id;
GO

-- =============================================
-- SAMPLE QUERIES
-- =============================================

-- 1. Hiển thị tất cả file theo tab và category (như yêu cầu ban đầu)
SELECT 
    tab_name AS 'Tab',
    category_name AS 'Mục',
    file_name AS 'Tên file',
    uploaded_by_name AS 'Nhân viên đăng tải',
    department_name AS 'Đơn vị',
    upload_date AS 'Ngày tải file',
    'Download | Edit | Delete' AS 'Tác vụ'
FROM [v_files_detail]
WHERE is_deleted = 0
ORDER BY tab_name, category_name, upload_date DESC;

-- 2. Hiển thị file của Tab A
SELECT 
    category_name AS 'Mục',
    file_name AS 'Tên file',
    uploaded_by_name AS 'Nhân viên đăng tải',
    department_name AS 'Đơn vị',
    upload_date AS 'Ngày tải file',
    file_size_formatted AS 'Kích thước',
    download_count AS 'Lượt tải'
FROM [v_files_detail]
WHERE tab_name = 'Tab A - Tài liệu hành chính' AND is_deleted = 0
ORDER BY category_name, upload_date DESC;

-- 3. Hiển thị file của Tab B
SELECT 
    category_name AS 'Mục',
    file_name AS 'Tên file',
    uploaded_by_name AS 'Nhân viên đăng tải',
    department_name AS 'Đơn vị',
    upload_date AS 'Ngày tải file',
    file_size_formatted AS 'Kích thước',
    download_count AS 'Lượt tải'
FROM [v_files_detail]
WHERE tab_name = 'Tab B - Tài liệu kỹ thuật' AND is_deleted = 0
ORDER BY category_name, upload_date DESC;

-- 4. Thống kê file theo tab và category
SELECT 
    tab_name AS 'Tab',
    category_name AS 'Mục',
    total_files AS 'Số lượng file',
    CASE 
        WHEN total_size < 1024 THEN CAST(total_size AS VARCHAR(20)) + ' B'
        WHEN total_size < 1048576 THEN CAST(total_size / 1024 AS VARCHAR(20)) + ' KB'
        WHEN total_size < 1073741824 THEN CAST(total_size / 1048576 AS VARCHAR(20)) + ' MB'
        ELSE CAST(total_size / 1073741824 AS VARCHAR(20)) + ' GB'
    END AS 'Tổng dung lượng',
    total_downloads AS 'Tổng lượt tải',
    latest_upload AS 'Lần tải cuối'
FROM [v_file_statistics]
ORDER BY tab_name, category_name;

-- 5. Hoạt động gần đây (10 hoạt động mới nhất)
SELECT TOP 10
    action_date AS 'Thời gian',
    action_type AS 'Hành động',
    employee_name AS 'Nhân viên',
    department_name AS 'Phòng ban',
    file_name AS 'Tên file',
    tab_name AS 'Tab',
    category_name AS 'Mục'
FROM [v_recent_activities]
ORDER BY action_date DESC;

-- 6. Tìm file theo tên
DECLARE @search_term NVARCHAR(100) = 'báo cáo';
SELECT 
    tab_name AS 'Tab',
    category_name AS 'Mục',
    file_name AS 'Tên file',
    uploaded_by_name AS 'Nhân viên đăng tải',
    department_name AS 'Đơn vị',
    upload_date AS 'Ngày tải file'
FROM [v_files_detail]
WHERE file_name LIKE '%' + @search_term + '%' AND is_deleted = 0
ORDER BY upload_date DESC;

-- 7. File được tải nhiều nhất
SELECT TOP 5
    file_name AS 'Tên file',
    tab_name AS 'Tab',
    category_name AS 'Mục',
    uploaded_by_name AS 'Người tải lên',
    download_count AS 'Lượt tải',
    upload_date AS 'Ngày tải lên'
FROM [v_files_detail]
WHERE is_deleted = 0
ORDER BY download_count DESC;

-- 8. File theo phòng ban
SELECT 
    department_name AS 'Phòng ban',
    COUNT(*) AS 'Số file',
    SUM(file_size) AS 'Tổng dung lượng (bytes)',
    AVG(download_count) AS 'Trung bình lượt tải'
FROM [v_files_detail]
WHERE is_deleted = 0
GROUP BY department_name
ORDER BY COUNT(*) DESC;

-- 9. File mới nhất (7 ngày gần đây)
SELECT 
    tab_name AS 'Tab',
    category_name AS 'Mục',
    file_name AS 'Tên file',
    uploaded_by_name AS 'Nhân viên đăng tải',
    department_name AS 'Đơn vị',
    upload_date AS 'Ngày tải file'
FROM [v_files_detail]
WHERE upload_date >= DATEADD(DAY, -7, GETDATE()) AND is_deleted = 0
ORDER BY upload_date DESC;

-- 10. Danh sách file có quyền truy cập theo phòng ban
SELECT 
    d.department_name AS 'Phòng ban',
    f.file_name AS 'Tên file',
    fp.permission_type AS 'Quyền truy cập',
    t.tab_name AS 'Tab',
    c.category_name AS 'Mục'
FROM [file_permissions] fp
JOIN [departments] d ON fp.department_id = d.department_id
JOIN [files] f ON fp.file_id = f.file_id
JOIN [tabs] t ON f.tab_id = t.tab_id
JOIN [categories] c ON f.category_id = c.category_id
WHERE fp.is_active = 1 AND f.is_deleted = 0
ORDER BY d.department_name, t.tab_name, c.category_name;

PRINT 'Views and queries created successfully!';
PRINT 'Available views:';
PRINT '- v_files_detail: Detailed file information';
PRINT '- v_file_statistics: Statistics by tab and category';
PRINT '- v_recent_activities: Recent file activities';
PRINT '';
PRINT 'Sample queries provided for:';
PRINT '- File listing by tab and category';
PRINT '- File statistics and analytics';
PRINT '- Search and filtering';
PRINT '- Permission management';
