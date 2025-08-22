#!/usr/bin/env bash
set -euo pipefail

# Global variables
APPLY_MODE=false
DISTRO_ID=""
PACKAGE_MANAGER=""
PACKAGES_FILE="$HOME/packages.txt"

# Parse command line arguments
parse_arguments() {
  if [[ "${1:-}" == "--apply" ]]; then
    APPLY_MODE=true
  fi
}

# Detect OS distribution and set appropriate package manager
detect_os_and_package_manager() {
  if [[ ! -f /etc/os-release ]]; then
    echo "Error: Cannot detect OS - /etc/os-release not found"
    exit 1
  fi

  source /etc/os-release
  DISTRO_ID="$ID"

  case "$DISTRO_ID" in
  ubuntu | debian)
    PACKAGE_MANAGER="apt"
    ;;
  manjaro | arch)
    if command -v yay &>/dev/null; then
      PACKAGE_MANAGER="yay"
    else
      PACKAGE_MANAGER="pacman"
    fi
    ;;
  *)
    echo "Error: Unsupported OS: $DISTRO_ID"
    exit 1
    ;;
  esac
}

# Read package list from file, filtering out comments and empty lines
read_package_list() {
  local packages=()

  if [[ ! -f "$PACKAGES_FILE" ]]; then
    echo "Error: Package file '$PACKAGES_FILE' not found"
    exit 1
  fi

  while IFS= read -r line; do
    # Skip empty lines and lines starting with #
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    # Extract package name (first word)
    local package_name
    package_name=$(echo "$line" | awk '{print $1}')
    [[ -n "$package_name" ]] && packages+=("$package_name")
  done <"$PACKAGES_FILE"

  echo "${packages[@]}"
}

# Check if a package is available in apt repositories
is_package_available_in_apt() {
  local package_name="$1"
  apt-cache show "$package_name" &>/dev/null
}

# Filter packages for Ubuntu: separate available vs unavailable packages
filter_ubuntu_packages() {
  local -a all_packages=("$@")
  local -a available_packages=()
  local -a unavailable_packages=()

  echo "Checking package availability in apt repositories..."

  for package in "${all_packages[@]}"; do
    if is_package_available_in_apt "$package"; then
      available_packages+=("$package")
    else
      unavailable_packages+=("$package")
    fi
  done

  # Return results via global arrays (bash limitation workaround)
  AVAILABLE_PACKAGES=("${available_packages[@]}")
  UNAVAILABLE_PACKAGES=("${unavailable_packages[@]}")
}

# Install packages on Arch-based distributions
install_arch_packages() {
  local -a packages=("$@")
  local install_command

  case "$PACKAGE_MANAGER" in
  yay)
    install_command="yay -S --needed --noconfirm ${packages[*]}"
    ;;
  pacman)
    install_command="sudo pacman -S --needed --noconfirm ${packages[*]}"
    ;;
  esac

  if $APPLY_MODE; then
    echo "Installing ${#packages[@]} packages with $PACKAGE_MANAGER..."
    eval "$install_command"
  else
    echo "[DRY RUN] Would run: $install_command"
  fi
}

# Handle Ubuntu package installation with availability checking
handle_ubuntu_packages() {
  local -a packages=("$@")

  # Global arrays to store filtered results
  declare -a AVAILABLE_PACKAGES=()
  declare -a UNAVAILABLE_PACKAGES=()

  filter_ubuntu_packages "${packages[@]}"

  if $APPLY_MODE; then
    # Apply mode: install available packages, list unavailable ones
    if [[ ${#AVAILABLE_PACKAGES[@]} -gt 0 ]]; then
      echo "Installing ${#AVAILABLE_PACKAGES[@]} packages from apt..."
      sudo apt update
      sudo apt install -y "${AVAILABLE_PACKAGES[@]}"
    fi

    if [[ ${#UNAVAILABLE_PACKAGES[@]} -gt 0 ]]; then
      echo ""
      echo "The following packages are not available in apt and need manual installation:"
      printf "  - %s\n" "${UNAVAILABLE_PACKAGES[@]}"
    fi
  else
    # Dry run mode: show what would be installed and what's not available
    echo "[DRY RUN] Package availability check results:"
    echo ""

    if [[ ${#AVAILABLE_PACKAGES[@]} -gt 0 ]]; then
      echo "Would install ${#AVAILABLE_PACKAGES[@]} packages from apt:"
      printf "  ✓ %s\n" "${AVAILABLE_PACKAGES[@]}"
    fi

    if [[ ${#UNAVAILABLE_PACKAGES[@]} -gt 0 ]]; then
      echo ""
      echo "Not available in apt (${#UNAVAILABLE_PACKAGES[@]} packages):"
      printf "  ✗ %s\n" "${UNAVAILABLE_PACKAGES[@]}"
    fi

    echo ""
    echo "Run with --apply to install available packages"
  fi
}

# Main execution function
main() {
  parse_arguments "$@"
  detect_os_and_package_manager

  # Read all packages from file
  local -a all_packages
  IFS=' ' read -ra all_packages <<<"$(read_package_list)"

  echo "Detected OS: $DISTRO_ID"
  echo "Package manager: $PACKAGE_MANAGER"
  echo "Total packages to process: ${#all_packages[@]}"
  echo ""

  # Handle packages based on distribution
  case "$DISTRO_ID" in
  ubuntu | debian)
    handle_ubuntu_packages "${all_packages[@]}"
    ;;
  manjaro | arch)
    install_arch_packages "${all_packages[@]}"
    ;;
  esac
}

# Run main function with all arguments
main "$@"
