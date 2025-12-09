#!/bin/bash

# Cron Job Setup Script for System Monitor
# This script helps set up automated execution of the system monitor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_SCRIPT="$SCRIPT_DIR/system_monitor.sh"
CRON_ENTRY="30 16 * * * $MONITOR_SCRIPT"

# Function to check if script exists
check_script() {
    if [[ ! -f "$MONITOR_SCRIPT" ]]; then
        echo "Error: System monitor script not found at $MONITOR_SCRIPT"
        exit 1
    fi
}

# Function to setup cron job
setup_cron() {
    echo "Setting up cron job for daily system monitoring at 4:30 PM..."
    
    # Check if cron entry already exists
    if crontab -l 2>/dev/null | grep -q "system_monitor.sh"; then
        echo "Cron entry already exists. Removing old entry..."
        crontab -l 2>/dev/null | grep -v "system_monitor.sh" | crontab -
    fi
    
    # Add new cron entry
    (crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -
    
    echo "Cron job setup complete!"
    echo "Schedule: Daily at 4:30 PM (16:30)"
    echo "Command: $MONITOR_SCRIPT"
}

# Function to remove cron job
remove_cron() {
    echo "Removing cron job for system monitor..."
    
    if crontab -l 2>/dev/null | grep -q "system_monitor.sh"; then
        crontab -l 2>/dev/null | grep -v "system_monitor.sh" | crontab -
        echo "Cron job removed successfully!"
    else
        echo "No cron job found for system monitor."
    fi
}

# Function to show current cron jobs
show_cron() {
    echo "Current cron jobs:"
    crontab -l 2>/dev/null | grep -n "system_monitor.sh" || echo "No system monitor cron jobs found."
}

# Function to test script execution
test_script() {
    echo "Testing system monitor script execution..."
    echo "This will run the script with output to terminal only..."
    
    if bash "$MONITOR_SCRIPT" --test 2>/dev/null || bash "$MONITOR_SCRIPT"; then
        echo "Script test completed successfully!"
    else
        echo "Script test failed!"
        exit 1
    fi
}

# Function to show usage
usage() {
    echo "Usage: $0 {setup|remove|show|test|help}"
    echo
    echo "Commands:"
    echo "  setup  - Install cron job for daily execution"
    echo "  remove - Remove existing cron job"
    echo "  show   - Show current cron jobs for system monitor"
    echo "  test   - Test script execution"
    echo "  help   - Show this help message"
}

# Main script logic
case "${1:-help}" in
    setup)
        check_script
        setup_cron
        ;;
    remove)
        remove_cron
        ;;
    show)
        show_cron
        ;;
    test)
        check_script
        test_script
        ;;
    help|*)
        usage
        ;;
esac
