-- =============================================
-- Sample Data for File Management System
-- =============================================

USE FileManagementDB;
GO

-- =============================================
-- 1. INSERT TABS DATA
-- =============================================
INSERT INTO [tabs] ([tab_code], [tab_name], [tab_description], [sort_order]) VALUES
('TAB_A', 'Tab A - Tài liệu hành chính', 'Quản lý các tài liệu hành chính', 1),
('TAB_B', 'Tab B - Tài liệu kỹ thuật', 'Quản lý các tài liệu kỹ thuật', 2);

-- =============================================
-- 2. INSERT CATEGORIES DATA
-- =============================================
-- Categories for Tab A
INSERT INTO [categories] ([tab_id], [category_code], [category_name], [category_description], [sort_order]) VALUES
(1, 'B', 'Mục B - Báo cáo', 'Các báo cáo định kỳ', 1),
(1, 'C', 'Mục C - Công văn', 'Công văn đi và đến', 2),
(1, 'D', 'Mục D - Quyết định', 'Các quyết định của lãnh đạo', 3),
(1, 'C2', 'Mục C - Chỉ thị', 'Các chỉ thị từ cấp trên', 4);

-- Categories for Tab B
INSERT INTO [categories] ([tab_id], [category_code], [category_name], [category_description], [sort_order]) VALUES
(2, 'X', 'Mục X - Thiết kế', 'Bản vẽ thiết kế kỹ thuật', 1),
(2, 'V', 'Mục V - Vận hành', 'Tài liệu vận hành thiết bị', 2),
(2, 'E', 'Mục E - Bảo trì', 'Tài liệu bảo trì và sửa chữa', 3),
(2, 'B2', 'Mục B - Biên bản', 'Biên bản kiểm tra kỹ thuật', 4);

-- =============================================
-- 3. INSERT DEPARTMENTS DATA
-- =============================================
INSERT INTO [departments] ([department_code], [department_name], [description]) VALUES
('IT', 'Phòng Công nghệ thông tin', 'Quản lý hệ thống thông tin'),
('HR', 'Phòng Nhân sự', 'Quản lý nhân lực'),
('FINANCE', 'Phòng Tài chính', 'Quản lý tài chính kế toán'),
('TECH', 'Phòng Kỹ thuật', 'Phòng kỹ thuật và sản xuất'),
('ADMIN', 'Phòng Hành chính', 'Quản lý hành chính tổng hợp');

-- =============================================
-- 4. INSERT EMPLOYEES DATA
-- =============================================
INSERT INTO [employees] ([employee_code], [full_name], [email], [phone], [position], [department_id]) VALUES
('EMP001', 'Nguyễn Văn An', 'an.nguyen@company.com', '0901234567', 'Trưởng phòng IT', 1),
('EMP002', 'Trần Thị Bình', 'binh.tran@company.com', '0901234568', 'Chuyên viên HR', 2),
('EMP003', 'Lê Văn Cường', 'cuong.le@company.com', '0901234569', 'Kế toán trưởng', 3),
('EMP004', 'Phạm Thị Dung', 'dung.pham@company.com', '0901234570', 'Kỹ sư kỹ thuật', 4),
('EMP005', 'Hoàng Văn Em', 'em.hoang@company.com', '0901234571', 'Chuyên viên hành chính', 5),
('EMP006', 'Vũ Thị Phương', 'phuong.vu@company.com', '0901234572', 'Lập trình viên', 1),
('EMP007', 'Đỗ Văn Giang', 'giang.do@company.com', '0901234573', 'Nhân viên HR', 2);

-- =============================================
-- 5. INSERT FILES DATA
-- =============================================
-- Files for Tab A
INSERT INTO [files] ([tab_id], [category_id], [file_name], [original_filename], [file_extension], [file_size], [mime_type], [file_path], [uploaded_by], [department_id], [description], [is_active]) VALUES
-- Tab A - Mục B (Báo cáo)
(1, 1, 'Báo cáo tháng 1-2024', 'bao-cao-thang-1-2024.pdf', '.pdf', 1024000, 'application/pdf', '/files/tab_a/b/bao-cao-thang-1-2024.pdf', 2, 2, 'Báo cáo tổng kết tháng 1/2024', 1),
(1, 1, 'Báo cáo tháng 2-2024', 'bao-cao-thang-2-2024.pdf', '.pdf', 1124000, 'application/pdf', '/files/tab_a/b/bao-cao-thang-2-2024.pdf', 2, 2, 'Báo cáo tổng kết tháng 2/2024', 1),

-- Tab A - Mục C (Công văn)
(1, 2, 'Công văn 001/2024', 'cong-van-001-2024.docx', '.docx', 512000, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', '/files/tab_a/c/cong-van-001-2024.docx', 5, 5, 'Công văn về tổ chức cuộc họp', 1),
(1, 2, 'Công văn 002/2024', 'cong-van-002-2024.docx', '.docx', 612000, 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', '/files/tab_a/c/cong-van-002-2024.docx', 5, 5, 'Công văn về quy định mới', 0),

-- Tab A - Mục D (Quyết định)
(1, 3, 'Quyết định 01/2024', 'quyet-dinh-01-2024.pdf', '.pdf', 824000, 'application/pdf', '/files/tab_a/d/quyet-dinh-01-2024.pdf', 5, 5, 'Quyết định bổ nhiệm cán bộ', 1),

-- Tab B - Mục X (Thiết kế)
(2, 5, 'Bản vẽ thiết kế A01', 'thiet-ke-a01.dwg', '.dwg', 2048000, 'application/acad', '/files/tab_b/x/thiet-ke-a01.dwg', 4, 4, 'Bản vẽ thiết kế sản phẩm A01', 1),
(2, 5, 'Bản vẽ thiết kế A02', 'thiet-ke-a02.dwg', '.dwg', 2248000, 'application/acad', '/files/tab_b/x/thiet-ke-a02.dwg', 4, 4, 'Bản vẽ thiết kế sản phẩm A02', 1),

-- Tab B - Mục V (Vận hành)
(2, 6, 'Hướng dẫn vận hành máy X1', 'van-hanh-may-x1.pdf', '.pdf', 1512000, 'application/pdf', '/files/tab_b/v/van-hanh-may-x1.pdf', 4, 4, 'Hướng dẫn vận hành máy X1', 1),

-- Tab B - Mục E (Bảo trì)
(2, 7, 'Lịch bảo trì Q1-2024', 'lich-bao-tri-q1-2024.xlsx', '.xlsx', 256000, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', '/files/tab_b/e/lich-bao-tri-q1-2024.xlsx', 4, 4, 'Lịch bảo trì quý 1/2024', 0);

-- =============================================
-- 6. INSERT FILE_ACTIONS DATA
-- =============================================
INSERT INTO [file_actions] ([file_id], [action_type], [performed_by], [action_date], [notes]) VALUES
-- Upload actions
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 1-2024'), 'UPLOAD', 2, '2024-01-15 09:00:00', 'Upload báo cáo tháng 1'),
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 2-2024'), 'UPLOAD', 2, '2024-02-15 09:00:00', 'Upload báo cáo tháng 2'),
((SELECT file_id FROM [files] WHERE file_name = 'Công văn 001/2024'), 'UPLOAD', 5, '2024-01-10 14:30:00', 'Upload công văn 001'),
((SELECT file_id FROM [files] WHERE file_name = 'Bản vẽ thiết kế A01'), 'UPLOAD', 4, '2024-01-20 10:15:00', 'Upload bản vẽ thiết kế A01'),

-- Download actions
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 1-2024'), 'DOWNLOAD', 1, '2024-01-16 15:30:00', 'Download để xem xét'),
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 1-2024'), 'DOWNLOAD', 3, '2024-01-17 11:00:00', 'Download để phân tích'),
((SELECT file_id FROM [files] WHERE file_name = 'Công văn 001/2024'), 'DOWNLOAD', 1, '2024-01-11 08:45:00', 'Download để xử lý'),
((SELECT file_id FROM [files] WHERE file_name = 'Bản vẽ thiết kế A01'), 'DOWNLOAD', 1, '2024-01-21 16:20:00', 'Download để kiểm tra');

-- =============================================
-- 7. INSERT FILE_PERMISSIONS DATA
-- =============================================
INSERT INTO [file_permissions] ([file_id], [department_id], [permission_type], [granted_by]) VALUES
-- Phòng HR có quyền đọc tất cả báo cáo
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 1-2024'), 2, 'READ', 1),
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 2-2024'), 2, 'READ', 1),

-- Phòng IT có quyền đọc tất cả file
((SELECT file_id FROM [files] WHERE file_name = 'Báo cáo tháng 1-2024'), 1, 'FULL', 1),
((SELECT file_id FROM [files] WHERE file_name = 'Công văn 001/2024'), 1, 'FULL', 1),
((SELECT file_id FROM [files] WHERE file_name = 'Bản vẽ thiết kế A01'), 1, 'FULL', 1),

-- Phòng Kỹ thuật có quyền đầy đủ với file kỹ thuật
((SELECT file_id FROM [files] WHERE file_name = 'Bản vẽ thiết kế A01'), 4, 'FULL', 1),
((SELECT file_id FROM [files] WHERE file_name = 'Bản vẽ thiết kế A02'), 4, 'FULL', 1),
((SELECT file_id FROM [files] WHERE file_name = 'Hướng dẫn vận hành máy X1'), 4, 'FULL', 1);

-- Update download count
UPDATE [files] SET [download_count] = 2 WHERE [file_name] = 'Báo cáo tháng 1-2024';
UPDATE [files] SET [download_count] = 1 WHERE [file_name] = 'Công văn 001/2024';
UPDATE [files] SET [download_count] = 1 WHERE [file_name] = 'Bản vẽ thiết kế A01';

PRINT 'Sample data inserted successfully!';
PRINT 'Data summary:';
PRINT '- 2 Tabs (A, B)';
PRINT '- 8 Categories (4 per tab)';
PRINT '- 5 Departments';
PRINT '- 7 Employees';
PRINT '- 9 Files';
PRINT '- 8 File Actions';
PRINT '- 7 File Permissions';
