#!/bin/bash

# configuration
LIST_URL="https://raw.githubusercontent.com/hagezi/dns-blocklists/main/dnsmasq/pro.txt"
TARGET_FILE="/etc/dnsmasq.d/hagezi.pro.conf"
TMP_FILE="/tmp/hagezi.tmp"
LOG_FILE="/home/melik/Documents/projects/scripts/dns/update.log"

echo "--- Update started: $(date) ---" >> "$LOG_FILE"

# 1. download the new list
curl -L "$LIST_URL" -o "$TMP_FILE"

# 2. validate: check if file exists and has content (size > 100kb)
if [ -s "$TMP_FILE" ] && [ $(stat -c%s "$TMP_FILE") -gt 102400 ]; then
    # move to the dnsmasq directory
    mv "$TMP_FILE" "$TARGET_FILE"
    
    # 3. restart dnsmasq to load the new list
    systemctl restart dnsmasq

    # 4. delete cache files if any (optional)
    echo "Clearing Firefox cache2 folders..." >> "$LOG_FILE"
    find /home/melik/.cache/mozilla/firefox/ -name "cache2" -type d -exec rm -rf {} + 2>/dev/null
    echo "Firefox cache cleared successfully." >> "$LOG_FILE"
    
    echo "SUCCESS: HaGeZi Pro list updated, dnsmasq restarted and firefox log is deleted" >> "$LOG_FILE"
else
    echo "ERROR: Download failed or file is too small. Keeping old list." >> "$LOG_FILE"
    rm -f "$TMP_FILE"
    exit 1
fi
