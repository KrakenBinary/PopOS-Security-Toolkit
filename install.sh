#!/usr/bin/env bash
# PopOS Security Toolkit - Quick Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/KrakenBinary/PopOS-Security-Toolkit/main/install.sh | sudo bash

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Colors for output
C_GREEN="\033[38;5;78m"
C_CYAN="\033[38;5;81m"
C_YELLOW="\033[38;5;220m"
C_RED="\033[38;5;196m"
C_RESET="\033[0m"

echo -e "${C_CYAN}╔════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_CYAN}║  PopOS Security Toolkit - Quick Install   ║${C_RESET}"
echo -e "${C_CYAN}╚════════════════════════════════════════════╝${C_RESET}"
echo ""

# Set installation directory
INSTALL_DIR="/opt/popos-toolkit"

# Check if git is installed
if ! command -v git &>/dev/null; then
    echo -e "${C_YELLOW}Installing git...${C_RESET}"
    apt-get update -qq
    apt-get install -y git
fi

# Remove old installation if exists
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${C_YELLOW}Removing old installation...${C_RESET}"
    rm -rf "$INSTALL_DIR"
fi

# Clone repository
echo -e "${C_CYAN}Downloading PopOS Security Toolkit...${C_RESET}"
git clone https://github.com/KrakenBinary/PopOS-Security-Toolkit.git "$INSTALL_DIR"

# Make executable
chmod +x "$INSTALL_DIR/run.sh"

# Create symlink in /usr/local/bin
if [[ -L /usr/local/bin/popos-toolkit ]]; then
    rm /usr/local/bin/popos-toolkit
fi
ln -s "$INSTALL_DIR/run.sh" /usr/local/bin/popos-toolkit

echo ""
echo -e "${C_GREEN}✓ Installation complete!${C_RESET}"
echo ""
echo -e "${C_CYAN}Run the toolkit with:${C_RESET}"
echo -e "  ${C_YELLOW}sudo popos-toolkit${C_RESET}"
echo ""
echo -e "${C_CYAN}Or directly:${C_RESET}"
echo -e "  ${C_YELLOW}cd $INSTALL_DIR && sudo ./run.sh${C_RESET}"
echo ""
