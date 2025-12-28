#!/bin/bash
#
# Maestro Release Build Script
# Builds optimized release binaries and creates distribution package
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎯 Building Maestro Release${NC}"
echo ""

# Get version from git tag or use default
VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.1.0")
BUILD_DIR=".build/release"
DIST_DIR="dist/maestro-${VERSION}"

echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo -e "${YELLOW}Build Directory: ${BUILD_DIR}${NC}"
echo -e "${YELLOW}Distribution Directory: ${DIST_DIR}${NC}"
echo ""

# Clean previous builds
echo -e "${GREEN}🧹 Cleaning previous builds...${NC}"
rm -rf .build/release
rm -rf dist

# Build release configuration
echo -e "${GREEN}🔨 Building release binaries...${NC}"
swift build -c release

# Verify binaries were created
if [ ! -f "${BUILD_DIR}/maestrod" ]; then
    echo -e "${RED}❌ Failed to build maestrod${NC}"
    exit 1
fi

if [ ! -d "${BUILD_DIR}/maestro-app.app" ]; then
    echo -e "${RED}❌ Failed to build maestro-app${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"
echo ""

# Create distribution directory
echo -e "${GREEN}📦 Creating distribution package...${NC}"
mkdir -p "${DIST_DIR}/bin"
mkdir -p "${DIST_DIR}/app"
mkdir -p "${DIST_DIR}/docs"

# Copy binaries
cp "${BUILD_DIR}/maestrod" "${DIST_DIR}/bin/"
cp -R "${BUILD_DIR}/maestro-app.app" "${DIST_DIR}/app/"

# Copy documentation
cp README.md "${DIST_DIR}/"
cp -R docs "${DIST_DIR}/"

# Create default config
mkdir -p "${DIST_DIR}/config"
cat > "${DIST_DIR}/config/config.json" << EOF
{
  "logLevel": "info",
  "logPath": "~/.maestro/logs/maestrod.log",
  "logRotationSizeMB": 10,
  "databasePath": "~/Library/Application Support/Maestro/maestro.db",
  "refreshInterval": 300
}
EOF

# Create installation script
cat > "${DIST_DIR}/install.sh" << 'EOF'
#!/bin/bash

set -e

echo "🎯 Installing Maestro"
echo ""

# Check if daemon is running
DAEMON_WAS_RUNNING=false
if pgrep -x maestrod > /dev/null; then
    DAEMON_WAS_RUNNING=true
    echo "📍 Stopping running daemon..."
    pkill -x maestrod || true
    sleep 1
fi

# Install daemon
echo "📍 Installing daemon to /usr/local/bin..."
sudo cp bin/maestrod /usr/local/bin/
sudo chmod +x /usr/local/bin/maestrod

# Install app
echo "📱 Installing menu bar app to ~/Applications..."
mkdir -p ~/Applications
# Kill app if running to allow replacement
if pgrep -x maestro-app > /dev/null; then
    echo "   Closing running app..."
    pkill -x maestro-app || true
    sleep 1
fi
rm -rf ~/Applications/maestro-app.app
cp -R app/maestro-app.app ~/Applications/

# Create config directory if needed
if [ ! -d ~/.maestro ]; then
    echo "⚙️  Setting up configuration..."
    mkdir -p ~/.maestro/logs
    cp config/config.json ~/.maestro/
else
    echo "⚙️  Config directory exists, preserving settings"
    mkdir -p ~/.maestro/logs
fi

# Create database directory
mkdir -p ~/Library/Application\ Support/Maestro

echo ""
echo "✅ Installation complete!"

# Restart daemon if it was running (fully detached)
if [ "$DAEMON_WAS_RUNNING" = true ]; then
    echo ""
    echo "🔄 Restarting daemon..."
    ( /usr/local/bin/maestrod < /dev/null > /dev/null 2>&1 & disown ) 2>/dev/null
    sleep 0.5
    if pgrep -x maestrod > /dev/null; then
        echo "   ✓ Daemon running in background"
    else
        echo "   ⚠ Daemon may need manual start"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Done! You can close this terminal."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
EOF

chmod +x "${DIST_DIR}/install.sh"

# Create uninstall script
cat > "${DIST_DIR}/uninstall.sh" << 'EOF'
#!/bin/bash

echo "🗑️  Uninstalling Maestro"
echo ""

# Remove daemon
if [ -f "/usr/local/bin/maestrod" ]; then
    echo "Removing daemon..."
    sudo rm /usr/local/bin/maestrod
fi

# Remove app
if [ -d ~/Applications/maestro-app.app ]; then
    echo "Removing menu bar app..."
    rm -rf ~/Applications/maestro-app.app
fi

# Optionally remove data
read -p "Remove configuration and data? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing configuration and data..."
    rm -rf ~/.maestro
    rm -rf ~/Library/Application\ Support/Maestro
fi

echo ""
echo "✅ Uninstall complete!"
EOF

chmod +x "${DIST_DIR}/uninstall.sh"

# Create archive
echo -e "${GREEN}📦 Creating archive...${NC}"
cd dist
tar -czf "maestro-${VERSION}-macos.tar.gz" "maestro-${VERSION}"
cd ..

echo ""
echo -e "${GREEN}✅ Release build complete!${NC}"
echo ""
echo "Distribution package: dist/maestro-${VERSION}-macos.tar.gz"
echo ""
echo "To install:"
echo "  tar -xzf dist/maestro-${VERSION}-macos.tar.gz"
echo "  cd maestro-${VERSION}"
echo "  ./install.sh"
echo ""
echo "To test locally:"
echo "  .build/release/maestrod --version"
echo "  open .build/release/maestro-app.app"
