#!/usr/bin/env bash

# Network status script for Polybar
# Shows network name and Tailscale VPN status

# VPN icon
ICON_VPN="󰦝"

# Check Tailscale VPN status
if command -v tailscale &> /dev/null; then
    if tailscale status 2>/dev/null | grep -q "active\|idle"; then
        vpn_status=" ${ICON_VPN}"
    fi
fi

# Check WiFi
wifi_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes:" | cut -d: -f2)
if [[ -n "$wifi_ssid" ]]; then
    echo "${wifi_ssid}${vpn_status}"
    exit 0
fi

# Check Ethernet
eth_connection=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null | grep "^ethernet:connected:" | cut -d: -f3 | head -n1)
if [[ -n "$eth_connection" ]]; then
    echo "${eth_connection}${vpn_status}"
    exit 0
fi

# Disconnected
echo "Offline"
