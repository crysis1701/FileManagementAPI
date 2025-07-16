-- =============================================
-- File Management System - Display Queries
-- Các truy vấn hiển thị cho Tab A (mục b,c,d,c) và Tab B (mục x,v,e,b)
-- =============================================

USE FileManagementDB;
GO

-- =============================================
-- 1. VIEW HIỂN THỊ THÔNG TIN FILE CHI TIẾT
-- =============================================
CREATE OR ALTER VIEW [v_files_display] AS
SELECT 
    t.tab_name AS [Tab],
    c.category_name AS [Mục],
    f.file_name AS [Tên File],
    e.full_name AS [Nhân viên đăng tải],
    d.department_name AS [Đơn vị],
    f.upload_date AS [Ngày tải file],
    CASE 
        WHEN fa.action_type = 'UPLOAD' THEN N'Tải lên'
        WHEN fa.action_type = 'DOWNLOAD' THEN N'Tải xuống'
        WHEN fa.action_type = 'VIEW' THEN N'Xem'
        WHEN fa.action_type = 'UPDATE' THEN N'Cập nhật'
        WHEN fa.action_type = 'DELETE' THEN N'Xóa'
        ELSE N'Không xác định'
    END AS [Tác vụ],
    f.file_size AS [Kích thước (bytes)],
    f.download_count AS [Lượt tải],
    f.is_current_version AS [Phiên bản hiện tại],
    f.file_id
FROM [files] f
INNER JOIN [tabs] t ON f.tab_id = t.tab_id
INNER JOIN [categories] c ON f.category_id = c.category_id
INNER JOIN [employees] e ON f.uploaded_by = e.employee_id
INNER JOIN [departments] d ON f.department_id = d.department_id
LEFT JOIN [file_actions] fa ON f.file_id = fa.file_id 
    AND fa.action_date = (
        SELECT MAX(fa2.action_date) 
        FROM [file_actions] fa2 
        WHERE fa2.file_id = f.file_id
    )
WHERE f.is_deleted = 0 AND f.is_active = 1
GO

-- =============================================
-- 2. HIỂN THỊ TOÀN BỘ FILE THEO TAB VÀ MỤC
-- =============================================
SELECT 
    [Tab],
    [Mục],
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ],
    CASE 
        WHEN [Kích thước (bytes)] > 1048576 THEN CAST([Kích thước (bytes)] / 1048576.0 AS DECIMAL(10,2)) + ' MB'
        WHEN [Kích thước (bytes)] > 1024 THEN CAST([Kích thước (bytes)] / 1024.0 AS DECIMAL(10,2)) + ' KB'
        ELSE CAST([Kích thước (bytes)] AS VARCHAR) + ' bytes'
    END AS [Kích thước],
    [Lượt tải]
FROM [v_files_display]
ORDER BY [Tab], [Mục], [Ngày tải file] DESC;

-- =============================================
-- 3. HIỂN THỊ RIÊNG TAB A (các mục b,c,d,c)
-- =============================================
PRINT N'=== TAB A - CÁC MỤC B, C, D, C ===';
SELECT 
    [Mục],
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab A%'
ORDER BY [Mục], [Ngày tải file] DESC;

-- =============================================
-- 4. HIỂN THỊ RIÊNG TAB B (các mục x,v,e,b)
-- =============================================
PRINT N'=== TAB B - CÁC MỤC X, V, E, B ===';
SELECT 
    [Mục],
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab B%'
ORDER BY [Mục], [Ngày tải file] DESC;

-- =============================================
-- 5. HIỂN THỊ THEO TỪNG MỤC CỤ THẺ
-- =============================================

-- Tab A - Mục B
PRINT N'=== TAB A - MỤC B ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab A%' AND [Mục] LIKE '%Mục B%'
ORDER BY [Ngày tải file] DESC;

-- Tab A - Mục C
PRINT N'=== TAB A - MỤC C ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab A%' AND [Mục] LIKE '%Mục C%'
ORDER BY [Ngày tải file] DESC;

-- Tab A - Mục D
PRINT N'=== TAB A - MỤC D ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab A%' AND [Mục] LIKE '%Mục D%'
ORDER BY [Ngày tải file] DESC;

-- Tab B - Mục X
PRINT N'=== TAB B - MỤC X ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab B%' AND [Mục] LIKE '%Mục X%'
ORDER BY [Ngày tải file] DESC;

-- Tab B - Mục V
PRINT N'=== TAB B - MỤC V ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab B%' AND [Mục] LIKE '%Mục V%'
ORDER BY [Ngày tải file] DESC;

-- Tab B - Mục E
PRINT N'=== TAB B - MỤC E ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab B%' AND [Mục] LIKE '%Mục E%'
ORDER BY [Ngày tải file] DESC;

-- Tab B - Mục B
PRINT N'=== TAB B - MỤC B ===';
SELECT 
    [Tên File],
    [Nhân viên đăng tải],
    [Đơn vị],
    FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
    [Tác vụ]
FROM [v_files_display]
WHERE [Tab] LIKE '%Tab B%' AND [Mục] LIKE '%Mục B%'
ORDER BY [Ngày tải file] DESC;

-- =============================================
-- 6. THỐNG KÊ THEO TAB VÀ MỤC
-- =============================================
PRINT N'=== THỐNG KÊ THEO TAB VÀ MỤC ===';
SELECT 
    [Tab],
    [Mục],
    COUNT(*) AS [Số file],
    SUM([Kích thước (bytes)]) AS [Tổng kích thước (bytes)],
    AVG([Lượt tải]) AS [Trung bình lượt tải],
    MAX([Ngày tải file]) AS [File mới nhất],
    MIN([Ngày tải file]) AS [File cũ nhất]
FROM [v_files_display]
GROUP BY [Tab], [Mục]
ORDER BY [Tab], [Mục];

-- =============================================
-- 7. THỐNG KÊ THEO NHÂN VIÊN
-- =============================================
PRINT N'=== THỐNG KÊ THEO NHÂN VIÊN ===';
SELECT 
    [Nhân viên đăng tải],
    [Đơn vị],
    COUNT(*) AS [Số file đã tải],
    SUM([Kích thước (bytes)]) AS [Tổng kích thước (bytes)],
    MAX([Ngày tải file]) AS [Lần tải gần nhất]
FROM [v_files_display]
GROUP BY [Nhân viên đăng tải], [Đơn vị]
ORDER BY [Số file đã tải] DESC;

-- =============================================
-- 8. THỐNG KÊ THEO ĐỜN VỊ
-- =============================================
PRINT N'=== THỐNG KÊ THEO ĐƠN VỊ ===';
SELECT 
    [Đơn vị],
    COUNT(*) AS [Số file],
    COUNT(DISTINCT [Nhân viên đăng tải]) AS [Số nhân viên tham gia],
    SUM([Kích thước (bytes)]) AS [Tổng kích thước (bytes)],
    AVG([Lượt tải]) AS [Trung bình lượt tải]
FROM [v_files_display]
GROUP BY [Đơn vị]
ORDER BY [Số file] DESC;

-- =============================================
-- 9. LỊCH SỬ TÁC VỤ CHI TIẾT
-- =============================================
PRINT N'=== LỊCH SỬ TÁC VỤ CHI TIẾT ===';
SELECT 
    t.tab_name AS [Tab],
    c.category_name AS [Mục],
    f.file_name AS [Tên File],
    e.full_name AS [Nhân viên thực hiện],
    d.department_name AS [Đơn vị],
    CASE 
        WHEN fa.action_type = 'UPLOAD' THEN N'Tải lên'
        WHEN fa.action_type = 'DOWNLOAD' THEN N'Tải xuống'
        WHEN fa.action_type = 'VIEW' THEN N'Xem'
        WHEN fa.action_type = 'UPDATE' THEN N'Cập nhật'
        WHEN fa.action_type = 'DELETE' THEN N'Xóa'
        ELSE N'Không xác định'
    END AS [Tác vụ],
    FORMAT(fa.action_date, 'dd/MM/yyyy HH:mm:ss') AS [Thời gian],
    fa.ip_address AS [Địa chỉ IP],
    fa.notes AS [Ghi chú]
FROM [file_actions] fa
INNER JOIN [files] f ON fa.file_id = f.file_id
INNER JOIN [tabs] t ON f.tab_id = t.tab_id
INNER JOIN [categories] c ON f.category_id = c.category_id
INNER JOIN [employees] e ON fa.performed_by = e.employee_id
INNER JOIN [departments] d ON e.department_id = d.department_id
WHERE f.is_deleted = 0
ORDER BY fa.action_date DESC;

-- =============================================
-- 10. STORED PROCEDURES TIỆN ÍCH
-- =============================================

-- Procedure hiển thị file theo tab
CREATE OR ALTER PROCEDURE [sp_GetFilesByTab]
    @TabCode NVARCHAR(50)
AS
BEGIN
    SELECT 
        [Mục],
        [Tên File],
        [Nhân viên đăng tải],
        [Đơn vị],
        FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
        [Tác vụ]
    FROM [v_files_display]
    WHERE [Tab] LIKE '%' + @TabCode + '%'
    ORDER BY [Mục], [Ngày tải file] DESC;
END
GO

-- Procedure hiển thị file theo mục
CREATE OR ALTER PROCEDURE [sp_GetFilesByCategory]
    @TabCode NVARCHAR(50),
    @CategoryCode NVARCHAR(50)
AS
BEGIN
    SELECT 
        [Tên File],
        [Nhân viên đăng tải],
        [Đơn vị],
        FORMAT([Ngày tải file], 'dd/MM/yyyy HH:mm') AS [Ngày tải file],
        [Tác vụ]
    FROM [v_files_display] v
    INNER JOIN [tabs] t ON v.[Tab] = t.tab_name
    INNER JOIN [categories] c ON v.[Mục] = c.category_name
    WHERE t.tab_code = @TabCode AND c.category_code = @CategoryCode
    ORDER BY [Ngày tải file] DESC;
END
GO

-- =============================================
-- 11. STORED PROCEDURES QUẢN LÝ TRẠNG THÁI ACTIVE
-- =============================================

-- Procedure active/deactive file
CREATE OR ALTER PROCEDURE [sp_ToggleFileActive]
    @FileId UNIQUEIDENTIFIER,
    @IsActive BIT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CurrentStatus BIT;
    DECLARE @FileName NVARCHAR(255);
    
    -- Kiểm tra file tồn tại
    SELECT @CurrentStatus = is_active, @FileName = file_name
    FROM [files] 
    WHERE file_id = @FileId AND is_deleted = 0;
    
    IF @CurrentStatus IS NULL
    BEGIN
        SELECT 
            'error' AS status,
            N'File không tồn tại hoặc đã bị xóa' AS message;
        RETURN;
    END
    
    -- Cập nhật trạng thái
    UPDATE [files] 
    SET is_active = @IsActive,
        updated_at = GETDATE()
    WHERE file_id = @FileId;
    
    -- Ghi log action
    INSERT INTO [file_actions] ([file_id], [action_type], [performed_by], [notes])
    VALUES (@FileId, 
            CASE WHEN @IsActive = 1 THEN 'ACTIVATE' ELSE 'DEACTIVATE' END,
            @UserId,
            CASE WHEN @IsActive = 1 THEN N'Kích hoạt file' ELSE N'Hủy kích hoạt file' END);
    
    -- Trả về kết quả
    SELECT 
        'success' AS status,
        CASE WHEN @IsActive = 1 THEN N'File đã được kích hoạt' ELSE N'File đã bị hủy kích hoạt' END AS message,
        @FileName AS file_name,
        @IsActive AS is_active,
        GETDATE() AS updated_at;
END
GO

-- Procedure lấy danh sách file theo trạng thái active
CREATE OR ALTER PROCEDURE [sp_GetFilesByActiveStatus]
    @IsActive BIT = NULL, -- NULL = tất cả, 1 = active, 0 = inactive
    @TabCode NVARCHAR(50) = NULL,
    @CategoryCode NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        f.file_id,
        f.file_name,
        f.is_active,
        f.is_deleted,
        t.tab_name,
        c.category_name,
        e.full_name AS uploaded_by,
        d.department_name,
        f.upload_date,
        f.download_count,
        CASE 
            WHEN f.is_active = 1 THEN N'Đang hoạt động'
            ELSE N'Không hoạt động'
        END AS status_display
    FROM [files] f
    INNER JOIN [tabs] t ON f.tab_id = t.tab_id
    INNER JOIN [categories] c ON f.category_id = c.category_id
    INNER JOIN [employees] e ON f.uploaded_by = e.employee_id
    INNER JOIN [departments] d ON f.department_id = d.department_id
    WHERE f.is_deleted = 0
        AND (@IsActive IS NULL OR f.is_active = @IsActive)
        AND (@TabCode IS NULL OR t.tab_code = @TabCode)
        AND (@CategoryCode IS NULL OR c.category_code = @CategoryCode)
    ORDER BY f.upload_date DESC;
END
GO

-- Procedure thống kê file theo trạng thái active
CREATE OR ALTER PROCEDURE [sp_GetFileActiveStatistics]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        'overview' AS category,
        COUNT(*) AS total_files,
        SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_files,
        SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS inactive_files,
        CAST(SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS active_percentage
    FROM [files]
    WHERE is_deleted = 0
    
    UNION ALL
    
    SELECT 
        'by_tab' AS category,
        COUNT(*) AS total_files,
        SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) AS active_files,
        SUM(CASE WHEN f.is_active = 0 THEN 1 ELSE 0 END) AS inactive_files,
        CAST(SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS active_percentage
    FROM [files] f
    INNER JOIN [tabs] t ON f.tab_id = t.tab_id
    WHERE f.is_deleted = 0
    GROUP BY t.tab_name
    
    UNION ALL
    
    SELECT 
        'by_department' AS category,
        COUNT(*) AS total_files,
        SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) AS active_files,
        SUM(CASE WHEN f.is_active = 0 THEN 1 ELSE 0 END) AS inactive_files,
        CAST(SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS active_percentage
    FROM [files] f
    INNER JOIN [departments] d ON f.department_id = d.department_id
    WHERE f.is_deleted = 0
    GROUP BY d.department_name;
END
GO

-- =============================================
-- 12. VIEW HIỂN THỊ CHI TIẾT TRẠNG THÁI FILE
-- =============================================
CREATE OR ALTER VIEW [v_files_with_status] AS
SELECT 
    f.file_id,
    f.file_name,
    f.original_filename,
    f.file_size,
    f.upload_date,
    f.download_count,
    f.is_active,
    f.is_deleted,
    t.tab_name,
    c.category_name,
    e.full_name AS uploaded_by,
    d.department_name,
    CASE 
        WHEN f.is_deleted = 1 THEN N'Đã xóa'
        WHEN f.is_active = 1 THEN N'Đang hoạt động'
        ELSE N'Không hoạt động'
    END AS status_display,
    CASE 
        WHEN f.is_deleted = 1 THEN 'deleted'
        WHEN f.is_active = 1 THEN 'active'
        ELSE 'inactive'
    END AS status_code
FROM [files] f
INNER JOIN [tabs] t ON f.tab_id = t.tab_id
INNER JOIN [categories] c ON f.category_id = c.category_id
INNER JOIN [employees] e ON f.uploaded_by = e.employee_id
INNER JOIN [departments] d ON f.department_id = d.department_id
GO

-- =============================================
-- DEMO SỬ DỤNG CÁC PROCEDURES MỚI
-- =============================================

PRINT N'=== DEMO QUẢN LÝ TRẠNG THÁI ACTIVE ===';

-- Xem tất cả file với trạng thái
PRINT N'1. Xem tất cả file với trạng thái:';
SELECT * FROM [v_files_with_status] ORDER BY upload_date DESC;

-- Xem chỉ file đang active
PRINT N'2. Xem file đang active:';
EXEC [sp_GetFilesByActiveStatus] @IsActive = 1;

-- Xem chỉ file không active
PRINT N'3. Xem file không active:';
EXEC [sp_GetFilesByActiveStatus] @IsActive = 0;

-- Xem thống kê trạng thái
PRINT N'4. Thống kê trạng thái file:';
EXEC [sp_GetFileActiveStatistics];

-- Demo toggle active (cần thay file_id thật)
PRINT N'5. Demo toggle active file:';
DECLARE @SampleFileId UNIQUEIDENTIFIER = (SELECT TOP 1 file_id FROM [files] WHERE is_deleted = 0);
IF @SampleFileId IS NOT NULL
BEGIN
    EXEC [sp_ToggleFileActive] @FileId = @SampleFileId, @IsActive = 0, @UserId = 1;
    EXEC [sp_ToggleFileActive] @FileId = @SampleFileId, @IsActive = 1, @UserId = 1;
END

PRINT N'=== HƯỚNG DẪN SỬ DỤNG ===';
PRINT N'1. Xem toàn bộ file: SELECT * FROM [v_files_display]';
PRINT N'2. Xem file Tab A: EXEC [sp_GetFilesByTab] ''TAB_A''';
PRINT N'3. Xem file Tab B: EXEC [sp_GetFilesByTab] ''TAB_B''';
PRINT N'4. Xem file theo mục: EXEC [sp_GetFilesByCategory] ''TAB_A'', ''B''';
PRINT N'5. Các truy vấn thống kê đã được tạo sẵn trong file này';
