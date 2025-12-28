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
