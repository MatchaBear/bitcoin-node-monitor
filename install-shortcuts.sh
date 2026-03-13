#!/bin/bash

# Bitcoin Node Monitor - Shortcut Installer
# Installs convenient shortcuts for easy access
# Version: 3.0.0

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════╗"
echo "║    🟠 Bitcoin Monitor Shortcut Installer    ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${WHITE}This installer will create convenient shortcuts for Bitcoin Monitor${NC}"
echo

# Detect shell
SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
    "zsh")
        RC_FILE="$HOME/.zshrc"
        ;;
    "bash")
        RC_FILE="$HOME/.bashrc"
        ;;
    *)
        echo -e "${YELLOW}⚠️  Shell '$SHELL_NAME' detected. Using .bashrc as fallback.${NC}"
        RC_FILE="$HOME/.bashrc"
        ;;
esac

echo -e "${CYAN}🔍 Detected shell: ${WHITE}$SHELL_NAME${NC}"
echo -e "${CYAN}📝 Configuration file: ${WHITE}$RC_FILE${NC}"
echo

# Check if already installed
if grep -q "# Bitcoin Monitor Shortcuts" "$RC_FILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Bitcoin Monitor shortcuts already installed!${NC}"
    echo -e "${WHITE}Do you want to reinstall/update them? (y/N): ${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Installation cancelled.${NC}"
        exit 0
    fi
    
    # Remove old installation
    echo -e "${YELLOW}🔄 Removing old shortcuts...${NC}"
    sed -i.backup '/# Bitcoin Monitor Shortcuts/,/# End Bitcoin Monitor Shortcuts/d' "$RC_FILE"
fi

# Create shortcuts
echo -e "${GREEN}📝 Installing shortcuts...${NC}"

cat >> "$RC_FILE" << EOF

# Bitcoin Monitor Shortcuts
# Professional Bitcoin Node Monitor - Easy Access Commands
export PATH="\$PATH:$SCRIPT_DIR"

# Direct script access
alias btc="$SCRIPT_DIR/btc"

# Quick shortcuts for common tasks
alias btc-test="$SCRIPT_DIR/btc test"
alias btc-peers="$SCRIPT_DIR/btc peers"
alias btc-monitor="$SCRIPT_DIR/btc monitor"
alias btc-status="$SCRIPT_DIR/btc status"

# Development shortcuts
alias btc-dir="cd $SCRIPT_DIR"
alias btc-logs="ls -la $SCRIPT_DIR/cache/"
alias btc-config="ls -la $SCRIPT_DIR/config/"

# Help reminder
alias btc-help="$SCRIPT_DIR/btc help"

# End Bitcoin Monitor Shortcuts
EOF

echo -e "${GREEN}✅ Shortcuts installed successfully!${NC}"
echo

echo -e "${BOLD}${WHITE}🎉 Installation Complete!${NC}"
echo
echo -e "${CYAN}Available shortcuts after restarting terminal:${NC}"
echo
echo -e "${GREEN}📊 Main Commands:${NC}"
echo -e "  ${YELLOW}btc${NC}              - Main Bitcoin Monitor command"
echo -e "  ${YELLOW}btc test${NC}         - Test all libraries (recommended first run)"
echo -e "  ${YELLOW}btc peers${NC}        - Show connected peers with countries"
echo -e "  ${YELLOW}btc monitor${NC}      - Full monitoring dashboard"
echo -e "  ${YELLOW}btc status${NC}       - System status check"
echo -e "  ${YELLOW}btc help${NC}         - Show help menu"
echo
echo -e "${BLUE}⚡ Quick Shortcuts:${NC}"
echo -e "  ${YELLOW}btc-test${NC}         - Quick test command"
echo -e "  ${YELLOW}btc-peers${NC}        - Quick peers command"
echo -e "  ${YELLOW}btc-monitor${NC}      - Quick monitor command"
echo -e "  ${YELLOW}btc-status${NC}       - Quick status command"
echo
echo -e "${PURPLE}🛠️  Development:${NC}"
echo -e "  ${YELLOW}btc-dir${NC}          - Navigate to Bitcoin Monitor directory"
echo -e "  ${YELLOW}btc-logs${NC}         - Show cache files"
echo -e "  ${YELLOW}btc-config${NC}       - Show configuration files"
echo
echo -e "${WHITE}💻 Quick Start:${NC}"
echo -e "  1. Restart your terminal or run: ${YELLOW}source $RC_FILE${NC}"
echo -e "  2. Test installation: ${YELLOW}btc test${NC}"
echo -e "  3. Check system status: ${YELLOW}btc status${NC}"
echo -e "  4. Start monitoring: ${YELLOW}btc monitor${NC}"
echo

echo -e "${CYAN}🔄 To apply changes immediately, run:${NC}"
echo -e "${YELLOW}source $RC_FILE${NC}"
echo

echo -e "${GREEN}🎯 Pro Tip: Type 'btc' from anywhere to access Bitcoin Monitor!${NC}"
