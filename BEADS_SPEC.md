# Maestro - Beads Specification

**Project:** Headless Maestro MVP
**Started:** 2025-12-17 08:39 CET
**Goal:** Ship working headless organizational system with MCP tools and viewer

---

## Bead Structure

### Phase 0: Foundation

**B001: Project Setup**
- Create Swift package with proper structure
- Configure SPM dependencies (SQLite, etc.)
- Set up basic project structure
- **Tests:** Package builds without errors
- **Dependencies:** None
- **Estimate:** 1 hour

**B002: Test Infrastructure**
- Configure XCTest
- Create test database helpers (in-memory SQLite)
- Create base MaestroTestCase class
- Verify tests run on clean checkout
- **Tests:** Empty test passes
- **Dependencies:** B001
- **Estimate:** 1 hour

**B003: CI Setup**
- Set up GitHub Actions workflow
- Run tests on push
- Check Swift formatting/linting
- **Tests:** CI runs successfully
- **Dependencies:** B002
- **Estimate:** 30 minutes

---

### Phase 1: Database Foundation

**B004: Database Manager**
- Implement SQLiteDatabase class
- Connection management (open, close, reconnect)
- Transaction support
- Error handling
- **Tests:** `testSQLitePersistence()` - Write data → Close DB → Reopen → Verify data
- **Dependencies:** B002
- **Estimate:** 2 hours

**B005: Migration System**
- Implement migration runner
- Version tracking
- Idempotent migrations
- **Tests:** `testMigrationFromEmptyDB()` - Start empty → Run migrations → Verify schema
- **Dependencies:** B004
- **Estimate:** 2 hours

**B006: Core Schema Migration**
- Create initial migration with spaces, tasks, documents tables
- Define all columns, indexes, foreign keys
- **Tests:** Verify tables exist with correct schema
- **Dependencies:** B005
- **Estimate:** 1 hour

---

### Phase 1: Spaces Implementation

**B007: Space Store - CRUD**
- Implement SpaceStore.create()
- Implement SpaceStore.get()
- Implement SpaceStore.list()
- Implement SpaceStore.update()
- Implement SpaceStore.archive()
- Implement SpaceStore.delete()
- **Tests:** `testSpaceCRUDFlow()` - Create → Get → Update → List → Archive → Delete
- **Dependencies:** B006
- **Estimate:** 3 hours

**B008: Space Validation**
- Name required validation
- Color format validation
- Invalid UUID handling
- **Tests:** `testSpaceValidation()` - All validation rules
- **Dependencies:** B007
- **Estimate:** 1 hour

**B009: Space Hierarchy**
- Parent/child relationships
- Get child spaces
- Get root spaces
- Move space to new parent
- Prevent circular nesting
- **Tests:** `testSpaceHierarchy()` - Create parent → Create children → Move → Verify
- **Dependencies:** B007
- **Estimate:** 2 hours

**B010: Space Path Inference**
- Path matching for connected directories
- Subdirectory inference
- **Tests:** `testSpacePathMatching()` - Set paths → Test inference from subdirectories
- **Dependencies:** B007
- **Estimate:** 2 hours

---

### Phase 1: Tasks Implementation

**B011: Task Store - CRUD**
- Implement TaskStore.create()
- Implement TaskStore.get()
- Implement TaskStore.update()
- Implement TaskStore.delete()
- Status transitions
- **Tests:** `testTaskCRUDFlow()` - Create → Get → Update → Complete → Archive
- **Dependencies:** B007 (needs spaces)
- **Estimate:** 3 hours

**B012: Task Validation**
- Title required
- Valid spaceId required
- Defaults (inbox status, no priority)
- **Tests:** `testTaskValidation()` - All validation rules
- **Dependencies:** B011
- **Estimate:** 1 hour

**B013: Task Status Transitions**
- inbox → todo → inProgress → done → archived flow
- CompletedAt timestamps
- **Tests:** `testTaskStatusTransitions()` - Full state machine
- **Dependencies:** B011
- **Estimate:** 1 hour

**B014: Task Surfacing Algorithm**
- Priority ordering (inProgress first, then urgent/high/medium/low)
- Position within status
- Exclude done/archived
- Limit results
- **Tests:** `testTaskSurfacingAndOrdering()` - Create varied tasks → Get surfaced → Verify order
- **Dependencies:** B011
- **Estimate:** 2 hours

---

### Phase 1: Documents Implementation

**B015: Document Store - CRUD**
- Implement DocumentStore.create()
- Implement DocumentStore.get()
- Implement DocumentStore.update()
- Implement DocumentStore.delete()
- **Tests:** `testDocumentCRUDFlow()` - Create → Get → Update → Delete
- **Dependencies:** B007 (needs spaces)
- **Estimate:** 2 hours

**B016: Default Document**
- Auto-create default document on space creation
- Prevent deletion of default document
- Flag default document
- **Tests:** `testDefaultDocumentCreation()` - Create space → Verify default → Attempt delete → Verify fails
- **Dependencies:** B015
- **Estimate:** 1 hour

**B017: Document Organization**
- Virtual folder paths
- Pin/unpin documents
- **Tests:** `testDocumentOrganization()` - Create docs → Set paths → Pin/unpin → Verify
- **Dependencies:** B015
- **Estimate:** 1 hour

---

### Phase 1: Walking Skeleton

**B018: End-to-End Core Flow**
- Test: Create space → Create task → Create document → Retrieve all
- Verify entire core data layer works together
- **Tests:** `testCreateSpaceStoreRetrieveFlow()` and related E2E tests
- **Dependencies:** B007, B011, B015
- **Estimate:** 1 hour

---

### Phase 5: MCP Server Foundation

**B019: MCP Server Base**
- Implement MCPServer class
- Start/stop server
- Accept connections
- Handle ping requests
- **Tests:** `testMCPServerStartsAndAcceptsConnections()`
- **Dependencies:** B018 (needs working data layer)
- **Estimate:** 3 hours

**B020: MCP Tool Registration**
- Tool schema system
- Register tools with MCP server
- Validate all tool schemas
- **Tests:** `testAllMCPToolsHaveValidSchema()`
- **Dependencies:** B019
- **Estimate:** 2 hours

---

### Phase 5: MCP Tools Implementation

**B021: MCP Spaces Tools**
- maestro_list_spaces
- maestro_get_space
- maestro_create_space
- maestro_update_space
- maestro_archive_space
- maestro_delete_space
- **Tests:** `testMCPSpacesCRUDFlow()` - Full CRUD via MCP
- **Dependencies:** B020, B007
- **Estimate:** 3 hours

**B022: MCP Tasks Tools**
- maestro_list_tasks (with filtering)
- maestro_get_task
- maestro_create_task
- maestro_update_task
- maestro_complete_task
- **Tests:** `testMCPTasksCRUDFlow()` and `testMCPTasksFiltering()`
- **Dependencies:** B020, B011
- **Estimate:** 3 hours

**B023: MCP Documents Tools**
- maestro_list_documents
- maestro_get_document
- maestro_create_document
- maestro_update_document
- maestro_delete_document
- **Tests:** `testMCPDocumentsCRUDFlow()`
- **Dependencies:** B020, B015
- **Estimate:** 2 hours

**B024: MCP Error Handling**
- Missing parameter errors
- Invalid ID errors
- Not found errors
- Proper error response format
- **Tests:** `testMCPErrorResponses()` - All error cases
- **Dependencies:** B021, B022, B023
- **Estimate:** 1 hour

---

### Phase 8: Daemon

**B025: Daemon Process**
- Long-running background process
- Signal handling (SIGTERM, SIGINT)
- Process management
- **Tests:** `testDaemonStartsAndStaysRunning()`
- **Dependencies:** B019 (needs MCP server)
- **Estimate:** 2 hours

**B026: Daemon Startup Sequence**
- Initialize database
- Run migrations
- Start MCP server
- Load configuration
- **Tests:** `testStartupSequence()` - Full init flow
- **Dependencies:** B025, B005, B019
- **Estimate:** 2 hours

**B027: Logging and Configuration**
- File-based logging with rotation
- Configuration file loading (JSON)
- Default configuration values
- **Tests:** `testLoggingAndConfiguration()`
- **Dependencies:** B025
- **Estimate:** 2 hours

---

### Phase 9: Visualization - Menu Bar

**B028: Menu Bar App Base**
- Create native macOS menu bar application
- Status icon appears in menu bar
- Basic app lifecycle
- **Tests:** `testMenuBarIconAppears()`
- **Dependencies:** B026 (needs daemon)
- **Estimate:** 3 hours

**B029: Quick View UI**
- Dropdown panel from menu bar
- Show active agents section (placeholder for now)
- Show recent spaces
- Show due tasks
- Open viewer button
- **Tests:** `testQuickViewShowsSpacesAndTasks()`
- **Dependencies:** B028
- **Estimate:** 4 hours

---

### Phase 9: Visualization - Web Viewer

**B030: Web Viewer HTML/CSS/JS**
- Single-page dashboard HTML
- CSS styling (clean, functional)
- JavaScript for data fetching and rendering
- Display spaces, tasks, documents
- Auto-refresh every 5 seconds
- **Tests:** `testWebViewerLoadsAndDisplaysData()`
- **Dependencies:** B019 (needs data to display)
- **Estimate:** 5 hours

**B031: Native Viewer Window**
- WKWebView wrapper in native window
- Window management (open, close, resize)
- Remember window position
- Load web viewer HTML
- **Tests:** `testNativeWindowManagement()`
- **Dependencies:** B030
- **Estimate:** 2 hours

**B032: Connect Quick View to Viewer**
- Quick view "Open Viewer" button opens native window
- Pass data between menu bar and viewer
- **Tests:** Manual verification
- **Dependencies:** B029, B031
- **Estimate:** 1 hour

---

### Phase 10: Integrations

**B033: EventKit Reminders Integration**
- Request EventKit permissions
- Fetch reminders from Reminders.app
- Create reminder_space_links table
- Link reminders to spaces
- Display in viewer
- **Tests:** `testEventKitIntegrationFlow()` and `testReminderSyncFlow()`
- **Dependencies:** B006 (schema), B030 (viewer)
- **Estimate:** 4 hours

**B034: Linear Integration**
- Linear API authentication
- Fetch issues from Linear
- Map Linear issues to Maestro tasks
- Sync bidirectionally (fetch updates, push new tasks)
- Create linear_sync table for state
- **Tests:** `testLinearSyncFlow()` - Auth → Fetch → Map → Sync
- **Dependencies:** B011 (tasks), B006 (schema)
- **Estimate:** 5 hours

---

### Final Integration

**B035: End-to-End System Test**
- Start daemon
- Connect via MCP
- Create space via MCP
- Create task via MCP
- View in menu bar quick view
- View in web viewer
- Sync with Linear
- Link reminder to space
- **Tests:** Full system integration test
- **Dependencies:** B026, B032, B033, B034
- **Estimate:** 2 hours

**B036: Documentation and Polish**
- README with installation instructions
- MCP server configuration guide
- Known issues / limitations
- Future roadmap (link to FUTURE QUESTIONS)
- **Tests:** Manual review
- **Dependencies:** B035
- **Estimate:** 2 hours

---

## Dependency Graph

```
B001 (Setup)
  └─> B002 (Test Infra)
       ├─> B003 (CI)
       └─> B004 (DB Manager)
            └─> B005 (Migrations)
                 └─> B006 (Schema)
                      ├─> B007 (Spaces)
                      │    ├─> B008 (Space Validation)
                      │    ├─> B009 (Space Hierarchy)
                      │    ├─> B010 (Space Path)
                      │    ├─> B011 (Tasks)
                      │    │    ├─> B012 (Task Validation)
                      │    │    ├─> B013 (Task Transitions)
                      │    │    └─> B014 (Task Surfacing)
                      │    └─> B015 (Documents)
                      │         ├─> B016 (Default Doc)
                      │         └─> B017 (Doc Organization)
                      └─> B018 (E2E Core)
                           └─> B019 (MCP Server)
                                ├─> B020 (Tool Registration)
                                │    ├─> B021 (MCP Spaces)
                                │    ├─> B022 (MCP Tasks)
                                │    └─> B023 (MCP Docs)
                                │         └─> B024 (MCP Errors)
                                └─> B025 (Daemon)
                                     ├─> B026 (Startup)
                                     │    ├─> B028 (Menu Bar)
                                     │    │    └─> B029 (Quick View)
                                     │    └─> B030 (Web Viewer)
                                     │         └─> B031 (Native Window)
                                     │              └─> B032 (Connect UI)
                                     └─> B027 (Logging)

B033 (EventKit) ────┐
B034 (Linear) ───────┼─> B035 (E2E System Test)
B032 (Connect UI) ───┘      └─> B036 (Documentation)
```

---

## Critical Path

The fastest path to a working MVP:

1. B001 → B002 → B004 → B005 → B006 (Foundation: 6.5 hours)
2. B007 → B011 → B015 → B018 (Core Data: 11 hours)
3. B019 → B020 → B021 → B022 → B023 (MCP Server: 13 hours)
4. B025 → B026 (Daemon: 4 hours)
5. B028 → B029 (Menu Bar: 7 hours)
6. B030 → B031 → B032 (Viewer: 8 hours)
7. B033 → B034 (Integrations: 9 hours)
8. B035 → B036 (Polish: 4 hours)

**Total Critical Path: ~62.5 hours** (roughly 8 full work days)

---

## Parallel Work Opportunities

These beads can be worked on in parallel once their dependencies are met:

- After B007: Work on B008, B009, B010 simultaneously
- After B011: Work on B012, B013, B014 simultaneously
- After B015: Work on B016, B017 simultaneously
- After B020: Work on B021, B022, B023 simultaneously
- After B026: Work on B027, B028, B030 simultaneously
- After B011 and B006: Work on B033, B034 simultaneously

With parallelization: **~4-5 full work days**

---

## Notes

- All estimates are approximate
- Each bead should have tests passing before marking complete
- Zero-warning, zero-error policy applies to all code
- Use `bd create`, `bd dep add`, `bd ready` to manage beads
- Update this spec as you learn during implementation

---

**Let's ship this thing. 🚀**
