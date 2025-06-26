#!/bin/bash
# Usage: ./parse-wg-endpoint.sh /etc/wireguard/nl.conf

CONF_FILE="$1"
if [[ ! -f "$CONF_FILE" ]]; then
    echo "File not found: $CONF_FILE" >&2
    exit 1
fi

# etract the endpoint line
line=$(sudo grep -i '^Endpoint' "$CONF_FILE" | head -n1)
endpoint=$(echo "$line" | sed -E 's/^[^=]*=[[:space:]]*//')
ip=${endpoint%%:*}
port=${endpoint##*:}

# Output in a format easily parsed by main script
echo "$ip $port"
