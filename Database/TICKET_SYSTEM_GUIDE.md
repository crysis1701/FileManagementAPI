# 🎫 HƯỚNG DẪN SỬ DỤNG HỆ THỐNG TICKET MANAGEMENT

## 📋 Tổng quan hệ thống

Hệ thống Ticket Management được thiết kế để quản lý các ticket với workflow động dựa trên **4 ComboBox**:

1. **Loại giao dịch** (Transaction Type)
2. **Đối tác** (Partner) 
3. **Luồng** (Flow)
4. **Tổ chức phát hành** (Issuing Organization)

### 🌟 Tính năng chính:
- **Dynamic Workflow**: Quy trình tự động được chọn dựa trên 4 combobox
- **File Management**: Upload/delete file theo từng bước workflow
- **Role-based Permission**: Ma trận phân quyền chi tiết
- **5 Flow chính**: Khởi tạo → Chuyển kiểm soát → Kiểm soát phê duyệt → Phê duyệt → Hoàn thành

## 🚀 Khởi tạo hệ thống

### Bước 1: Tạo Database
```sql
-- Chạy schema chính
sqlcmd -S your_server -d master -i ticket_management_schema.sql

-- Import dữ liệu mẫu
sqlcmd -S your_server -d TicketManagementDB -i ticket_management_sample_data.sql

-- Import stored procedures
sqlcmd -S your_server -d TicketManagementDB -i ticket_management_procedures.sql
```

### Bước 2: Kiểm tra cài đặt
```sql
USE TicketManagementDB;

-- Kiểm tra tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE';

-- Kiểm tra dữ liệu mẫu
SELECT 'Transaction Types' as Table_Name, COUNT(*) as Count FROM transaction_types
UNION ALL
SELECT 'Partners', COUNT(*) FROM partners
UNION ALL
SELECT 'Flows', COUNT(*) FROM flows
UNION ALL
SELECT 'Issuing Organizations', COUNT(*) FROM issuing_organizations
UNION ALL
SELECT 'Workflow Templates', COUNT(*) FROM workflow_templates;
```

## 🎯 Luồng nghiệp vụ chính

### 1. **Tạo Ticket mới**

#### Bước 1: Chọn 4 ComboBox
```sql
-- Lấy dữ liệu cho 4 combobox
SELECT id, code, name FROM transaction_types WHERE is_active = 1;
SELECT id, code, name FROM partners WHERE is_active = 1;
SELECT id, code, name FROM flows WHERE is_active = 1;
SELECT id, code, name FROM issuing_organizations WHERE is_active = 1;
```

#### Bước 2: Tạo Ticket
```sql
-- Tạo ticket mới
DECLARE @TicketId UNIQUEIDENTIFIER, @TicketNumber NVARCHAR(50);

EXEC sp_CreateTicket
    @Title = N'Thanh toán hóa đơn VCB',
    @Description = N'Thanh toán hóa đơn nhà cung cấp qua VCB',
    @TransactionTypeId = 1,    -- PAYMENT
    @PartnerId = 1,            -- VCB
    @FlowId = 1,               -- NORMAL
    @IssuingOrgId = 1,         -- SBV
    @Priority = 'HIGH',
    @DueDate = DATEADD(DAY, 7, GETDATE()),
    @CreatedBy = 4,            -- fin001 user
    @TicketId = @TicketId OUTPUT,
    @TicketNumber = @TicketNumber OUTPUT;

-- Xem kết quả
SELECT @TicketId as TicketId, @TicketNumber as TicketNumber;
```

### 2. **Upload File trong giai đoạn Khởi tạo**

#### File Categories (Hồ sơ đính kèm):
```sql
-- Xem các loại file có thể upload
SELECT 
    id, code, name, category_type, is_required, max_file_size_mb, allowed_extensions
FROM file_categories 
WHERE is_active = 1
ORDER BY category_type, name;
```

#### Upload File:
```sql
-- Upload file hợp đồng (Tác nghiệp)
DECLARE @FileId UNIQUEIDENTIFIER;

EXEC sp_UploadFile
    @TicketId = @TicketId,
    @FileCategoryId = 1,       -- CONTRACT
    @FileName = 'contract_001.pdf',
    @OriginalFilename = N'Hợp đồng VCB.pdf',
    @FileExtension = '.pdf',
    @FileSize = 2048000,       -- 2MB
    @MimeType = 'application/pdf',
    @FilePath = '/uploads/tickets/' + CAST(@TicketId AS VARCHAR(50)) + '/contract_001.pdf',
    @UploadedBy = 4,
    @Description = N'Hợp đồng thanh toán với VCB',
    @FileId = @FileId OUTPUT;

-- Upload file CMND (Không tác nghiệp)
EXEC sp_UploadFile
    @TicketId = @TicketId,
    @FileCategoryId = 6,       -- ID_COPY
    @FileName = 'id_copy_001.jpg',
    @OriginalFilename = N'Bản sao CMND.jpg',
    @FileExtension = '.jpg',
    @FileSize = 1024000,       -- 1MB
    @MimeType = 'image/jpeg',
    @FilePath = '/uploads/tickets/' + CAST(@TicketId AS VARCHAR(50)) + '/id_copy_001.jpg',
    @UploadedBy = 4,
    @Description = N'Bản sao CMND người ký hợp đồng',
    @FileId = @FileId OUTPUT;
```

### 3. **Chuyển Workflow Steps**

#### Chuyển từ Khởi tạo → Chuyển kiểm soát:
```sql
-- User chuyển ticket sang bước tiếp theo
EXEC sp_ProcessWorkflowStep
    @TicketId = @TicketId,
    @Action = 'TRANSFER',
    @PerformedBy = 4,          -- fin001
    @Comments = N'Đã hoàn thành upload file, chuyển sang kiểm soát';
```

#### Controller xử lý:
```sql
-- Finance Controller approve
EXEC sp_ProcessWorkflowStep
    @TicketId = @TicketId,
    @Action = 'APPROVE',
    @PerformedBy = 5,          -- fin_controller
    @Comments = N'Đã kiểm tra hồ sơ, phù hợp quy định',
    @AssignTo = 6;             -- Assign cho fin_manager
```

#### Approver phê duyệt cuối:
```sql
-- Finance Manager final approve
EXEC sp_ProcessWorkflowStep
    @TicketId = @TicketId,
    @Action = 'APPROVE', 
    @PerformedBy = 6,          -- fin_manager
    @Comments = N'Phê duyệt thanh toán theo đề xuất';
```

## 📊 Truy vấn và Báo cáo

### 1. **Xem chi tiết Ticket**
```sql
-- Xem thông tin đầy đủ ticket
SELECT * FROM vw_TicketDetails WHERE ticket_id = @TicketId;

-- Xem files của ticket
SELECT 
    tf.original_filename,
    fc.name as category_name,
    fc.category_type,
    tf.file_size,
    tf.upload_date,
    u.full_name as uploaded_by
FROM ticket_files tf
JOIN file_categories fc ON tf.file_category_id = fc.id
JOIN users u ON tf.uploaded_by = u.id
WHERE tf.ticket_id = @TicketId AND tf.is_active = 1
ORDER BY tf.upload_date;

-- Xem lịch sử workflow
SELECT 
    wh.performed_at,
    wh.action,
    u.full_name as performed_by,
    ws.step_name,
    wh.comments,
    wh.duration_minutes
FROM workflow_history wh
JOIN users u ON wh.performed_by = u.id
JOIN workflow_steps ws ON wh.step_id = ws.id
WHERE wh.instance_id = (SELECT id FROM workflow_instances WHERE ticket_id = @TicketId)
ORDER BY wh.performed_at;
```

### 2. **Tasks của User**
```sql
-- Xem tickets cần xử lý của Finance Controller
SELECT 
    ticket_number,
    title, 
    priority,
    current_step,
    pending_days,
    creator_name,
    can_approve,
    can_upload_files
FROM vw_UserTasks 
WHERE user_id = 5  -- fin_controller
ORDER BY pending_days DESC;
```

### 3. **Dashboard và thống kê**
```sql
-- Thống kê theo trạng thái
SELECT 
    current_status,
    COUNT(*) as count,
    AVG(processing_days) as avg_processing_days
FROM vw_TicketDetails
WHERE created_at >= DATEADD(MONTH, -1, GETDATE())
GROUP BY current_status;

-- Thống kê theo loại giao dịch
SELECT 
    transaction_type_name,
    COUNT(*) as total_tickets,
    SUM(CASE WHEN current_status = 'COMPLETED' THEN 1 ELSE 0 END) as completed,
    AVG(CASE WHEN current_status = 'COMPLETED' THEN processing_days END) as avg_completion_days
FROM vw_TicketDetails
GROUP BY transaction_type_name
ORDER BY total_tickets DESC;

-- Top users tạo nhiều ticket nhất
SELECT 
    created_by_name,
    department_name,
    COUNT(*) as total_tickets,
    AVG(processing_days) as avg_processing_days
FROM vw_TicketDetails
WHERE created_at >= DATEADD(MONTH, -3, GETDATE())
GROUP BY created_by_name, department_name
ORDER BY total_tickets DESC;
```

## 🔒 Ma trận phân quyền

### Quyền theo Role và Step:

| Step | USER | CONTROLLER | APPROVER | ADMIN |
|------|------|------------|----------|-------|
| **INITIATE** | ✅ Tất cả | ❌ | ❌ | ✅ Tất cả |
| **TRANSFER_CONTROL** | ✅ Edit, Upload, Approve | 👀 View only | ❌ | ✅ Tất cả |
| **CONTROL_APPROVAL** | 👀 View only | ✅ Edit, Upload, Approve/Reject | 👀 View only | ✅ Tất cả |
| **APPROVE** | 👀 View only | 👀 View only | ✅ Approve/Reject | ✅ Tất cả |
| **COMPLETE** | 👀 View only | 👀 View only | 👀 View only | ✅ Tất cả |

### Kiểm tra quyền của user:
```sql
-- Xem quyền của user ở step hiện tại
SELECT 
    u.full_name,
    u.role,
    ws.step_name,
    rp.can_view,
    rp.can_edit,
    rp.can_upload_files,
    rp.can_delete_files,
    rp.can_approve,
    rp.can_reject
FROM users u
JOIN role_permissions rp ON u.role = rp.role
JOIN workflow_steps ws ON rp.workflow_step_id = ws.id
JOIN tickets t ON t.current_step_id = ws.id
WHERE u.id = 5  -- user_id
AND t.id = @TicketId;
```

## 🔄 Workflow Template Matching

### Logic chọn Template:

1. **Exact Match**: Khớp chính xác 4 tham số
2. **Partial Match**: Khớp 3/4 tham số (NULL = wildcard)
3. **Default Template**: Nếu không tìm thấy template nào

### Ví dụ Templates:
```sql
-- Template cụ thể: PAYMENT + VCB + NORMAL + SBV
SELECT * FROM workflow_templates WHERE template_code = 'PAYMENT_VCB_NORMAL_SBV';

-- Template cho tất cả TRANSFER + EXPRESS
SELECT * FROM workflow_templates WHERE template_code = 'TRANSFER_EXPRESS';

-- Template mặc định
SELECT * FROM workflow_templates WHERE is_default = 1;
```

## 📁 File Management

### File Categories:
- **Tác nghiệp**: CONTRACT, INVOICE, RECEIPT, AUTHORIZATION, BANK_STATEMENT
- **Không tác nghiệp**: ID_COPY, PHOTO, EMAIL_SCREENSHOT, OTHER_DOC
- **Khác**: SYSTEM_LOG, REPORT

### Upload Rules:
- Kiểm tra **file size** theo category
- Kiểm tra **file extension** allowed
- Kiểm tra **quyền upload** theo role và step
- **Version control** cho file thay thế

### Xóa File:
```sql
-- Xóa file (soft delete)
EXEC sp_DeleteFile
    @FileId = @FileId,
    @DeletedBy = 4,
    @DeleteReason = N'File không chính xác, cần upload lại';
```

## 🔔 Notifications

### Các loại thông báo:
- **NEW_TICKET**: Ticket mới được tạo
- **STEP_ASSIGNED**: Ticket được assign
- **FILE_UPLOADED**: File được upload
- **APPROVED**: Ticket được approve  
- **REJECTED**: Ticket bị reject

### Xem notifications:
```sql
-- Notifications chưa đọc của user
SELECT 
    n.title,
    n.message,
    n.notification_type,
    n.created_at,
    t.ticket_number
FROM notifications n
JOIN tickets t ON n.ticket_id = t.id
WHERE n.recipient_id = 5  -- user_id
AND n.is_read = 0
ORDER BY n.created_at DESC;
```

## 🛠️ API Endpoints đề xuất

### Ticket Management:
- `POST /api/tickets` - Tạo ticket mới
- `GET /api/tickets/{id}` - Lấy chi tiết ticket
- `PUT /api/tickets/{id}/workflow` - Xử lý workflow step
- `GET /api/tickets/my-tasks` - Lấy tasks của user

### File Management:
- `POST /api/tickets/{id}/files` - Upload file
- `GET /api/tickets/{id}/files` - Lấy danh sách file
- `DELETE /api/files/{fileId}` - Xóa file
- `GET /api/files/{fileId}/download` - Download file

### Master Data:
- `GET /api/transaction-types` - Lấy loại giao dịch
- `GET /api/partners` - Lấy đối tác
- `GET /api/flows` - Lấy luồng
- `GET /api/issuing-organizations` - Lấy tổ chức phát hành

## 📝 Lưu ý quan trọng

1. **Workflow Template**: Thứ tự ưu tiên theo `priority` ASC
2. **File Storage**: Files lưu trong `/uploads/tickets/{ticket_id}/`
3. **Permissions**: Check ma trận quyền trước mọi action
4. **Audit Trail**: Toàn bộ lịch sử được lưu trong `workflow_history`
5. **Soft Delete**: Files chỉ được soft delete để audit

## 🆘 Troubleshooting

### Lỗi thường gặp:
1. **No workflow template found**: Kiểm tra có template default không
2. **Permission denied**: Kiểm tra role_permissions matrix
3. **File size exceeded**: Kiểm tra max_file_size_mb trong file_categories
4. **Invalid file extension**: Kiểm tra allowed_extensions

### Test các chức năng:
```sql
-- Test tạo ticket với combo khác nhau
EXEC sp_CreateTicket @TransactionTypeId=2, @PartnerId=2, @FlowId=2, @IssuingOrgId=2, ...

-- Test upload file các loại khác nhau  
EXEC sp_UploadFile @FileCategoryId=1, ... -- CONTRACT
EXEC sp_UploadFile @FileCategoryId=6, ... -- ID_COPY

-- Test workflow với các role khác nhau
EXEC sp_ProcessWorkflowStep @PerformedBy=5, ... -- CONTROLLER
EXEC sp_ProcessWorkflowStep @PerformedBy=6, ... -- APPROVER
```

---
**🎉 Hệ thống Ticket Management đã sẵn sàng sử dụng!**

Dynamic workflow dựa trên 4 combobox, file management đầy đủ, và ma trận phân quyền chi tiết sẽ đáp ứng mọi nhu cầu nghiệp vụ của bạn.
