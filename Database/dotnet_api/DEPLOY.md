# File Management API - Deploy Guide

## 🚀 Deployment Options

### 1. Local Development

#### Yêu cầu:
- .NET 8.0 SDK
- SQL Server (LocalDB hoặc SQL Server Express)
- MinIO Server

#### Cài đặt:
```bash
# 1. Clone và restore packages
cd /Users/duylinh/Database/dotnet_api
dotnet restore

# 2. Cập nhật database
dotnet ef database update

# 3. Chạy API
dotnet run
```

### 2. Docker Deployment

#### Chạy với Docker Compose:
```bash
# 1. Build và chạy tất cả services
docker-compose up -d

# 2. Kiểm tra logs
docker-compose logs -f api

# 3. Dừng services
docker-compose down
```

#### Services:
- **API**: http://localhost:5000
- **MinIO Console**: http://localhost:9001
- **SQL Server**: localhost:1433

### 3. Production Deployment

#### Azure App Service + Azure SQL:
```bash
# 1. Tạo Azure resources
az group create --name FileManagementRG --location "Southeast Asia"
az sql server create --name filemanagement-sql --resource-group FileManagementRG --location "Southeast Asia" --admin-user adminuser --admin-password "StrongPassword123!"
az sql db create --resource-group FileManagementRG --server filemanagement-sql --name FileManagementDB --service-objective Basic

# 2. Deploy API
az webapp create --resource-group FileManagementRG --plan FileManagementPlan --name filemanagement-api --runtime "DOTNETCORE|8.0"
az webapp deployment source config --name filemanagement-api --resource-group FileManagementRG --repo-url https://github.com/your-repo/filemanagement-api --branch main
```

#### AWS ECS + RDS:
```bash
# 1. Build và push Docker image
docker build -t filemanagement-api .
docker tag filemanagement-api:latest your-account.dkr.ecr.region.amazonaws.com/filemanagement-api:latest
docker push your-account.dkr.ecr.region.amazonaws.com/filemanagement-api:latest

# 2. Create ECS service
aws ecs create-service --cluster filemanagement-cluster --service-name filemanagement-api --task-definition filemanagement-api:1 --desired-count 1
```

## 🔧 Configuration

### Environment Variables:
```bash
# Database
ConnectionStrings__DefaultConnection="Server=your-server;Database=FileManagementDB;User Id=user;Password=password;TrustServerCertificate=true"

# MinIO
MinIO__Endpoint="your-minio-endpoint:9000"
MinIO__AccessKey="your-access-key"
MinIO__SecretKey="your-secret-key"
MinIO__UseSSL=false

# File Upload
FileUpload__MaxFileSizeMB=50
FileUpload__MaxFileSizeBytes=52428800
```

### SSL Certificate:
```bash
# Development
dotnet dev-certs https --trust

# Production
# Configure SSL certificate in hosting platform
```

## 🧪 Testing

### Unit Tests:
```bash
# Run tests
dotnet test

# With coverage
dotnet test --collect:"XPlat Code Coverage"
```

### API Testing:
```bash
# Make test script executable
chmod +x test_upload.sh

# Run tests
./test_upload.sh
```

### Load Testing:
```bash
# Install wrk
brew install wrk

# Test upload endpoint
wrk -t12 -c400 -d30s -H "Content-Type: multipart/form-data" --script=upload_test.lua http://localhost:5000/api/files/upload
```

## 📊 Monitoring

### Health Checks:
- **Health**: `/health`
- **Swagger**: `/swagger`

### Logging:
- Console logging in development
- Application Insights in production (Azure)
- CloudWatch in production (AWS)

### Metrics:
- Request count và response time
- File upload success/failure rates
- Storage usage

## 🔐 Security

### Authentication:
- JWT tokens
- OAuth 2.0 integration
- API key validation

### Authorization:
- Role-based access control
- Resource-based permissions

### Data Protection:
- HTTPS only
- File encryption at rest
- Input validation và sanitization

## 📈 Scaling

### Horizontal Scaling:
- Load balancer (nginx, HAProxy)
- Multiple API instances
- Database read replicas

### Vertical Scaling:
- Increased CPU/memory
- SSD storage
- Connection pooling

### Caching:
- Redis for session data
- CDN for static content
- Memory caching for frequently accessed data

## 🔄 CI/CD Pipeline

### GitHub Actions:
```yaml
name: Deploy to Production
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0'
      - name: Restore dependencies
        run: dotnet restore
      - name: Build
        run: dotnet build --no-restore
      - name: Test
        run: dotnet test --no-build --verbosity normal
      - name: Deploy
        run: dotnet publish -c Release -o ./publish
```

## 📝 Troubleshooting

### Common Issues:

1. **Database Connection**:
   - Kiểm tra connection string
   - Verify SQL Server đang chạy
   - Check firewall settings

2. **MinIO Connection**:
   - Verify MinIO server đang chạy
   - Check endpoint và credentials
   - Ensure buckets exist

3. **File Upload**:
   - Check file size limits
   - Verify file type permissions
   - Ensure adequate disk space

4. **Performance**:
   - Monitor database queries
   - Check MinIO performance
   - Analyze API response times

### Debugging:
```bash
# Enable detailed logging
export ASPNETCORE_ENVIRONMENT=Development
export Logging__LogLevel__Default=Debug

# Check application logs
docker-compose logs -f api

# Monitor system resources
docker stats
```
