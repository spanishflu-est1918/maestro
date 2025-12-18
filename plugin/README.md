# Maestro Plugin for Claude Code

Intelligent task and project management with Linear integration, agent monitoring, and menu bar intelligence.

## Features

- **23 MCP Tools** - Complete task/space/document management API
- **Intelligent Surfacing** - AI-powered task prioritization
- **Linear Integration** - Bidirectional sync with Linear issues
- **Agent Monitoring** - Track Claude Code and Codex activity
- **Menu Bar Intelligence** - Real-time status with color-coded states
- **Maestro Skill** - Workflow guidance and best practices
- **Slash Commands** - Quick access to common operations

## Installation

### Step 1: Install the macOS App

Download and install Maestro.app:

```bash
# Download latest release
curl -L https://github.com/spanishflu-est1918/maestro/releases/latest/download/Maestro.zip -o Maestro.zip

# Unzip and install
unzip Maestro.zip
mv Maestro.app /Applications/

# Launch (right-click → Open for unsigned apps)
open /Applications/Maestro.app
```

The first-run wizard will automatically configure everything.

### Step 2: Install the Plugin

In Claude Code:

```
/plugin marketplace add spanishflu-est1918/maestro
/plugin install maestro@spanishflu-est1918/maestro
```

Or for project-level installation (shared with team via git):

```
/plugin marketplace add spanishflu-est1918/maestro
/plugin install maestro@spanishflu-est1918/maestro --scope project
```

### Step 3: Verify Installation

```
/status
```

You should see:
- Maestro icon in menu bar
- Menu bar status and top surfaced tasks
- All 23 maestro_* tools available

## Quick Start

### Create Your First Space

```
/setup-space
```

Follow the prompts to create a project/team/sprint/client/personal space.

### Create a Task

```
/create-task
```

Answer questions to create a well-structured task.

### Check Status

```
/status
```

See menu bar state and top 10 surfaced tasks.

### Ask the Skill

```
"How should I organize tasks in Maestro?"
"Show me Linear integration workflows"
"What are the best practices for agent monitoring?"
```

The Maestro Skill provides comprehensive workflow guidance.

## Available Tools (23)

### Spaces (6)
- `maestro_list_spaces` - List all spaces
- `maestro_get_space` - Get space details
- `maestro_create_space` - Create new space
- `maestro_update_space` - Update space properties
- `maestro_archive_space` - Archive space
- `maestro_delete_space` - Delete space permanently

### Tasks (8)
- `maestro_list_tasks` - List tasks with filters
- `maestro_get_task` - Get task details
- `maestro_create_task` - Create new task
- `maestro_update_task` - Update task properties
- `maestro_complete_task` - Mark task done
- `maestro_archive_task` - Archive task
- `maestro_delete_task` - Delete task permanently
- `maestro_get_surfaced_tasks` - Get AI-prioritized tasks

### Documents (9)
- `maestro_list_documents` - List documents
- `maestro_get_document` - Get document content
- `maestro_create_document` - Create new document
- `maestro_update_document` - Update document
- `maestro_pin_document` - Pin document
- `maestro_unpin_document` - Unpin document
- `maestro_delete_document` - Delete document
- `maestro_get_default_document` - Get space default doc
- `maestro_set_default_document` - Set space default doc

### Agent Monitoring (7)
- `maestro_start_agent_session` - Start tracking session
- `maestro_end_agent_session` - End session with outcome
- `maestro_log_agent_activity` - Log activity event
- `maestro_get_agent_session` - Get session details
- `maestro_list_agent_sessions` - List all sessions
- `maestro_list_agent_activities` - List activities
- `maestro_get_agent_metrics` - Get performance metrics

### Status (1)
- `maestro_get_status` - Get menu bar state and metrics

## Slash Commands

- `/status` - Check Maestro status and top priorities
- `/create-task` - Create a well-structured task
- `/setup-space` - Set up a new project/team space

## Menu Bar Intelligence

The Maestro menu bar icon shows real-time status:

| Color | State | Meaning |
|-------|-------|---------|
| 🟢 Green | clear | Nothing actionable |
| 🟡 Yellow | attention | Stale tasks (3+ days inactive) |
| 🟠 Orange | input | Agent needs your input |
| 🔴 Red | urgent | Overdue tasks exist |

**Badge** = Overdue tasks + Agents waiting for input

Click the icon to see detailed status summary.

## Intelligent Surfacing

The surfacing algorithm prioritizes tasks by:

1. **Overdue** (past due date) → Highest priority
2. **Due date proximity** (within 7 days > 14 days > beyond)
3. **Priority** (urgent 4x > high 2x > medium 1x)
4. **Recency** (recently updated > stale)

Use `maestro_get_surfaced_tasks` to get your top priorities daily.

## Linear Integration

Link Maestro tasks ↔ Linear issues:

1. Create Linear issue
2. Reference issue in Maestro task description: `[ENG-123] Feature name`
3. Keep status in sync:
   - Maestro inProgress → Linear "In Progress"
   - Maestro done → Linear "Done"
4. Track Linear metrics via `maestro_get_status`

Use Linear for: Team visibility, sprint planning
Use Maestro for: Detailed execution, surfacing, agent tracking

## Agent Monitoring

Track AI agent activity:

```
# Start session
maestro_start_agent_session: { "agentName": "claude-code" }

# Log activities
maestro_log_agent_activity: {
  "sessionId": "...",
  "activityType": "tool_call",
  "description": "Created task for auth feature"
}

# End session
maestro_end_agent_session: {
  "sessionId": "...",
  "outcome": "completed"
}

# Review metrics
maestro_get_agent_metrics
```

## Documentation

The Maestro Skill includes comprehensive guides:

- **SKILL.md** - Main workflow guide
- **TASK_MANAGEMENT.md** - Complete task lifecycle
- **SPACE_ORGANIZATION.md** - Organization best practices
- **LINEAR_WORKFLOW.md** - Integration patterns
- **AGENT_MONITORING.md** - Session tracking guide
- **templates/** - Task and space templates

Access by asking Claude:
```
"Show me Maestro task management patterns"
"How should I organize spaces?"
"What's the Linear workflow?"
```

## Performance

- **~0.16ms** surfacing calculation (62x faster than 10ms target)
- **30-second** menu bar refresh
- **186 tests** - All passing
- **< 50MB** memory footprint

## Troubleshooting

### Plugin Not Loading

```bash
# Verify plugin installed
/plugin list

# Reinstall if needed
/plugin uninstall maestro@spanishflu-est1918/maestro
/plugin install maestro@spanishflu-est1918/maestro
```

### MCP Server Not Found

```bash
# Check Maestro.app is installed
ls /Applications/Maestro.app

# Verify MCP server path in plugin/.mcp.json
# Should point to: /Applications/Maestro.app/Contents/MacOS/Maestro
```

### Skill Not Loading

```bash
# Verify skill files exist
ls ~/.claude/plugins/maestro@spanishflu-est1918_maestro/skills/maestro/

# Should contain:
# - SKILL.md
# - TASK_MANAGEMENT.md
# - SPACE_ORGANIZATION.md
# - LINEAR_WORKFLOW.md
# - AGENT_MONITORING.md
# - templates/
```

### App Won't Open

```bash
# Remove quarantine (for unsigned apps)
xattr -d com.apple.quarantine /Applications/Maestro.app

# Or right-click → Open
```

## Support

- **Issues**: [GitHub Issues](https://github.com/spanishflu-est1918/maestro/issues)
- **Discussions**: [GitHub Discussions](https://github.com/spanishflu-est1918/maestro/discussions)
- **Documentation**: Full docs in plugin/skills/maestro/

## Contributing

Contributions welcome! See [main repo](https://github.com/spanishflu-est1918/maestro) for development setup.

## License

MIT License - see LICENSE file for details.

---

**⭐ If Maestro helps you stay organized, star the repo!**
