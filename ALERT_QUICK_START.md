# Alert System - Quick Start Guide

## What's New?

Your monitoring script now has **real-time terminal alerts** with color-coded output and optional system bell notifications. No external setup required!

## Quick Test

Run the script to see alerts in action:

```bash
cd /home/victoire/CascadeProjects/monitor
./system_monitor.sh
```

You'll see colored alerts like:

- 🚨 **CRITICAL ALERT** (Red) - Immediate attention needed
- ⚠️ **WARNING** (Yellow) - Check this soon
- ℹ️ **INFO** (Blue) - Status updates

## Configuration

Edit `/home/victoire/CascadeProjects/monitor/system_monitor.conf`:

```bash
# Thresholds (adjust as needed)
CPU_THRESHOLD=50          # Alert if process uses > 50% CPU
MEMORY_THRESHOLD=80       # Alert if process uses > 80% memory
DISK_THRESHOLD=80         # Alert if disk is > 80% full

# Sound alerts
ENABLE_ALERT_BELL=true    # Set to false to disable bell sound
```

## Alert Types

| Alert | Trigger | Sound |
|-------|---------|-------|
| 🚨 CRITICAL | CPU > 50%, Disk > 80%, Critical errors | 2 beeps |
| ⚠️ WARNING | Memory > 80%, Disk 70-80%, 10+ errors | 1 beep |
| ℹ️ INFO | System health status | No sound |

## Where Alerts Appear

1. **Terminal** - Real-time colored output while script runs
2. **Log file** - Timestamped in `/tmp/system_monitor_*`
3. **Report file** - Included in text report

## Disable Bell (If Annoying)

Edit `system_monitor.conf`:

```bash
ENABLE_ALERT_BELL=false
```

## Adjust Thresholds

Edit `system_monitor.conf` to match your system:

```bash
CPU_THRESHOLD=70          # More lenient (70% instead of 50%)
MEMORY_THRESHOLD=90       # More lenient (90% instead of 80%)
DISK_THRESHOLD=90         # More lenient (90% instead of 80%)
```

## Use with Cron (Automated Monitoring)

Schedule the script to run periodically:

```bash
# Run every hour
0 * * * * /home/victoire/CascadeProjects/monitor/system_monitor.sh >> /var/log/system_monitor.log 2>&1

# Run every 30 minutes
*/30 * * * * /home/victoire/CascadeProjects/monitor/system_monitor.sh >> /var/log/system_monitor.log 2>&1
```

## Full Documentation

See `ALERT_SYSTEM.md` for detailed information about:
- All alert triggers
- Alert function usage
- Terminal bell behavior
- Troubleshooting
- Best practices

## What's Implemented

- ✅ Color-coded terminal alerts
- ✅ System bell notifications (configurable)
- ✅ Alert logging with timestamps
- ✅ CPU threshold alerts
- ✅ Memory threshold alerts
- ✅ Disk threshold alerts
- ✅ Log error analysis alerts
- ✅ System health status alerts

## Next Steps

1. Run the script: `./system_monitor.sh`
2. Adjust thresholds in `system_monitor.conf` if needed
3. Enable/disable bell based on preference
4. Set up cron job for automated monitoring
