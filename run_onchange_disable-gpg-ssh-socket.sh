#!/bin/bash
# Disable GPG agent's SSH socket — we use a dedicated ssh-agent.service instead
systemctl --user disable --now gpg-agent-ssh.socket 2>/dev/null || true
systemctl --user mask gpg-agent-ssh.socket 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now ssh-agent.service 2>/dev/null || true
