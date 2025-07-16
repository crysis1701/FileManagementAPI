-- =============================================
-- SQL Queries to Generate JSON Response Data
-- Các truy vấn SQL tạo dữ liệu JSON cho API
-- =============================================

USE FileManagementDB;
GO

-- =============================================
-- 1. QUERY TẠO JSON CHO TOÀN BỘ 2 TAB
-- =============================================
WITH TabData AS (
    SELECT 
        t.tab_id,
        t.tab_code,
        t.tab_name,
        t.tab_description,
        t.sort_order,
        t.is_active,
        
        -- Category data
        c.category_id,
        c.category_code,
        c.category_name,
        c.category_description,
        c.sort_order AS category_sort_order,
        
        -- File data
        f.file_id,
        f.file_name,
        f.original_filename,
        f.file_extension,
        f.file_size,
        f.mime_type,
        f.upload_date,
        f.description AS file_description,
        f.version,
        f.is_current_version,
        f.download_count,
        
        -- Employee data
        e.employee_id,
        e.employee_code,
        e.full_name,
        e.position,
        
        -- Department data
        d.department_id,
        d.department_code,
        d.department_name,
        
        -- Last action data
        la.action_type,
        la.action_date,
        la.performed_by,
        la_emp.full_name AS action_performer_name,
        
        -- File size display
        CASE 
            WHEN f.file_size > 1048576 THEN CAST(f.file_size / 1048576.0 AS DECIMAL(10,2)) + ' MB'
            WHEN f.file_size > 1024 THEN CAST(f.file_size / 1024.0 AS DECIMAL(10,2)) + ' KB'
            ELSE CAST(f.file_size AS VARCHAR) + ' bytes'
        END AS file_size_display,
        
        -- Action display
        CASE 
            WHEN la.action_type = 'UPLOAD' THEN N'Tải lên'
            WHEN la.action_type = 'DOWNLOAD' THEN N'Tải xuống'
            WHEN la.action_type = 'VIEW' THEN N'Xem'
            WHEN la.action_type = 'UPDATE' THEN N'Cập nhật'
            WHEN la.action_type = 'DELETE' THEN N'Xóa'
            ELSE N'Không xác định'
        END AS action_display
        
    FROM [tabs] t
    LEFT JOIN [categories] c ON t.tab_id = c.tab_id
    LEFT JOIN [files] f ON c.category_id = f.category_id AND f.is_deleted = 0
    LEFT JOIN [employees] e ON f.uploaded_by = e.employee_id
    LEFT JOIN [departments] d ON f.department_id = d.department_id
    LEFT JOIN [file_actions] la ON f.file_id = la.file_id 
        AND la.action_date = (
            SELECT MAX(fa2.action_date) 
            FROM [file_actions] fa2 
            WHERE fa2.file_id = f.file_id
        )
    LEFT JOIN [employees] la_emp ON la.performed_by = la_emp.employee_id
    WHERE t.is_active = 1 AND (c.is_active = 1 OR c.is_active IS NULL)
)
SELECT 
    t.tab_code,
    t.tab_name,
    (
        SELECT 
            t.tab_id,
            t.tab_code,
            t.tab_name,
            t.tab_description,
            t.sort_order,
            t.is_active,
            (
                SELECT 
                    c.category_id,
                    c.category_code,
                    c.category_name,
                    c.category_description,
                    c.category_sort_order AS sort_order,
                    COUNT(f.file_id) AS file_count,
                    (
                        SELECT 
                            f.file_id,
                            f.file_name,
                            f.original_filename,
                            f.file_extension,
                            f.file_size,
                            f.file_size_display,
                            f.mime_type,
                            f.upload_date,
                            FORMAT(f.upload_date, 'dd/MM/yyyy HH:mm') AS upload_date_display,
                            f.file_description AS description,
                            f.version,
                            f.is_current_version,
                            f.download_count,
                            JSON_OBJECT(
                                'employee_id', f.employee_id,
                                'employee_code', f.employee_code,
                                'full_name', f.full_name,
                                'position', f.position
                            ) AS uploaded_by,
                            JSON_OBJECT(
                                'department_id', f.department_id,
                                'department_code', f.department_code,
                                'department_name', f.department_name
                            ) AS department,
                            JSON_OBJECT(
                                'action_type', f.action_type,
                                'action_display', f.action_display,
                                'performed_by', f.action_performer_name,
                                'action_date', f.action_date,
                                'action_date_display', FORMAT(f.action_date, 'dd/MM/yyyy HH:mm')
                            ) AS last_action
                        FROM TabData f
                        WHERE f.category_id = c.category_id
                        ORDER BY f.upload_date DESC
                        FOR JSON PATH
                    ) AS files
                FROM TabData c
                WHERE c.tab_id = t.tab_id
                GROUP BY c.category_id, c.category_code, c.category_name, c.category_description, c.category_sort_order
                ORDER BY c.category_sort_order
                FOR JSON PATH
            ) AS categories,
            JSON_OBJECT(
                'total_files', (SELECT COUNT(*) FROM TabData f WHERE f.tab_id = t.tab_id),
                'total_size', (SELECT SUM(f.file_size) FROM TabData f WHERE f.tab_id = t.tab_id),
                'total_size_display', (
                    SELECT CASE 
                        WHEN SUM(f.file_size) > 1048576 THEN CAST(SUM(f.file_size) / 1048576.0 AS DECIMAL(10,2)) + ' MB'
                        WHEN SUM(f.file_size) > 1024 THEN CAST(SUM(f.file_size) / 1024.0 AS DECIMAL(10,2)) + ' KB'
                        ELSE CAST(SUM(f.file_size) AS VARCHAR) + ' bytes'
                    END
                    FROM TabData f WHERE f.tab_id = t.tab_id
                ),
                'total_downloads', (SELECT SUM(f.download_count) FROM TabData f WHERE f.tab_id = t.tab_id),
                'latest_upload', (SELECT MAX(f.upload_date) FROM TabData f WHERE f.tab_id = t.tab_id),
                'latest_upload_display', (SELECT FORMAT(MAX(f.upload_date), 'dd/MM/yyyy HH:mm') FROM TabData f WHERE f.tab_id = t.tab_id)
            ) AS statistics
        FROM TabData t
        WHERE t.tab_id = (SELECT DISTINCT tab_id FROM TabData td WHERE td.tab_code = t.tab_code)
        GROUP BY t.tab_id, t.tab_code, t.tab_name, t.tab_description, t.sort_order, t.is_active
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    ) AS tab_data
FROM (SELECT DISTINCT tab_code, tab_name FROM TabData) t
ORDER BY t.tab_code
FOR JSON PATH;

-- =============================================
-- 2. QUERY TẠO JSON CHO 1 TAB CỤ THỂ
-- =============================================
CREATE OR ALTER PROCEDURE [sp_GetTabDataJSON]
    @TabCode NVARCHAR(50)
AS
BEGIN
    WITH TabData AS (
        SELECT 
            t.tab_id, t.tab_code, t.tab_name, t.tab_description, t.sort_order, t.is_active,
            c.category_id, c.category_code, c.category_name, c.category_description,
            c.sort_order AS category_sort_order,
            f.file_id, f.file_name, f.original_filename, f.file_extension, f.file_size,
            f.mime_type, f.upload_date, f.description AS file_description,
            f.version, f.is_current_version, f.download_count,
            e.employee_id, e.employee_code, e.full_name, e.position,
            d.department_id, d.department_code, d.department_name,
            la.action_type, la.action_date, la_emp.full_name AS action_performer_name,
            CASE 
                WHEN f.file_size > 1048576 THEN CAST(f.file_size / 1048576.0 AS DECIMAL(10,2)) + ' MB'
                WHEN f.file_size > 1024 THEN CAST(f.file_size / 1024.0 AS DECIMAL(10,2)) + ' KB'
                ELSE CAST(f.file_size AS VARCHAR) + ' bytes'
            END AS file_size_display,
            CASE 
                WHEN la.action_type = 'UPLOAD' THEN N'Tải lên'
                WHEN la.action_type = 'DOWNLOAD' THEN N'Tải xuống'
                WHEN la.action_type = 'VIEW' THEN N'Xem'
                WHEN la.action_type = 'UPDATE' THEN N'Cập nhật'
                WHEN la.action_type = 'DELETE' THEN N'Xóa'
                ELSE N'Không xác định'
            END AS action_display
        FROM [tabs] t
        LEFT JOIN [categories] c ON t.tab_id = c.tab_id
        LEFT JOIN [files] f ON c.category_id = f.category_id AND f.is_deleted = 0
        LEFT JOIN [employees] e ON f.uploaded_by = e.employee_id
        LEFT JOIN [departments] d ON f.department_id = d.department_id
        LEFT JOIN [file_actions] la ON f.file_id = la.file_id 
            AND la.action_date = (SELECT MAX(fa2.action_date) FROM [file_actions] fa2 WHERE fa2.file_id = f.file_id)
        LEFT JOIN [employees] la_emp ON la.performed_by = la_emp.employee_id
        WHERE t.tab_code = @TabCode AND t.is_active = 1 AND (c.is_active = 1 OR c.is_active IS NULL)
    )
    SELECT 
        JSON_OBJECT(
            'status', 'success',
            'data', JSON_OBJECT(
                'tab_info', JSON_OBJECT(
                    'tab_id', t.tab_id,
                    'tab_code', t.tab_code,
                    'tab_name', t.tab_name,
                    'tab_description', t.tab_description,
                    'sort_order', t.sort_order,
                    'is_active', t.is_active
                ),
                'categories', (
                    SELECT 
                        JSON_OBJECT(
                            'category_info', JSON_OBJECT(
                                'category_id', c.category_id,
                                'category_code', c.category_code,
                                'category_name', c.category_name,
                                'category_description', c.category_description,
                                'sort_order', c.category_sort_order,
                                'file_count', COUNT(f.file_id)
                            ),
                            'files', (
                                SELECT 
                                    JSON_OBJECT(
                                        'file_id', f.file_id,
                                        'file_name', f.file_name,
                                        'original_filename', f.original_filename,
                                        'file_extension', f.file_extension,
                                        'file_size', f.file_size,
                                        'file_size_display', f.file_size_display,
                                        'mime_type', f.mime_type,
                                        'upload_date', f.upload_date,
                                        'upload_date_display', FORMAT(f.upload_date, 'dd/MM/yyyy HH:mm'),
                                        'description', f.file_description,
                                        'version', f.version,
                                        'is_current_version', f.is_current_version,
                                        'download_count', f.download_count,
                                        'uploaded_by', JSON_OBJECT(
                                            'employee_id', f.employee_id,
                                            'employee_code', f.employee_code,
                                            'full_name', f.full_name,
                                            'position', f.position
                                        ),
                                        'department', JSON_OBJECT(
                                            'department_id', f.department_id,
                                            'department_code', f.department_code,
                                            'department_name', f.department_name
                                        ),
                                        'last_action', JSON_OBJECT(
                                            'action_type', f.action_type,
                                            'action_display', f.action_display,
                                            'performed_by', f.action_performer_name,
                                            'action_date', f.action_date,
                                            'action_date_display', FORMAT(f.action_date, 'dd/MM/yyyy HH:mm')
                                        )
                                    )
                                FROM TabData f
                                WHERE f.category_id = c.category_id
                                ORDER BY f.upload_date DESC
                                FOR JSON PATH
                            )
                        )
                    FROM TabData c
                    WHERE c.tab_id = t.tab_id
                    GROUP BY c.category_id, c.category_code, c.category_name, c.category_description, c.category_sort_order
                    ORDER BY c.category_sort_order
                    FOR JSON PATH
                )
            )
        ) AS json_result
    FROM (SELECT DISTINCT tab_id, tab_code, tab_name, tab_description, sort_order, is_active FROM TabData) t;
END
GO

-- =============================================
-- 3. QUERY TẠO JSON CHO FILES THEO CATEGORY
-- =============================================
CREATE OR ALTER PROCEDURE [sp_GetCategoryFilesJSON]
    @TabCode NVARCHAR(50),
    @CategoryCode NVARCHAR(50)
AS
BEGIN
    SELECT 
        JSON_OBJECT(
            'status', 'success',
            'data', JSON_OBJECT(
                'category_info', JSON_OBJECT(
                    'category_id', c.category_id,
                    'category_code', c.category_code,
                    'category_name', c.category_name,
                    'tab_name', t.tab_name
                ),
                'files', (
                    SELECT 
                        JSON_OBJECT(
                            'file_id', f.file_id,
                            'file_name', f.file_name,
                            'uploaded_by', JSON_OBJECT(
                                'employee_id', e.employee_id,
                                'full_name', e.full_name,
                                'position', e.position
                            ),
                            'department', JSON_OBJECT(
                                'department_name', d.department_name
                            ),
                            'upload_date', f.upload_date,
                            'upload_date_display', FORMAT(f.upload_date, 'dd/MM/yyyy HH:mm'),
                            'last_action', JSON_OBJECT(
                                'action_type', la.action_type,
                                'action_display', CASE 
                                    WHEN la.action_type = 'UPLOAD' THEN N'Tải lên'
                                    WHEN la.action_type = 'DOWNLOAD' THEN N'Tải xuống'
                                    WHEN la.action_type = 'VIEW' THEN N'Xem'
                                    WHEN la.action_type = 'UPDATE' THEN N'Cập nhật'
                                    WHEN la.action_type = 'DELETE' THEN N'Xóa'
                                    ELSE N'Không xác định'
                                END,
                                'performed_by', la_emp.full_name,
                                'action_date_display', FORMAT(la.action_date, 'dd/MM/yyyy HH:mm')
                            ),
                            'file_size_display', CASE 
                                WHEN f.file_size > 1048576 THEN CAST(f.file_size / 1048576.0 AS DECIMAL(10,2)) + ' MB'
                                WHEN f.file_size > 1024 THEN CAST(f.file_size / 1024.0 AS DECIMAL(10,2)) + ' KB'
                                ELSE CAST(f.file_size AS VARCHAR) + ' bytes'
                            END,
                            'download_count', f.download_count
                        )
                    FROM [files] f
                    INNER JOIN [employees] e ON f.uploaded_by = e.employee_id
                    INNER JOIN [departments] d ON f.department_id = d.department_id
                    LEFT JOIN [file_actions] la ON f.file_id = la.file_id 
                        AND la.action_date = (SELECT MAX(fa2.action_date) FROM [file_actions] fa2 WHERE fa2.file_id = f.file_id)
                    LEFT JOIN [employees] la_emp ON la.performed_by = la_emp.employee_id
                    WHERE f.category_id = c.category_id AND f.is_deleted = 0
                    ORDER BY f.upload_date DESC
                    FOR JSON PATH
                )
            )
        ) AS json_result
    FROM [tabs] t
    INNER JOIN [categories] c ON t.tab_id = c.tab_id
    WHERE t.tab_code = @TabCode AND c.category_code = @CategoryCode
    AND t.is_active = 1 AND c.is_active = 1;
END
GO

-- =============================================
-- 4. QUERY TẠO JSON CHO THỐNG KÊ
-- =============================================
CREATE OR ALTER PROCEDURE [sp_GetStatisticsJSON]
AS
BEGIN
    SELECT 
        JSON_OBJECT(
            'status', 'success',
            'data', JSON_OBJECT(
                'overview', JSON_OBJECT(
                    'total_tabs', (SELECT COUNT(*) FROM [tabs] WHERE is_active = 1),
                    'total_categories', (SELECT COUNT(*) FROM [categories] WHERE is_active = 1),
                    'total_files', (SELECT COUNT(*) FROM [files] WHERE is_deleted = 0),
                    'total_size', (SELECT SUM(file_size) FROM [files] WHERE is_deleted = 0),
                    'total_size_display', (
                        SELECT CASE 
                            WHEN SUM(file_size) > 1048576 THEN CAST(SUM(file_size) / 1048576.0 AS DECIMAL(10,2)) + ' MB'
                            WHEN SUM(file_size) > 1024 THEN CAST(SUM(file_size) / 1024.0 AS DECIMAL(10,2)) + ' KB'
                            ELSE CAST(SUM(file_size) AS VARCHAR) + ' bytes'
                        END
                        FROM [files] WHERE is_deleted = 0
                    ),
                    'total_downloads', (SELECT SUM(download_count) FROM [files] WHERE is_deleted = 0),
                    'active_users', (SELECT COUNT(DISTINCT uploaded_by) FROM [files] WHERE is_deleted = 0)
                ),
                'by_tab', (
                    SELECT 
                        JSON_OBJECT(
                            'tab_name', t.tab_name,
                            'file_count', COUNT(f.file_id),
                            'total_size', SUM(f.file_size),
                            'total_size_display', CASE 
                                WHEN SUM(f.file_size) > 1048576 THEN CAST(SUM(f.file_size) / 1048576.0 AS DECIMAL(10,2)) + ' MB'
                                WHEN SUM(f.file_size) > 1024 THEN CAST(SUM(f.file_size) / 1024.0 AS DECIMAL(10,2)) + ' KB'
                                ELSE CAST(SUM(f.file_size) AS VARCHAR) + ' bytes'
                            END,
                            'download_count', SUM(f.download_count),
                            'latest_upload', MAX(f.upload_date)
                        )
                    FROM [tabs] t
                    LEFT JOIN [categories] c ON t.tab_id = c.tab_id
                    LEFT JOIN [files] f ON c.category_id = f.category_id AND f.is_deleted = 0
                    WHERE t.is_active = 1
                    GROUP BY t.tab_id, t.tab_name
                    ORDER BY t.sort_order
                    FOR JSON PATH
                ),
                'by_department', (
                    SELECT 
                        JSON_OBJECT(
                            'department_name', d.department_name,
                            'file_count', COUNT(f.file_id),
                            'total_size', SUM(f.file_size),
                            'employee_count', COUNT(DISTINCT f.uploaded_by),
                            'download_count', SUM(f.download_count)
                        )
                    FROM [departments] d
                    LEFT JOIN [files] f ON d.department_id = f.department_id AND f.is_deleted = 0
                    WHERE d.is_active = 1
                    GROUP BY d.department_id, d.department_name
                    HAVING COUNT(f.file_id) > 0
                    ORDER BY COUNT(f.file_id) DESC
                    FOR JSON PATH
                )
            )
        ) AS json_result;
END
GO

-- =============================================
-- 5. DEMO CHẠY CÁC PROCEDURES
-- =============================================
PRINT N'=== DEMO JSON OUTPUT ===';

-- Lấy data Tab A
PRINT N'1. Tab A Data:';
EXEC [sp_GetTabDataJSON] 'TAB_A';

-- Lấy data Tab B
PRINT N'2. Tab B Data:';
EXEC [sp_GetTabDataJSON] 'TAB_B';

-- Lấy files của Tab A - Mục B
PRINT N'3. Tab A - Mục B Files:';
EXEC [sp_GetCategoryFilesJSON] 'TAB_A', 'B';

-- Lấy thống kê
PRINT N'4. Statistics:';
EXEC [sp_GetStatisticsJSON];

PRINT N'=== HƯỚNG DẪN SỬ DỤNG ===';
PRINT N'1. Chạy [sp_GetTabDataJSON] ''TAB_A'' để lấy JSON của Tab A';
PRINT N'2. Chạy [sp_GetTabDataJSON] ''TAB_B'' để lấy JSON của Tab B';
PRINT N'3. Chạy [sp_GetCategoryFilesJSON] ''TAB_A'', ''B'' để lấy files của mục B trong Tab A';
PRINT N'4. Chạy [sp_GetStatisticsJSON] để lấy thống kê tổng quan';
PRINT N'5. Tất cả output đều ở định dạng JSON chuẩn';
