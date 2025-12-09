#!/bin/bash

# Simple HTML Report Generator
REPORT_DIR="/home/victoire/CascadeProjects/monitor/reports"
HTML_FILE="${REPORT_DIR}/system_report_$(date +%Y%m%d_%H%M%S).html"

mkdir -p "$REPORT_DIR"

# Gather system info
HOSTNAME=$(hostname)
KERNEL=$(uname -r)
UPTIME=$(uptime -p 2>/dev/null || uptime)
CPU_CORES=$(nproc)
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

# Create HTML Report
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>System Health Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .header h1 { color: #333; margin-bottom: 10px; }
        .header p { color: #666; margin: 5px 0; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-bottom: 20px; }
        .card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .card h2 { color: #333; margin-bottom: 15px; font-size: 18px; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        .status-box { display: flex; justify-content: space-between; align-items: center; padding: 15px; background: #f8f9fa; border-radius: 8px; margin-bottom: 10px; }
        .status-label { font-weight: 600; color: #333; }
        .status-value { font-size: 24px; font-weight: bold; }
        .good { color: #27ae60; }
        .warning { color: #f39c12; }
        .critical { color: #e74c3c; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th { background: #667eea; color: white; padding: 12px; text-align: left; }
        td { padding: 10px 12px; border-bottom: 1px solid #eee; }
        tr:hover { background: #f8f9fa; }
        .info-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
        .info-label { font-weight: 600; color: #666; }
        .info-value { color: #333; }
        .footer { text-align: center; color: white; margin-top: 30px; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🖥️ System Health Monitor Report</h1>
            <p><strong>Generated:</strong> TIMESTAMP</p>
            <p><strong>Hostname:</strong> HOSTNAME</p>
        </div>

        <div class="grid">
            <div class="card">
                <h2>System Status</h2>
                <div class="status-box">
                    <span class="status-label">CPU Usage</span>
                    <span class="status-value CPU_CLASS">CPU_USAGE%</span>
                </div>
                <div class="status-box">
                    <span class="status-label">Memory Usage</span>
                    <span class="status-value MEM_CLASS">MEM_USAGE%</span>
                </div>
                <div class="status-box">
                    <span class="status-label">Disk Usage</span>
                    <span class="status-value DISK_CLASS">DISK_USAGE%</span>
                </div>
            </div>

            <div class="card">
                <h2>System Information</h2>
                <div class="info-row">
                    <span class="info-label">Kernel:</span>
                    <span class="info-value">KERNEL</span>
                </div>
                <div class="info-row">
                    <span class="info-label">CPU Cores:</span>
                    <span class="info-value">CPU_CORES</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Uptime:</span>
                    <span class="info-value">UPTIME</span>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>Memory Information</h2>
            <pre style="background: #f8f9fa; padding: 15px; border-radius: 8px; overflow-x: auto;">MEMORY_INFO</pre>
        </div>

        <div class="card">
            <h2>Disk Usage</h2>
            <table>
                <thead>
                    <tr>
                        <th>Filesystem</th>
                        <th>Size</th>
                        <th>Used</th>
                        <th>Available</th>
                        <th>Usage %</th>
                    </tr>
                </thead>
                <tbody>
DISK_TABLE
                </tbody>
            </table>
        </div>

        <div class="card">
            <h2>Top 5 Memory-Consuming Processes</h2>
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Memory %</th>
                        <th>CPU %</th>
                        <th>Command</th>
                    </tr>
                </thead>
                <tbody>
PROCESS_TABLE
                </tbody>
            </table>
        </div>

        <div class="card">
            <h2>Logged-in Users</h2>
            <table>
                <thead>
                    <tr>
                        <th>User</th>
                        <th>Terminal</th>
                        <th>Login Time</th>
                    </tr>
                </thead>
                <tbody>
USERS_TABLE
                </tbody>
            </table>
        </div>

        <div class="footer">
            <p>System Health Monitor - Automated Report Generation</p>
        </div>
    </div>
</body>
</html>
HTMLEOF

# Gather all data first
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MEMORY_INFO=$(free -h)
DISK_TABLE=$(df -h | grep "^/dev/" | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5}')
PROCESS_TABLE=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $4, $3, $NF}')
USERS_TABLE=$(who | awk '{printf "<tr><td>%s</td><td>%s</td><td>%s %s</td></tr>\n", $1, $2, $3, $4}')

# Determine color classes
if (( ${CPU_USAGE%.*} > 50 )); then
    CPU_CLASS="warning"
else
    CPU_CLASS="good"
fi

if (( ${MEM_USAGE%.*} > 80 )); then
    MEM_CLASS="critical"
elif (( ${MEM_USAGE%.*} > 50 )); then
    MEM_CLASS="warning"
else
    MEM_CLASS="good"
fi

if (( ${DISK_USAGE%.*} > 80 )); then
    DISK_CLASS="critical"
elif (( ${DISK_USAGE%.*} > 70 )); then
    DISK_CLASS="warning"
else
    DISK_CLASS="good"
fi

# Use Python for safe replacement
python3 << PYEOF
import re

with open("$HTML_FILE", "r") as f:
    content = f.read()

# Replace all placeholders
content = content.replace("TIMESTAMP", "$TIMESTAMP")
content = content.replace("HOSTNAME", "$HOSTNAME")
content = content.replace("CPU_USAGE", "$CPU_USAGE")
content = content.replace("MEM_USAGE", "$MEM_USAGE")
content = content.replace("DISK_USAGE", "$DISK_USAGE")
content = content.replace("KERNEL", "$KERNEL")
content = content.replace("CPU_CORES", "$CPU_CORES")
content = content.replace("UPTIME", "$UPTIME")
content = content.replace("CPU_CLASS", "$CPU_CLASS")
content = content.replace("MEM_CLASS", "$MEM_CLASS")
content = content.replace("DISK_CLASS", "$DISK_CLASS")
content = content.replace("MEMORY_INFO", """$MEMORY_INFO""")
content = content.replace("DISK_TABLE", """$DISK_TABLE""")
content = content.replace("PROCESS_TABLE", """$PROCESS_TABLE""")
content = content.replace("USERS_TABLE", """$USERS_TABLE""")

with open("$HTML_FILE", "w") as f:
    f.write(content)
PYEOF

echo "✅ HTML Report generated: $HTML_FILE"
echo "📊 Open in browser to view the formatted report"
