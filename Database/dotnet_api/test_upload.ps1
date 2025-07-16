# PowerShell script test upload file cho Windows
# Chạy: .\test_upload.ps1

$API_URL = "https://localhost:5001"
$TEST_FILE = "test_file.txt"

# Tạo file test
"This is a test file for upload API from PowerShell" | Out-File -FilePath $TEST_FILE -Encoding utf8

Write-Host "🔄 Testing File Upload API..." -ForegroundColor Cyan
Write-Host "API URL: $API_URL" -ForegroundColor Green
Write-Host "Test file: $TEST_FILE" -ForegroundColor Green
Write-Host ""

# Test upload file
Write-Host "📤 Uploading file..." -ForegroundColor Yellow

$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = (
    "--$boundary",
    "Content-Disposition: form-data; name=`"file`"; filename=`"$TEST_FILE`"",
    "Content-Type: text/plain$LF",
    (Get-Content $TEST_FILE -Raw),
    "--$boundary",
    "Content-Disposition: form-data; name=`"tabId`"$LF",
    "1",
    "--$boundary",
    "Content-Disposition: form-data; name=`"categoryId`"$LF",
    "1",
    "--$boundary",
    "Content-Disposition: form-data; name=`"employeeId`"$LF",
    "1",
    "--$boundary",
    "Content-Disposition: form-data; name=`"description`"$LF",
    "Test upload from PowerShell script",
    "--$boundary--$LF"
) -join $LF

try {
    $response = Invoke-RestMethod -Uri "$API_URL/api/files/upload" -Method Post -ContentType "multipart/form-data; boundary=$boundary" -Body $bodyLines -SkipCertificateCheck
    Write-Host "✅ Upload successful!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 3)" -ForegroundColor Green
} catch {
    Write-Host "❌ Upload failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test health check
Write-Host "🏥 Testing Health Check..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "$API_URL/health" -Method Get -SkipCertificateCheck
    Write-Host "✅ Health check successful!" -ForegroundColor Green
    Write-Host "Response: $($healthResponse | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health check failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test API documentation
Write-Host "📚 API Documentation available at:" -ForegroundColor Cyan
Write-Host "$API_URL/swagger" -ForegroundColor Blue

# Cleanup
Remove-Item $TEST_FILE -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ Test completed!" -ForegroundColor Green
