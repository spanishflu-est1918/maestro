# Getting Started with Maestro

Quick setup guide for first-time installation.

## What is Maestro?

Maestro is a native macOS task and project management system with Claude integration. It provides:
- **Menu bar app** - Ambient awareness of your work state
- **MCP server** - 23 tools for Claude to manage tasks/spaces/documents
- **Maestro Skill** - Teaches Claude how to use Maestro effectively

Think of it as: Maestro is the backend, Claude is the frontend.

---

## Installation (5 minutes)

### 1. Extract and Install

```bash
tar -xzf maestro-0.1.0-macos.tar.gz
cd maestro-0.1.0
./install.sh
```

This installs:
- `maestrod` daemon to `/usr/local/bin/`
- Maestro.app to `~/Applications/`
- Config to `~/.maestro/`

### 2. First Launch

```bash
open ~/Applications/maestro-app.app
```

**On first launch:**
- Right-click → Open (since it's not code signed)
- Allow in System Settings → Privacy & Security if prompted
- Click "Continue" in the setup wizard
- Wait 30 seconds for auto-configuration

**What happens automatically:**
- Creates database at `~/Library/Application Support/Maestro/maestro.db`
- Adds MCP server to `~/.mcp.json` (Claude Code) or `~/.config/claude/config.json` (Claude Desktop)
- Installs Maestro Skill to `~/.claude/skills/maestro/`

### 3. Restart Claude

**Claude Code:**
```bash
# Just restart your terminal or reload
```

**Claude Desktop:**
- Quit and reopen Claude Desktop

### 4. Verify Installation

In Claude, try:
```
"List my Maestro spaces"
```

You should see Maestro tools available (23 total).

---

## Quick Start

### Create Your First World

```
"Create a Maestro space called 'Personal Projects' with color #22C55E"
```

### Add a Task

```
"Create a task in Personal Projects: 'Set up Maestro' with high priority"
```

### Check Status

```
"What should I work on?"
```

### Understand the Workflow

```
"How should I use Maestro?"
```

Claude will use the Maestro Skill to explain workflows and patterns.

---

## Key Concepts

### Worlds (Spaces)
Contexts you operate in — not just projects, but worlds where you're a different version of yourself. Nest infinitely via parent-child relationships.

### Tasks
Signals of what's in motion:
- **inbox** → **todo** → **inProgress** → **done**
- Priority: urgent / high / medium / low / none
- Tasks >3 days in progress = stale (need attention)

### State of the World Document
Every space should have a default document capturing:
- Current state and context
- Active projects (status, problems, what's been tried)
- Mentioned / Undefined items (things lacking detail)

### Defined vs Mentioned
- **Defined** = Active work with context → create space
- **Mentioned** = Vague reference → add to parent doc, don't create space yet

---

## Menu Bar

Look for the Maestro icon in your menu bar:
- 🟢 **Clear** - Nothing actionable
- 🟡 **Attention** - Stale tasks (>3 days)
- 🟠 **Input** - Agent waiting for you
- 🔴 **Urgent** - Overdue items

Click the icon to see QuickView panel with:
- Current status
- Active spaces
- Top tasks
- "Open Maestro" button (full viewer window)

---

## For Different Claude Platforms

### Claude Code (CLI) ✅
- Full support: MCP server + Maestro Skill
- Auto-configured via first-run wizard

### Claude Desktop ✅
- MCP server only (no Skills support)
- Auto-configured via first-run wizard
- Config at `~/.config/claude/config.json`

### ChatGPT (Experimental)
- See `docs/SETUP.md` for manual setup
- MCP server works, but Skills must be recreated as Custom GPT

---

## Troubleshooting

### "Tools not appearing"

**Claude Code:**
```bash
cat ~/.mcp.json
# Should show maestro server
```

**Claude Desktop:**
```bash
cat ~/.config/claude/config.json
# Should show maestro server
```

Restart Claude after confirming config.

### "Database errors"

```bash
# Check if database exists
ls ~/Library/Application\ Support/Maestro/maestro.db

# Check if daemon is running
ps aux | grep maestrod
```

### "Permission errors"

```bash
# Ensure daemon is executable
chmod +x /usr/local/bin/maestrod

# Check database directory permissions
mkdir -p ~/Library/Application\ Support/Maestro
```

### "Skill not loading"

```bash
# Verify skill files
ls ~/.claude/skills/maestro/SKILL.md

# If missing, reinstall
open ~/Applications/maestro-app.app
# Go through setup wizard again
```

---

## Next Steps

1. **Read the docs**: `docs/SETUP.md` - Complete setup guide
2. **Explore patterns**: `docs/IMPLEMENTATION.md` - Technical details
3. **Use with Claude**: Ask Claude "How should I organize my work with Maestro?"

---

## Uninstalling

```bash
cd maestro-0.1.0
./uninstall.sh
```

This removes:
- Daemon from `/usr/local/bin/`
- App from `~/Applications/`
- Optionally: config and data from `~/.maestro/` and `~/Library/Application Support/Maestro/`

---

## Support

- Check logs: `~/.maestro/logs/maestrod.log`
- Verify config: `~/.maestro/config.json`
- Issues: [GitHub Issues](https://github.com/yourusername/maestro/issues) *(update with real URL)*

---

**Happy organizing! 🎯**
