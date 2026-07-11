#!/usr/bin/env bash

# Network status script for Polybar
# Shows network name and Tailscale VPN status

TEAL="#94e2d5"
ICON_WIFI="%{F$TEAL}%{F-}  "
ICON_ETH="%{F$TEAL}󰈀%{F-}  "
ICON_OFF="%{F$TEAL}󰤮%{F-}  "
ICON_VPN="󰦝"

# Check Tailscale VPN status
if command -v tailscale &>/dev/null; then
	if tailscale status 2>/dev/null | grep -q "active\|idle"; then
		vpn_status=" ${ICON_VPN}"
	fi
fi

# Check WiFi
wifi_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes:" | cut -d: -f2)
if [[ -n "$wifi_ssid" ]]; then
	echo "${ICON_WIFI}${wifi_ssid}${vpn_status}"
	exit 0
fi

# Check Ethernet
eth_connection=$(nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null | grep "^ethernet:connected:" | cut -d: -f3 | head -n1)
if [[ -n "$eth_connection" ]]; then
	echo "${ICON_ETH}Wired${vpn_status}"
	exit 0
fi

# Disconnected
echo "${ICON_OFF}Offline"
