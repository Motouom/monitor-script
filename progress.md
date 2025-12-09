# 🧩 Challenging Bash Task: System Monitoring & Log Analyzer

**Task Name:** Ultimate System Health Monitor & Reporter

## Objective

Write a Bash script that continuously monitors your Linux system and produces a detailed daily report. The script should handle errors gracefully, log events, and send notifications (via terminal or email).

## Requirements / Features

### System Information Section

- [x] Show CPU, memory, disk usage
- [x] List all currently logged-in users
- [x] Report kernel version, uptime, and hostname

### Process Monitoring

- [x] Identify the top 5 memory-consuming processes
- [x] Identify the top 5 CPU-consuming processes
- [x] Alert if any process is using more than a configurable threshold (e.g., 50% CPU)

### Disk & Filesystem Monitoring

- [x] List all mounted filesystems and their usage
- [x] Alert if any filesystem is more than 80% full
- [x] Find the largest 10 files on the system

### Network Monitoring

- [ ] List all active network connections (TCP/UDP)
- [x] Show the top 5 processes by network usage
- [x] Detect if any unusual open ports exist (ports > 1024)

### Log Analysis

- [ ] Scan /var/log/syslog (or /var/log/messages) for errors/warnings in the last 24 hours
- [ ] Count how many times each error appears
- [ ] Highlight critical errors only

### Automation & Archiving

- [ ] Save the report as a timestamped file in /var/log/system-reports/
- [ ] Compress older reports (older than 7 days) automatically
- [x] Optionally, print a summary to terminal

## Advanced Requirements

- [ ] Use awk, sed, grep, cut, sort, uniq, find, and du effectively
- [ ] Implement functions for each section of the script
- [x] Add colorful output in the terminal for warnings/errors
- [ ] Make the script configurable via a .conf file (thresholds, directories, email notifications, etc.)
- [x] Include error handling (e.g., if a command fails, log the error but continue)