## 🔄 Quản lý trạng thái Active/Inactive

### Tính năng mới: Active/Inactive File
- **Cột `is_active`**: Cho phép kích hoạt/hủy kích hoạt file
- **Chỉ hiển thị file active**: Hệ thống mặc định chỉ hiển thị file đang active
- **Quản lý linh hoạt**: Admin có thể bật/tắt file mà không cần xóa

### Cách sử dụng:

#### Active/Deactive file
```sql
-- Kích hoạt file
EXEC [sp_ToggleFileActive] @FileId = 'your-file-id', @IsActive = 1, @UserId = 1;

-- Hủy kích hoạt file
EXEC [sp_ToggleFileActive] @FileId = 'your-file-id', @IsActive = 0, @UserId = 1;
```

#### Xem file theo trạng thái
```sql
-- Xem tất cả file đang active
EXEC [sp_GetFilesByActiveStatus] @IsActive = 1;

-- Xem tất cả file không active
EXEC [sp_GetFilesByActiveStatus] @IsActive = 0;

-- Xem file active trong Tab A
EXEC [sp_GetFilesByActiveStatus] @IsActive = 1, @TabCode = 'TAB_A';
```

#### Thống kê trạng thái
```sql
-- Thống kê tổng quan về trạng thái file
EXEC [sp_GetFileActiveStatistics];

-- Xem chi tiết trạng thái tất cả file
SELECT * FROM [v_files_with_status] ORDER BY upload_date DESC;
```

### Migration:
- Chạy file `migration_add_active_column.sql` để cập nhật database hiện có
- Tự động thêm cột `is_active` với giá trị mặc định là `1` (active)
- Tạo index cho hiệu năng
- Cập nhật constraints và procedures

---
