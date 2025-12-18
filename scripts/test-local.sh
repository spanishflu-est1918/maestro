#!/bin/bash

# Maestro Local Testing Script
# Verifies build, installation, and configuration

set -e

echo "🧪 Maestro Local Testing"
echo "========================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

section() {
    echo ""
    echo "═══════════════════════════════════════"
    echo "$1"
    echo "═══════════════════════════════════════"
    echo ""
}

# Phase 1: Build Verification
section "Phase 1: Build Verification"

if [ -f ".build/release/maestro-app" ]; then
    pass "maestro-app binary found"
else
    fail "maestro-app binary not found. Run: swift build -c release"
fi

if [ -f ".build/release/maestrod" ]; then
    pass "maestrod binary found"
else
    fail "maestrod binary not found. Run: swift build -c release"
fi

# Phase 2: App Installation
section "Phase 2: MCP Configuration"

if [ -f ~/.mcp.json ]; then
    if grep -q "maestrod" ~/.mcp.json; then
        pass "Claude Code MCP configured correctly (uses maestrod)"
    else
        fail "Claude Code MCP config uses wrong binary (should be maestrod)"
    fi
else
    warn "~/.mcp.json not found"
fi

if [ -f ~/Library/Application\ Support/Claude/claude_desktop_config.json ]; then
    if grep -q "maestrod" ~/Library/Application\ Support/Claude/claude_desktop_config.json; then
        pass "Claude Desktop MCP configured correctly (uses maestrod)"
    else
        fail "Claude Desktop MCP config uses wrong binary (should be maestrod)"
    fi
else
    warn "Claude Desktop config not found"
fi

# Check if skill files are bundled
if [ -f "/Applications/Maestro.app/Contents/Resources/skills/maestro/SKILL.md" ]; then
    pass "Skill files bundled in app"
else
    fail "Skill files NOT bundled. Add build phase script."
fi

# Phase 3: First-Run Configuration
section "Phase 3: First-Run Configuration"

if [ -f ~/.mcp.json ]; then
    if grep -q "maestro" ~/.mcp.json; then
        pass "MCP server configured in ~/.mcp.json"
    else
        warn "~/.mcp.json exists but no maestro server. Run first-time setup."
    fi
else
    warn "~/.mcp.json not found. Launch Maestro.app and run wizard."
fi

if [ -d ~/.claude/skills/maestro ]; then
    pass "Maestro Skill installed in ~/.claude/skills/"

    if [ -f ~/.claude/skills/maestro/SKILL.md ]; then
        pass "SKILL.md found"
    else
        fail "SKILL.md missing from skill directory"
    fi
else
    warn "Skill not installed. Launch Maestro.app and run wizard."
fi

if [ -f ~/Library/Application\ Support/Maestro/maestro.db ]; then
    pass "Database created"
else
    warn "Database not created. Launch Maestro.app."
fi

# Phase 4: Build Tests
section "Phase 4: Running Tests"

echo "Running swift test..."
if swift test > /dev/null 2>&1; then
    pass "All tests passing"
else
    fail "Tests failing. Run: swift test"
fi

# Phase 5: Plugin Structure (if exists)
section "Phase 5: Plugin Structure"

if [ -d "plugin" ]; then
    if [ -f "plugin/.claude-plugin/plugin.json" ]; then
        pass "Plugin manifest found"
    else
        fail "plugin.json missing"
    fi

    if [ -f "plugin/skills/maestro/SKILL.md" ]; then
        pass "Plugin skill found"
    else
        fail "Plugin skill missing"
    fi

    if [ -f "plugin/.mcp.json" ]; then
        pass "Plugin MCP config found"
    else
        fail "Plugin MCP config missing"
    fi
else
    warn "Plugin directory not found (optional)"
fi

# Phase 5: Process Check
section "Phase 5: Running Processes"

if pgrep -x "maestro-app" > /dev/null; then
    pass "maestro-app is running"
else
    warn "maestro-app not running. Launch it: .build/release/maestro-app"
fi

if pgrep -x "maestrod" > /dev/null; then
    pass "maestrod is running"
else
    warn "maestrod not running (starts when Claude connects)"
fi

# Summary
section "Test Summary"

TOTAL=$((PASSED + FAILED))

echo "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Ready for testing.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Launch Maestro.app and complete wizard"
    echo "2. Restart Claude Code"
    echo "3. Test MCP tools in Claude"
    echo "4. Test slash commands"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Fix issues before proceeding.${NC}"
    echo ""
    echo "See TESTING.md for detailed testing guide."
    echo ""
    exit 1
fi
