# Headless Maestro - Native macOS Spec

## Development Philosophy: Integration-First Testing

**This project is built test-first, with a focus on integration tests.**

There is no UI to look at. Tests are how you see it works. We prioritize testing outcomes and flows over implementation details.

### Why Integration-First Testing

| Reason | Explanation |
|--------|-------------|
| **Headless** | No UI to eyeball. Tests are the visibility layer. |
| **Agent-built** | Give agents clear success criteria: "When I do X, Y happens." |
| **Data integrity** | SQLite operations must be correct. Test the actual database operations. |
| **MCP protocol** | Tool inputs/outputs must match spec exactly. Test the contracts. |
| **Real-world flows** | Test how things actually work together, not isolated methods. |
| **Faster iteration** | Fewer tests to write and maintain, more confidence per test. |

### The Approach

```
1. Write an integration test for the flow
2. Write minimal code to pass
3. Refactor
4. Repeat

Test outcomes, not implementation.
Focus on contracts and flows.
Unit tests only when logic is complex.
```

### Test Categories (Priority Order)

**Integration Tests** - Core flows (HIGHEST PRIORITY)
```swift
func testCreateSpaceAndRetrieveViaDB()
func testCreateTaskUpdatesSpaceState()
func testMCPToolCreatesAndReturnsSpace()
```

**Contract Tests** - MCP tool inputs/outputs (HIGH PRIORITY)
```swift
func testMCPListSpacesReturnsValidJSON()
func testMCPCreateTaskValidatesRequiredFields()
func testMCPToolsMatchSchema()
```

**End-to-End Tests** - Full user flows (MEDIUM PRIORITY)
```swift
func testDaemonStartsAndAcceptsMCPConnection()
func testAgentSessionTrackedFromStartToEnd()
```

**Unit Tests** - Complex logic only (LOW PRIORITY)
```swift
func testTaskSurfacingAlgorithm()
func testSpacePathInferenceEdgeCases()
```

---

## Test Specifications

### Core Integration Tests (Build These First)

```swift
// Walking Skeleton - End-to-End
func testCreateSpaceStoreRetrieveFlow()
  // Create space → Store in DB → Retrieve by ID → Verify data

func testCreateTaskInSpaceFlow()
  // Create space → Create task in space → List tasks → Verify task exists

func testUpdateTaskStatusFlow()
  // Create task → Update status → Retrieve → Verify status changed

func testArchiveSpaceAndVerifyCascade()
  // Create space with tasks → Archive space → Verify tasks archived

// Database Integration
func testSQLitePersistence()
  // Write data → Close DB → Reopen → Verify data still there

func testMigrationFromEmptyDB()
  // Start with no DB → Run migrations → Verify schema correct

func testSpacePathInference()
  // Create space with path → Query by directory → Verify space found

func testTaskSurfacingAlgorithm()
  // Create tasks with different statuses/priorities → Get surfaced → Verify order
```

### Spaces - Integration Tests

```swift
// Core CRUD (combined tests)
func testSpaceCRUDFlow()
  // Create → Get → Update → List → Archive → Delete

func testSpaceValidation()
  // Test all validation rules in one flow (missing name, invalid color, etc.)

func testSpaceHierarchy()
  // Create parent → Create children → Move child → Verify structure

func testSpacePathMatching()
  // Set paths → Test inference from various subdirectories
```

### Tasks - Integration Tests

```swift
// Core CRUD
func testTaskCRUDFlow()
  // Create → Get → Update → Complete → Archive

func testTaskValidation()
  // Test all validation rules (missing title, invalid spaceId, etc.)

func testTaskStatusTransitions()
  // inbox → todo → inProgress → done → archived

func testTaskSurfacingAndOrdering()
  // Create various tasks → Get surfaced → Verify priority/order
```

### Documents - Integration Tests

```swift
// Core CRUD
func testDocumentCRUDFlow()
  // Create → Get → Update → Delete

func testDefaultDocumentCreation()
  // Create space → Verify default doc exists → Attempt delete → Verify fails

func testDocumentOrganization()
  // Create docs → Set paths → Pin/unpin → Verify structure
```

### Reminders - Integration Tests (EventKit)

```swift
// macOS Reminders integration
func testEventKitIntegrationFlow()
  // Connect to Reminders.app → Create reminder → Verify appears in Reminders.app

func testReminderSyncFlow()
  // Fetch reminders from Reminders.app → Link to spaces → Display in viewer
```

---

**Note:** Memory System, Agent Monitor, Focus Monitor, and Maestro Agent test specifications are at the end of this document. Build the core system first.

### MCP Tools - Contract Tests

```swift
// Schema validation
func testAllMCPToolsHaveValidSchema()
  // Verify all tools have required fields, correct types

// Spaces tools
func testMCPSpacesCRUDFlow()
  // list → create → get → update → archive → delete via MCP

func testMCPSpacesValidation()
  // Missing params → Error, Invalid ID → Error, etc.

// Tasks tools
func testMCPTasksCRUDFlow()
  // list → create → get → update → complete via MCP

func testMCPTasksFiltering()
  // Filter by space, status, priority → Verify correct results

// Documents tools
func testMCPDocumentsCRUDFlow()
  // list → create → get → update → delete via MCP

// Error handling
func testMCPErrorResponses()
  // Missing params, invalid IDs, not found → Proper error format
```

### Integrations (Later)

```swift
// Linear
func testLinearSyncFlow()
  // Auth → Fetch issues → Map to tasks → Sync → Create → Push

// Calendar (future)
func testCalendarSyncFlow()
  // Auth → Fetch events → Sync reminders
```

---

## Test Infrastructure

### Setup

```swift
class MaestroTestCase: XCTestCase {
    var db: SQLiteDatabase!
    var engine: MaestroEngine!
    
    override func setUp() {
        // Fresh in-memory database for each test
        db = SQLiteDatabase(path: ":memory:")
        db.runMigrations()
        engine = MaestroEngine(db: db)
    }
    
    override func tearDown() {
        db.close()
    }
}
```

### Fixtures

```swift
extension MaestroTestCase {
    func createTestSpace(name: String = "Test Space") -> Space {
        return engine.spaces.create(name: name)
    }
    
    func createTestTask(spaceId: UUID, title: String = "Test Task") -> Task {
        return engine.tasks.create(spaceId: spaceId, title: title)
    }
    
    func createTestObservation(sessionId: UUID) -> Observation {
        return engine.memory.createObservation(
            sessionId: sessionId,
            type: .decision,
            narrative: "Test observation"
        )
    }
}
```

### Assertions

```swift
// Custom assertions for common patterns
func assertSpaceExists(_ id: UUID)
func assertTaskInStatus(_ id: UUID, _ status: TaskStatus)
func assertObservationSearchable(_ id: UUID, query: String)
func assertMCPResponseValid(_ response: MCPResponse, schema: Schema)
```

---

## Coverage Requirements

| Component | Minimum Coverage |
|-----------|------------------|
| Core Engine | 90% |
| SQLite Operations | 95% |
| MCP Tools | 100% |
| Memory System | 90% |
| Agent Monitor | 85% |
| Maestro Agent | 80% |

**No PR merged without passing tests. No feature shipped without coverage.**

---

## What This Is

A headless organizational system that runs as a native macOS daemon. Any AI (Claude, GPT, local models) can connect to it. The system extends itself to match how you work.

---

## Core Primitives (MVP)

| Primitive | Purpose |
|-----------|---------|
| **Spaces** | Work contexts (projects, areas of life) |
| **Documents** | Narrative progress logs, notes, knowledge |
| **Tasks** | Structured work items (headless Linear) |
| **Integrations** | External tools (Linear, macOS Reminders via EventKit) |

**Deferred:** Memory, Monitors, Focus tracking (see FUTURE QUESTIONS at end)

---

## Data Model

### Space

```
Space {
  id: UUID
  name: String
  path: String?              // Connected directory
  color: String              // Hex
  parentId: UUID?            // Fractal nesting
  archived: Bool
  
  // Settings
  trackFocus: Bool           // Monitor when active
  
  // Metadata
  createdAt: Date
  lastActiveAt: Date
  totalFocusTime: Int        // Seconds
}
```

### Document

```
Document {
  id: UUID
  spaceId: UUID
  
  title: String
  content: String            // Markdown
  path: String               // Virtual folder path
  
  isDefault: Bool            // Scratchpad
  isPinned: Bool
  
  createdAt: Date
  updatedAt: Date
}
```

### Task

```
Task {
  id: UUID
  spaceId: UUID
  
  title: String
  description: String?       // Markdown
  
  status: Enum {
    inbox
    todo
    inProgress
    done
    archived
  }
  
  priority: Enum {
    none
    low
    medium
    high
    urgent
  }
  
  position: Int              // Ordering within status
  dueDate: Date?
  
  createdAt: Date
  updatedAt: Date
  completedAt: Date?
}
```

### Reminder (EventKit Integration)

```
ReminderSpaceLink {
  id: UUID
  eventKitReminderId: String // ID from macOS Reminders.app
  spaceId: UUID?             // Optional - can be global

  // All actual reminder data lives in Reminders.app
  // We only store the link between Reminders and Spaces
}
```

### Memory (inspired by claude-mem)

```
Session {
  id: UUID
  spaceId: UUID
  agentType: String          // "claude-code", "codex", "gemini"
  
  startedAt: Date
  endedAt: Date?
  
  summary: String?           // AI-generated summary
}

Observation {
  id: UUID
  sessionId: UUID
  spaceId: UUID
  
  type: Enum {
    decision
    bugfix
    feature
    refactor
    discovery
    change
  }
  
  narrative: String          // Compressed description
  facts: [String]            // Extracted facts
  files: [String]            // Referenced files
  concepts: [String]         // Tags
  
  importance: Enum {
    critical
    decision
    informational
  }
  
  createdAt: Date
}
```

### Monitor

```
Monitor {
  id: UUID
  name: String
  type: String               // "claude-code", "codex", "focus", "custom"
  
  enabled: Bool
  config: JSON               // Type-specific config
  
  // For self-built monitors
  script: String?            // Extension script path
}

AgentSession {
  id: UUID
  monitorId: UUID
  spaceId: UUID?             // Inferred from project path
  
  projectPath: String
  status: Enum {
    active
    idle
    needsInput
    ended
  }
  
  startedAt: Date
  endedAt: Date?
  lastActivityAt: Date
  
  // Stats
  tokenUsage: Int?
  cost: Float?
}
```

### Integration

```
Integration {
  id: UUID
  type: String               // "linear", "calendar", "reminders"
  
  enabled: Bool
  config: JSON               // Auth tokens, settings
  
  // Per-space connections
  spaceConnections: [{
    spaceId: UUID
    externalId: String       // Linear project ID, etc.
  }]
}
```

### FocusEvent (optional monitoring)

```
FocusEvent {
  id: UUID
  spaceId: UUID?             // Inferred from app/path
  
  app: String                // Bundle ID
  windowTitle: String?
  path: String?              // If in connected directory
  
  startedAt: Date
  endedAt: Date
  duration: Int              // Seconds
}
```

---

## SQLite Schema (MVP)

```sql
-- Core tables
CREATE TABLE spaces (...);
CREATE TABLE documents (...);
CREATE TABLE tasks (...);

-- Integrations
CREATE TABLE reminder_space_links (...);  -- Link EventKit reminders to spaces
CREATE TABLE linear_sync (...);           -- Linear integration state

-- Future: sessions, observations, monitors, focus_events (see FUTURE QUESTIONS)
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Headless Maestro                          │
│                   (Native macOS Daemon)                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ MCP Server      │  │ Maestro Agent   │                  │
│  │ (tools for AI)  │  │ (queryable)     │                  │
│  └────────┬────────┘  └────────┬────────┘                  │
│           │                    │                            │
│           ▼                    ▼                            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Core Engine                          ││
│  │  Spaces | Tasks | Documents | Memory | Reminders        ││
│  └─────────────────────────────────────────────────────────┘│
│           │                    │                            │
│           ▼                    ▼                            │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │ SQLite          │  │ Monitors        │                  │
│  │ + FTS5          │  │ (extensible)    │                  │
│  └─────────────────┘  └─────────────────┘                  │
│                                │                            │
│                                ▼                            │
│                       ┌─────────────────┐                  │
│                       │ File Watchers   │                  │
│                       │ Focus Monitor   │                  │
│                       │ Agent Monitor   │                  │
│                       └─────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
           │                              │
           ▼                              ▼
    Claude/GPT/etc.              Optional Viewer UI
    (via MCP)                    (menu bar + web view)
```

---

## Visualization Layer

A simple native viewer for you to see what's happening:

### Menu Bar App

- Icon shows system status (green = healthy, yellow = agent needs input)
- Click to expand quick view
- Keyboard shortcut to open full viewer

### Quick View (dropdown from menu bar)

```
┌─────────────────────────────────────────┐
│ Maestro                            ⚙    │
├─────────────────────────────────────────┤
│                                         │
│ Active Agents                           │
│ ● claude-code  maestro/     2m ago      │
│ ○ codex        rody/        idle        │
│                                         │
│ Recent Spaces                           │
│ ▌ Maestro         1h 23m today          │
│ ▌ Rody            45m today             │
│                                         │
│ Tasks Due                               │
│ ○ Fix auth bug           today          │
│ ○ Review PR              tomorrow       │
│                                         │
│                    [Open Viewer]        │
└─────────────────────────────────────────┘
```

### Full Viewer (web view in native window)

Single-page dashboard showing everything:

```
┌─────────────────────────────────────────────────────────────────────┐
│ Maestro Viewer                                                ─ □ x │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │ SPACES                                                          ││
│  │ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                ││
│  │ │ Maestro │ │ Rody    │ │ Music   │ │ + New   │                ││
│  │ │ 3 tasks │ │ 1 task  │ │ 0 tasks │ │         │                ││
│  │ └─────────┘ └─────────┘ └─────────┘ └─────────┘                ││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                     │
│  ┌─────────────────────────────┐ ┌─────────────────────────────────┐│
│  │ AGENTS                      │ │ MEMORY (recent observations)    ││
│  │                             │ │                                 ││
│  │ ● claude-code               │ │ 10:23 - Fixed auth token bug   ││
│  │   maestro/ - active 2m     │ │ 10:15 - Decided on SQLite      ││
│  │   tokens: 12.4k  $0.03     │ │ 09:45 - Refactored monitors    ││
│  │                             │ │ 09:30 - Added focus tracking   ││
│  │ ○ codex                     │ │                                 ││
│  │   rody/ - idle 15m         │ │                                 ││
│  │                             │ │                                 ││
│  └─────────────────────────────┘ └─────────────────────────────────┘│
│                                                                     │
│  ┌─────────────────────────────┐ ┌─────────────────────────────────┐│
│  │ TASKS                       │ │ FOCUS TODAY                     ││
│  │                             │ │                                 ││
│  │ In Progress                 │ │ Maestro        ████████░░ 2h    ││
│  │ ○ Fix auth bug      🔴     │ │ Rody           ███░░░░░░░ 45m   ││
│  │ ○ Write tests       🟡     │ │ Other          ██░░░░░░░░ 30m   ││
│  │                             │ │                                 ││
│  │ Todo                        │ │                                 ││
│  │ ○ Review PR         🟠     │ │                                 ││
│  │ ○ Update docs       🔵     │ │                                 ││
│  │                             │ │                                 ││
│  └─────────────────────────────┘ └─────────────────────────────────┘│
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Agent Integration

### Claude Code

Connect via Claude Code's hook system (like claude-mem):

**Hooks:**
- `SessionStart`: Inject space context + recent observations
- `UserPromptSubmit`: Log prompt, infer space from cwd
- `PostToolUse`: Capture observation, compress with AI
- `Stop`: Generate summary
- `SessionEnd`: Close session

**MCP Tools exposed:**
- `maestro_list_spaces`
- `maestro_get_space`
- `maestro_create_task`
- `maestro_list_tasks`
- `maestro_update_task`
- `maestro_create_document`
- `maestro_search_memory`
- `maestro_log_observation`
- `maestro_ask_agent` (query Maestro Agent)

### Codex CLI

Similar hook pattern if Codex supports it, otherwise:
- File watcher on Codex session logs
- Infer activity from file changes
- MCP connection for tool access

### Context Injection

At session start, inject:

```
<maestro-context>
Space: Maestro
Path: /Users/gorka/projects/maestro

Recent observations:
- [10:23] Fixed auth token refresh - tokens now auto-renew
- [10:15] Decided on SQLite + FTS5 for memory storage
- [09:45] Refactored monitor system for extensibility

Active tasks:
- [in-progress] Fix auth bug (urgent)
- [todo] Review PR (high)

The Maestro Agent is available via maestro_ask_agent for complex queries.
</maestro-context>
```

---

## File Structure

```
~/.maestro/
├── maestro.db              # SQLite database
├── config.json             # Global settings
├── extensions/             # Self-built extensions
│   ├── claude-code-monitor.swift
│   └── focus-tracker.swift
└── logs/
    └── daemon.log
```

---

## Native Swift Components

| Component | Purpose |
|-----------|---------|
| **Daemon** | Long-running background process |
| **MCP Server** | Exposes tools to AI |
| **SQLite Manager** | All data operations |
| **Agent Monitor** | Watches agent session files |
| **Focus Monitor** | NSWorkspace notifications |
| **Menu Bar App** | Status icon + quick view |
| **Viewer Window** | WKWebView dashboard |
| **Maestro Agent** | AI with full context (via Claude API) |

---

## Technology Stack

| Technology | Purpose | Why |
|------------|---------|-----|
| **Swift Package Manager** | Build system | Native, no external tools |
| **GRDB.swift** | SQLite toolkit | Built-in migrations, type-safe queries, excellent API |
| **XCTest** | Testing framework | Native, integration-friendly |
| **EventKit** | macOS Reminders | System integration |
| **NSWorkspace** | Focus tracking | macOS window/app events |

**Key Decision: GRDB.swift over SQLite.swift**
- Built-in migration system (no custom runner needed)
- Better transaction handling and connection management
- Type-safe query builder
- Active development and excellent documentation
- Simpler API for our integration-first approach

---

## MVP Scope

Ship this first:

1. **Daemon with SQLite** (spaces, tasks, documents)
2. **MCP Server** (CRUD tools for Spaces, Tasks, Documents)
3. **Menu bar app** (status + quick view)
4. **Web viewer** (single page dashboard)
5. **EventKit integration** (link macOS Reminders to Spaces)
6. **Linear integration** (sync issues to tasks)

**Deferred to later** (see FUTURE QUESTIONS):
- Memory system (observations, compression, search)
- Agent monitoring (session tracking, status inference)
- Focus monitoring (NSWorkspace tracking)
- Maestro Agent (second AI layer)
- Self-extending capabilities

---

## Maestro Agent

The second-layer AI that has full system context. Claude/GPT can consult it for complex queries that go beyond simple data retrieval.

### Why It Exists

| Simple Query | Complex Query |
|--------------|---------------|
| "List my tasks" → MCP tool, fast | "What should I focus on today?" → Needs reasoning |
| "Get space by ID" → Direct lookup | "What's blocking progress on Maestro?" → Needs synthesis |
| "Create a task" → CRUD operation | "Summarize what happened yesterday" → Needs full context |

MCP tools are stateless function calls. The Maestro Agent is an AI with memory.

### What It Knows

- All spaces and their relationships
- All tasks across all spaces
- All documents and notes
- Full observation history (compressed memory)
- Agent session history
- Focus patterns (if enabled)
- Your work habits over time

### How It Works

```
User → Claude → "What should I focus on?"
                        │
                        ▼
                maestro_ask_agent({
                  query: "What should I focus on today?"
                })
                        │
                        ▼
              ┌─────────────────────┐
              │   Maestro Agent     │
              │                     │
              │ • Loads full context│
              │ • Reasons about it  │
              │ • Returns synthesis │
              └─────────────────────┘
                        │
                        ▼
                Claude receives:
                "Based on your patterns: You have 2 urgent 
                 tasks in Maestro. Rody has been idle 4 days.
                 Yesterday you spent 3h on agent monitoring.
                 Suggest: finish auth bug, then review PR."
```

### Implementation

The Maestro Agent is a Claude API call with a rich system prompt:

```
System prompt includes:
- All spaces (names, paths, activity)
- Active tasks (status, priority, age)
- Recent observations (last 7 days, compressed)
- Agent session summaries
- Focus time breakdown
- Any relevant documents

User query is passed through.
Response returned to calling AI.
```

### MCP Tool

```
maestro_ask_agent({
  query: String,           // Natural language question
  spaceId: String?,        // Optional focus on specific space
  includeMemory: Bool,     // Include observation history
  includeFocus: Bool       // Include focus data
})

Returns: {
  response: String,        // Agent's synthesized answer
  sources: [{              // What it drew from
    type: "task" | "observation" | "document" | "focus",
    id: String,
    summary: String
  }]
}
```

### Example Queries

| Query | What Agent Does |
|-------|-----------------|
| "What should I focus on?" | Weighs task priority, recency, deadlines, patterns |
| "What's the state of Maestro?" | Synthesizes tasks, recent work, blockers |
| "What did I do yesterday?" | Summarizes observations + focus time |
| "Why is Rody stuck?" | Looks for stale tasks, missing decisions |
| "Compare my productivity this week vs last" | Analyzes focus data trends |
| "What decisions have I made about auth?" | Searches memory, synthesizes |

### Cost Consideration

Each agent query costs API tokens. The agent should:
- Only be invoked for complex queries
- Cache recent context to reduce prompt size
- Compress aggressively
- Simple queries should use MCP tools directly

Claude/GPT should learn when to use `maestro_ask_agent` vs direct tools.

### Context Prompt Template

```
You are the Maestro Agent, an AI with full context of the user's work system.

SPACES:
{{#each spaces}}
- {{name}} ({{path}})
  Tasks: {{taskCount}} | Last active: {{lastActiveAt}}
  {{#if urgent}}⚠️ Has urgent items{{/if}}
{{/each}}

ACTIVE TASKS:
{{#each activeTasks}}
- [{{status}}] {{title}} ({{priority}}) - {{spaceName}}
  {{#if dueDate}}Due: {{dueDate}}{{/if}}
{{/each}}

RECENT MEMORY (last 7 days):
{{#each observations}}
- [{{date}}] {{narrative}}
{{/each}}

FOCUS TODAY:
{{#each focusBySpace}}
- {{spaceName}}: {{duration}}
{{/each}}

USER QUERY: {{query}}

Respond with actionable insight. Be concise. Reference specific tasks or observations when relevant.
```

---

## What Makes This Different

| Other Tools | This System |
|-------------|-------------|
| UI-first apps | Headless-first, viewer is optional |
| Single AI provider | Any AI connects via MCP |
| Fixed features | Self-extending based on needs |
| Cloud-locked | Local-first, you own the data |
| Passive recall | Active organization + memory |

---

## Implementation Checklist

**Every checkbox requires passing tests before marking complete.**

### Phase 0: Project Setup

- [x] Create Swift package
- [x] Configure XCTest
- [ ] Set up CI (GitHub Actions)
- [x] Configure GRDB.swift dependency
- [x] Create test database helpers
- [x] Create base test case class
- [x] Create Database manager with GRDB
- [x] Verify tests run on clean checkout (15/15 tests passing)

### Phase 1: Core Data Layer (Integration-First)

#### Walking Skeleton
- [ ] Test: Create space → Store → Retrieve flow
- [ ] Test: SQLite persistence (close DB, reopen, verify)
- [ ] Test: Migrations from empty DB
- [ ] Implement: Database manager + migrations

#### Spaces
- [ ] Test: Space CRUD flow (create → get → update → list → archive → delete)
- [ ] Test: Space validation (missing name, invalid color, etc.)
- [ ] Test: Space hierarchy (parent/child relationships)
- [ ] Test: Space path inference (connect directory → infer space)
- [ ] Implement: SpaceStore with all operations

#### Tasks
- [ ] Test: Task CRUD flow (create → get → update → complete → archive)
- [ ] Test: Task validation (missing fields, invalid IDs)
- [ ] Test: Task status transitions (inbox → todo → inProgress → done)
- [ ] Test: Task surfacing algorithm (priority/order)
- [ ] Implement: TaskStore with all operations

#### Documents
- [ ] Test: Document CRUD flow (create → get → update → delete)
- [ ] Test: Default document creation and protection
- [ ] Test: Document organization (paths, pinning)
- [ ] Implement: DocumentStore with all operations

#### Reminders (EventKit)
- [ ] Test: EventKit integration flow (connect to Reminders.app)
- [ ] Test: Reminder sync flow (fetch → link to spaces → display)
- [ ] Implement: EventKit integration and space linking

### Phase 2-4: Deferred Features

**These phases are deferred. See "FUTURE QUESTIONS" section at end of document.**
- Memory System (observation compression, search)
- Agent Monitor (file watching, status inference)
- Focus Monitor (NSWorkspace tracking)
- Maestro Agent (second AI layer)

### Phase 5: MCP Server

- [ ] Test: MCP server starts and accepts connections
- [ ] Test: All tools have valid schemas
- [ ] Test: Spaces CRUD via MCP (list → create → get → update → delete)
- [ ] Test: Tasks CRUD via MCP (with filtering)
- [ ] Test: Documents CRUD via MCP
- [ ] Test: Error handling (missing params, invalid IDs)
- [ ] Implement: MCPServer with all tools

### Phase 6: Deferred - See "FUTURE QUESTIONS" at end

### Phase 7: Deferred - See "FUTURE QUESTIONS" at end

### Phase 8: Daemon

- [ ] Test: Daemon starts and stays running
- [ ] Test: Startup sequence (DB init, migrations, MCP server)
- [ ] Test: Logging and configuration
- [ ] Implement: Daemon process with full startup

### Phase 9: Visualization Layer

- [ ] Test: Menu bar app appears and opens quick view
- [ ] Test: Quick view shows agents, spaces, tasks
- [ ] Test: Web viewer loads and displays all data
- [ ] Test: Native window management
- [ ] Implement: Menu bar app + web viewer + native window

### Phase 10: Integrations (LATER)

- [ ] Test: Linear sync flow (auth → fetch → map → sync)
- [ ] Test: Calendar sync flow (future)
- [ ] Implement: LinearIntegration, CalendarIntegration

### Phase 11: Extension System (FUTURE)

- [ ] Test: Extension loading and execution
- [ ] Test: Extension sandbox security
- [ ] Test: Self-building capabilities
- [ ] Implement: ExtensionLoader, ExtensionRuntime

---

## Progress Tracking

| Phase | Priority | Tests | Status |
|-------|----------|-------|--------|
| 0. Setup | FIRST | 7 tasks | ⬜ Not started |
| 1. Core Data | FIRST | ~20 integration tests | ⬜ Not started |
| 5. MCP Server | SECOND | ~6 contract tests | ⬜ Not started |
| 8. Daemon | THIRD | ~3 integration tests | ⬜ Not started |
| 9. Visualization | FOURTH | ~4 UI tests | ⬜ Not started |
| 10. Linear Integration | FIFTH | ~2 integration tests | ⬜ Not started |
| **MVP** | **CORE** | **~42 tests** | **⬜ Not started** |

**MVP Scope:** Phases 0, 1, 5, 8, 9, 10 = Headless system with:
- SQLite storage (Spaces, Tasks, Documents)
- MCP tools for AI agents
- Native macOS daemon
- Menu bar + web viewer
- EventKit reminders integration
- Linear sync

**Update status:** ⬜ Not started → 🟡 In progress → ✅ Complete

**Deferred features:** See "FUTURE QUESTIONS" section at end

---

# FUTURE QUESTIONS

These features are deferred. Build MVP first, then revisit these questions when you have real usage data.

---

## Q1: Should we build a Memory System?

**The idea:**
- Capture AI session observations (decisions, bugs fixed, features added)
- Compress tool outputs (10:1 ratio) to preserve meaning
- Store as narratives + extracted facts
- Search with FTS5
- Inject relevant context into new sessions

**Why defer:**
- Compression is subjective ("preserves meaning" is hard to test)
- Requires AI calls to compress (cost, latency)
- Can add later once we see how Claude uses the system

**When to revisit:**
- After 2-4 weeks of real usage
- If you find yourself re-explaining context to Claude repeatedly
- If context injection becomes a clear pain point

**Data model preserved in spec** (see Memory section earlier in document)

---

## Q2: Should we monitor AI agent sessions?

**The idea:**
- Watch `~/.claude/projects/*.jsonl` files
- Parse session data (project path, status, token usage)
- Infer space from project path
- Display agent status in viewer (active, idle, needs input)
- Track multiple agents simultaneously

**Why defer:**
- File watching is brittle (format could change)
- Tight coupling to Claude Code internals
- File locking issues, parsing errors
- Alternative: Build Claude Code plugin that pushes data to Maestro directly

**When to revisit:**
- After MVP ships and you're using it daily
- If agent status tracking proves valuable
- Consider building as Claude Code plugin instead of file watcher

**Data model preserved in spec** (see Monitor/AgentSession schemas)

---

## Q3: Should we track focus time?

**The idea:**
- Use NSWorkspace to detect app switches
- Capture window titles, bundle IDs
- Infer space from app context
- Track duration per space
- Display "focus time today" in viewer

**Why defer:**
- Requires accessibility permissions (privacy concern)
- Potentially creepy if not done carefully
- Adds complexity without clear ROI

**When to revisit:**
- After MVP, if you want quantified focus metrics
- Make it opt-in, off by default
- Clearly communicate what's being tracked

**Data model preserved in spec** (see FocusEvent schema)

---

## Q4: Should we build a Maestro Agent (second AI layer)?

**The idea:**
- An AI (via Claude API) that has full system context
- Answers complex queries like "What should I focus on today?"
- Claude queries it via `maestro_ask_agent` MCP tool
- Returns synthesized answers with sources

**Why defer:**
- The MCP tools already let Claude query everything
- Claude can do multi-step reasoning with multiple tool calls
- Adds cost, latency, complexity
- Not clear it's needed

**When to revisit:**
- If Claude struggles with complex queries even with tools
- If you find yourself wanting pre-synthesized answers
- Might never need it

**Implementation preserved in spec** (see Maestro Agent section)

---

## Q5: Extension system for self-building?

**The idea:**
- Load custom Swift extensions at runtime
- Extensions can add new capabilities
- Sandboxed execution
- AI agents can write extensions

**Why defer:**
- Complex and risky (security)
- Need rock-solid core first
- V2.0 feature at earliest

**When to revisit:**
- After 6+ months of stable MVP usage
- If there's proven demand for extensibility

---

**These questions are here so you don't forget them. Ship MVP first. Revisit based on real usage.**

---