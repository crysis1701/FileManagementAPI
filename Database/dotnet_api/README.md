# File Management API - .NET Core với MinIO

## 📋 Tổng quan

API .NET Core để upload file lên MinIO và lưu metadata trong SQL Server Database cho hệ thống quản lý file 2 tab.

## 🎯 Tổng quan API

Hệ thống API .NET Core quản lý file với các controller chính:

### 📁 **FilesController** (`/api/files`)
- Quản lý upload, download, search, và thao tác với file
- Hỗ trợ upload đơn và upload nhiều file
- Quản lý trạng thái active/inactive
- Audit log và thống kê

### 📋 **TabsController** (`/api/tabs`)
- Quản lý cấu trúc tab và category
- Hiển thị danh sách file theo tab/category
- Phân trang và filter

### 👥 **UsersController** (`/api/users`)
- Quản lý người dùng và quyền hạn
- Theo dõi hoạt động user
- Phân quyền truy cập

### 📊 **StatisticsController** (`/api/statistics`)
- Thống kê tổng quan hệ thống
- Báo cáo theo thời gian
- Top users và hoạt động

### 🏥 **Health Check** (`/health`)
- Kiểm tra tình trạng API
- Monitoring và alerting

## 🚀 Cài đặt và Chạy

### Cách 1: Chạy tự động (Khuyến nghị)
```bash
cd /Users/duylinh/Database/dotnet_api

# Cấp quyền execute cho script
chmod +x manage.sh

# Khởi động toàn bộ hệ thống
./manage.sh start

# Kiểm tra trạng thái
./manage.sh status

# Xem logs
./manage.sh logs

# Dừng hệ thống
./manage.sh stop
```

### Cách 2: Chạy thủ công

#### 1. Cài đặt dependencies
```bash
cd /Users/duylinh/Database/dotnet_api
dotnet restore
```

#### 2. Khởi động Docker services
```bash
docker-compose up -d sqlserver minio
```

#### 3. Cấu hình Database
```bash
# Đợi SQL Server sẵn sàng (30 giây)
sleep 30

# Chạy script tạo database
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "StrongPassword123!" -i /var/opt/mssql/file_management_schema.sql

# Chạy script tạo dữ liệu mẫu
docker-compose exec sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "StrongPassword123!" -i /var/opt/mssql/sample_data.sql
```

#### 4. Chạy API
```bash
dotnet run
```

API sẽ chạy tại: `https://localhost:5001` hoặc `http://localhost:5000`

### Cách 3: Chạy bằng Docker Compose
```bash
# Chạy toàn bộ hệ thống
docker-compose up -d

# Xem logs
docker-compose logs -f api

# Dừng hệ thống
docker-compose down
```

## ⚡ Quick Start

### 1. Khởi động nhanh
```bash
# Clone và chạy
cd /Users/duylinh/Database/dotnet_api
./manage.sh start

# Đợi vài giây để hệ thống khởi động
# Truy cập: https://localhost:5001/swagger
```

### 2. Test API
```bash
# Test tất cả endpoints
./test_all_apis.sh

# Test upload file
curl -X POST "https://localhost:5001/api/files/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test.pdf" \
  -F "tabId=1" \
  -F "categoryId=1" \
  -F "employeeId=1" \
  -k
```

### 3. Web Demo
```bash
# Mở file demo_upload.html trong browser
open demo_upload.html
```

### 1. Legal Documents Controller (`/api/legal-documents`)
**Quản lý hồ sơ pháp lý - bao gồm tabs, categories và files**

#### Tab Management:
- **GET** `/api/legal-documents/tabs` - Get all tabs
- **GET** `/api/legal-documents/tabs/{tabId}` - Get tab by ID
- **GET** `/api/legal-documents/tabs/{tabId}/files` - Get files by tab

#### File Management:
- **POST** `/api/legal-documents/upload` - Upload legal document
- **GET** `/api/legal-documents/files/{fileId}` - Get file details
- **GET** `/api/legal-documents/files/{fileId}/download` - Download file
- **PUT** `/api/legal-documents/files/{fileId}/toggle-active` - Toggle file active status
- **GET** `/api/legal-documents/files/search` - Search files
- **GET** `/api/legal-documents/files/{fileId}/history` - Get file history

### 2. Files Controller (`/api/files`)
**API chung cho tất cả các loại file**

- **GET** `/api/files` - Get all files (paginated)
- **POST** `/api/files/upload-multiple` - Upload multiple files
- **DELETE** `/api/files/{fileId}` - Delete file (soft delete)
- **GET** `/api/files/{fileId}/actions` - Get file actions/audit log

### 3. Statistics Controller (`/api/statistics`)
**Thống kê và báo cáo**

- **GET** `/api/statistics` - Get general statistics
- **GET** `/api/statistics/date-range` - Get statistics by date range
- **GET** `/api/statistics/top-users` - Get top users by activity

### 4. Users Controller (`/api/users`)
**Quản lý người dùng và phân quyền**

- **GET** `/api/users` - Get all users
- **GET** `/api/users/{userId}` - Get user by ID
- **GET** `/api/users/{userId}/permissions` - Get user permissions
- **POST** `/api/users/{userId}/permissions` - Grant user permissions
- **DELETE** `/api/users/{userId}/permissions/{permissionId}` - Revoke user permissions

## 📚 API Endpoints Examples

### 1. Legal Documents Management

#### Upload legal document
**POST** `/api/legal-documents/upload`
- **Content-Type:** `multipart/form-data`
- **Parameters:**
  - `file`: File to upload
  - `tabId`: Tab ID (int)
  - `categoryId`: Category ID (int)
  - `employeeId`: Employee ID (int)
  - `description`: File description (optional)

**Example Request:**
```bash
curl -X POST "https://localhost:5001/api/legal-documents/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "TabId=1" \
  -F "CategoryId=1" \
  -F "File=@/path/to/file.pdf" \
  -F "Description=Báo cáo tháng 1" \
  -F "EmployeeId=1"
```

**Example Response:**
```json
{
  "status": "success",
  "message": "File uploaded successfully",
  "data": {
    "fileId": "550e8400-e29b-41d4-a716-446655440001",
    "fileName": "Báo cáo tháng 1",
    "originalFilename": "bao-cao-thang-1.pdf",
    "fileExtension": ".pdf",
    "fileSize": 1024000,
    "fileSizeDisplay": "1.00 MB",
    "mimeType": "application/pdf",
    "minioUrl": "http://localhost:9000/file-management-tab1-cat1/bao-cao-thang-1_20240716_12345678.pdf",
    "uploadDate": "2024-07-16T10:30:00Z",
    "uploadDateDisplay": "16/07/2024 10:30",
    "uploadedBy": {
      "employeeId": 1,
      "employeeCode": "EMP001",
      "fullName": "Nguyễn Văn A",
      "position": "Trưởng phòng",
      "email": "nguyenvana@company.com"
    },
    "department": {
      "departmentId": 1,
      "departmentCode": "IT",
      "departmentName": "Phòng Công nghệ thông tin"
    },
    "tabName": "Tab A - Tài liệu hành chính",
    "categoryName": "Mục B - Báo cáo"
  }
}
```

#### Upload multiple files
**POST** `/api/files/upload-multiple`
- **Content-Type:** `multipart/form-data`
- **Parameters:**
  - `files`: Multiple files
  - `tabId`: Tab ID (int)
  - `categoryId`: Category ID (int)
  - `employeeId`: Employee ID (int)
  - `descriptions`: Array of descriptions (optional)

**Example Request:**
```bash
curl -X POST "https://localhost:5001/api/files/upload-multiple" \
  -H "Content-Type: multipart/form-data" \
  -F "tabId=1" \
  -F "categoryId=1" \
  -F "uploadedBy=1" \
  -F "departmentId=1" \
  -F "files=@/path/to/file1.pdf" \
  -F "files=@/path/to/file2.docx" \
  -F "descriptions=Báo cáo 1" \
  -F "descriptions=Báo cáo 2"
```

### 3. Get file details
**GET** `/api/files/{fileId}`
- Returns detailed information about a specific file

**Example Request:**
```bash
curl -X GET "https://localhost:5001/api/files/550e8400-e29b-41d4-a716-446655440001"
```

### 4. Download file
**GET** `/api/files/{fileId}/download`
- Downloads the file content

**Example Request:**
```bash
curl -X GET "https://localhost:5001/api/files/550e8400-e29b-41d4-a716-446655440001/download"
```

### 5. Search files
**GET** `/api/files/search`
- **Query Parameters:**
  - `q`: Search query (string)
  - `tabId`: Tab ID filter (optional)
  - `categoryId`: Category ID filter (optional)
  - `uploadedBy`: Employee ID filter (optional)
  - `dateFrom`: Date from filter (optional)
  - `dateTo`: Date to filter (optional)
  - `page`: Page number (default: 1)
  - `pageSize`: Page size (default: 10)

### 6. Toggle file active status
**PUT** `/api/files/{fileId}/toggle-active`
- **Body:** `{ "isActive": true/false }`

### 7. Get files by status
**GET** `/api/files/status`
- **Query Parameters:**
  - `isActive`: true/false
  - `tabId`: Tab ID filter (optional)
  - `categoryId`: Category ID filter (optional)
  - `page`: Page number (default: 1)
  - `pageSize`: Page size (default: 10)

### 8. Get file status statistics
**GET** `/api/files/status/statistics`
- Returns statistics about file active/inactive status

### 2. Tab Management

#### Get all tabs
**GET** `/api/tabs`
- Returns all tabs with their categories and files

#### Get specific tab
**GET** `/api/tabs/{tabId}`
- Returns detailed information about a specific tab

#### Get category files
**GET** `/api/tabs/{tabId}/categories/{categoryId}/files`
- **Query Parameters:**
  - `page`: Page number (default: 1)
  - `pageSize`: Page size (default: 10)

### 3. Statistics

#### Get general statistics
**GET** `/api/statistics`
- Returns overview statistics and recent activities

#### Get statistics by date range
**GET** `/api/statistics/date-range`
- **Query Parameters:**
  - `startDate`: Start date (optional, default: 30 days ago)
  - `endDate`: End date (optional, default: now)

#### Get top users
**GET** `/api/statistics/top-users`
- **Query Parameters:**
  - `limit`: Number of users to return (default: 10)

### 4. User Management

#### Get all users
**GET** `/api/users`
- Returns list of all active users

#### Get user permissions
**GET** `/api/users/{userId}/permissions`
- Returns user's permissions and access levels

#### Get user activity
**GET** `/api/users/{userId}/activity`
- **Query Parameters:**
  - `limit`: Number of activities to return (default: 20)

### 5. Health Check

#### Health check
**GET** `/health`
- Returns API health status

## 🔧 Cấu hình

### File Upload Settings
```json
{
  "FileUpload": {
    "MaxFileSizeMB": 50,
    "MaxFileSizeBytes": 52428800,
    "AllowedFileTypes": [
      ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
      ".txt", ".jpg", ".jpeg", ".png", ".gif", ".zip", ".rar", ".7z",
      ".dwg", ".sql"
    ]
  }
}
```

### MinIO Bucket Structure
- **Bucket naming:** `{BucketPrefix}-tab{TabId}-cat{CategoryId}`
- **Example:** `file-management-tab1-cat1`
- **File naming:** `{OriginalName}_{Timestamp}_{UniqueId}.{Extension}`
- **Example:** `bao-cao-thang-1_20240716_12345678.pdf`

## 🛡️ Bảo mật và Validation

### File Validation
- **File size:** Tối đa 50MB (có thể cấu hình)
- **File types:** Chỉ cho phép các loại file được định nghĩa
- **File name:** Kiểm tra tên file độc hại
- **MIME type:** Validate MIME type với extension

### Security Features
- **SQL Injection:** Sử dụng Entity Framework với parameterized queries
- **Path Traversal:** Kiểm tra tên file độc hại
- **File Type Validation:** Kiểm tra cả extension và MIME type
- **IP Logging:** Ghi log IP address của người upload

## 📊 Logging và Monitoring

### File Actions Logging
- **UPLOAD:** Khi upload file thành công
- **DOWNLOAD:** Khi download file
- **DELETE:** Khi xóa file
- **ACTIVATE/DEACTIVATE:** Khi thay đổi trạng thái file

### Log Information
- File ID
- Action type
- Performed by (Employee ID)
- Timestamp
- IP Address
- User Agent
- Notes

## 🔍 Error Handling

### Common Error Responses
```json
{
  "status": "error",
  "message": "File size exceeds maximum limit of 50 MB"
}
```

### Error Types
- **Validation errors:** File size, type, name validation
- **Permission errors:** Upload permissions
- **Storage errors:** MinIO connection issues
- **Database errors:** SQL Server connection issues

## 🧪 Testing

### 1. Test bằng Script tự động
```bash
# Linux/macOS
chmod +x test_upload.sh
./test_upload.sh

# Windows PowerShell
.\test_upload.ps1
```

### 2. Test bằng Browser
- Mở file `demo_upload.html` trong browser
- Chọn file và fill form
- Click "Upload File"

### 3. Test bằng cURL
```bash
# Upload file
curl -X POST "https://localhost:5001/api/files/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_file.pdf" \
  -F "tabId=1" \
  -F "categoryId=1" \
  -F "employeeId=1" \
  -F "description=Test upload" \
  -k

# Get file info
curl -X GET "https://localhost:5001/api/files/{fileId}" -k

# Download file
curl -X GET "https://localhost:5001/api/files/{fileId}/download" -k
```

### 4. Test bằng Management Script
```bash
# Chạy tất cả tests
./manage.sh test

# Chỉ test API health
curl -s -k https://localhost:5001/health | jq .
```

### 5. Test file upload với JavaScript
```javascript
// Example frontend integration
const formData = new FormData();
formData.append('file', fileInput.files[0]);
formData.append('tabId', '1');
formData.append('categoryId', '1');
formData.append('employeeId', '1');
formData.append('description', 'Uploaded from frontend');

const response = await fetch('https://localhost:5001/api/files/upload', {
    method: 'POST',
    body: formData
});

const result = await response.json();
console.log('Upload result:', result);
```

## 🚀 Deployment

### Production Settings
- Cập nhật connection string cho production
- Cấu hình MinIO cluster
- Enable HTTPS
- Set up proper CORS policy
- Configure logging providers

### Docker Support
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["FileManagementAPI.csproj", "."]
RUN dotnet restore "./FileManagementAPI.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "FileManagementAPI.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "FileManagementAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "FileManagementAPI.dll"]
```

API đã sẵn sàng sử dụng! Bạn có thể test bằng Swagger UI tại `https://localhost:5001/swagger` khi chạy trong development mode.
