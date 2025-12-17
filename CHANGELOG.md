# Changelog

All notable changes to Maestro will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-17

### Added

#### Core Data Layer
- Database manager with GRDB integration
- Automatic migrations system (v1, v2, v3)
- Space model with hierarchy support and path inference
- Task model with status transitions and priority levels
- Document model with default/pinned support
- SpaceStore with full CRUD operations
- TaskStore with surfacing algorithm and status management
- DocumentStore with organization features

#### MCP Server Integration
- MCP server daemon with stdio transport
- 23 MCP tools for spaces, tasks, and documents
- Space management tools (list, get, create, update, archive, delete)
- Task management tools (list, get, create, update, complete, archive, delete, surfaced)
- Document management tools (list, get, create, update, pin, unpin, delete, default)
- Comprehensive error handling with detailed error messages
- Tool parameter validation

#### Daemon
- Background daemon process with signal handling (SIGTERM, SIGINT, SIGQUIT)
- JSON-based configuration system with path expansion
- File-based logging with automatic rotation
- Configurable log levels (debug, info, warning, error)
- Database path configuration
- Graceful shutdown handling

#### Menu Bar App
- Native macOS status bar integration
- Quick view dropdown panel with recent spaces and due tasks
- Native web viewer window with WKWebView
- Window position persistence across launches
- Preferences window for configuration
- Database connection with automatic initialization

#### External Integrations
- **EventKit Integration**
  - Link spaces to Reminders.app reminders
  - Sync reminder state (completed, due date)
  - ReminderLink model with GRDB persistence
  - ReminderSync service with permission handling

- **Linear Integration**
  - Full GraphQL API integration with LinearAPIClient
  - Create Linear issues from Maestro tasks
  - Bidirectional sync (Maestro ↔ Linear)
  - Fetch and update Linear issues asynchronously
  - Status and priority mapping between systems
  - LinearLink model with GRDB persistence
  - LinearSync service with async/await API calls
  - Error handling for API key validation and task linking

#### Testing
- 143 comprehensive tests (unit, integration, E2E, async)
- SpaceStore tests (10 tests)
- TaskStore tests (10 tests)
- DocumentStore tests (5 tests)
- Space model tests (9 tests)
- Task model tests (6 tests)
- Document model tests (3 tests)
- Database tests (9 tests)
- Migration tests (7 tests)
- MCP server tests (17 tests)
- MCP tools tests (21 tests)
- Daemon tests (4 tests)
- AppDelegate tests (3 tests)
- QuickView tests (3 tests)
- Viewer window tests (2 tests)
- ReminderSync tests (4 tests)
- LinearSync tests (12 tests - including async API tests)
- E2E system tests (3 tests)
- Performance benchmarks (10 tests)

#### CI/CD
- GitHub Actions workflow for automated testing
- Swift build verification on push/PR
- SwiftFormat lint checking
- macOS 14 runner configuration
- Xcode 15.2 build environment

#### Documentation
- Comprehensive README with installation and usage
- Detailed MCP server configuration guide
- Database schema documentation
- Architecture overview
- Known issues and future roadmap
- Release build scripts
- Installation and uninstallation scripts

### Database Schema

#### v1 - Core Schema
- `spaces` table with hierarchy and path support
- `tasks` table with status and priority
- `documents` table with default/pinned flags
- Foreign key relationships with cascade delete
- Indexes for performance optimization

#### v2 - EventKit Integration
- `reminder_space_links` table for Reminders.app sync
- Unique constraint on reminder_id
- Indexes on space_id and reminder_id

#### v3 - Linear Integration
- `linear_sync` table for Linear issue linking
- Unique constraint on linear_issue_id
- Indexes on task_id and linear_issue_id

### Technical Details

#### Dependencies
- GRDB.swift 6.29.3 for SQLite persistence
- Anthropic MCP Swift SDK 0.10.2 for MCP integration
- Swift 5.9+ required
- macOS 13.0+ required

#### Architecture
- Modular design with separate libraries (MaestroCore, MaestroUI, Maestro)
- Clean separation of concerns (models, stores, services, UI)
- Protocol-oriented design for testability
- Async/await for modern Swift concurrency
- Actor isolation for thread safety

#### Performance
- Lazy database connections
- Efficient GRDB queries with indexes
- Minimal memory footprint for menu bar app
- Optimized task surfacing algorithm
- Log file rotation to prevent disk bloat

### Known Limitations

- EventKit permissions required for Reminders sync
- Linear API integration is stubbed (placeholder)
- Web viewer dashboard UI is minimal
- Menu bar icon uses system symbol (custom icon pending)

## [Unreleased]

### Planned Features

#### Phase 1: Core Stability
- Complete Linear API integration with OAuth
- Enhanced web dashboard UI with React
- Custom menu bar icon and animations
- Improved error reporting and recovery
- Performance optimizations

#### Phase 2: Advanced Features
- Focus time tracking with automatic detection
- ML-based task prioritization
- Multi-workspace support with separate databases
- iCloud sync for cross-device access
- Advanced search and filtering

#### Phase 3: Ecosystem Integration
- GitHub Issues integration
- Notion database sync
- Calendar integration beyond EventKit
- Slack notifications and commands
- Obsidian vault linking

#### Phase 4: AI Features
- Natural language task creation
- Smart task suggestions
- Automated categorization
- Time estimation with ML
- Deadline prediction

---

## Version History

- **0.1.0** (2025-12-17) - Initial release with core features
  - 126 tests passing
  - 23 MCP tools
  - EventKit and Linear integrations
  - Full documentation

---

For detailed commit history, see: https://github.com/yourusername/maestro/commits/main
