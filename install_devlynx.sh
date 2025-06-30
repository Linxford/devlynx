#!/bin/bash

# DevLynx Installation Script
# This script sets up DevLynx to auto-start on system boot

set -e

echo "🚀 Installing DevLynx Personal Development Assistant..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current directory
DEVLYNX_DIR="$(pwd)"
USER_HOME="$HOME"

echo -e "${BLUE}DevLynx Directory: ${DEVLYNX_DIR}${NC}"
echo -e "${BLUE}User Home: ${USER_HOME}${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed. Please install Flutter first.${NC}"
    echo -e "${YELLOW}Visit: https://docs.flutter.dev/get-started/install/linux${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"

# Install Flutter dependencies
echo -e "${BLUE}📦 Installing Flutter dependencies...${NC}"
flutter pub get

# Build release version
echo -e "${BLUE}🔨 Building DevLynx release version...${NC}"
flutter build linux --release

# Create systemd user service directory
SYSTEMD_USER_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

# Create the service file
SERVICE_FILE="$SYSTEMD_USER_DIR/devlynx.service"
echo -e "${BLUE}📝 Creating systemd service file...${NC}"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=DevLynx - Personal Development Assistant
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=simple
ExecStart=$DEVLYNX_DIR/build/linux/x64/release/bundle/devlynx
WorkingDirectory=$DEVLYNX_DIR
Environment=DISPLAY=:0
Environment=HOME=$USER_HOME
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo -e "${GREEN}✅ Service file created at: ${SERVICE_FILE}${NC}"

# Reload systemd and enable the service
echo -e "${BLUE}🔄 Enabling DevLynx service...${NC}"
systemctl --user daemon-reload
systemctl --user enable devlynx.service

# Create desktop entry for manual launching
DESKTOP_DIR="$USER_HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

DESKTOP_FILE="$DESKTOP_DIR/devlynx.desktop"
echo -e "${BLUE}🖥️ Creating desktop entry...${NC}"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=DevLynx
Comment=Personal Development Assistant
Exec=$DEVLYNX_DIR/build/linux/x64/release/bundle/devlynx
Icon=$DEVLYNX_DIR/assets/icon.png
Terminal=false
Type=Application
Categories=Development;Utility;
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
echo -e "${GREEN}✅ Desktop entry created${NC}"

# Create a simple launcher script
LAUNCHER_SCRIPT="$USER_HOME/.local/bin/devlynx"
mkdir -p "$USER_HOME/.local/bin"

cat > "$LAUNCHER_SCRIPT" << EOF
#!/bin/bash
cd "$DEVLYNX_DIR"
exec "$DEVLYNX_DIR/build/linux/x64/release/bundle/devlynx" "\$@"
EOF

chmod +x "$LAUNCHER_SCRIPT"
echo -e "${GREEN}✅ Launcher script created at: ${LAUNCHER_SCRIPT}${NC}"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$USER_HOME/.local/bin:"* ]]; then
    echo -e "${YELLOW}⚠️ Adding ~/.local/bin to PATH in ~/.bashrc${NC}"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
fi

echo -e "${GREEN}🎉 DevLynx installation completed!${NC}"
echo ""
echo -e "${BLUE}📋 What's been set up:${NC}"
echo -e "  • DevLynx built for release"
echo -e "  • Systemd user service enabled (auto-start on login)"
echo -e "  • Desktop application entry"
echo -e "  • Command-line launcher: ${YELLOW}devlynx${NC}"
echo ""
echo -e "${BLUE}🚀 To start DevLynx now:${NC}"
echo -e "  systemctl --user start devlynx"
echo ""
echo -e "${BLUE}📊 To check status:${NC}"
echo -e "  systemctl --user status devlynx"
echo ""
echo -e "${BLUE}🛑 To stop auto-start:${NC}"
echo -e "  systemctl --user disable devlynx"
echo ""
echo -e "${GREEN}DevLynx will automatically start when you log in!${NC}"

# Ask if user wants to start now
read -p "Would you like to start DevLynx now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🚀 Starting DevLynx...${NC}"
    systemctl --user start devlynx
    echo -e "${GREEN}✅ DevLynx started!${NC}"
fi 