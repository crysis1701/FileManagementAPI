#!/bin/bash

# Comprehensive API Test Script
# Tests all endpoints in the File Management API

API_URL="https://localhost:5001"
TEST_FILE="test_document.pdf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  File Management API - Comprehensive Test${NC}"
    echo -e "${BLUE}=================================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_test_file() {
    echo "This is a test document for API testing" > $TEST_FILE
    echo "Created: $(date)" >> $TEST_FILE
    echo "Content: Sample document for file management system" >> $TEST_FILE
}

cleanup() {
    rm -f $TEST_FILE
    echo "Test file cleaned up"
}

test_health() {
    print_test "Testing health check endpoint..."
    
    response=$(curl -s -k "$API_URL/health" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Health check passed"
        echo "Response: $body"
    else
        print_error "Health check failed (HTTP $http_status)"
    fi
    echo ""
}

test_upload_file() {
    print_test "Testing file upload..."
    
    response=$(curl -s -k -X POST "$API_URL/api/files/upload" \
        -H "Content-Type: multipart/form-data" \
        -F "file=@$TEST_FILE" \
        -F "tabId=1" \
        -F "categoryId=1" \
        -F "employeeId=1" \
        -F "description=Test upload from comprehensive test script" \
        -w "HTTP_STATUS:%{http_code}")
    
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "File upload successful"
        # Extract file ID for later tests
        FILE_ID=$(echo "$body" | jq -r '.data.fileId' 2>/dev/null)
        if [ "$FILE_ID" != "null" ] && [ -n "$FILE_ID" ]; then
            echo "File ID: $FILE_ID"
        fi
    else
        print_error "File upload failed (HTTP $http_status)"
    fi
    echo "Response: $body"
    echo ""
}

test_get_all_tabs() {
    print_test "Testing get all tabs..."
    
    response=$(curl -s -k "$API_URL/api/tabs" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get all tabs successful"
        echo "Response: $(echo "$body" | jq '.data.tabs[0].tab_info' 2>/dev/null || echo "$body")"
    else
        print_error "Get all tabs failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_tab_by_id() {
    print_test "Testing get tab by ID (ID: 1)..."
    
    response=$(curl -s -k "$API_URL/api/tabs/1" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get tab by ID successful"
        echo "Response: $(echo "$body" | jq '.data.tab_info' 2>/dev/null || echo "$body")"
    else
        print_error "Get tab by ID failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_category_files() {
    print_test "Testing get category files (Tab: 1, Category: 1)..."
    
    response=$(curl -s -k "$API_URL/api/tabs/1/categories/1/files" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get category files successful"
        echo "Response: $(echo "$body" | jq '.data.category_info' 2>/dev/null || echo "$body")"
    else
        print_error "Get category files failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_search_files() {
    print_test "Testing search files..."
    
    response=$(curl -s -k "$API_URL/api/files/search?q=test" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Search files successful"
        echo "Response: $(echo "$body" | jq '.data.results[0].file_name' 2>/dev/null || echo "$body")"
    else
        print_error "Search files failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_file_details() {
    if [ -z "$FILE_ID" ]; then
        print_test "Skipping file details test (no file ID available)"
        echo ""
        return
    fi
    
    print_test "Testing get file details (ID: $FILE_ID)..."
    
    response=$(curl -s -k "$API_URL/api/files/$FILE_ID" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get file details successful"
        echo "Response: $(echo "$body" | jq '.data.file_info.file_name' 2>/dev/null || echo "$body")"
    else
        print_error "Get file details failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_toggle_file_active() {
    if [ -z "$FILE_ID" ]; then
        print_test "Skipping toggle active test (no file ID available)"
        echo ""
        return
    fi
    
    print_test "Testing toggle file active status (ID: $FILE_ID)..."
    
    response=$(curl -s -k -X PUT "$API_URL/api/files/$FILE_ID/toggle-active" \
        -H "Content-Type: application/json" \
        -d '{"isActive": false}' \
        -w "HTTP_STATUS:%{http_code}")
    
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Toggle file active successful"
        echo "Response: $(echo "$body" | jq '.message' 2>/dev/null || echo "$body")"
    else
        print_error "Toggle file active failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_files_by_status() {
    print_test "Testing get files by status..."
    
    response=$(curl -s -k "$API_URL/api/files/status?isActive=true" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get files by status successful"
        echo "Response: $(echo "$body" | jq '.data.statistics' 2>/dev/null || echo "$body")"
    else
        print_error "Get files by status failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_file_status_statistics() {
    print_test "Testing get file status statistics..."
    
    response=$(curl -s -k "$API_URL/api/files/status/statistics" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get file status statistics successful"
        echo "Response: $(echo "$body" | jq '.data.overview' 2>/dev/null || echo "$body")"
    else
        print_error "Get file status statistics failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_statistics() {
    print_test "Testing get general statistics..."
    
    response=$(curl -s -k "$API_URL/api/statistics" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get general statistics successful"
        echo "Response: $(echo "$body" | jq '.data.overview' 2>/dev/null || echo "$body")"
    else
        print_error "Get general statistics failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_top_users() {
    print_test "Testing get top users..."
    
    response=$(curl -s -k "$API_URL/api/statistics/top-users" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get top users successful"
        echo "Response: $(echo "$body" | jq '.data.top_uploaders[0].employee_name' 2>/dev/null || echo "$body")"
    else
        print_error "Get top users failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_all_users() {
    print_test "Testing get all users..."
    
    response=$(curl -s -k "$API_URL/api/users" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get all users successful"
        echo "Response: $(echo "$body" | jq '.data.users[0].full_name' 2>/dev/null || echo "$body")"
    else
        print_error "Get all users failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_user_permissions() {
    print_test "Testing get user permissions (User ID: 1)..."
    
    response=$(curl -s -k "$API_URL/api/users/1/permissions" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get user permissions successful"
        echo "Response: $(echo "$body" | jq '.data.user_info' 2>/dev/null || echo "$body")"
    else
        print_error "Get user permissions failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

test_get_user_activity() {
    print_test "Testing get user activity (User ID: 1)..."
    
    response=$(curl -s -k "$API_URL/api/users/1/activity" -w "HTTP_STATUS:%{http_code}")
    http_status=$(echo "$response" | grep -o "HTTP_STATUS:[0-9]*" | cut -d: -f2)
    body=$(echo "$response" | sed 's/HTTP_STATUS:[0-9]*$//')
    
    if [ "$http_status" = "200" ]; then
        print_success "Get user activity successful"
        echo "Response: $(echo "$body" | jq '.data.statistics' 2>/dev/null || echo "$body")"
    else
        print_error "Get user activity failed (HTTP $http_status)"
        echo "Response: $body"
    fi
    echo ""
}

# Main test execution
print_header
echo "API URL: $API_URL"
echo "Test file: $TEST_FILE"
echo ""

# Create test file
create_test_file

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Note: jq is not installed, JSON responses will be shown as raw text"
fi

# Run all tests
test_health
test_upload_file
test_get_all_tabs
test_get_tab_by_id
test_get_category_files
test_search_files
test_get_file_details
test_toggle_file_active
test_get_files_by_status
test_get_file_status_statistics
test_get_statistics
test_get_top_users
test_get_all_users
test_get_user_permissions
test_get_user_activity

# Cleanup
cleanup

echo -e "${BLUE}=================================================${NC}"
echo -e "${GREEN}  All tests completed!${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""
echo "📚 API Documentation: $API_URL/swagger"
echo "🏥 Health Check: $API_URL/health"
echo "🌐 Web Demo: Open demo_upload.html in browser"
