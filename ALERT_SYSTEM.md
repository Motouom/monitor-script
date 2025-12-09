# Terminal Alert System Documentation

## Overview

The system monitoring script now includes a comprehensive **terminal alert system** with color-coded output and optional system bell notifications. This provides immediate, real-time feedback during script execution without requiring external setup.

## Features

### 1. Color-Coded Alerts

Alerts are displayed in the terminal with distinct colors for different severity levels:

- **🚨 CRITICAL ALERT** (Red) - Immediate attention required
  - Processes exceeding CPU threshold
  - Disk usage exceeding threshold
  - Critical system errors in logs
  - Overall system health is CRITICAL

- **⚠️ WARNING** (Yellow) - Requires attention
  - Processes exceeding memory threshold
  - Disk usage between 70-80%
  - Multiple errors in logs
  - Overall system health is WARNING

- **ℹ️ INFO** (Blue) - Informational
  - System health is GOOD
  - General status updates

### 2. System Bell Notifications

The script can emit audio alerts via the system bell:

- **CRITICAL alerts**: Double bell (`\a\a`) - Two beeps
- **WARNING alerts**: Single bell (`\a`) - One beep
- **INFO alerts**: No bell

This allows you to hear alerts even if you're not looking at the terminal.

## Configuration

### Enable/Disable Alert Bell

Edit `/home/victoire/CascadeProjects/monitor/system_monitor.conf`:

```bash
# Enable system bell for alerts (true/false)
ENABLE_ALERT_BELL=true
```

Set to `false` to disable the bell sound.

## Alert Triggers

### Process Monitoring Alerts

```text
CPU Threshold Alert:
- Triggered when any process uses > CPU_THRESHOLD% CPU (default: 50%)
- Severity: CRITICAL
- Shows: User, CPU %, Command name

Memory Threshold Alert:
- Triggered when any process uses > MEMORY_THRESHOLD% Memory (default: 80%)
- Severity: WARNING
- Shows: User, Memory %, Command name
```

### Disk Monitoring Alerts

```text
Critical Disk Alert:
- Triggered when filesystem usage > DISK_THRESHOLD% (default: 80%)
- Severity: CRITICAL
- Shows: Filesystem, Mount point, Usage %

Warning Disk Alert:
- Triggered when filesystem usage > 70%
- Severity: WARNING
- Shows: Filesystem, Mount point, Usage %
```

### Log Analysis Alerts

```text
Critical Log Alert:
- Triggered when critical/fatal/panic/emergency errors found in last 24 hours
- Severity: CRITICAL
- Shows: Error count

Error Count Alert:
- Triggered when > 10 errors found in last 24 hours
- Severity: WARNING
- Shows: Error count
```

### System Health Alerts

```text
Overall Health Status:
- GOOD: System is operating normally (INFO alert)
- WARNING: Resource usage is high (WARNING alert)
- CRITICAL: System requires immediate attention (CRITICAL alert)
```

## Alert Function Usage

### Basic Usage

```bash
send_alert "CRITICAL" "This is a critical message"
send_alert "WARNING" "This is a warning message"
send_alert "INFO" "This is an info message"
```

### Disable Bell for Specific Alert

```bash
send_alert "CRITICAL" "Message" false  # No bell, even if enabled globally
```

## Example Output

When an alert is triggered, you'll see:

```text
🚨 CRITICAL ALERT: Processes using more than 50% CPU detected
  User: root, CPU: 75.3%, Command: /usr/bin/python3
  User: user, CPU: 62.1%, Command: /opt/app/server

⚠️  WARNING: /dev/sda1 (/home) is 78% full

ℹ️  INFO: System health is GOOD
```

## Logging

All alerts are automatically logged to the temporary log file with timestamps:

```text
[2024-12-09 18:30:45] [CRITICAL] Processes using more than 50% CPU detected
[2024-12-09 18:30:46] [WARNING] /dev/sda1 (/home) is 78% full
[2024-12-09 18:31:00] [INFO] System health is GOOD
```

## Terminal Bell Behavior

The system bell works in most terminals:

- **Linux terminals**: Uses `printf '\a'` to emit bell
- **SSH sessions**: Bell may be disabled by terminal settings
- **Screen/Tmux**: May require configuration to pass bell through
- **Windows Terminal/WSL**: Supported

### Troubleshooting Bell

If you don't hear the bell:

1. Check if bell is enabled in your terminal settings
2. Check volume settings on your system
3. Disable bell alerts in config if not needed:

```bash
ENABLE_ALERT_BELL=false
```

## Integration with Reports

Alerts are displayed in real-time during script execution AND logged to the text report file for later review.

## Best Practices

1. **Monitor the terminal output** - Alerts provide immediate feedback
2. **Review the report file** - Contains all alerts with timestamps
3. **Adjust thresholds** - Customize CPU_THRESHOLD, MEMORY_THRESHOLD, DISK_THRESHOLD in config
4. **Use with cron** - Combine with scheduled execution for continuous monitoring
5. **Redirect output** - Capture alerts in a log file for archival:

```bash
./system_monitor.sh 2>&1 | tee monitoring.log
```

## Next Steps

The alert system is now ready to use. You can:

1. Run the script to see alerts in action
2. Adjust thresholds in `system_monitor.conf` as needed
3. Enable/disable the bell based on your preference
4. Integrate with cron for automated monitoring
