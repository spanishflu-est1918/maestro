# Maestro

A native macOS task management system with MCP server integration, Linear sync, and EventKit reminders linking.

## Features

- **Native macOS Menu Bar App** - Quick access to spaces, tasks, and documents
- **MCP Server Integration** - Control Maestro via Anthropic's Model Context Protocol
- **Linear Sync** - Link Maestro tasks with Linear issues
- **EventKit Integration** - Sync with Reminders.app
- **Space-Based Organization** - Organize tasks and documents into spaces with filesystem paths
- **Task Surfacing Algorithm** - Intelligent task prioritization based on status and priority
- **Native Web Viewer** - WKWebView-based dashboard for task management

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

- 126 tests covering all major functionality
- Unit tests for all stores and models
- Integration tests for MCP tools
- End-to-end system tests

### Code Quality

```bash
# Format code
swiftformat Sources/ Tests/

# Lint
swiftlint
```

## Known Issues

1. **EventKit Permissions** - Reminder sync requires explicit user permission on first run
2. **Linear API** - Full Linear sync is stubbed; API integration pending
3. **Web Viewer** - Dashboard UI is placeholder; full implementation pending
4. **Menu Bar Icon** - Currently uses default system icon; custom icon needed

## Future Roadmap

### Phase 1: Core Stability (Q1 2025)

- Complete Linear API integration with OAuth flow
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
