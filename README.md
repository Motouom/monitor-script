# System Health Monitor

Automated Linux system monitoring with daily HTML reports at 4:30 PM.

## Features

- System information (CPU, memory, disk, users, kernel, uptime, hostname)
- Process monitoring (top 5 CPU/memory processes, threshold alerts)
- Disk monitoring (filesystem usage, 80% alerts, largest files)
- Network monitoring (active connections, unusual ports)
- Log analysis (24-hour error scanning, critical alerts)
- HTML reports with color-coded status indicators
- Configurable thresholds via configuration file
- Automated daily execution via cron at 4:30 PM

## Project Structure

```
/home/victoire/CascadeProjects/
├── README.md
├── monitor/
│   ├── system_monitor.sh
│   ├── system_monitor.conf
│   ├── setup_cron.sh
│   ├── generate_html_report.sh
│   └── reports/
```

## Quick Start

Generate an HTML report:
```bash
/home/victoire/CascadeProjects/monitor/generate_html_report.sh
```

View reports:
```bash
ls -la /home/victoire/CascadeProjects/monitor/reports/
```

Run full monitoring:
```bash
/home/victoire/CascadeProjects/monitor/system_monitor.sh
```

Manage cron job:
```bash
crontab -l | grep system_monitor
/home/victoire/CascadeProjects/monitor/setup_cron.sh remove
/home/victoire/CascadeProjects/monitor/setup_cron.sh test
```

## Configuration

Edit `monitor/system_monitor.conf` to customize:

- CPU_THRESHOLD=50 (CPU alert threshold %)
- MEMORY_THRESHOLD=80 (Memory alert threshold %)
- DISK_THRESHOLD=80 (Disk alert threshold %)
- LOG_RETENTION_DAYS=7 (Days to keep reports)
- REPORT_DIR (Where to save reports)

## Automation

Cron schedule: Daily at 4:30 PM (16:30)

```
30 16 * * * /home/victoire/CascadeProjects/monitor/system_monitor.sh
```
