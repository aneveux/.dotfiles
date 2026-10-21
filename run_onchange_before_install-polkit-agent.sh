#!/usr/bin/env bash
# i3 has no polkit agent of its own; ~/.i3/config execs the GNOME one.
set -euo pipefail
sudo apt-get install -y --no-install-recommends policykit-1-gnome
