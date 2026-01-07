#!/usr/bin/env bash

# PulseAudio Control Script for Polybar
# Provides easy-to-read sink names for different audio devices

# Icons
ICON_VOLUME=",,"
ICON_MUTED=""
ICON_HEADSET=""
ICON_SPEAKER=""

# Sink configurations (device pattern : icon / display name)
SINK_BOSE="bluez_output.E4_58_BC_2E_14_26.1:${ICON_HEADSET} /bose"
SINK_LOGI="alsa_output.usb-Logitech_Zone_Vibe_125_2216MH00LDD8-00.analog-stereo:${ICON_HEADSET} /logi"
SINK_LOGI_Z407="alsa_output.usb-Logitech_Logi_Z407_*:${ICON_SPEAKER} /logi"
SINK_BUILTIN="alsa_output.pci-*:${ICON_SPEAKER} /builtin"
INPUT_BUILTIN="alsa_input.pci-0000_0b_00.3.analog-stereo:${ICON_SPEAKER}"

# Build the command
pulseaudio-control \
  --node-nicknames-from "device.description" \
  --icons-volume "${ICON_VOLUME}" \
  --icon-muted "${ICON_MUTED}" \
  --node-nickname "${SINK_BOSE}" \
  --node-nickname "${SINK_LOGI}" \
  --node-nickname "${SINK_LOGI_Z407}" \
  --node-nickname "${SINK_BUILTIN}" \
  --node-nickname "${INPUT_BUILTIN}" \
  --node-blacklist "*.monitor" \
  listen
