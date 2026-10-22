#!/bin/bash
# Nextcloud's packaged user unit starts before DISPLAY exists and crash-loops at login;
# ~/.config/autostart/Nextcloud.desktop (run by dex from i3) starts it instead.
systemctl --user disable --now com.nextcloud.desktopclient.nextcloud.service 2>/dev/null || true
systemctl --user mask com.nextcloud.desktopclient.nextcloud.service 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true
