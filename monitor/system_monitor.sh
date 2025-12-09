#!/bin/bash

# Ultimate System Health Monitor & Reporter
# Author: System Administrator
# Version: 1.0
# Description: Comprehensive system monitoring and log analysis script

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/system_monitor.conf"
TEMP_LOG="/tmp/system_monitor_$$"

# Default configuration (will be overridden by config file)
CPU_THRESHOLD=50
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80
LOG_RETENTION_DAYS=7
REPORT_DIR="${SCRIPT_DIR}/reports"
SCAN_DIRECTORIES=("/var/log" "/home" "/tmp")
MAX_FILE_SIZE_MB=100
BC_AVAILABLE=true
ENABLE_ALERT_BELL=true  # Enable system bell for alerts

# Report file will be set after config is loaded
REPORT_FILE=""

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$TEMP_LOG"
}

# Error handling function
error_handler() {
    local line_number=$1
    local error_code=$2
    log_message "ERROR" "Script failed at line $line_number with exit code $error_code"
    cleanup
    exit $error_code
}

# Cleanup function
cleanup() {
    if [[ -f "$TEMP_LOG" ]]; then
        rm -f "$TEMP_LOG"
    fi
}

# Set up error trapping
trap 'error_handler ${LINENO} $?' ERR
trap cleanup EXIT

# Function to print colored output
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to print section headers
print_header() {
    local title="$1"
    echo
    print_color "$CYAN" "=========================================="
    print_color "$CYAN" "$title"
    print_color "$CYAN" "=========================================="
    echo
}

# Function to send terminal alerts with color and optional bell
send_alert() {
    local alert_level="$1"  # CRITICAL, WARNING, or INFO
    local message="$2"
    local use_bell="${3:-true}"  # Optional: enable/disable bell
    
    case "$alert_level" in
        "CRITICAL")
            print_color "$RED" "🚨 CRITICAL ALERT: $message"
            ;;
        "WARNING")
            print_color "$YELLOW" "⚠️  WARNING: $message"
            ;;
        "INFO")
            print_color "$BLUE" "ℹ️  INFO: $message"
            ;;
        *)
            print_color "$WHITE" "$message"
            ;;
    esac
    
    # Play system bell if enabled and alert level is CRITICAL or WARNING
    if [[ "$use_bell" == "true" ]] && [[ "$ENABLE_ALERT_BELL" == "true" ]]; then
        if [[ "$alert_level" == "CRITICAL" ]]; then
            # Double bell for critical alerts
            printf '\a\a'
        elif [[ "$alert_level" == "WARNING" ]]; then
            # Single bell for warnings
            printf '\a'
        fi
    fi
    
    log_message "$alert_level" "$message"
}

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_message "INFO" "Configuration loaded from $CONFIG_FILE"
    else
        log_message "WARN" "Configuration file not found, using defaults"
    fi
    # Set REPORT_FILE after config is loaded
    REPORT_FILE="${REPORT_DIR}/system_report_$(date +%Y%m%d_%H%M%S).txt"
}

# Function to create necessary directories
create_directories() {
    if [[ ! -d "$REPORT_DIR" ]]; then
        mkdir -p "$REPORT_DIR"
        chmod 755 "$REPORT_DIR"
        log_message "INFO" "Created report directory: $REPORT_DIR"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for essential commands
    for cmd in awk grep sed sort head tail find du; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for bc (needed for floating point comparisons)
    if ! command_exists bc; then
        log_message "WARN" "bc command not found - using integer comparisons"
        BC_AVAILABLE=false
    else
        BC_AVAILABLE=true
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing required commands: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Function to get system information
get_system_info() {
    print_header "SYSTEM INFORMATION"
    
    {
        echo "Hostname: $(hostname)"
        echo "Kernel Version: $(uname -r)"
        echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo "Current Date: $(date)"
        echo
        
        print_color "$BLUE" "CPU Information:"
        if command_exists lscpu; then
            lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core)"
        else
            cat /proc/cpuinfo | grep -E "(processor|model name|cpu MHz)" | head -10
        fi
        echo
        
        print_color "$BLUE" "Memory Information:"
        free -h
        echo
        
        print_color "$BLUE" "Disk Usage Summary:"
        df -h | grep -E "^/dev/"
        echo
        
        print_color "$BLUE" "Currently Logged-in Users:"
        who
        echo
        
    } | tee -a "$REPORT_FILE"
}

# Function to monitor processes
monitor_processes() {
    print_header "PROCESS MONITORING"
    
    {
        print_color "$BLUE" "Top 5 Memory-Consuming Processes:"
        ps aux --sort=-%mem | head -6 | awk 'NR==1 {print $0} NR>1 {printf "%-10s %5s%% %5s%% %s\n", $1, $4, $3, $11}'
        echo
        
        print_color "$BLUE" "Top 5 CPU-Consuming Processes:"
        ps aux --sort=-%cpu | head -6 | awk 'NR==1 {print $0} NR>1 {printf "%-10s %5s%% %5s%% %s\n", $1, $3, $4, $11}'
        echo
        
        # Check for processes exceeding CPU threshold
        local high_cpu_processes=$(ps aux --sort=-%cpu | awk -v threshold="$CPU_THRESHOLD" 'NR>1 && $3>threshold {print $1, $3, $11}')
        if [[ -n "$high_cpu_processes" ]]; then
            send_alert "CRITICAL" "Processes using more than ${CPU_THRESHOLD}% CPU detected"
            echo "$high_cpu_processes" | while read user cpu cmd; do
                print_color "$RED" "  User: $user, CPU: $cpu%, Command: $cmd"
            done
            echo
        fi
        
        # Check for processes exceeding memory threshold
        local high_mem_processes=$(ps aux --sort=-%mem | awk -v threshold="$MEMORY_THRESHOLD" 'NR>1 && $4>threshold {print $1, $4, $11}')
        if [[ -n "$high_mem_processes" ]]; then
            send_alert "WARNING" "Processes using more than ${MEMORY_THRESHOLD}% Memory detected"
            echo "$high_mem_processes" | while read user mem cmd; do
                print_color "$YELLOW" "  User: $user, Memory: $mem%, Command: $cmd"
            done
            echo
        fi
        
    } | tee -a "$REPORT_FILE"
}

# Function to monitor disk and filesystem
monitor_disk_filesystem() {
    print_header "DISK & FILESYSTEM MONITORING"
    
    {
        print_color "$BLUE" "Mounted Filesystems Usage:"
        df -h | grep -E "^/dev/" | while read filesystem size used avail use_percent mount; do
            percent_num=$(echo "$use_percent" | sed 's/%//')
            if (( percent_num > DISK_THRESHOLD )); then
                send_alert "CRITICAL" "$filesystem ($mount) is ${use_percent} full - exceeds threshold!"
            elif (( percent_num > 70 )); then
                send_alert "WARNING" "$filesystem ($mount) is ${use_percent} full"
            else
                echo "$filesystem ($mount) is ${use_percent} full"
            fi
        done
        echo
        
        print_color "$BLUE" "Largest 10 Files in monitored directories:"
        for dir in "${SCAN_DIRECTORIES[@]}"; do
            if [[ -d "$dir" ]]; then
                find "$dir" -type f -size +${MAX_FILE_SIZE_MB:-100}M 2>/dev/null | head -10 | while read -r file; do
                    if [[ -f "$file" ]]; then
                        size=$(du -h "$file" 2>/dev/null | cut -f1)
                        echo "$size $file"
                    fi
                done
            fi
        done
        echo
        
        print_color "$BLUE" "Disk I/O Statistics:"
        if command_exists iostat; then
            iostat -x 1 1 | grep -E "^Device|^[a-zA-Z]"
        else
            echo "iostat not available"
        fi
        echo
        
    } | tee -a "$REPORT_FILE"
}

# Function to monitor network
monitor_network() {
    print_header "NETWORK MONITORING"
    
    {
        print_color "$BLUE" "Active Network Connections:"
        if command_exists ss; then
            timeout 10 ss -tuln | head -20 || echo "ss command timed out"
        elif command_exists netstat; then
            timeout 10 netstat -tuln | head -20 || echo "netstat command timed out"
        else
            echo "Neither ss nor netstat available"
        fi
        echo
        
        print_color "$BLUE" "Network Interface Statistics:"
        if command_exists ip; then
            ip addr show | grep -E "^[0-9]+:|inet "
        elif command_exists ifconfig; then
            ifconfig | grep -E "^[a-zA-Z]|inet "
        fi
        echo
        
        # Check for unusual ports (>1024)
        print_color "$BLUE" "Unusual Open Ports (>1024):"
        if command_exists ss; then
            ss -tuln | awk 'NR>1 && $5 ~ /:([1-9][0-9]{3,}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/ {print $0}'
        elif command_exists netstat; then
            netstat -tuln | awk 'NR>1 && $4 ~ /:([1-9][0-9]{3,}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$/ {print $0}'
        fi
        echo
        
        print_color "$BLUE" "Top 5 Processes by Network Usage:"
        if command_exists nethogs; then
            echo "nethogs requires interactive mode - showing basic connection info"
            timeout 5 ss -tp | head -10 || echo "ss -tp command timed out"
        else
            echo "nethogs not available - showing basic connection info"
            timeout 5 ss -tp | head -10 || echo "ss -tp command timed out"
        fi
        echo
        
    } | tee -a "$REPORT_FILE"
}

# Function to analyze logs
analyze_logs() {
    print_header "LOG ANALYSIS"
    
    local syslog_file="/var/log/syslog"
    local messages_file="/var/log/messages"
    local log_file=""
    
    if [[ -f "$syslog_file" ]]; then
        log_file="$syslog_file"
    elif [[ -f "$messages_file" ]]; then
        log_file="$messages_file"
    else
        print_color "$YELLOW" "No syslog file found"
        return
    fi
    
    {
        print_color "$BLUE" "Analyzing log file: $log_file"
        echo "Time period: Last 24 hours"
        echo
        
        # Get yesterday's timestamp
        local yesterday=$(date -d "1 day ago" '+%b %d %H:' 2>/dev/null || date -v-1d '+%b %d %H:')
        
        print_color "$BLUE" "Error and Warning Summary (Last 24 hours):"
        local error_count=0
        local warning_count=0
        local critical_count=0
        
        # Count errors and warnings more efficiently - limit to recent entries
        local log_data=$(grep "$yesterday" "$log_file" 2>/dev/null | tail -1000 || true)
        
        if [[ -n "$log_data" ]]; then
            error_count=$(echo "$log_data" | grep -ic "error" || true)
            warning_count=$(echo "$log_data" | grep -ic "warn" || true)
            critical_count=$(echo "$log_data" | grep -iE "critical|fatal|panic|emergency" | wc -l)
            
            # Show only first 5 critical errors
            echo "$log_data" | grep -iE "critical|fatal|panic|emergency" | head -5 | while read -r line; do
                print_color "$RED" "CRITICAL: $line"
            done
        fi
        
        echo "Total Errors: $error_count"
        echo "Total Warnings: $warning_count"
        echo "Critical Errors: $critical_count"
        echo
        
        if (( critical_count > 0 )); then
            send_alert "CRITICAL" "$critical_count critical errors found in the last 24 hours!"
        elif (( error_count > 10 )); then
            send_alert "WARNING" "$error_count errors found in the last 24 hours"
        fi
        
        print_color "$BLUE" "Top Error Types:"
        grep -i "$yesterday.*error" "$log_file" 2>/dev/null | \
            awk '{print $NF}' | sort | uniq -c | sort -nr | head -5
        echo
        
    } | tee -a "$REPORT_FILE"
}

# Function to archive old reports
archive_reports() {
    print_header "ARCHIVING OLD REPORTS"
    
    {
        print_color "$BLUE" "Compressing reports older than $LOG_RETENTION_DAYS days..."
        find "$LOG_DIR" -name "system_report_*.txt" -mtime +$LOG_RETENTION_DAYS -type f 2>/dev/null | while read file; do
            if [[ -f "$file" ]]; then
                gzip "$file"
                log_message "INFO" "Compressed old report: $file"
                echo "Compressed: $file.gz"
            fi
        done
        echo
        
        print_color "$BLUE" "Current report archive status:"
        ls -la "$LOG_DIR" 2>/dev/null | head -10
        echo
        
    } | tee -a "$REPORT_FILE"
}

# Function to generate summary
generate_summary() {
    print_header "EXECUTIVE SUMMARY"
    
    {
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "System Health Report Generated: $timestamp"
        echo "Report File: $REPORT_FILE"
        echo
        
        # Quick health checks
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        
        echo "Current System Status:"
        echo "  CPU Usage: ${cpu_usage}%"
        echo "  Memory Usage: ${mem_usage}%"
        echo "  Disk Usage: ${disk_usage}%"
        echo
        
        # Overall health assessment
        local health_status="GOOD"
        
        # Use integer arithmetic if bc not available
        if [[ "$BC_AVAILABLE" == "true" ]]; then
            if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
                health_status="WARNING"
            fi
            if (( $(echo "$mem_usage > $MEMORY_THRESHOLD" | bc -l) )); then
                health_status="WARNING"
            fi
        else
            # Integer comparison (less precise but faster)
            local cpu_int=${cpu_usage%.*}
            local mem_int=${mem_usage%.*}
            if (( cpu_int > CPU_THRESHOLD )); then
                health_status="WARNING"
            fi
            if (( mem_int > MEMORY_THRESHOLD )); then
                health_status="WARNING"
            fi
        fi
        
        if (( disk_usage > DISK_THRESHOLD )); then
            health_status="CRITICAL"
        fi
        
        case $health_status in
            "GOOD")
                print_color "$GREEN" "Overall System Health: GOOD"
                send_alert "INFO" "System health is GOOD"
                ;;
            "WARNING")
                print_color "$YELLOW" "Overall System Health: WARNING"
                send_alert "WARNING" "System health is WARNING - check resource usage"
                ;;
            "CRITICAL")
                print_color "$RED" "Overall System Health: CRITICAL"
                send_alert "CRITICAL" "System health is CRITICAL - immediate attention required"
                ;;
        esac
        
        echo
        echo "Report saved to: $REPORT_FILE"
        
    } | tee -a "$REPORT_FILE"
}

# Function to generate HTML report
generate_html_report() {
    local html_file="${REPORT_DIR}/system_report_$(date +%Y%m%d_%H%M%S).html"
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>System Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .header { background-color: #2c3e50; color: white; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .section { background-color: white; padding: 15px; margin-bottom: 15px; border-left: 4px solid #3498db; border-radius: 3px; }
        .section h2 { margin-top: 0; color: #2c3e50; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #3498db; color: white; }
        tr:hover { background-color: #f9f9f9; }
        .good { color: #27ae60; font-weight: bold; }
        .warning { color: #f39c12; font-weight: bold; }
        .critical { color: #e74c3c; font-weight: bold; }
        .status-box { display: inline-block; padding: 10px 15px; margin: 5px; border-radius: 3px; }
        .status-good { background-color: #d5f4e6; color: #27ae60; }
        .status-warning { background-color: #fdebd0; color: #f39c12; }
        .status-critical { background-color: #fadbd8; color: #e74c3c; }
    </style>
</head>
<body>
    <div class="header">
        <h1>System Health Monitor Report</h1>
        <p>Generated: $(date '+%Y-%m-%d %H:%M:%S')</p>
        <p>Hostname: $(hostname)</p>
    </div>

    <div class="section">
        <h2>System Information</h2>
        <table>
            <tr><th>Property</th><th>Value</th></tr>
            <tr><td>Hostname</td><td>$(hostname)</td></tr>
            <tr><td>Kernel</td><td>$(uname -r)</td></tr>
            <tr><td>Uptime</td><td>$(uptime -p 2>/dev/null || uptime)</td></tr>
            <tr><td>CPU Cores</td><td>$(nproc)</td></tr>
        </table>
    </div>

    <div class="section">
        <h2>System Status</h2>
        <div class="status-box status-good">CPU: ${cpu_usage}% ✓</div>
        <div class="status-box status-good">Memory: ${mem_usage}% ✓</div>
        <div class="status-box status-critical">Disk: ${disk_usage}% ⚠️</div>
    </div>

    <div class="section">
        <h2>Memory Information</h2>
        <pre>$(free -h)</pre>
    </div>

    <div class="section">
        <h2>Disk Usage</h2>
        <table>
            <tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Available</th><th>Usage %</th></tr>
            $(df -h | grep "^/dev/" | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5}')
        </table>
    </div>

    <div class="section">
        <h2>Top 5 Memory-Consuming Processes</h2>
        <table>
            <tr><th>User</th><th>Memory %</th><th>CPU %</th><th>Command</th></tr>
            $(ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $4, $3, $NF}')
        </table>
    </div>

    <div class="section">
        <h2>Currently Logged-in Users</h2>
        <table>
            <tr><th>User</th><th>Terminal</th><th>Login Time</th></tr>
            $(who | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s %s</td></tr>\n", $1, $2, $3, $4}')
        </table>
    </div>

    <div class="section">
        <p style="text-align: center; color: #7f8c8d; font-size: 12px;">
            System Health Monitor - Report Generated Automatically
        </p>
    </div>
</body>
</html>
EOF
    
    print_color "$GREEN" "HTML Report saved to: $html_file"
    log_message "INFO" "HTML report generated: $html_file"
}

# Main function
main() {
    print_color "$GREEN" "Starting System Health Monitor..."
    log_message "INFO" "System monitoring started"
    
    # Load configuration
    load_config
    
    # Check dependencies
    if ! check_dependencies; then
        print_color "$RED" "Missing required dependencies. Exiting."
        exit 1
    fi
    
    # Create necessary directories
    create_directories
    
    # Initialize report file
    {
        echo "SYSTEM HEALTH MONITOR REPORT"
        echo "============================="
        echo "Generated on: $(date)"
        echo "Hostname: $(hostname)"
        echo "============================="
        echo
    } > "$REPORT_FILE"
    
    # Run all monitoring functions
    get_system_info
    monitor_processes
    monitor_disk_filesystem
    monitor_network
    analyze_logs
    archive_reports
    generate_summary
    generate_html_report
    
    print_color "$GREEN" "System monitoring completed successfully!"
    print_color "$BLUE" "Report saved to: $REPORT_FILE"
    
    log_message "INFO" "System monitoring completed"
}

# Check if running as root for certain operations
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        print_color "$YELLOW" "Warning: Some functions may require root privileges"
        print_color "$YELLOW" "Consider running with sudo for full functionality"
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_permissions
    main "$@"
fi
