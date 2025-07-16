-- =============================================
-- Database Migration Script
-- Thêm cột is_active vào bảng files
-- =============================================

USE FileManagementDB;
GO

-- =============================================
-- 1. THÊM CỘT is_active VÀO BẢNG files
-- =============================================
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('files') 
    AND name = 'is_active'
)
BEGIN
    ALTER TABLE [files] 
    ADD [is_active] BIT NOT NULL DEFAULT 1;
    
    PRINT 'Đã thêm cột is_active vào bảng files';
END
ELSE
BEGIN
    PRINT 'Cột is_active đã tồn tại trong bảng files';
END
GO

-- =============================================
-- 2. TẠO INDEX CHO CỘT is_active
-- =============================================
IF NOT EXISTS (
    SELECT * FROM sys.indexes 
    WHERE name = 'IX_files_is_active' 
    AND object_id = OBJECT_ID('files')
)
BEGIN
    CREATE INDEX [IX_files_is_active] ON [files] ([is_active]);
    PRINT 'Đã tạo index IX_files_is_active';
END
ELSE
BEGIN
    PRINT 'Index IX_files_is_active đã tồn tại';
END
GO

-- =============================================
-- 3. CẬP NHẬT DỮ LIỆU MẪU
-- =============================================
-- Set một số file là inactive để demo
UPDATE [files] 
SET is_active = 0 
WHERE file_name IN (
    'Công văn 002/2024',
    'Lịch bảo trì Q1-2024'
);

PRINT 'Đã cập nhật trạng thái active cho dữ liệu mẫu';
GO

-- =============================================
-- 4. THÊM CÁC ACTION TYPE MỚI
-- =============================================
-- Cập nhật constraint cho file_actions để hỗ trợ ACTIVATE/DEACTIVATE
ALTER TABLE [file_actions] 
DROP CONSTRAINT [CK_file_actions_action_type];

ALTER TABLE [file_actions] 
ADD CONSTRAINT [CK_file_actions_action_type] 
CHECK ([action_type] IN ('UPLOAD', 'DOWNLOAD', 'DELETE', 'UPDATE', 'VIEW', 'ACTIVATE', 'DEACTIVATE'));

PRINT 'Đã cập nhật constraint cho file_actions';
GO

-- =============================================
-- 5. STORED PROCEDURE QUẢN LÝ TRẠNG THÁI ACTIVE
-- =============================================
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

-- =============================================
-- 6. VIEW HIỂN THỊ FILE VỚI TRẠNG THÁI
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
    END AS status_code,
    CASE 
        WHEN f.file_size > 1048576 THEN CAST(f.file_size / 1048576.0 AS DECIMAL(10,2)) + ' MB'
        WHEN f.file_size > 1024 THEN CAST(f.file_size / 1024.0 AS DECIMAL(10,2)) + ' KB'
        ELSE CAST(f.file_size AS VARCHAR) + ' bytes'
    END AS file_size_display
FROM [files] f
INNER JOIN [tabs] t ON f.tab_id = t.tab_id
INNER JOIN [categories] c ON f.category_id = c.category_id
INNER JOIN [employees] e ON f.uploaded_by = e.employee_id
INNER JOIN [departments] d ON f.department_id = d.department_id
GO

-- =============================================
-- 7. PROCEDURE LẤY FILE THEO TRẠNG THÁI
-- =============================================
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
        f.status_display,
        f.status_code,
        f.file_size_display
    FROM [v_files_with_status] f
    INNER JOIN [tabs] t ON f.tab_name = t.tab_name
    INNER JOIN [categories] c ON f.category_name = c.category_name
    WHERE f.is_deleted = 0
        AND (@IsActive IS NULL OR f.is_active = @IsActive)
        AND (@TabCode IS NULL OR t.tab_code = @TabCode)
        AND (@CategoryCode IS NULL OR c.category_code = @CategoryCode)
    ORDER BY f.upload_date DESC;
END
GO

-- =============================================
-- 8. PROCEDURE THỐNG KÊ TRẠNG THÁI
-- =============================================
CREATE OR ALTER PROCEDURE [sp_GetFileActiveStatistics]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Thống kê tổng quan
    SELECT 
        'Tổng quan' AS [Phạm vi],
        COUNT(*) AS [Tổng file],
        SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS [File active],
        SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS [File inactive],
        CAST(SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Tỷ lệ active (%)]
    FROM [files]
    WHERE is_deleted = 0
    
    UNION ALL
    
    -- Thống kê theo tab
    SELECT 
        'Tab: ' + t.tab_name AS [Phạm vi],
        COUNT(*) AS [Tổng file],
        SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) AS [File active],
        SUM(CASE WHEN f.is_active = 0 THEN 1 ELSE 0 END) AS [File inactive],
        CAST(SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Tỷ lệ active (%)]
    FROM [files] f
    INNER JOIN [tabs] t ON f.tab_id = t.tab_id
    WHERE f.is_deleted = 0
    GROUP BY t.tab_name
    
    UNION ALL
    
    -- Thống kê theo phòng ban
    SELECT 
        'Phòng ban: ' + d.department_name AS [Phạm vi],
        COUNT(*) AS [Tổng file],
        SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) AS [File active],
        SUM(CASE WHEN f.is_active = 0 THEN 1 ELSE 0 END) AS [File inactive],
        CAST(SUM(CASE WHEN f.is_active = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS [Tỷ lệ active (%)]
    FROM [files] f
    INNER JOIN [departments] d ON f.department_id = d.department_id
    WHERE f.is_deleted = 0
    GROUP BY d.department_name
    ORDER BY [Tổng file] DESC;
END
GO

-- =============================================
-- 9. DEMO VÀ KIỂM TRA
-- =============================================
PRINT N'=== DEMO TÍNH NĂNG ACTIVE/INACTIVE ===';

-- Xem tất cả file với trạng thái
PRINT N'1. Tất cả file với trạng thái:';
SELECT 
    file_name,
    tab_name,
    category_name,
    uploaded_by,
    status_display,
    file_size_display,
    FORMAT(upload_date, 'dd/MM/yyyy HH:mm') AS upload_date
FROM [v_files_with_status]
ORDER BY upload_date DESC;

-- Xem chỉ file active
PRINT N'2. Chỉ file đang active:';
EXEC [sp_GetFilesByActiveStatus] @IsActive = 1;

-- Xem chỉ file inactive
PRINT N'3. Chỉ file inactive:';
EXEC [sp_GetFilesByActiveStatus] @IsActive = 0;

-- Thống kê trạng thái
PRINT N'4. Thống kê trạng thái:';
EXEC [sp_GetFileActiveStatistics];

-- Demo toggle active
PRINT N'5. Demo toggle active:';
DECLARE @TestFileId UNIQUEIDENTIFIER = (
    SELECT TOP 1 file_id 
    FROM [files] 
    WHERE is_deleted = 0 AND file_name = N'Báo cáo tháng 1-2024'
);

IF @TestFileId IS NOT NULL
BEGIN
    PRINT N'Deactivate file:';
    EXEC [sp_ToggleFileActive] @FileId = @TestFileId, @IsActive = 0, @UserId = 1;
    
    PRINT N'Activate file:';
    EXEC [sp_ToggleFileActive] @FileId = @TestFileId, @IsActive = 1, @UserId = 1;
END

PRINT N'=== MIGRATION HOÀN THÀNH ===';
PRINT N'✅ Đã thêm cột is_active vào bảng files';
PRINT N'✅ Đã tạo index cho hiệu năng';
PRINT N'✅ Đã cập nhật dữ liệu mẫu';
PRINT N'✅ Đã tạo stored procedures quản lý';
PRINT N'✅ Đã tạo views hiển thị';
PRINT N'✅ Sẵn sàng sử dụng tính năng active/inactive';
