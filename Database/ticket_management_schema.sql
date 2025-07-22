-- =============================================
-- TICKET MANAGEMENT SYSTEM DATABASE SCHEMA
-- Dynamic Workflow based on 4 ComboBoxes
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TicketManagementDB')
BEGIN
    CREATE DATABASE TicketManagementDB
    COLLATE SQL_Latin1_General_CP1_CI_AS;
END
GO

USE TicketManagementDB;
GO

-- =============================================
-- 1. MASTER DATA TABLES - Dữ liệu cho 4 ComboBoxes
-- =============================================

-- Loại giao dịch
CREATE TABLE [transaction_types] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [code] NVARCHAR(20) NOT NULL UNIQUE,
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(500),
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Đối tác
CREATE TABLE [partners] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [code] NVARCHAR(20) NOT NULL UNIQUE,
    [name] NVARCHAR(100) NOT NULL,
    [contact_info] NVARCHAR(500),
    [partner_type] NVARCHAR(50), -- BANK, COMPANY, INDIVIDUAL, etc.
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Luồng
CREATE TABLE [flows] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [code] NVARCHAR(20) NOT NULL UNIQUE,
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(500),
    [flow_type] NVARCHAR(50), -- NORMAL, EXPRESS, URGENT, etc.
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Tổ chức phát hành
CREATE TABLE [issuing_organizations] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [code] NVARCHAR(20) NOT NULL UNIQUE,
    [name] NVARCHAR(100) NOT NULL,
    [organization_type] NVARCHAR(50), -- BANK, GOVERNMENT, COMPANY, etc.
    [contact_info] NVARCHAR(500),
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- =============================================
-- 2. WORKFLOW CONFIGURATION TABLES
-- =============================================

-- Workflow Templates - Dynamic dựa trên 4 combobox
CREATE TABLE [workflow_templates] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [template_name] NVARCHAR(200) NOT NULL,
    [template_code] NVARCHAR(50) NOT NULL UNIQUE,
    
    -- Điều kiện áp dụng template (có thể NULL = áp dụng cho tất cả)
    [transaction_type_id] INT NULL,
    [partner_id] INT NULL,
    [flow_id] INT NULL,
    [issuing_organization_id] INT NULL,
    
    [description] NVARCHAR(1000),
    [is_default] BIT NOT NULL DEFAULT 0,
    [is_active] BIT NOT NULL DEFAULT 1,
    [priority] INT NOT NULL DEFAULT 1, -- Độ ưu tiên khi match nhiều template
    [created_by] INT NOT NULL,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_workflow_templates_transaction_type] FOREIGN KEY ([transaction_type_id]) REFERENCES [transaction_types]([id]),
    CONSTRAINT [FK_workflow_templates_partner] FOREIGN KEY ([partner_id]) REFERENCES [partners]([id]),
    CONSTRAINT [FK_workflow_templates_flow] FOREIGN KEY ([flow_id]) REFERENCES [flows]([id]),
    CONSTRAINT [FK_workflow_templates_issuing_org] FOREIGN KEY ([issuing_organization_id]) REFERENCES [issuing_organizations]([id])
);

-- Workflow Steps
CREATE TABLE [workflow_steps] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [template_id] INT NOT NULL,
    [step_name] NVARCHAR(100) NOT NULL,
    [step_code] NVARCHAR(50) NOT NULL,
    [step_order] INT NOT NULL,
    [step_type] NVARCHAR(20) NOT NULL, -- INITIATE, TRANSFER_CONTROL, CONTROL_APPROVAL, APPROVE, COMPLETE
    [required_role] NVARCHAR(50), -- Role cần thiết để thực hiện bước này
    [required_department] NVARCHAR(50) NULL, -- Phòng ban cần thiết (tùy chọn)
    [auto_proceed] BIT NOT NULL DEFAULT 0, -- Tự động chuyển bước tiếp theo
    [timeout_hours] INT NULL, -- Thời gian timeout (giờ)
    [can_upload_files] BIT NOT NULL DEFAULT 1, -- Cho phép upload file ở bước này
    [can_delete_files] BIT NOT NULL DEFAULT 0, -- Cho phép xóa file ở bước này
    [description] NVARCHAR(500),
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_workflow_steps_template] FOREIGN KEY ([template_id]) REFERENCES [workflow_templates]([id]),
    CONSTRAINT [CK_workflow_steps_step_type] CHECK ([step_type] IN ('INITIATE', 'TRANSFER_CONTROL', 'CONTROL_APPROVAL', 'APPROVE', 'COMPLETE'))
);

-- =============================================
-- 3. USER & ROLE MANAGEMENT
-- =============================================

-- Departments
CREATE TABLE [departments] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [code] NVARCHAR(20) NOT NULL UNIQUE,
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(500),
    [manager_id] INT NULL,
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Users
CREATE TABLE [users] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [username] NVARCHAR(50) NOT NULL UNIQUE,
    [email] NVARCHAR(255) NOT NULL UNIQUE,
    [password_hash] NVARCHAR(500) NOT NULL,
    [full_name] NVARCHAR(100) NOT NULL,
    [employee_code] NVARCHAR(20) UNIQUE,
    [phone] NVARCHAR(20),
    [department_id] INT NOT NULL,
    [role] NVARCHAR(50) NOT NULL DEFAULT 'USER', -- USER, CONTROLLER, APPROVER, ADMIN
    [is_active] BIT NOT NULL DEFAULT 1,
    [last_login] DATETIME2 NULL,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_users_department] FOREIGN KEY ([department_id]) REFERENCES [departments]([id]),
    CONSTRAINT [CK_users_role] CHECK ([role] IN ('USER', 'CONTROLLER', 'APPROVER', 'ADMIN'))
);

-- Ma trận phân quyền - Ai có thể làm gì ở bước nào
CREATE TABLE [role_permissions] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [workflow_step_id] INT NOT NULL,
    [role] NVARCHAR(50) NOT NULL,
    [department_id] INT NULL, -- Có thể giới hạn theo phòng ban
    [can_view] BIT NOT NULL DEFAULT 1,
    [can_edit] BIT NOT NULL DEFAULT 0,
    [can_upload_files] BIT NOT NULL DEFAULT 0,
    [can_delete_files] BIT NOT NULL DEFAULT 0,
    [can_approve] BIT NOT NULL DEFAULT 0,
    [can_reject] BIT NOT NULL DEFAULT 0,
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_role_permissions_workflow_step] FOREIGN KEY ([workflow_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_role_permissions_department] FOREIGN KEY ([department_id]) REFERENCES [departments]([id]),
    CONSTRAINT [CK_role_permissions_role] CHECK ([role] IN ('USER', 'CONTROLLER', 'APPROVER', 'ADMIN'))
);

-- =============================================
-- 4. TICKET MANAGEMENT
-- =============================================

-- Main Tickets
CREATE TABLE [tickets] (
    [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [ticket_number] NVARCHAR(50) NOT NULL UNIQUE, -- Số ticket tự động sinh
    [title] NVARCHAR(200) NOT NULL,
    [description] NVARCHAR(2000),
    
    -- 4 ComboBox values
    [transaction_type_id] INT NOT NULL,
    [partner_id] INT NOT NULL,
    [flow_id] INT NOT NULL,
    [issuing_organization_id] INT NOT NULL,
    
    -- Workflow info
    [workflow_template_id] INT NOT NULL, -- Template được chọn dựa trên 4 combobox
    [current_step_id] INT NULL, -- Bước hiện tại trong workflow
    [current_status] NVARCHAR(20) NOT NULL DEFAULT 'DRAFT', -- DRAFT, INITIATED, IN_PROGRESS, APPROVED, REJECTED, COMPLETED
    
    -- Ticket info
    [priority] NVARCHAR(10) NOT NULL DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    [due_date] DATETIME2 NULL,
    [created_by] INT NOT NULL,
    [assigned_to] INT NULL, -- Người được assign xử lý hiện tại
    [department_id] INT NOT NULL,
    
    -- Timestamps
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [initiated_at] DATETIME2 NULL, -- Khi nào được khởi tạo (chuyển từ DRAFT)
    [completed_at] DATETIME2 NULL,
    
    CONSTRAINT [FK_tickets_transaction_type] FOREIGN KEY ([transaction_type_id]) REFERENCES [transaction_types]([id]),
    CONSTRAINT [FK_tickets_partner] FOREIGN KEY ([partner_id]) REFERENCES [partners]([id]),
    CONSTRAINT [FK_tickets_flow] FOREIGN KEY ([flow_id]) REFERENCES [flows]([id]),
    CONSTRAINT [FK_tickets_issuing_organization] FOREIGN KEY ([issuing_organization_id]) REFERENCES [issuing_organizations]([id]),
    CONSTRAINT [FK_tickets_workflow_template] FOREIGN KEY ([workflow_template_id]) REFERENCES [workflow_templates]([id]),
    CONSTRAINT [FK_tickets_current_step] FOREIGN KEY ([current_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_tickets_created_by] FOREIGN KEY ([created_by]) REFERENCES [users]([id]),
    CONSTRAINT [FK_tickets_assigned_to] FOREIGN KEY ([assigned_to]) REFERENCES [users]([id]),
    CONSTRAINT [FK_tickets_department] FOREIGN KEY ([department_id]) REFERENCES [departments]([id]),
    CONSTRAINT [CK_tickets_priority] CHECK ([priority] IN ('LOW', 'NORMAL', 'HIGH', 'URGENT')),
    CONSTRAINT [CK_tickets_status] CHECK ([current_status] IN ('DRAFT', 'INITIATED', 'IN_PROGRESS', 'APPROVED', 'REJECTED', 'COMPLETED'))
);

-- =============================================
-- 5. FILE MANAGEMENT
-- =============================================

-- File Categories cho Hồ sơ đính kèm
CREATE TABLE [file_categories] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [code] NVARCHAR(20) NOT NULL UNIQUE,
    [name] NVARCHAR(100) NOT NULL,
    [category_type] NVARCHAR(50) NOT NULL, -- TAC_NGHIEP, KHONG_TAC_NGHIEP, OTHER
    [description] NVARCHAR(500),
    [is_required] BIT NOT NULL DEFAULT 0, -- File bắt buộc hay không
    [max_file_size_mb] INT NOT NULL DEFAULT 10,
    [allowed_extensions] NVARCHAR(200) DEFAULT '.pdf,.doc,.docx,.xls,.xlsx,.jpg,.png', -- Các extension cho phép
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [CK_file_categories_type] CHECK ([category_type] IN ('TAC_NGHIEP', 'KHONG_TAC_NGHIEP', 'OTHER'))
);

-- Files đính kèm
CREATE TABLE [ticket_files] (
    [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [ticket_id] UNIQUEIDENTIFIER NOT NULL,
    [file_category_id] INT NOT NULL,
    [workflow_step_id] INT NULL, -- File được upload ở bước nào
    
    -- File info
    [file_name] NVARCHAR(255) NOT NULL,
    [original_filename] NVARCHAR(255) NOT NULL,
    [file_extension] NVARCHAR(10) NOT NULL,
    [file_size] BIGINT NOT NULL,
    [mime_type] NVARCHAR(100) NOT NULL,
    [file_path] NVARCHAR(1000) NOT NULL, -- Đường dẫn lưu file
    
    -- Upload info
    [uploaded_by] INT NOT NULL,
    [upload_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [description] NVARCHAR(500),
    [version] INT NOT NULL DEFAULT 1, -- Version của file (cho phép replace)
    
    -- Status
    [is_active] BIT NOT NULL DEFAULT 1,
    [is_deleted] BIT NOT NULL DEFAULT 0,
    [deleted_at] DATETIME2 NULL,
    [deleted_by] INT NULL,
    [delete_reason] NVARCHAR(500),
    
    CONSTRAINT [FK_ticket_files_ticket] FOREIGN KEY ([ticket_id]) REFERENCES [tickets]([id]),
    CONSTRAINT [FK_ticket_files_category] FOREIGN KEY ([file_category_id]) REFERENCES [file_categories]([id]),
    CONSTRAINT [FK_ticket_files_workflow_step] FOREIGN KEY ([workflow_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_ticket_files_uploaded_by] FOREIGN KEY ([uploaded_by]) REFERENCES [users]([id]),
    CONSTRAINT [FK_ticket_files_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [users]([id])
);

-- =============================================
-- 6. WORKFLOW EXECUTION
-- =============================================

-- Workflow Instances - Instance thực thi cho từng ticket
CREATE TABLE [workflow_instances] (
    [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [ticket_id] UNIQUEIDENTIFIER NOT NULL,
    [template_id] INT NOT NULL,
    [current_step_id] INT NOT NULL,
    [status] NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, COMPLETED, CANCELLED
    [started_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [completed_at] DATETIME2 NULL,
    [started_by] INT NOT NULL,
    
    CONSTRAINT [FK_workflow_instances_ticket] FOREIGN KEY ([ticket_id]) REFERENCES [tickets]([id]),
    CONSTRAINT [FK_workflow_instances_template] FOREIGN KEY ([template_id]) REFERENCES [workflow_templates]([id]),
    CONSTRAINT [FK_workflow_instances_current_step] FOREIGN KEY ([current_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_workflow_instances_started_by] FOREIGN KEY ([started_by]) REFERENCES [users]([id]),
    CONSTRAINT [CK_workflow_instances_status] CHECK ([status] IN ('ACTIVE', 'COMPLETED', 'CANCELLED'))
);

-- Workflow History - Lịch sử thực hiện workflow
CREATE TABLE [workflow_history] (
    [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [instance_id] UNIQUEIDENTIFIER NOT NULL,
    [step_id] INT NOT NULL,
    [action] NVARCHAR(20) NOT NULL, -- INITIATE, TRANSFER, APPROVE, REJECT, COMPLETE
    [performed_by] INT NOT NULL,
    [performed_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [comments] NVARCHAR(1000),
    [previous_step_id] INT NULL,
    [next_step_id] INT NULL,
    [duration_minutes] INT NULL, -- Thời gian xử lý (phút)
    [files_uploaded] INT DEFAULT 0, -- Số file upload trong action này
    
    CONSTRAINT [FK_workflow_history_instance] FOREIGN KEY ([instance_id]) REFERENCES [workflow_instances]([id]),
    CONSTRAINT [FK_workflow_history_step] FOREIGN KEY ([step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_workflow_history_performed_by] FOREIGN KEY ([performed_by]) REFERENCES [users]([id]),
    CONSTRAINT [FK_workflow_history_previous_step] FOREIGN KEY ([previous_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_workflow_history_next_step] FOREIGN KEY ([next_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [CK_workflow_history_action] CHECK ([action] IN ('INITIATE', 'TRANSFER', 'APPROVE', 'REJECT', 'RETURN', 'COMPLETE'))
);

-- =============================================
-- 7. NOTIFICATIONS & COMMENTS
-- =============================================

-- Notifications
CREATE TABLE [notifications] (
    [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [ticket_id] UNIQUEIDENTIFIER NOT NULL,
    [recipient_id] INT NOT NULL,
    [notification_type] NVARCHAR(20) NOT NULL, -- NEW_TICKET, STEP_ASSIGNED, FILE_UPLOADED, APPROVED, REJECTED
    [title] NVARCHAR(200) NOT NULL,
    [message] NVARCHAR(1000) NOT NULL,
    [is_read] BIT NOT NULL DEFAULT 0,
    [read_at] DATETIME2 NULL,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [expires_at] DATETIME2 NULL,
    
    CONSTRAINT [FK_notifications_ticket] FOREIGN KEY ([ticket_id]) REFERENCES [tickets]([id]),
    CONSTRAINT [FK_notifications_recipient] FOREIGN KEY ([recipient_id]) REFERENCES [users]([id]),
    CONSTRAINT [CK_notifications_type] CHECK ([notification_type] IN ('NEW_TICKET', 'STEP_ASSIGNED', 'FILE_UPLOADED', 'FILE_REVISION_REQUIRED', 'APPROVED', 'REJECTED'))
);

-- Comments
CREATE TABLE [ticket_comments] (
    [id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [ticket_id] UNIQUEIDENTIFIER NOT NULL,
    [user_id] INT NOT NULL,
    [comment_text] NVARCHAR(2000) NOT NULL,
    [comment_type] NVARCHAR(20) NOT NULL DEFAULT 'GENERAL', -- GENERAL, APPROVAL, REJECTION, INTERNAL
    [workflow_step_id] INT NULL, -- Comment ở bước nào
    [parent_comment_id] UNIQUEIDENTIFIER NULL, -- Cho phép reply comment
    [is_internal] BIT NOT NULL DEFAULT 0, -- Comment nội bộ
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [is_deleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [FK_ticket_comments_ticket] FOREIGN KEY ([ticket_id]) REFERENCES [tickets]([id]),
    CONSTRAINT [FK_ticket_comments_user] FOREIGN KEY ([user_id]) REFERENCES [users]([id]),
    CONSTRAINT [FK_ticket_comments_workflow_step] FOREIGN KEY ([workflow_step_id]) REFERENCES [workflow_steps]([id]),
    CONSTRAINT [FK_ticket_comments_parent] FOREIGN KEY ([parent_comment_id]) REFERENCES [ticket_comments]([id]),
    CONSTRAINT [CK_ticket_comments_type] CHECK ([comment_type] IN ('GENERAL', 'APPROVAL', 'REJECTION', 'INTERNAL'))
);

-- =============================================
-- 8. INDEXES FOR PERFORMANCE
-- =============================================

-- Master data indexes
CREATE INDEX [IX_transaction_types_code] ON [transaction_types] ([code]);
CREATE INDEX [IX_partners_code] ON [partners] ([code]);
CREATE INDEX [IX_flows_code] ON [flows] ([code]);
CREATE INDEX [IX_issuing_organizations_code] ON [issuing_organizations] ([code]);

-- Workflow configuration indexes
CREATE INDEX [IX_workflow_templates_combo] ON [workflow_templates] ([transaction_type_id], [partner_id], [flow_id], [issuing_organization_id]);
CREATE INDEX [IX_workflow_steps_template] ON [workflow_steps] ([template_id], [step_order]);

-- User indexes
CREATE INDEX [IX_users_username] ON [users] ([username]);
CREATE INDEX [IX_users_department_role] ON [users] ([department_id], [role]);

-- Ticket indexes
CREATE INDEX [IX_tickets_number] ON [tickets] ([ticket_number]);
CREATE INDEX [IX_tickets_status] ON [tickets] ([current_status]);
CREATE INDEX [IX_tickets_created_by] ON [tickets] ([created_by]);
CREATE INDEX [IX_tickets_assigned_to] ON [tickets] ([assigned_to]);
CREATE INDEX [IX_tickets_combo] ON [tickets] ([transaction_type_id], [partner_id], [flow_id], [issuing_organization_id]);

-- File indexes
CREATE INDEX [IX_ticket_files_ticket] ON [ticket_files] ([ticket_id]);
CREATE INDEX [IX_ticket_files_category] ON [ticket_files] ([file_category_id]);
CREATE INDEX [IX_ticket_files_uploaded_by] ON [ticket_files] ([uploaded_by]);

-- Workflow execution indexes
CREATE INDEX [IX_workflow_instances_ticket] ON [workflow_instances] ([ticket_id]);
CREATE INDEX [IX_workflow_history_instance] ON [workflow_history] ([instance_id]);
CREATE INDEX [IX_workflow_history_performed_by] ON [workflow_history] ([performed_by]);

-- Notification indexes
CREATE INDEX [IX_notifications_recipient] ON [notifications] ([recipient_id], [is_read]);
CREATE INDEX [IX_ticket_comments_ticket] ON [ticket_comments] ([ticket_id]);

PRINT 'Ticket Management System Database Schema created successfully!';
PRINT 'Features: Dynamic Workflow, 4-ComboBox Configuration, File Management, Role-based Permissions';
