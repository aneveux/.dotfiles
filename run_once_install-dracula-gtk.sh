#!/bin/bash

set -e

echo "🧛 Installing Dracula GTK theme..."

# Check for required commands
UNZIP_CMD=$(command -v unzip)
CURL_CMD=$(command -v curl)
GSETTINGS_CMD=$(command -v gsettings)

if [ -z "$UNZIP_CMD" ]; then
  echo "❌ Error: unzip is not installed."
  exit 1
fi

if [ -z "$CURL_CMD" ]; then
  echo "❌ Error: curl is not installed."
  exit 1
fi

if [ -z "$GSETTINGS_CMD" ]; then
  echo "❌ Error: gsettings is not installed."
  exit 1
fi

# Create temporary directory for downloads
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download and install GTK theme
echo "📥 Downloading Dracula GTK theme..."
cd "$TEMP_DIR"
curl -sL https://github.com/dracula/gtk/archive/master.zip -o dracula-gtk.zip

echo "📦 Extracting GTK theme..."
unzip -q dracula-gtk.zip

# Create themes directory if it doesn't exist
mkdir -p ~/.themes

# Remove old theme if it exists and install new one
echo "🎨 Installing theme to ~/.themes/Dracula..."
rm -rf ~/.themes/Dracula
mv gtk-master ~/.themes/Dracula

echo "⚙️  Setting GTK theme via gsettings..."
gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"

# Copy assets to config directory
echo "📁 Copying assets to ~/.config..."
mkdir -p ~/.config
cp -r ~/.themes/Dracula/assets ~/.config/

# Copy GTK 4.0 files
echo "🔧 Copying GTK 4.0 configuration..."
mkdir -p ~/.config/gtk-4.0
cp ~/.themes/Dracula/gtk-4.0/gtk.css ~/.config/gtk-4.0/
cp ~/.themes/Dracula/gtk-4.0/gtk-dark.css ~/.config/gtk-4.0/

# Download and install icon theme
echo "📥 Downloading Dracula icon theme..."
cd "$TEMP_DIR"
curl -sL https://github.com/dracula/gtk/files/5214870/Dracula.zip -o dracula-icons.zip

echo "📦 Extracting icon theme..."
unzip -q dracula-icons.zip

# Create icons directory if it doesn't exist
mkdir -p ~/.icons

# Remove old icons if they exist and install new ones
echo "🖼️  Installing icons to ~/.icons/Dracula..."
rm -rf ~/.icons/Dracula
mv Dracula ~/.icons/

echo "⚙️  Setting icon theme via gsettings..."
gsettings set org.gnome.desktop.interface icon-theme "Dracula"

echo "✅ Dracula GTK theme installation complete!"
