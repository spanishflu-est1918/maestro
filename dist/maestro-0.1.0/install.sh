#!/bin/bash

set -e

echo "🎯 Installing Maestro"
echo ""

# Install daemon
echo "📍 Installing daemon to /usr/local/bin..."
sudo cp bin/maestrod /usr/local/bin/
sudo chmod +x /usr/local/bin/maestrod

# Install app
echo "📱 Installing menu bar app to ~/Applications..."
mkdir -p ~/Applications
cp -R app/maestro-app.app ~/Applications/

# Create config directory
echo "⚙️  Setting up configuration..."
mkdir -p ~/.maestro/logs
cp config/config.json ~/.maestro/

# Create database directory
mkdir -p ~/Library/Application\ Support/Maestro

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "1. Configure MCP server (see docs/SETUP.md)"
echo "2. Start daemon: maestrod"
echo "3. Launch app: open ~/Applications/maestro-app.app"
