#!/bin/bash

# Script test upload file đơn giản cho API
# Chạy: chmod +x test_upload.sh && ./test_upload.sh

API_URL="https://localhost:5001"
TEST_FILE="test_file.txt"

# Tạo file test
echo "This is a test file for upload API" > $TEST_FILE

echo "🔄 Testing File Upload API..."
echo "API URL: $API_URL"
echo "Test file: $TEST_FILE"
echo ""

# Test upload file
echo "📤 Uploading file..."
curl -X POST "$API_URL/api/files/upload" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@$TEST_FILE" \
  -F "tabId=1" \
  -F "categoryId=1" \
  -F "employeeId=1" \
  -F "description=Test upload from script" \
  -k -v

echo ""
echo ""

# Test health check
echo "🏥 Testing Health Check..."
curl -X GET "$API_URL/health" -k -s | jq .

echo ""
echo ""

# Test API documentation
echo "📚 API Documentation available at:"
echo "$API_URL/swagger"

# Cleanup
rm -f $TEST_FILE

echo ""
echo "✅ Test completed!"
