#!/bin/bash

set -e

echo "🐱 Installing Catppuccin GTK theme..."

# Check for required commands
GIT_CMD=$(command -v git)
FLATPAK_CMD=$(command -v flatpak)

if [ -z "$GIT_CMD" ]; then
  echo "❌ Error: git is not installed."
  exit 1
fi

# Create tools directory if it doesn't exist
TOOLS_DIR="$HOME/tools"
REPO_DIR="$TOOLS_DIR/Catppuccin-GTK-Theme"

mkdir -p "$TOOLS_DIR"

# Clone or update repository
if [ -d "$REPO_DIR" ]; then
  echo "📦 Repository already exists, pulling latest changes..."
  cd "$REPO_DIR"
  git pull
else
  echo "📥 Cloning Catppuccin GTK Theme repository..."
  git clone https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git "$REPO_DIR"
fi

# Navigate to themes directory and run install script
echo "🎨 Installing Catppuccin theme..."
cd "$REPO_DIR/themes"

# Make install script executable if it isn't already
chmod +x install.sh

# Install theme with specified options:
# -c dark: dark color variant only
# -t blue: blue theme accent
# -s standard: standard size variant
# -l: link gtk-4.0 theme for libadwaita apps
./install.sh -c dark -t blue -s standard -l

echo "✅ Catppuccin GTK theme installed successfully!"

# Apply theme settings with gsettings
GSETTINGS_CMD=$(command -v gsettings)

if [ -n "$GSETTINGS_CMD" ]; then
  echo "⚙️  Applying GTK theme settings..."

  # Set GTK theme (GTK3)
  gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Dark-blue"

  # Set window manager theme
  gsettings set org.gnome.desktop.wm.preferences theme "Catppuccin-Dark-blue"

  # Set color scheme to prefer dark mode (GTK4 and modern apps)
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

  echo "✅ Theme settings applied!"
else
  echo "⚠️  gsettings not found, skipping theme configuration."
  echo "   You may need to set the theme manually in your desktop settings."
fi

# Configure flatpak to access themes and icons
if [ -n "$FLATPAK_CMD" ]; then
  echo "🔧 Configuring Flatpak theme access..."

  # Check if flatpak has any apps installed
  if flatpak list 2>/dev/null | grep -q .; then
    echo "📦 Setting up Flatpak theme overrides..."

    # Override flatpak themes to ~/.themes
    sudo flatpak override --filesystem=$HOME/.themes

    # Override flatpak icons to ~/.icons
    sudo flatpak override --filesystem=$HOME/.icons

    # Override flatpak themes to ~/.config/gtk-4.0 locally
    flatpak override --user --filesystem=xdg-config/gtk-4.0

    # Override flatpak themes to ~/.config/gtk-4.0 globally
    sudo flatpak override --filesystem=xdg-config/gtk-4.0

    echo "✅ Flatpak configuration complete!"
  else
    echo "ℹ️  No Flatpak apps installed, skipping Flatpak configuration."
  fi
else
  echo "ℹ️  Flatpak not installed, skipping Flatpak configuration."
fi

echo ""
echo "🎉 All done! The Catppuccin GTK theme is now installed."
echo "   Theme location: ~/.themes/Catppuccin-Dark-blue"
echo "   You may need to log out and log back in for all changes to take effect."
