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
