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
    
    echo "SUCCESS: HaGeZi Pro list updated and dnsmasq restarted." >> "$LOG_FILE"
else
    echo "ERROR: Download failed or file is too small. Keeping old list." >> "$LOG_FILE"
    rm -f "$TMP_FILE"
    exit 1
fi
