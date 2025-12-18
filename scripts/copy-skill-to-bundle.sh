#!/bin/bash

# Copy Maestro Skill to app bundle
# This script runs during Xcode build to include the skill files in the app

set -e

# Source and destination paths
SKILL_SOURCE="${SRCROOT}/.claude/skills/maestro"
SKILL_DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/Resources/skills/maestro"

echo "Copying Maestro Skill to app bundle..."
echo "Source: ${SKILL_SOURCE}"
echo "Dest: ${SKILL_DEST}"

# Create destination directory
mkdir -p "${SKILL_DEST}"

# Copy skill files
if [ -d "${SKILL_SOURCE}" ]; then
    cp -R "${SKILL_SOURCE}/"* "${SKILL_DEST}/"
    echo "✅ Skill files copied successfully"
else
    echo "❌ Skill source directory not found: ${SKILL_SOURCE}"
    exit 1
fi

# List copied files for verification
echo "Copied files:"
ls -la "${SKILL_DEST}"
