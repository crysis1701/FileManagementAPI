-- =============================================
-- TICKET MANAGEMENT SYSTEM STORED PROCEDURES
-- Các thủ tục xử lý logic nghiệp vụ
-- =============================================

USE TicketManagementDB;
GO

-- =============================================
-- 1. FUNCTION: Tìm Workflow Template phù hợp
-- =============================================

CREATE OR ALTER FUNCTION fn_FindWorkflowTemplate(
    @TransactionTypeId INT,
    @PartnerId INT,
    @FlowId INT,
    @IssuingOrgId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @TemplateId INT;
    
    -- Tìm template khớp chính xác với 4 tham số
    SELECT TOP 1 @TemplateId = id
    FROM workflow_templates
    WHERE transaction_type_id = @TransactionTypeId
      AND partner_id = @PartnerId
      AND flow_id = @FlowId
      AND issuing_organization_id = @IssuingOrgId
      AND is_active = 1
    ORDER BY priority ASC;
    
    -- Nếu không tìm thấy, tìm template khớp 3 tham số
    IF @TemplateId IS NULL
    BEGIN
        SELECT TOP 1 @TemplateId = id
        FROM workflow_templates
        WHERE ((transaction_type_id = @TransactionTypeId) OR (transaction_type_id IS NULL))
          AND ((partner_id = @PartnerId) OR (partner_id IS NULL))
          AND ((flow_id = @FlowId) OR (flow_id IS NULL))
          AND ((issuing_organization_id = @IssuingOrgId) OR (issuing_organization_id IS NULL))
          AND is_active = 1
        ORDER BY 
            CASE WHEN transaction_type_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN partner_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN flow_id IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN issuing_organization_id IS NOT NULL THEN 1 ELSE 0 END DESC,
            priority ASC;
    END
    
    -- Nếu vẫn không tìm thấy, lấy template mặc định
    IF @TemplateId IS NULL
    BEGIN
        SELECT @TemplateId = id
        FROM workflow_templates
        WHERE is_default = 1 AND is_active = 1;
    END
    
    RETURN @TemplateId;
END;
GO

-- =============================================
-- 2. PROCEDURE: Tạo Ticket mới
-- =============================================

CREATE OR ALTER PROCEDURE sp_CreateTicket
    @Title NVARCHAR(200),
    @Description NVARCHAR(2000),
    @TransactionTypeId INT,
    @PartnerId INT,
    @FlowId INT,
    @IssuingOrgId INT,
    @Priority NVARCHAR(10) = 'NORMAL',
    @DueDate DATETIME2 = NULL,
    @CreatedBy INT,
    @TicketId UNIQUEIDENTIFIER OUTPUT,
    @TicketNumber NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Generate Ticket ID và Number
        SET @TicketId = NEWID();
        SET @TicketNumber = 'TKT' + FORMAT(GETDATE(), 'yyyyMMdd') + 
                           RIGHT('000' + CAST(ABS(CHECKSUM(@TicketId)) % 1000 AS VARCHAR(3)), 3);
        
        -- Tìm workflow template phù hợp
        DECLARE @WorkflowTemplateId INT;
        SET @WorkflowTemplateId = dbo.fn_FindWorkflowTemplate(@TransactionTypeId, @PartnerId, @FlowId, @IssuingOrgId);
        
        IF @WorkflowTemplateId IS NULL
        BEGIN
            RAISERROR('Không tìm thấy workflow template phù hợp', 16, 1);
            RETURN;
        END
        
        -- Lấy thông tin user
        DECLARE @DepartmentId INT;
        SELECT @DepartmentId = department_id FROM users WHERE id = @CreatedBy;
        
        -- Tạo ticket
        INSERT INTO tickets (
            id, ticket_number, title, description, 
            transaction_type_id, partner_id, flow_id, issuing_organization_id,
            workflow_template_id, priority, due_date, created_by, department_id
        )
        VALUES (
            @TicketId, @TicketNumber, @Title, @Description,
            @TransactionTypeId, @PartnerId, @FlowId, @IssuingOrgId,
            @WorkflowTemplateId, @Priority, @DueDate, @CreatedBy, @DepartmentId
        );
        
        -- Lấy step đầu tiên của workflow
        DECLARE @FirstStepId INT;
        SELECT @FirstStepId = id
        FROM workflow_steps 
        WHERE template_id = @WorkflowTemplateId 
        AND step_type = 'INITIATE'
        AND step_order = (SELECT MIN(step_order) FROM workflow_steps WHERE template_id = @WorkflowTemplateId);
        
        -- Tạo workflow instance
        DECLARE @InstanceId UNIQUEIDENTIFIER = NEWID();
        INSERT INTO workflow_instances (id, ticket_id, template_id, current_step_id, started_by)
        VALUES (@InstanceId, @TicketId, @WorkflowTemplateId, @FirstStepId, @CreatedBy);
        
        -- Cập nhật current_step_id trong ticket
        UPDATE tickets 
        SET current_step_id = @FirstStepId
        WHERE id = @TicketId;
        
        -- Ghi lịch sử khởi tạo
        INSERT INTO workflow_history (
            instance_id, step_id, action, performed_by, comments
        )
        VALUES (
            @InstanceId, @FirstStepId, 'INITIATE', @CreatedBy, N'Tạo ticket mới'
        );
        
        COMMIT TRANSACTION;
        
        SELECT @TicketId as TicketId, @TicketNumber as TicketNumber, @WorkflowTemplateId as WorkflowTemplateId;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 3. PROCEDURE: Xử lý Workflow Step
-- =============================================

CREATE OR ALTER PROCEDURE sp_ProcessWorkflowStep
    @TicketId UNIQUEIDENTIFIER,
    @Action NVARCHAR(20), -- 'TRANSFER', 'APPROVE', 'REJECT'
    @PerformedBy INT,
    @Comments NVARCHAR(1000) = NULL,
    @AssignTo INT = NULL -- Assign cho user khác (tùy chọn)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @CurrentStepId INT, @NextStepId INT, @InstanceId UNIQUEIDENTIFIER;
        DECLARE @CurrentStatus NVARCHAR(20), @NewStatus NVARCHAR(20);
        DECLARE @TemplateId INT, @CurrentStepType NVARCHAR(20);
        
        -- Lấy thông tin hiện tại
        SELECT 
            @CurrentStepId = t.current_step_id, 
            @CurrentStatus = t.current_status,
            @InstanceId = wi.id,
            @TemplateId = wi.template_id
        FROM tickets t
        JOIN workflow_instances wi ON t.id = wi.ticket_id
        WHERE t.id = @TicketId;
        
        -- Lấy thông tin step hiện tại
        SELECT @CurrentStepType = step_type 
        FROM workflow_steps 
        WHERE id = @CurrentStepId;
        
        -- Kiểm tra quyền của user
        DECLARE @CanPerformAction BIT = 0;
        SELECT @CanPerformAction = 
            CASE 
                WHEN @Action = 'APPROVE' OR @Action = 'TRANSFER' THEN 
                    CASE WHEN can_approve = 1 THEN 1 ELSE 0 END
                WHEN @Action = 'REJECT' THEN 
                    CASE WHEN can_reject = 1 THEN 1 ELSE 0 END
                ELSE 0
            END
        FROM role_permissions rp
        JOIN users u ON rp.role = u.role AND (rp.department_id IS NULL OR rp.department_id = u.department_id)
        WHERE rp.workflow_step_id = @CurrentStepId 
        AND u.id = @PerformedBy;
        
        IF @CanPerformAction = 0
        BEGIN
            RAISERROR('Người dùng không có quyền thực hiện action này', 16, 1);
            RETURN;
        END
        
        IF @Action = 'APPROVE' OR @Action = 'TRANSFER'
        BEGIN
            -- Tìm step tiếp theo
            SELECT @NextStepId = id
            FROM workflow_steps
            WHERE template_id = @TemplateId 
            AND step_order = (
                SELECT MIN(step_order) 
                FROM workflow_steps 
                WHERE template_id = @TemplateId 
                AND step_order > (SELECT step_order FROM workflow_steps WHERE id = @CurrentStepId)
            );
            
            IF @NextStepId IS NULL
            BEGIN
                -- Đây là step cuối, hoàn thành workflow
                SET @NewStatus = 'COMPLETED';
                UPDATE workflow_instances 
                SET status = 'COMPLETED', completed_at = GETDATE()
                WHERE id = @InstanceId;
                
                UPDATE tickets 
                SET current_status = 'COMPLETED', completed_at = GETDATE(), updated_at = GETDATE()
                WHERE id = @TicketId;
            END
            ELSE
            BEGIN
                -- Chuyển sang step tiếp theo
                SET @NewStatus = 'IN_PROGRESS';
                UPDATE workflow_instances 
                SET current_step_id = @NextStepId
                WHERE id = @InstanceId;
                
                UPDATE tickets 
                SET current_step_id = @NextStepId,
                    current_status = @NewStatus,
                    updated_at = GETDATE(),
                    assigned_to = @AssignTo
                WHERE id = @TicketId;
            END
        END
        ELSE IF @Action = 'REJECT'
        BEGIN
            SET @NewStatus = 'REJECTED';
            UPDATE tickets 
            SET current_status = @NewStatus, updated_at = GETDATE()
            WHERE id = @TicketId;
            
            UPDATE workflow_instances 
            SET status = 'CANCELLED'
            WHERE id = @InstanceId;
        END
        
        -- Ghi lịch sử
        INSERT INTO workflow_history (
            instance_id, step_id, action, performed_by, comments,
            previous_step_id, next_step_id,
            duration_minutes
        )
        VALUES (
            @InstanceId, @CurrentStepId, @Action, @PerformedBy, @Comments,
            @CurrentStepId, @NextStepId,
            DATEDIFF(MINUTE, 
                (SELECT MAX(performed_at) FROM workflow_history WHERE instance_id = @InstanceId), 
                GETDATE())
        );
        
        -- Tạo notification
        IF @Action = 'APPROVE' OR @Action = 'TRANSFER'
        BEGIN
            IF @NextStepId IS NOT NULL
            BEGIN
                -- Thông báo cho user được assign hoặc users có role phù hợp
                IF @AssignTo IS NOT NULL
                BEGIN
                    INSERT INTO notifications (ticket_id, recipient_id, notification_type, title, message)
                    SELECT @TicketId, @AssignTo, 'STEP_ASSIGNED',
                           N'Ticket được assign cho bạn',
                           N'Ticket ' + t.ticket_number + N' đã được assign cho bạn xử lý'
                    FROM tickets t WHERE t.id = @TicketId;
                END
                ELSE
                BEGIN
                    -- Notify users có role phù hợp
                    INSERT INTO notifications (ticket_id, recipient_id, notification_type, title, message)
                    SELECT @TicketId, u.id, 'STEP_ASSIGNED',
                           N'Ticket cần xử lý',
                           N'Ticket ' + t.ticket_number + N' cần xử lý tại bước: ' + ws.step_name
                    FROM workflow_steps ws
                    CROSS JOIN users u
                    JOIN tickets t ON t.id = @TicketId
                    JOIN role_permissions rp ON rp.workflow_step_id = ws.id AND rp.role = u.role
                    WHERE ws.id = @NextStepId 
                    AND u.is_active = 1
                    AND rp.can_approve = 1;
                END
            END
        END
        ELSE IF @Action = 'REJECT'
        BEGIN
            -- Thông báo cho người tạo ticket
            INSERT INTO notifications (ticket_id, recipient_id, notification_type, title, message)
            SELECT @TicketId, t.created_by, 'REJECTED',
                   N'Ticket bị từ chối',
                   N'Ticket ' + t.ticket_number + N' đã bị từ chối. Lý do: ' + ISNULL(@Comments, N'Không có lý do cụ thể')
            FROM tickets t
            WHERE t.id = @TicketId;
        END
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result, @NewStatus as NewStatus, @NextStepId as NextStepId;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 5. PROCEDURE: Return to Previous Step (Trả về bước trước)
-- =============================================

CREATE OR ALTER PROCEDURE sp_ReturnToPreviousStep
    @TicketId UNIQUEIDENTIFIER,
    @ReturnedBy INT,
    @ReturnReason NVARCHAR(1000),
    @RequiredFileRevision BIT = 0, -- Có yêu cầu upload lại file không
    @FileIds NVARCHAR(MAX) = NULL -- Danh sách file IDs cần inactive (JSON format: "[guid1,guid2,...]")
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @CurrentStepId INT, @PreviousStepId INT, @InstanceId UNIQUEIDENTIFIER;
        DECLARE @CurrentStepOrder INT, @TemplateId INT;
        
        -- Lấy thông tin hiện tại
        SELECT 
            @CurrentStepId = t.current_step_id,
            @InstanceId = wi.id,
            @TemplateId = wi.template_id,
            @CurrentStepOrder = ws.step_order
        FROM tickets t
        JOIN workflow_instances wi ON t.id = wi.ticket_id
        JOIN workflow_steps ws ON t.current_step_id = ws.id
        WHERE t.id = @TicketId;
        
        -- Kiểm tra quyền return
        DECLARE @CanReturn BIT = 0;
        SELECT @CanReturn = rp.can_reject -- Sử dụng quyền reject để return
        FROM role_permissions rp
        JOIN users u ON rp.role = u.role AND (rp.department_id IS NULL OR rp.department_id = u.department_id)
        WHERE rp.workflow_step_id = @CurrentStepId 
        AND u.id = @ReturnedBy;
        
        IF @CanReturn = 0
        BEGIN
            RAISERROR('Người dùng không có quyền trả về bước trước', 16, 1);
            RETURN;
        END
        
        -- Tìm bước trước đó
        SELECT @PreviousStepId = id
        FROM workflow_steps
        WHERE template_id = @TemplateId 
        AND step_order = @CurrentStepOrder - 1;
        
        IF @PreviousStepId IS NULL
        BEGIN
            RAISERROR('Không thể trả về bước trước, đây là bước đầu tiên', 16, 1);
            RETURN;
        END
        
        -- Cập nhật ticket về bước trước
        UPDATE tickets 
        SET current_step_id = @PreviousStepId,
            current_status = 'IN_PROGRESS',
            updated_at = GETDATE()
        WHERE id = @TicketId;
        
        -- Cập nhật workflow instance
        UPDATE workflow_instances 
        SET current_step_id = @PreviousStepId
        WHERE id = @InstanceId;
        
        -- Ghi lịch sử return
        INSERT INTO workflow_history (
            instance_id, step_id, action, performed_by, comments,
            previous_step_id, next_step_id,
            duration_minutes
        )
        VALUES (
            @InstanceId, @CurrentStepId, 'RETURN', @ReturnedBy, @ReturnReason,
            @CurrentStepId, @PreviousStepId,
            DATEDIFF(MINUTE, 
                (SELECT MAX(performed_at) FROM workflow_history WHERE instance_id = @InstanceId), 
                GETDATE())
        );
        
        -- Inactive các file được chỉ định
        IF @FileIds IS NOT NULL AND @RequiredFileRevision = 1
        BEGIN
            -- Parse JSON array của file IDs
            DECLARE @FileIdTable TABLE (FileId UNIQUEIDENTIFIER);
            
            INSERT INTO @FileIdTable (FileId)
            SELECT CAST(value AS UNIQUEIDENTIFIER)
            FROM OPENJSON(@FileIds);
            
            -- Inactive các file
            UPDATE ticket_files 
            SET is_active = 0, 
                is_deleted = 1,
                deleted_at = GETDATE(),
                deleted_by = @ReturnedBy,
                delete_reason = N'File cần revision: ' + @ReturnReason
            WHERE id IN (SELECT FileId FROM @FileIdTable)
            AND ticket_id = @TicketId;
        END
        
        -- Tạo notification cho người tạo ticket
        DECLARE @NotificationType NVARCHAR(20) = CASE 
            WHEN @RequiredFileRevision = 1 THEN 'FILE_REVISION_REQUIRED'
            ELSE 'STEP_ASSIGNED'
        END;
        
        DECLARE @NotificationTitle NVARCHAR(200) = CASE 
            WHEN @RequiredFileRevision = 1 THEN N'Yêu cầu upload lại file'
            ELSE N'Ticket được trả về xử lý'
        END;
        
        INSERT INTO notifications (ticket_id, recipient_id, notification_type, title, message)
        SELECT @TicketId, t.created_by, @NotificationType,
               @NotificationTitle,
               N'Ticket ' + t.ticket_number + N' đã được trả về để xử lý lại. Lý do: ' + @ReturnReason
        FROM tickets t 
        WHERE t.id = @TicketId;
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result, @PreviousStepId as ReturnedToStepId;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 6. PROCEDURE: Upload File
-- =============================================

CREATE OR ALTER PROCEDURE sp_UploadFile
    @TicketId UNIQUEIDENTIFIER,
    @FileCategoryId INT,
    @FileName NVARCHAR(255),
    @OriginalFilename NVARCHAR(255),
    @FileExtension NVARCHAR(10),
    @FileSize BIGINT,
    @MimeType NVARCHAR(100),
    @FilePath NVARCHAR(1000),
    @UploadedBy INT,
    @Description NVARCHAR(500) = NULL,
    @FileId UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Kiểm tra quyền upload
        DECLARE @CurrentStepId INT;
        SELECT @CurrentStepId = current_step_id FROM tickets WHERE id = @TicketId;
        
        DECLARE @CanUpload BIT = 0;
        SELECT @CanUpload = rp.can_upload_files
        FROM role_permissions rp
        JOIN users u ON rp.role = u.role AND (rp.department_id IS NULL OR rp.department_id = u.department_id)
        WHERE rp.workflow_step_id = @CurrentStepId 
        AND u.id = @UploadedBy;
        
        IF @CanUpload = 0
        BEGIN
            RAISERROR('Người dùng không có quyền upload file ở bước này', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra file category
        DECLARE @MaxFileSize INT, @AllowedExtensions NVARCHAR(200);
        SELECT @MaxFileSize = max_file_size_mb, @AllowedExtensions = allowed_extensions
        FROM file_categories WHERE id = @FileCategoryId;
        
        -- Kiểm tra size
        IF @FileSize > (@MaxFileSize * 1024 * 1024)
        BEGIN
            RAISERROR('File size vượt quá giới hạn cho phép', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra extension
        IF @AllowedExtensions IS NOT NULL AND CHARINDEX(@FileExtension, @AllowedExtensions) = 0
        BEGIN
            RAISERROR('File extension không được phép', 16, 1);
            RETURN;
        END
        
        -- Tạo file record
        SET @FileId = NEWID();
        INSERT INTO ticket_files (
            id, ticket_id, file_category_id, workflow_step_id,
            file_name, original_filename, file_extension, file_size, mime_type, file_path,
            uploaded_by, description
        )
        VALUES (
            @FileId, @TicketId, @FileCategoryId, @CurrentStepId,
            @FileName, @OriginalFilename, @FileExtension, @FileSize, @MimeType, @FilePath,
            @UploadedBy, @Description
        );
        
        -- Cập nhật workflow history với số file upload
        UPDATE workflow_history 
        SET files_uploaded = ISNULL(files_uploaded, 0) + 1
        WHERE instance_id = (SELECT id FROM workflow_instances WHERE ticket_id = @TicketId)
        AND id = (SELECT MAX(id) FROM workflow_history WHERE instance_id = (SELECT id FROM workflow_instances WHERE ticket_id = @TicketId));
        
        -- Tạo notification
        INSERT INTO notifications (ticket_id, recipient_id, notification_type, title, message)
        SELECT @TicketId, t.created_by, 'FILE_UPLOADED',
               N'File được upload',
               N'File "' + @OriginalFilename + N'" đã được upload vào ticket ' + t.ticket_number
        FROM tickets t 
        WHERE t.id = @TicketId AND t.created_by != @UploadedBy; -- Không notify chính người upload
        
        COMMIT TRANSACTION;
        
        SELECT @FileId as FileId, 'SUCCESS' as Result;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 5. PROCEDURE: Xóa File
-- =============================================

CREATE OR ALTER PROCEDURE sp_DeleteFile
    @FileId UNIQUEIDENTIFIER,
    @DeletedBy INT,
    @DeleteReason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Lấy thông tin file và ticket
        DECLARE @TicketId UNIQUEIDENTIFIER, @CurrentStepId INT;
        SELECT @TicketId = tf.ticket_id, @CurrentStepId = t.current_step_id
        FROM ticket_files tf
        JOIN tickets t ON tf.ticket_id = t.id
        WHERE tf.id = @FileId AND tf.is_active = 1;
        
        IF @TicketId IS NULL
        BEGIN
            RAISERROR('File không tồn tại hoặc đã bị xóa', 16, 1);
            RETURN;
        END
        
        -- Kiểm tra quyền xóa
        DECLARE @CanDelete BIT = 0;
        SELECT @CanDelete = rp.can_delete_files
        FROM role_permissions rp
        JOIN users u ON rp.role = u.role AND (rp.department_id IS NULL OR rp.department_id = u.department_id)
        WHERE rp.workflow_step_id = @CurrentStepId 
        AND u.id = @DeletedBy;
        
        IF @CanDelete = 0
        BEGIN
            RAISERROR('Người dùng không có quyền xóa file ở bước này', 16, 1);
            RETURN;
        END
        
        -- Soft delete file
        UPDATE ticket_files 
        SET is_active = 0, is_deleted = 1, deleted_at = GETDATE(), 
            deleted_by = @DeletedBy, delete_reason = @DeleteReason
        WHERE id = @FileId;
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' as Result;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- 6. VIEW: Ticket Details với thông tin đầy đủ
-- =============================================

CREATE OR ALTER VIEW vw_TicketDetails AS
SELECT 
    t.id as ticket_id,
    t.ticket_number,
    t.title,
    t.description,
    t.current_status,
    t.priority,
    t.due_date,
    t.created_at,
    t.completed_at,
    
    -- 4 ComboBox info
    tt.name as transaction_type_name,
    p.name as partner_name,
    f.name as flow_name,
    io.name as issuing_organization_name,
    
    -- User info
    u.full_name as created_by_name,
    u.email as created_by_email,
    assigned_user.full_name as assigned_to_name,
    
    -- Department
    d.name as department_name,
    
    -- Current step
    ws.step_name as current_step_name,
    ws.step_type as current_step_type,
    ws.required_role as current_required_role,
    
    -- Workflow info
    wt.template_name as workflow_template_name,
    wi.status as workflow_status,
    
    -- Files count
    (SELECT COUNT(*) FROM ticket_files tf WHERE tf.ticket_id = t.id AND tf.is_active = 1) as files_count,
    
    -- Comments count
    (SELECT COUNT(*) FROM ticket_comments tc WHERE tc.ticket_id = t.id AND tc.is_deleted = 0) as comments_count,
    
    -- Processing time
    CASE 
        WHEN t.current_status = 'COMPLETED' 
        THEN DATEDIFF(DAY, t.created_at, t.completed_at)
        ELSE DATEDIFF(DAY, t.created_at, GETDATE())
    END as processing_days
    
FROM tickets t
JOIN transaction_types tt ON t.transaction_type_id = tt.id
JOIN partners p ON t.partner_id = p.id
JOIN flows f ON t.flow_id = f.id
JOIN issuing_organizations io ON t.issuing_organization_id = io.id
JOIN users u ON t.created_by = u.id
LEFT JOIN users assigned_user ON t.assigned_to = assigned_user.id
JOIN departments d ON t.department_id = d.id
LEFT JOIN workflow_steps ws ON t.current_step_id = ws.id
LEFT JOIN workflow_templates wt ON t.workflow_template_id = wt.id
LEFT JOIN workflow_instances wi ON t.id = wi.ticket_id;
GO

-- =============================================
-- 7. VIEW: User Tasks - Tickets cần xử lý
-- =============================================

CREATE OR ALTER VIEW vw_UserTasks AS
SELECT 
    u.id as user_id,
    u.username,
    u.full_name,
    u.role,
    t.id as ticket_id,
    t.ticket_number,
    t.title,
    t.priority,
    t.current_status,
    t.created_at,
    t.due_date,
    ws.step_name as current_step,
    DATEDIFF(DAY, t.created_at, GETDATE()) as pending_days,
    
    -- Creator info
    creator.full_name as creator_name,
    creator_dept.name as creator_department,
    
    -- Permissions
    rp.can_view,
    rp.can_edit,
    rp.can_upload_files,
    rp.can_delete_files,
    rp.can_approve,
    rp.can_reject
    
FROM users u
JOIN role_permissions rp ON u.role = rp.role AND (rp.department_id IS NULL OR rp.department_id = u.department_id)
JOIN workflow_steps ws ON rp.workflow_step_id = ws.id
JOIN tickets t ON t.current_step_id = ws.id
JOIN users creator ON t.created_by = creator.id
JOIN departments creator_dept ON creator.department_id = creator_dept.id
WHERE t.current_status IN ('INITIATED', 'IN_PROGRESS')
AND u.is_active = 1
AND (t.assigned_to IS NULL OR t.assigned_to = u.id OR rp.can_approve = 1);
GO

PRINT 'Ticket Management System Stored Procedures created successfully!';
PRINT 'Created:';
PRINT '- fn_FindWorkflowTemplate: Tìm workflow template phù hợp';
PRINT '- sp_CreateTicket: Tạo ticket mới';
PRINT '- sp_ProcessWorkflowStep: Xử lý workflow step';
PRINT '- sp_UploadFile: Upload file với kiểm tra quyền';
PRINT '- sp_DeleteFile: Xóa file với kiểm tra quyền';
PRINT '- vw_TicketDetails: View chi tiết ticket';
PRINT '- vw_UserTasks: View tasks của user';
