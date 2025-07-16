#!/bin/bash

# Script quản lý hệ thống File Management
# Sử dụng: ./manage.sh [start|stop|restart|status|logs|test]

set -e

PROJECT_NAME="FileManagement"
API_DIR="/Users/duylinh/Database/dotnet_api"
DB_NAME="FileManagementDB"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===================================${NC}"
    echo -e "${BLUE}   File Management System${NC}"
    echo -e "${BLUE}===================================${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check .NET
    if ! command -v dotnet &> /dev/null; then
        print_error ".NET SDK not found. Please install .NET 8.0 SDK"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found. Please install Docker"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose not found. Please install Docker Compose"
        exit 1
    fi
    
    print_status "Prerequisites OK"
}

start_system() {
    print_header
    print_status "Starting File Management System..."
    
    cd "$API_DIR"
    
    # Start Docker services
    print_status "Starting Docker services (SQL Server + MinIO)..."
    docker-compose up -d sqlserver minio
    
    # Wait for services to be ready
    print_status "Waiting for services to be ready..."
    sleep 30
    
    # Create database if not exists
    print_status "Setting up database..."
    setup_database
    
    # Start API
    print_status "Starting .NET API..."
    dotnet run --urls="http://localhost:5000;https://localhost:5001" &
    API_PID=$!
    echo $API_PID > api.pid
    
    # Wait for API to start
    sleep 10
    
    # Test API health
    if curl -s -k https://localhost:5001/health | grep -q "healthy"; then
        print_status "✅ File Management System started successfully!"
        print_status "API: https://localhost:5001"
        print_status "Swagger: https://localhost:5001/swagger"
        print_status "MinIO Console: http://localhost:9001"
        print_status "SQL Server: localhost:1433"
    else
        print_error "❌ API failed to start properly"
        exit 1
    fi
}

stop_system() {
    print_header
    print_status "Stopping File Management System..."
    
    cd "$API_DIR"
    
    # Stop API
    if [ -f api.pid ]; then
        API_PID=$(cat api.pid)
        if kill -0 "$API_PID" 2>/dev/null; then
            print_status "Stopping .NET API (PID: $API_PID)..."
            kill "$API_PID"
        fi
        rm -f api.pid
    fi
    
    # Stop Docker services
    print_status "Stopping Docker services..."
    docker-compose down
    
    print_status "✅ File Management System stopped"
}

restart_system() {
    stop_system
    sleep 5
    start_system
}

show_status() {
    print_header
    print_status "System Status:"
    
    cd "$API_DIR"
    
    # Check API
    if [ -f api.pid ]; then
        API_PID=$(cat api.pid)
        if kill -0 "$API_PID" 2>/dev/null; then
            print_status "🟢 API: Running (PID: $API_PID)"
        else
            print_warning "🔴 API: Not running"
        fi
    else
        print_warning "🔴 API: Not running"
    fi
    
    # Check Docker services
    if docker-compose ps | grep -q "Up"; then
        print_status "🟢 Docker services:"
        docker-compose ps
    else
        print_warning "🔴 Docker services: Not running"
    fi
    
    # Check API health
    if curl -s -k https://localhost:5001/health | grep -q "healthy"; then
        print_status "🟢 API Health: OK"
    else
        print_warning "🔴 API Health: Not responding"
    fi
    
    # Check MinIO
    if curl -s http://localhost:9000/minio/health/ready | grep -q "OK"; then
        print_status "🟢 MinIO: Ready"
    else
        print_warning "🔴 MinIO: Not ready"
    fi
}

show_logs() {
    print_header
    print_status "System Logs:"
    
    cd "$API_DIR"
    
    echo -e "${BLUE}--- Docker Logs ---${NC}"
    docker-compose logs --tail=50 -f
}

run_tests() {
    print_header
    print_status "Running tests..."
    
    cd "$API_DIR"
    
    # Test API health
    print_status "Testing API health..."
    if curl -s -k https://localhost:5001/health | grep -q "healthy"; then
        print_status "✅ API Health: OK"
    else
        print_error "❌ API Health: Failed"
        return 1
    fi
    
    # Test various API endpoints
    print_status "Testing API endpoints..."
    
    # Test tabs API
    if curl -s -k https://localhost:5001/api/tabs | grep -q "success"; then
        print_status "✅ Tabs API: Working"
    else
        print_warning "❌ Tabs API: Not responding"
    fi
    
    # Test files API
    if curl -s -k https://localhost:5001/api/files | grep -q "success"; then
        print_status "✅ Files API: Working"
    else
        print_warning "❌ Files API: Not responding"
    fi
    
    # Test statistics API
    if curl -s -k https://localhost:5001/api/statistics | grep -q "success"; then
        print_status "✅ Statistics API: Working"
    else
        print_warning "❌ Statistics API: Not responding"
    fi
    
    # Test users API
    if curl -s -k https://localhost:5001/api/users | grep -q "success"; then
        print_status "✅ Users API: Working"
    else
        print_warning "❌ Users API: Not responding"
    fi
    
    # Run upload test
    print_status "Running upload test..."
    if [ -f test_upload.sh ]; then
        chmod +x test_upload.sh
        ./test_upload.sh
    else
        print_warning "Upload test script not found"
    fi
    
    # Run .NET tests
    print_status "Running .NET tests..."
    dotnet test --logger "console;verbosity=normal"
}

setup_database() {
    print_status "Setting up database..."
    
    # Wait for SQL Server to be ready
    for i in {1..30}; do
        if docker-compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "StrongPassword123!" -Q "SELECT 1" > /dev/null 2>&1; then
            print_status "SQL Server is ready"
            break
        fi
        print_status "Waiting for SQL Server... ($i/30)"
        sleep 2
    done
    
    # Create database and tables
    print_status "Creating database and tables..."
    docker-compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "StrongPassword123!" -i /var/opt/mssql/file_management_schema.sql 2>/dev/null || true
    
    # Insert sample data
    print_status "Inserting sample data..."
    docker-compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "StrongPassword123!" -i /var/opt/mssql/sample_data.sql 2>/dev/null || true
}

backup_system() {
    print_header
    print_status "Creating system backup..."
    
    BACKUP_DIR="/Users/duylinh/Database/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    print_status "Backing up database..."
    docker-compose exec -T sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "StrongPassword123!" -Q "BACKUP DATABASE [$DB_NAME] TO DISK = '/var/opt/mssql/backup/filemanagement_$(date +%Y%m%d_%H%M%S).bak'" 2>/dev/null || true
    
    # Backup MinIO data
    print_status "Backing up MinIO data..."
    docker-compose exec -T minio mc mirror --overwrite /data "$BACKUP_DIR/minio_data" 2>/dev/null || true
    
    # Backup API code
    print_status "Backing up API code..."
    cp -r "$API_DIR" "$BACKUP_DIR/api_code"
    
    print_status "✅ Backup completed: $BACKUP_DIR"
}

show_help() {
    print_header
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start      Start the File Management System"
    echo "  stop       Stop the File Management System"
    echo "  restart    Restart the File Management System"
    echo "  status     Show system status"
    echo "  logs       Show system logs"
    echo "  test       Run system tests"
    echo "  backup     Create system backup"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 logs"
}

# Main script logic
case "$1" in
    start)
        check_prerequisites
        start_system
        ;;
    stop)
        stop_system
        ;;
    restart)
        check_prerequisites
        restart_system
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    test)
        run_tests
        ;;
    backup)
        backup_system
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
