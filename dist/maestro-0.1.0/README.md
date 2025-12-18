# Maestro

Intelligent task and project management for macOS with Claude Code integration.

**⚡ Zero-Configuration Setup** - First-run wizard automatically configures everything in 30 seconds.

## Features

### 🎯 Smart Task Management
- **Intelligent Surfacing** - AI-powered task prioritization (overdue → due soon → high priority)
- **Status Workflow** - inbox → todo → inProgress → done
- **Priority Levels** - urgent, high, medium, low, none
- **Due Date Tracking** - Automatic overdue detection and alerts

### 📁 Space Organization
- **Hierarchical Spaces** - Organize work with parent/child relationships
- **Color Coding** - Visual organization with customizable colors (#hex)
- **Tag System** - Flexible categorization and filtering
- **Templates** - Pre-built structures for projects, teams, sprints

### 📊 Menu Bar Intelligence
- **Color States**:
  - 🟢 Green (clear): Nothing actionable
  - 🟡 Yellow (attention): Stale tasks (3+ days inactive)
  - 🟠 Orange (input): Agent needs your input
  - 🔴 Red (urgent): Overdue tasks exist
- **Badge Counter** - Shows overdue tasks + agents waiting
- **Auto-refresh** - Updates every 30 seconds
- **Performance** - ~0.16ms per calculation

### 🤖 Agent Monitoring
- **Session Tracking** - Track Claude Code and Codex activity
- **Activity Logging** - Record tool calls, user messages, errors
- **Metrics Dashboard** - Sessions, durations, tool usage, error rates
- **Performance Insights** - Optimize agent workflows

### 🔗 Linear Integration
- **Bidirectional Linking** - Connect Maestro tasks ↔ Linear issues
- **Status Sync** - Keep both systems in sync
- **Team Visibility** - Linear for stakeholders, Maestro for execution
- **Activity Tracking** - Monitor Linear completion metrics (last 24h)

### 📄 Document Management
- **Markdown Support** - Rich text documentation
- **Hierarchical Paths** - Folder-like organization (/specs/, /notes/)
- **Pinned Documents** - Quick access to frequently used docs
- **Default Documents** - Per-space landing pages

### 🧠 Maestro Skill (Workflow Guidance)
- **Task Management Patterns** - Capture → Plan → Execute → Complete
- **Space Organization** - Best practices for hierarchies
- **Linear Integration** - Bidirectional sync workflows
- **Agent Monitoring** - Session management strategies
- **Templates** - 7 task types, 6 space patterns

## Installation

### Quick Install (macOS 13.0+)

**1. Download & Install**
```bash
# Download latest release
curl -L https://github.com/spanishflu-est1918/maestro/releases/latest/download/Maestro.zip -o Maestro.zip

# Unzip
unzip Maestro.zip

# Move to Applications
mv Maestro.app /Applications/

# Launch (right-click → Open for unsigned apps)
open /Applications/Maestro.app
```

**2. First Launch - Automatic Setup**

When you first launch Maestro, you'll see:

```
┌─────────────────────────────────────┐
│   Welcome to Maestro!               │
│                                     │
│   Setup will:                       │
│   • Configure Claude Code (MCP)     │
│   • Install Maestro Skill           │
│   • Set up menu bar                 │
│                                     │
│   Takes ~30 seconds.                │
│                                     │
│        [Continue]  [Skip]           │
└─────────────────────────────────────┘
```

Click **Continue** and Maestro automatically:
- ✅ Adds Maestro MCP server to `~/.mcp.json`
- ✅ Installs Maestro Skill to `~/.claude/skills/maestro/`
- ✅ Creates database at `~/Library/Application Support/Maestro/`
- ✅ Starts menu bar monitoring

**3. Restart Claude Code**

After setup completes, restart Claude Code to load the Maestro tools.

**4. Verify**

Look for:
- Maestro icon in menu bar (green checklist)
- In Claude Code, ask: "How do I use Maestro?"
- Claude should provide detailed guidance from the Maestro Skill

**That's it!** No manual configuration needed.

## Architecture

```
maestro/
├── Sources/
│   ├── Maestro/          # MCP Server & Daemon
│   │   ├── main.swift    # Daemon entry point
│   │   ├── Daemon.swift  # Background service
│   │   ├── MCPServer.swift # MCP tool definitions
│   │   ├── Configuration.swift # Config management
│   │   └── Logger.swift  # File-based logging
│   ├── MaestroCore/      # Core data layer
│   │   ├── Database.swift # GRDB connection & migrations
│   │   ├── Space.swift   # Space model
│   │   ├── Task.swift    # Task model
│   │   ├── Document.swift # Document model
│   │   ├── ReminderLink.swift # EventKit link model
│   │   ├── LinearLink.swift # Linear link model
│   │   ├── ReminderSync.swift # EventKit integration
│   │   ├── LinearSync.swift # Linear integration
│   │   ├── SpaceStore.swift # Space CRUD
│   │   ├── TaskStore.swift # Task CRUD
│   │   └── DocumentStore.swift # Document CRUD
│   ├── MaestroUI/        # Menu bar app
│   │   ├── AppDelegate.swift # App entry point
│   │   ├── QuickViewPanel.swift # Dropdown panel
│   │   └── ViewerWindow.swift # Web viewer window
│   └── MaestroApp/       # Menu bar executable
│       └── main.swift
└── Tests/
    ├── MaestroTests/     # Integration tests
    └── MaestroCoreTests/ # Unit tests
```

## Installation

### Prerequisites

- macOS 13.0 or later
- Xcode 15.2 or later
- Swift 5.9 or later

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/maestro.git
cd maestro

# Build the project
swift build -c release

# Install the daemon
cp .build/release/maestrod /usr/local/bin/

# Install the menu bar app
cp -r .build/release/maestro-app.app ~/Applications/
```

## Configuration

### Daemon Configuration

Create `~/.maestro/config.json`:

```json
{
  "logLevel": "info",
  "logPath": "~/.maestro/logs/maestrod.log",
  "logRotationSizeMB": 10,
  "databasePath": "~/Library/Application Support/Maestro/maestro.db",
  "refreshInterval": 300
}
```

### MCP Server Setup

Add to your MCP client configuration (e.g., Claude Desktop `~/.config/claude/config.json`):

```json
{
  "mcpServers": {
    "maestro": {
      "command": "/usr/local/bin/maestrod",
      "args": [],
      "env": {}
    }
  }
}
```

## Usage

### Starting the Daemon

```bash
# Start in foreground
maestrod

# Start in background
maestrod &

# With custom config
maestrod --config /path/to/config.json
```

### Menu Bar App

Launch `maestro-app` from Applications. The app provides:

- Quick view dropdown with recent spaces and due tasks
- "Open Viewer" button to launch full web dashboard
- Real-time sync with daemon database

### MCP Tools

Available via any MCP-compatible client:

#### Space Management

- `maestro_list_spaces` - List all spaces
- `maestro_get_space` - Get space by ID
- `maestro_create_space` - Create a new space
- `maestro_update_space` - Update space properties
- `maestro_archive_space` - Archive a space
- `maestro_delete_space` - Delete a space

#### Task Management

- `maestro_list_tasks` - List tasks with filters
- `maestro_get_task` - Get task by ID
- `maestro_create_task` - Create a new task
- `maestro_update_task` - Update task properties
- `maestro_complete_task` - Mark task as done
- `maestro_archive_task` - Archive a task
- `maestro_delete_task` - Delete a task
- `maestro_get_surfaced_tasks` - Get prioritized tasks

#### Document Management

- `maestro_list_documents` - List documents
- `maestro_get_document` - Get document by ID
- `maestro_create_document` - Create a new document
- `maestro_update_document` - Update document content
- `maestro_pin_document` - Pin document
- `maestro_unpin_document` - Unpin document
- `maestro_delete_document` - Delete document
- `maestro_get_default_document` - Get space's default document
- `maestro_set_default_document` - Set space's default document

#### Agent Monitoring

- `maestro_start_agent_session` - Start a new agent work session
- `maestro_end_agent_session` - End an active agent session
- `maestro_log_agent_activity` - Log an agent activity
- `maestro_get_agent_session` - Get session by ID
- `maestro_list_agent_sessions` - List agent sessions with filters
- `maestro_list_agent_activities` - List agent activities
- `maestro_get_agent_metrics` - Get performance metrics for an agent

## Linear Integration

Maestro provides full Linear API integration via GraphQL, allowing bidirectional sync between Maestro tasks and Linear issues.

### Setup

1. Get your Linear API key from [Linear Settings](https://linear.app/settings/api)
2. Initialize LinearSync with your API key:

```swift
let linearSync = LinearSync(database: db, apiKey: "lin_api_YOUR_KEY")
```

### Features

#### Create Linear Issue from Task

Create a new Linear issue from an existing Maestro task:

```swift
let link = try await linearSync.createLinearIssue(
    taskId: task.id,
    teamId: "team-uuid"
)
print("Created Linear issue: \(link.linearIssueKey)")
```

The task's title, description, and priority are automatically mapped to Linear.

#### Link Existing Linear Issue

Link an existing Linear issue to a Maestro task:

```swift
try linearSync.linkIssue(
    taskId: task.id,
    linearIssueId: "issue-uuid",
    linearIssueKey: "PROJ-123",
    linearTeamId: "team-uuid",
    linearState: "In Progress"
)
```

#### Sync from Linear

Fetch updates from Linear and update local task states:

```swift
try await linearSync.sync()
```

This fetches all assigned Linear issues and updates the state of any linked tasks.

#### Update Linear from Maestro

Push Maestro task changes to Linear:

```swift
try await linearSync.syncTaskToLinear(taskId: task.id)
```

Updates the linked Linear issue with the task's current title, description, and priority.

### Status Mapping

| Maestro Status | Linear State |
|---------------|--------------|
| inbox         | Backlog      |
| todo          | Todo         |
| inProgress    | In Progress  |
| done          | Done         |
| archived      | Canceled     |

### Priority Mapping

| Maestro Priority | Linear Priority |
|-----------------|----------------|
| urgent          | 1 (Urgent)     |
| high            | 2 (High)       |
| medium          | 3 (Medium)     |
| low             | 4 (Low)        |
| none            | 0 (No priority)|

### GraphQL API

LinearAPIClient provides direct access to Linear's GraphQL API:

- `fetchMyIssues()` - Get all assigned issues
- `fetchIssue(id:)` - Get specific issue
- `createIssue(...)` - Create new issue
- `updateIssue(...)` - Update existing issue
- `fetchWorkflowStates(teamId:)` - Get team workflow states

## Database Schema

### Spaces Table

```sql
CREATE TABLE spaces (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    path TEXT,
    color TEXT NOT NULL,
    parent_id TEXT,
    tags TEXT NOT NULL DEFAULT '[]',
    archived INTEGER NOT NULL DEFAULT 0,
    track_focus INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    last_active_at TEXT NOT NULL,
    total_focus_time INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (parent_id) REFERENCES spaces(id) ON DELETE CASCADE
);
```

### Tasks Table

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    space_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'inbox',
    priority TEXT NOT NULL DEFAULT 'none',
    position INTEGER NOT NULL DEFAULT 0,
    due_date TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    completed_at TEXT,
    FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE,
    CHECK (status IN ('inbox', 'todo', 'inProgress', 'done', 'archived')),
    CHECK (priority IN ('none', 'low', 'medium', 'high', 'urgent'))
);
```

### Documents Table

```sql
CREATE TABLE documents (
    id TEXT PRIMARY KEY,
    space_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    path TEXT NOT NULL DEFAULT '/',
    is_default INTEGER NOT NULL DEFAULT 0,
    is_pinned INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (space_id) REFERENCES spaces(id) ON DELETE CASCADE
);
```

### Integration Tables

- `reminder_space_links` - Links Maestro spaces to EventKit reminders
- `linear_sync` - Links Maestro tasks to Linear issues

## Development

### Running Tests

```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter MaestroCoreTests

# Run with verbose output
swift test -v
```

### Test Coverage

- 156 tests covering all major functionality
- Unit tests for all stores and models
- Integration tests for MCP tools
- End-to-end system tests
- Async Linear API integration tests

### Code Quality

```bash
# Format code
swiftformat Sources/ Tests/

# Lint
swiftlint
```

## Known Issues

1. **EventKit Permissions** - Reminder sync requires explicit user permission on first run
2. **Linear OAuth** - Currently uses API key authentication; OAuth flow pending
3. **Linear Webhooks** - Real-time sync via webhooks not yet implemented
4. **Web Viewer** - Dashboard UI is placeholder; full implementation pending
5. **Menu Bar Icon** - Currently uses default system icon; custom icon needed

## Future Roadmap

### Phase 1: Core Stability (Q1 2025)

- ✅ Complete Linear API GraphQL integration
- Add Linear OAuth authentication flow
- Add Linear webhook support for real-time sync
- Implement full web dashboard UI
- Add custom menu bar icon and animations
- Enhanced logging and error reporting

### Phase 2: Advanced Features (Q2 2025)

- Focus time tracking with automatic detection
- Advanced task surfacing with ML-based prioritization
- Multi-workspace support
- iCloud sync for cross-device access

### Phase 3: Ecosystem Integration (Q3 2025)

- GitHub Issues integration
- Notion sync
- Calendar integration beyond EventKit
- Slack notifications and commands

### Phase 4: AI Features (Q4 2025)

- Natural language task creation via MCP
- Smart task suggestions based on context
- Automated task categorization
- Time estimation and deadline prediction

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built with [GRDB.swift](https://github.com/groue/GRDB.swift) for SQLite persistence
- MCP integration via [Anthropic MCP Swift SDK](https://github.com/anthropics/mcp-swift-sdk)
- Inspired by productivity systems from Getting Things Done and PARA Method
