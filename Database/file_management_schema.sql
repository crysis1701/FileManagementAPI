-- =============================================
-- File Management System Database Schema
-- SQL Server Implementation
-- =============================================

-- Create Database
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'FileManagementDB')
BEGIN
    CREATE DATABASE FileManagementDB
    COLLATE SQL_Latin1_General_CP1_CI_AS;
END
GO

USE FileManagementDB;
GO

-- =============================================
-- 1. TABS - Quản lý các tab chính
-- =============================================
CREATE TABLE [tabs] (
    [tab_id] INT IDENTITY(1,1) PRIMARY KEY,
    [tab_code] NVARCHAR(50) NOT NULL UNIQUE,
    [tab_name] NVARCHAR(100) NOT NULL,
    [tab_description] NVARCHAR(500),
    [sort_order] INT NOT NULL DEFAULT 0,
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- =============================================
-- 2. CATEGORIES - Quản lý các mục trong tab
-- =============================================
CREATE TABLE [categories] (
    [category_id] INT IDENTITY(1,1) PRIMARY KEY,
    [tab_id] INT NOT NULL,
    [category_code] NVARCHAR(50) NOT NULL,
    [category_name] NVARCHAR(100) NOT NULL,
    [category_description] NVARCHAR(500),
    [sort_order] INT NOT NULL DEFAULT 0,
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_categories_tab] FOREIGN KEY ([tab_id]) REFERENCES [tabs]([tab_id]),
    CONSTRAINT [UK_categories_tab_code] UNIQUE ([tab_id], [category_code])
);

-- =============================================
-- 3. DEPARTMENTS - Quản lý đơn vị
-- =============================================
CREATE TABLE [departments] (
    [department_id] INT IDENTITY(1,1) PRIMARY KEY,
    [department_code] NVARCHAR(50) NOT NULL UNIQUE,
    [department_name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(500),
    [parent_department_id] INT NULL, -- Cho phép phòng ban con
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_departments_parent] FOREIGN KEY ([parent_department_id]) REFERENCES [departments]([department_id])
);

-- =============================================
-- 4. EMPLOYEES - Quản lý nhân viên
-- =============================================
CREATE TABLE [employees] (
    [employee_id] INT IDENTITY(1,1) PRIMARY KEY,
    [employee_code] NVARCHAR(50) NOT NULL UNIQUE,
    [full_name] NVARCHAR(100) NOT NULL,
    [email] NVARCHAR(255) NOT NULL UNIQUE,
    [phone] NVARCHAR(20),
    [position] NVARCHAR(100),
    [department_id] INT NOT NULL,
    [is_active] BIT NOT NULL DEFAULT 1,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_employees_department] FOREIGN KEY ([department_id]) REFERENCES [departments]([department_id])
);

-- =============================================
-- 5. FILES - Quản lý file chính
-- =============================================
CREATE TABLE [files] (
    [file_id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [tab_id] INT NOT NULL,
    [category_id] INT NOT NULL,
    [file_name] NVARCHAR(255) NOT NULL,
    [original_filename] NVARCHAR(255) NOT NULL,
    [file_extension] NVARCHAR(10) NOT NULL,
    [file_size] BIGINT NOT NULL,
    [mime_type] NVARCHAR(100) NOT NULL,
    [file_path] NVARCHAR(1000) NOT NULL, -- Đường dẫn lưu file
    [uploaded_by] INT NOT NULL, -- Employee ID
    [department_id] INT NOT NULL,
    [upload_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [description] NVARCHAR(500),
    [version] INT NOT NULL DEFAULT 1,
    [is_current_version] BIT NOT NULL DEFAULT 1,
    [parent_file_id] UNIQUEIDENTIFIER NULL, -- Cho versioning
    [download_count] INT NOT NULL DEFAULT 0,
    [is_active] BIT NOT NULL DEFAULT 1, -- File có được active hay không
    [is_deleted] BIT NOT NULL DEFAULT 0,
    [deleted_at] DATETIME2 NULL,
    [deleted_by] INT NULL,
    [created_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [updated_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [FK_files_tab] FOREIGN KEY ([tab_id]) REFERENCES [tabs]([tab_id]),
    CONSTRAINT [FK_files_category] FOREIGN KEY ([category_id]) REFERENCES [categories]([category_id]),
    CONSTRAINT [FK_files_uploaded_by] FOREIGN KEY ([uploaded_by]) REFERENCES [employees]([employee_id]),
    CONSTRAINT [FK_files_department] FOREIGN KEY ([department_id]) REFERENCES [departments]([department_id]),
    CONSTRAINT [FK_files_parent] FOREIGN KEY ([parent_file_id]) REFERENCES [files]([file_id]),
    CONSTRAINT [FK_files_deleted_by] FOREIGN KEY ([deleted_by]) REFERENCES [employees]([employee_id])
);

-- =============================================
-- 6. FILE_ACTIONS - Quản lý tác vụ trên file
-- =============================================
CREATE TABLE [file_actions] (
    [action_id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [file_id] UNIQUEIDENTIFIER NOT NULL,
    [action_type] NVARCHAR(50) NOT NULL, -- UPLOAD, DOWNLOAD, DELETE, UPDATE, VIEW
    [performed_by] INT NOT NULL,
    [action_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [ip_address] NVARCHAR(45),
    [user_agent] NVARCHAR(500),
    [notes] NVARCHAR(500),
    
    CONSTRAINT [FK_file_actions_file] FOREIGN KEY ([file_id]) REFERENCES [files]([file_id]),
    CONSTRAINT [FK_file_actions_performed_by] FOREIGN KEY ([performed_by]) REFERENCES [employees]([employee_id]),
    CONSTRAINT [CK_file_actions_action_type] CHECK ([action_type] IN ('UPLOAD', 'DOWNLOAD', 'DELETE', 'UPDATE', 'VIEW'))
);

-- =============================================
-- 7. FILE_PERMISSIONS - Phân quyền truy cập file
-- =============================================
CREATE TABLE [file_permissions] (
    [permission_id] UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    [file_id] UNIQUEIDENTIFIER NOT NULL,
    [department_id] INT NULL, -- Phân quyền theo phòng ban
    [employee_id] INT NULL, -- Phân quyền theo cá nhân
    [permission_type] NVARCHAR(20) NOT NULL, -- READ, WRITE, DELETE, FULL
    [granted_by] INT NOT NULL,
    [granted_at] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [expires_at] DATETIME2 NULL,
    [is_active] BIT NOT NULL DEFAULT 1,
    
    CONSTRAINT [FK_file_permissions_file] FOREIGN KEY ([file_id]) REFERENCES [files]([file_id]),
    CONSTRAINT [FK_file_permissions_department] FOREIGN KEY ([department_id]) REFERENCES [departments]([department_id]),
    CONSTRAINT [FK_file_permissions_employee] FOREIGN KEY ([employee_id]) REFERENCES [employees]([employee_id]),
    CONSTRAINT [FK_file_permissions_granted_by] FOREIGN KEY ([granted_by]) REFERENCES [employees]([employee_id]),
    CONSTRAINT [CK_file_permissions_permission_type] CHECK ([permission_type] IN ('READ', 'WRITE', 'DELETE', 'FULL')),
    CONSTRAINT [CK_file_permissions_target] CHECK (([department_id] IS NOT NULL AND [employee_id] IS NULL) OR ([department_id] IS NULL AND [employee_id] IS NOT NULL))
);

-- =============================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- Tabs indexes
CREATE INDEX [IX_tabs_tab_code] ON [tabs] ([tab_code]);
CREATE INDEX [IX_tabs_is_active] ON [tabs] ([is_active]);

-- Categories indexes
CREATE INDEX [IX_categories_tab_id] ON [categories] ([tab_id]);
CREATE INDEX [IX_categories_category_code] ON [categories] ([category_code]);
CREATE INDEX [IX_categories_is_active] ON [categories] ([is_active]);

-- Departments indexes
CREATE INDEX [IX_departments_department_code] ON [departments] ([department_code]);
CREATE INDEX [IX_departments_parent_department_id] ON [departments] ([parent_department_id]);
CREATE INDEX [IX_departments_is_active] ON [departments] ([is_active]);

-- Employees indexes
CREATE INDEX [IX_employees_employee_code] ON [employees] ([employee_code]);
CREATE INDEX [IX_employees_email] ON [employees] ([email]);
CREATE INDEX [IX_employees_department_id] ON [employees] ([department_id]);
CREATE INDEX [IX_employees_is_active] ON [employees] ([is_active]);

-- Files indexes
CREATE INDEX [IX_files_tab_id] ON [files] ([tab_id]);
CREATE INDEX [IX_files_category_id] ON [files] ([category_id]);
CREATE INDEX [IX_files_uploaded_by] ON [files] ([uploaded_by]);
CREATE INDEX [IX_files_department_id] ON [files] ([department_id]);
CREATE INDEX [IX_files_upload_date] ON [files] ([upload_date]);
CREATE INDEX [IX_files_file_name] ON [files] ([file_name]);
CREATE INDEX [IX_files_is_current_version] ON [files] ([is_current_version]);
CREATE INDEX [IX_files_is_active] ON [files] ([is_active]);
CREATE INDEX [IX_files_is_deleted] ON [files] ([is_deleted]);

-- File actions indexes
CREATE INDEX [IX_file_actions_file_id] ON [file_actions] ([file_id]);
CREATE INDEX [IX_file_actions_performed_by] ON [file_actions] ([performed_by]);
CREATE INDEX [IX_file_actions_action_date] ON [file_actions] ([action_date]);
CREATE INDEX [IX_file_actions_action_type] ON [file_actions] ([action_type]);

-- File permissions indexes
CREATE INDEX [IX_file_permissions_file_id] ON [file_permissions] ([file_id]);
CREATE INDEX [IX_file_permissions_department_id] ON [file_permissions] ([department_id]);
CREATE INDEX [IX_file_permissions_employee_id] ON [file_permissions] ([employee_id]);
CREATE INDEX [IX_file_permissions_is_active] ON [file_permissions] ([is_active]);

PRINT 'File Management System tables created successfully!';
