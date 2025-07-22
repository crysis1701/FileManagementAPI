-- =============================================
-- TICKET MANAGEMENT SYSTEM SAMPLE DATA
-- Dữ liệu mẫu cho hệ thống Ticket Management
-- =============================================

USE TicketManagementDB;
GO

-- =============================================
-- 1. MASTER DATA - 4 ComboBoxes
-- =============================================

-- Transaction Types (Loại giao dịch)
INSERT INTO [transaction_types] ([code], [name], [description]) VALUES
('PAYMENT', N'Thanh toán', N'Các giao dịch thanh toán'),
('TRANSFER', N'Chuyển tiền', N'Các giao dịch chuyển tiền'),
('WITHDRAW', N'Rút tiền', N'Các giao dịch rút tiền'),
('DEPOSIT', N'Nạp tiền', N'Các giao dịch nạp tiền'),
('EXCHANGE', N'Đổi tiền', N'Các giao dịch đổi tiền tệ');

-- Partners (Đối tác)
INSERT INTO [partners] ([code], [name], [contact_info], [partner_type]) VALUES
('VCB', N'Ngân hàng Vietcombank', N'Hotline: 1900-545-413', 'BANK'),
('TCB', N'Ngân hàng Techcombank', N'Hotline: 1800-588-822', 'BANK'),
('MB', N'Ngân hàng MBBank', N'Hotline: 1900-545-422', 'BANK'),
('VNPAY', N'Ví điện tử VNPay', N'Support: support@vnpay.vn', 'COMPANY'),
('MOMO', N'Ví điện tử MoMo', N'Hotline: 1900-545-441', 'COMPANY'),
('COMPANY_A', N'Công ty ABC', N'Email: contact@abc.com', 'COMPANY');

-- Flows (Luồng)
INSERT INTO [flows] ([code], [name], [description], [flow_type]) VALUES
('NORMAL', N'Luồng thường', N'Quy trình xử lý thông thường', 'NORMAL'),
('EXPRESS', N'Luồng nhanh', N'Quy trình xử lý nhanh', 'EXPRESS'),
('URGENT', N'Luồng khẩn cấp', N'Quy trình xử lý khẩn cấp', 'URGENT'),
('BATCH', N'Luồng hàng loạt', N'Quy trình xử lý hàng loạt', 'BATCH'),
('MANUAL', N'Luồng thủ công', N'Quy trình xử lý thủ công', 'MANUAL');

-- Issuing Organizations (Tổ chức phát hành)
INSERT INTO [issuing_organizations] ([code], [name], [organization_type], [contact_info]) VALUES
('SBV', N'Ngân hàng Nhà nước Việt Nam', 'GOVERNMENT', N'Website: sbv.gov.vn'),
('VISA', N'Visa International', 'COMPANY', N'Website: visa.com'),
('MASTERCARD', N'Mastercard', 'COMPANY', N'Website: mastercard.com'),
('JCB', N'Japan Credit Bureau', 'COMPANY', N'Website: jcb.com'),
('NAPAS', N'Công ty NAPAS', 'COMPANY', N'Website: napas.com.vn'),
('INTERNAL', N'Tổ chức nội bộ', 'INTERNAL', N'Internal organization');

-- =============================================
-- 2. DEPARTMENTS & USERS
-- =============================================

-- Departments
INSERT INTO [departments] ([code], [name], [description]) VALUES
('IT', N'Phòng Công nghệ thông tin', N'Phòng ban IT'),
('FINANCE', N'Phòng Tài chính', N'Phòng ban tài chính'),
('OPERATIONS', N'Phòng Vận hành', N'Phòng ban vận hành'),
('RISK', N'Phòng Kiểm soát rủi ro', N'Phòng kiểm soát rủi ro'),
('COMPLIANCE', N'Phòng Tuân thủ', N'Phòng tuân thủ');

-- Users
INSERT INTO [users] ([username], [email], [password_hash], [full_name], [employee_code], [department_id], [role]) VALUES
-- Admin
('admin', 'admin@company.com', 'hashed_password_admin', N'Administrator', 'EMP001', 1, 'ADMIN'),

-- IT Department
('dev001', 'dev001@company.com', 'hashed_password_dev', N'Nguyễn Văn Developer', 'EMP002', 1, 'USER'),
('it_manager', 'it.manager@company.com', 'hashed_password_itm', N'Trần Thị IT Manager', 'EMP003', 1, 'APPROVER'),

-- Finance Department  
('fin001', 'fin001@company.com', 'hashed_password_fin', N'Lê Văn Finance', 'EMP004', 2, 'USER'),
('fin_controller', 'fin.controller@company.com', 'hashed_password_finc', N'Phạm Thị Controller', 'EMP005', 2, 'CONTROLLER'),
('fin_manager', 'fin.manager@company.com', 'hashed_password_finm', N'Hoàng Văn Finance Manager', 'EMP006', 2, 'APPROVER'),

-- Operations Department
('ops001', 'ops001@company.com', 'hashed_password_ops', N'Đỗ Thị Operations', 'EMP007', 3, 'USER'),
('ops_controller', 'ops.controller@company.com', 'hashed_password_opsc', N'Vũ Văn Ops Controller', 'EMP008', 3, 'CONTROLLER'),

-- Risk Department
('risk001', 'risk001@company.com', 'hashed_password_risk', N'Bùi Thị Risk', 'EMP009', 4, 'USER'),
('risk_controller', 'risk.controller@company.com', 'hashed_password_riskc', N'Ngô Văn Risk Controller', 'EMP010', 4, 'CONTROLLER');

-- =============================================
-- 3. FILE CATEGORIES
-- =============================================

INSERT INTO [file_categories] ([code], [name], [category_type], [description], [is_required], [max_file_size_mb]) VALUES
-- Tác nghiệp
('CONTRACT', N'Hợp đồng', 'TAC_NGHIEP', N'Các file hợp đồng liên quan', 1, 20),
('INVOICE', N'Hóa đơn', 'TAC_NGHIEP', N'Hóa đơn thanh toán', 1, 10),
('RECEIPT', N'Biên lai', 'TAC_NGHIEP', N'Biên lai giao dịch', 0, 10),
('AUTHORIZATION', N'Giấy ủy quyền', 'TAC_NGHIEP', N'Giấy ủy quyền thực hiện giao dịch', 1, 5),
('BANK_STATEMENT', N'Sao kê ngân hàng', 'TAC_NGHIEP', N'Sao kê tài khoản ngân hàng', 1, 15),

-- Không tác nghiệp
('ID_COPY', N'Bản sao CMND/CCCD', 'KHONG_TAC_NGHIEP', N'Bản sao giấy tờ tùy thân', 1, 5),
('PHOTO', N'Ảnh minh chứng', 'KHONG_TAC_NGHIEP', N'Ảnh chụp hiện trường, minh chứng', 0, 20),
('EMAIL_SCREENSHOT', N'Ảnh chụp email', 'KHONG_TAC_NGHIEP', N'Screenshot email liên quan', 0, 5),
('OTHER_DOC', N'Tài liệu khác', 'KHONG_TAC_NGHIEP', N'Các tài liệu khác', 0, 10),

-- Khác
('SYSTEM_LOG', N'Log hệ thống', 'OTHER', N'File log từ hệ thống', 0, 50),
('REPORT', N'Báo cáo', 'OTHER', N'Các file báo cáo', 0, 30);

-- =============================================
-- 4. WORKFLOW TEMPLATES
-- =============================================

-- Template 1: PAYMENT + VCB + NORMAL + SBV (Thanh toán VCB thường)
INSERT INTO [workflow_templates] ([template_name], [template_code], [transaction_type_id], [partner_id], [flow_id], [issuing_organization_id], [description], [is_default], [priority], [created_by])
VALUES (N'Quy trình thanh toán VCB thường', 'PAYMENT_VCB_NORMAL_SBV', 1, 1, 1, 1, N'Quy trình thanh toán qua VCB luồng thường của SBV', 0, 1, 1);

-- Template 2: TRANSFER + EXPRESS (Chuyển tiền nhanh - áp dụng cho tất cả partner)
INSERT INTO [workflow_templates] ([template_name], [template_code], [transaction_type_id], [partner_id], [flow_id], [issuing_organization_id], [description], [is_default], [priority], [created_by])
VALUES (N'Quy trình chuyển tiền nhanh', 'TRANSFER_EXPRESS', 2, NULL, 2, NULL, N'Quy trình chuyển tiền luồng nhanh cho tất cả đối tác', 0, 2, 1);

-- Template 3: Default template (áp dụng khi không match template nào)
INSERT INTO [workflow_templates] ([template_name], [template_code], [transaction_type_id], [partner_id], [flow_id], [issuing_organization_id], [description], [is_default], [priority], [created_by])
VALUES (N'Quy trình mặc định', 'DEFAULT_WORKFLOW', NULL, NULL, NULL, NULL, N'Quy trình mặc định cho các trường hợp không có template riêng', 1, 999, 1);

-- =============================================
-- 5. WORKFLOW STEPS
-- =============================================

-- Steps cho Template 1: PAYMENT_VCB_NORMAL_SBV
INSERT INTO [workflow_steps] ([template_id], [step_name], [step_code], [step_order], [step_type], [required_role], [required_department], [auto_proceed], [timeout_hours], [can_upload_files], [can_delete_files], [description])
VALUES 
(1, N'Khởi tạo', 'INITIATE', 1, 'INITIATE', 'USER', NULL, 1, NULL, 1, 1, N'Khởi tạo ticket và upload file ban đầu'),
(1, N'Chuyển kiểm soát', 'TRANSFER_CONTROL', 2, 'TRANSFER_CONTROL', 'USER', NULL, 0, 24, 1, 0, N'Chuyển ticket cho bộ phận kiểm soát'),
(1, N'Kiểm soát tài chính', 'CONTROL_FINANCE', 3, 'CONTROL_APPROVAL', 'CONTROLLER', 'FINANCE', 0, 48, 1, 0, N'Kiểm soát bởi phòng tài chính'),
(1, N'Phê duyệt', 'APPROVE', 4, 'APPROVE', 'APPROVER', 'FINANCE', 0, 24, 0, 0, N'Phê duyệt cuối cùng'),
(1, N'Hoàn thành', 'COMPLETE', 5, 'COMPLETE', NULL, NULL, 1, NULL, 0, 0, N'Hoàn thành quy trình');

-- Steps cho Template 2: TRANSFER_EXPRESS
INSERT INTO [workflow_steps] ([template_id], [step_name], [step_code], [step_order], [step_type], [required_role], [required_department], [auto_proceed], [timeout_hours], [can_upload_files], [can_delete_files], [description])
VALUES 
(2, N'Khởi tạo nhanh', 'INITIATE', 1, 'INITIATE', 'USER', NULL, 1, NULL, 1, 1, N'Khởi tạo ticket chuyển tiền nhanh'),
(2, N'Kiểm soát nhanh', 'CONTROL_EXPRESS', 2, 'CONTROL_APPROVAL', 'CONTROLLER', 'OPERATIONS', 0, 12, 1, 0, N'Kiểm soát nhanh bởi phòng vận hành'),
(2, N'Phê duyệt nhanh', 'APPROVE_EXPRESS', 3, 'APPROVE', 'APPROVER', NULL, 0, 6, 0, 0, N'Phê duyệt nhanh'),
(2, N'Hoàn thành', 'COMPLETE', 4, 'COMPLETE', NULL, NULL, 1, NULL, 0, 0, N'Hoàn thành quy trình');

-- Steps cho Template 3: DEFAULT_WORKFLOW
INSERT INTO [workflow_steps] ([template_id], [step_name], [step_code], [step_order], [step_type], [required_role], [required_department], [auto_proceed], [timeout_hours], [can_upload_files], [can_delete_files], [description])
VALUES 
(3, N'Khởi tạo', 'INITIATE', 1, 'INITIATE', 'USER', NULL, 1, NULL, 1, 1, N'Khởi tạo ticket mặc định'),
(3, N'Chuyển kiểm soát', 'TRANSFER_CONTROL', 2, 'TRANSFER_CONTROL', 'USER', NULL, 0, 48, 1, 0, N'Chuyển cho kiểm soát'),
(3, N'Kiểm soát', 'CONTROL', 3, 'CONTROL_APPROVAL', 'CONTROLLER', NULL, 0, 72, 1, 0, N'Kiểm soát chung'),
(3, N'Phê duyệt', 'APPROVE', 4, 'APPROVE', 'APPROVER', NULL, 0, 48, 0, 0, N'Phê duyệt'),
(3, N'Hoàn thành', 'COMPLETE', 5, 'COMPLETE', NULL, NULL, 1, NULL, 0, 0, N'Hoàn thành quy trình');

-- =============================================
-- 6. ROLE PERMISSIONS MATRIX
-- =============================================

-- Permissions cho Template 1 (PAYMENT_VCB_NORMAL_SBV)
-- Step 1: INITIATE - USER có thể làm tất cả
INSERT INTO [role_permissions] ([workflow_step_id], [role], [department_id], [can_view], [can_edit], [can_upload_files], [can_delete_files], [can_approve], [can_reject])
VALUES 
(1, 'USER', NULL, 1, 1, 1, 1, 1, 0),
(1, 'ADMIN', NULL, 1, 1, 1, 1, 1, 1);

-- Step 2: TRANSFER_CONTROL - USER submit, CONTROLLER có thể xem
INSERT INTO [role_permissions] ([workflow_step_id], [role], [department_id], [can_view], [can_edit], [can_upload_files], [can_delete_files], [can_approve], [can_reject])
VALUES 
(2, 'USER', NULL, 1, 1, 1, 0, 1, 0),
(2, 'CONTROLLER', 2, 1, 0, 0, 0, 0, 0), -- Finance controller có thể xem
(2, 'ADMIN', NULL, 1, 1, 1, 1, 1, 1);

-- Step 3: CONTROL_FINANCE - CONTROLLER Finance làm chủ
INSERT INTO [role_permissions] ([workflow_step_id], [role], [department_id], [can_view], [can_edit], [can_upload_files], [can_delete_files], [can_approve], [can_reject])
VALUES 
(3, 'USER', NULL, 1, 0, 0, 0, 0, 0), -- User chỉ xem, KHÔNG được delete file
(3, 'CONTROLLER', 2, 1, 1, 1, 1, 1, 1), -- Finance controller có quyền DELETE file của user khác
(3, 'APPROVER', 2, 1, 0, 0, 0, 0, 0), -- Finance approver xem trước
(3, 'ADMIN', NULL, 1, 1, 1, 1, 1, 1);

-- Step 4: APPROVE - APPROVER Finance quyết định
INSERT INTO [role_permissions] ([workflow_step_id], [role], [department_id], [can_view], [can_edit], [can_upload_files], [can_delete_files], [can_approve], [can_reject])
VALUES 
(4, 'USER', NULL, 1, 0, 0, 0, 0, 0),
(4, 'CONTROLLER', 2, 1, 0, 0, 0, 0, 0),
(4, 'APPROVER', 2, 1, 1, 0, 0, 1, 1), -- Finance approver có quyền approve/reject
(4, 'ADMIN', NULL, 1, 1, 1, 1, 1, 1);

-- Step 5: COMPLETE - Tất cả chỉ xem
INSERT INTO [role_permissions] ([workflow_step_id], [role], [department_id], [can_view], [can_edit], [can_upload_files], [can_delete_files], [can_approve], [can_reject])
VALUES 
(5, 'USER', NULL, 1, 0, 0, 0, 0, 0),
(5, 'CONTROLLER', NULL, 1, 0, 0, 0, 0, 0),
(5, 'APPROVER', NULL, 1, 0, 0, 0, 0, 0),
(5, 'ADMIN', NULL, 1, 1, 1, 1, 1, 1);

-- Tương tự cho các template khác (Template 2, 3)...
-- (Có thể thêm sau khi cần thiết)

-- =============================================
-- 7. SAMPLE TICKETS & STATUS HISTORY
-- =============================================

-- Tạo một số ticket mẫu để test
INSERT INTO [tickets] ([ticket_code], [title], [description], [transaction_type_id], [partner_id], [flow_id], [issuing_organization_id], [workflow_template_id], [current_step_id], [current_status], [priority], [created_by], [assigned_to], [department_id])
VALUES 
-- Ticket 1: Đang ở step CONTROL_FINANCE (step 3)
('TK2025001', N'Thanh toán VCB cho khách hàng ABC', N'Xử lý thanh toán qua VCB cho giao dịch của khách hàng ABC', 1, 1, 1, 1, 1, 3, 'IN_PROGRESS', 'HIGH', 4, 5, 2),

-- Ticket 2: Đã hoàn thành
('TK2025002', N'Chuyển tiền nhanh cho đối tác XYZ', N'Chuyển tiền nhanh qua luồng express', 2, 2, 2, 2, 2, 4, 'COMPLETED', 'MEDIUM', 7, NULL, 3),

-- Ticket 3: Mới khởi tạo
('TK2025003', N'Rút tiền ATM khách hàng DEF', N'Xử lý giao dịch rút tiền ATM', 3, 3, 1, 1, 3, 1, 'PENDING', 'LOW', 9, 10, 4);

-- Bảng lịch sử chuyển trạng thái
INSERT INTO [status_history] ([ticket_id], [from_status], [to_status], [from_step_id], [to_step_id], [changed_by], [change_reason], [comments])
VALUES 
-- Lịch sử cho Ticket 1 (TK2025001)
(1, 'DRAFT', 'PENDING', NULL, 1, 4, 'WORKFLOW_PROGRESSION', N'Khởi tạo ticket thanh toán VCB'),
(1, 'PENDING', 'IN_PROGRESS', 1, 2, 4, 'WORKFLOW_PROGRESSION', N'Chuyển sang bước transfer control'),
(1, 'IN_PROGRESS', 'IN_PROGRESS', 2, 3, 4, 'WORKFLOW_PROGRESSION', N'Chuyển sang bước kiểm soát tài chính'),

-- Lịch sử cho Ticket 2 (TK2025002) - Đã hoàn thành
(2, 'DRAFT', 'PENDING', NULL, 1, 7, 'WORKFLOW_PROGRESSION', N'Khởi tạo ticket chuyển tiền nhanh'),
(2, 'PENDING', 'IN_PROGRESS', 1, 2, 7, 'WORKFLOW_PROGRESSION', N'Chuyển sang bước kiểm soát nhanh'),
(2, 'IN_PROGRESS', 'APPROVED', 2, 3, 8, 'APPROVAL', N'Kiểm soát viên Operations phê duyệt'),
(2, 'APPROVED', 'COMPLETED', 3, 4, 8, 'WORKFLOW_PROGRESSION', N'Hoàn thành quy trình chuyển tiền'),

-- Lịch sử cho Ticket 3 (TK2025003) - Mới khởi tạo
(3, 'DRAFT', 'PENDING', NULL, 1, 9, 'WORKFLOW_PROGRESSION', N'Khởi tạo ticket rút tiền ATM');

-- Thêm một số lịch sử reject/revision mẫu
INSERT INTO [status_history] ([ticket_id], [from_status], [to_status], [from_step_id], [to_step_id], [changed_by], [change_reason], [comments])
VALUES 
-- Ticket bị reject và phải sửa lại
(1, 'IN_PROGRESS', 'REVISION_REQUIRED', 3, 2, 5, 'REJECTION', N'Thiếu tài liệu hợp đồng, yêu cầu bổ sung'),
(1, 'REVISION_REQUIRED', 'IN_PROGRESS', 2, 3, 4, 'RESUBMISSION', N'Đã bổ sung tài liệu theo yêu cầu');

-- =============================================
-- 8. SAMPLE TICKET FILES
-- =============================================

-- File cho Ticket 1
INSERT INTO [ticket_files] ([ticket_id], [file_category_id], [original_filename], [stored_filename], [file_path], [file_size_bytes], [mime_type], [uploaded_by], [upload_step_id])
VALUES 
(1, 1, 'hop_dong_ABC.pdf', 'tk2025001_contract_001.pdf', '/uploads/2025/01/', 2048576, 'application/pdf', 4, 1),
(1, 2, 'hoa_don_thanh_toan.pdf', 'tk2025001_invoice_001.pdf', '/uploads/2025/01/', 1024000, 'application/pdf', 4, 1),
(1, 6, 'cmnd_chu_tai_khoan.jpg', 'tk2025001_id_001.jpg', '/uploads/2025/01/', 512000, 'image/jpeg', 4, 1);

-- File cho Ticket 2
INSERT INTO [ticket_files] ([ticket_id], [file_category_id], [original_filename], [stored_filename], [file_path], [file_size_bytes], [mime_type], [uploaded_by], [upload_step_id])
VALUES 
(2, 4, 'uy_quyen_chuyen_tien.pdf', 'tk2025002_auth_001.pdf', '/uploads/2025/01/', 1536000, 'application/pdf', 7, 1),
(2, 5, 'sao_ke_ngan_hang.pdf', 'tk2025002_statement_001.pdf', '/uploads/2025/01/', 3072000, 'application/pdf', 7, 1);

-- File cho Ticket 3
INSERT INTO [ticket_files] ([ticket_id], [file_category_id], [original_filename], [stored_filename], [file_path], [file_size_bytes], [mime_type], [uploaded_by], [upload_step_id])
VALUES 
(3, 6, 'cccd_khach_hang.jpg', 'tk2025003_id_001.jpg', '/uploads/2025/01/', 768000, 'image/jpeg', 9, 1),
(3, 7, 'anh_atm_error.jpg', 'tk2025003_photo_001.jpg', '/uploads/2025/01/', 2560000, 'image/jpeg', 9, 1);

PRINT 'Ticket Management System Sample Data inserted successfully!';
PRINT 'Created:';
PRINT '- 5 Transaction Types';
PRINT '- 6 Partners'; 
PRINT '- 5 Flows';
PRINT '- 6 Issuing Organizations';
PRINT '- 5 Departments';
PRINT '- 10 Users';
PRINT '- 11 File Categories';
PRINT '- 3 Workflow Templates';
PRINT '- 14 Workflow Steps';
PRINT '- Role Permission Matrix configured';
PRINT '- 3 Sample Tickets';
PRINT '- 7 Status History Records';
PRINT '- 7 Sample Ticket Files';
