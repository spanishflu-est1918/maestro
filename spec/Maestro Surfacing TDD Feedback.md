# Maestro Surfacing Layer - TDD Specification

**Version:** 0.2.0  
**Date:** 2025-12-17  
**Status:** Specification  

---

## Overview

Menu bar ambient signal + structured popover. No AI in the daemon - Claude queries via MCP when user wants narrative.

```
┌──────────────────────────────────────────┐
│  Menu Bar                                │
│  🟠 ← color = "something to see"         │
└────────────────┬─────────────────────────┘
                 │ click
                 ▼
┌──────────────────────────────────────────┐
│  ┌────────────────────────────────────┐  │
│  │ 2 overdue • 1 agent waiting        │  │
│  │ Linear: 3 done since yesterday     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

---

## 1. Data Model

### 1.1 Menu Bar State

```swift
// MenuBarState.swift

public enum MenuBarColor: String, Codable {
    case clear = "clear"         // 🟢 Nothing actionable
    case attention = "attention" // 🟡 Stale tasks, idle agents
    case input = "input"         // 🟠 Agent needs input
    case urgent = "urgent"       // 🔴 Overdue task
}

public struct MenuBarState: Codable {
    public let color: MenuBarColor
    public let badgeCount: Int
    public let summary: StatusSummary
    public let updatedAt: Date
}

public struct StatusSummary: Codable {
    public let overdueTaskCount: Int
    public let staleTaskCount: Int
    public let agentsNeedingInputCount: Int
    public let activeAgentCount: Int
    public let linearDoneCount: Int      // Issues moved to Done in last 24h
    public let linearAssignedCount: Int  // New issues assigned
}
```

### 1.2 Priority Order

```
urgent (🔴) > input (🟠) > attention (🟡) > clear (🟢)
```

| Condition | Color | Badge Increment |
|-----------|-------|-----------------|
| Task overdue | urgent | +1 per task |
| Agent needs input | input | +1 per agent |
| Task stale (3+ days in progress) | attention | 0 |
| Agent idle | attention | 0 |
| Nothing | clear | 0 |

---

## 2. State Calculator

### 2.1 Core Tests

```swift
// Tests: MenuBarStateCalculatorTests.swift

// MARK: - Color Logic

func test_clearState_whenNoIssues() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .clear)
    XCTAssertEqual(state.badgeCount, 0)
}

func test_urgentState_whenOverdueTask() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Create overdue task
    let task = Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Overdue task",
        status: .todo,
        dueDate: Date().addingTimeInterval(-24 * 60 * 60) // Yesterday
    )
    try taskStore.create(task)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .urgent)
    XCTAssertEqual(state.summary.overdueTaskCount, 1)
    XCTAssertEqual(state.badgeCount, 1)
}

func test_urgentState_multipleOverdueTasks() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    try taskStore.create(Task(id: UUID(), spaceId: spaceId, title: "Overdue 1", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
    try taskStore.create(Task(id: UUID(), spaceId: spaceId, title: "Overdue 2", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
    try taskStore.create(Task(id: UUID(), spaceId: spaceId, title: "Overdue 3", status: .inProgress, dueDate: Date().addingTimeInterval(-86400)))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .urgent)
    XCTAssertEqual(state.summary.overdueTaskCount, 3)
    XCTAssertEqual(state.badgeCount, 3)
}

func test_notOverdue_whenDueDateInFuture() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    let task = Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Future task",
        status: .todo,
        dueDate: Date().addingTimeInterval(24 * 60 * 60) // Tomorrow
    )
    try taskStore.create(task)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .clear)
    XCTAssertEqual(state.summary.overdueTaskCount, 0)
}

func test_notOverdue_whenTaskDone() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Overdue but completed - shouldn't count
    let task = Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Done task",
        status: .done,
        dueDate: Date().addingTimeInterval(-86400),
        completedAt: Date()
    )
    try taskStore.create(task)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .clear)
    XCTAssertEqual(state.summary.overdueTaskCount, 0)
}

func test_attentionState_whenStaleTask() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Task in progress, not updated for 4 days
    let task = Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Stale task",
        status: .inProgress,
        createdAt: Date().addingTimeInterval(-10 * 86400),
        updatedAt: Date().addingTimeInterval(-4 * 86400) // 4 days ago
    )
    try taskStore.create(task)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .attention)
    XCTAssertEqual(state.summary.staleTaskCount, 1)
    XCTAssertEqual(state.badgeCount, 0) // Stale doesn't increment badge
}

func test_notStale_whenTodoStatus() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Todo tasks can sit - only inProgress goes stale
    let task = Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Old todo",
        status: .todo,
        createdAt: Date().addingTimeInterval(-10 * 86400),
        updatedAt: Date().addingTimeInterval(-10 * 86400)
    )
    try taskStore.create(task)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.staleTaskCount, 0)
}

func test_notStale_whenRecentlyUpdated() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    let task = Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Active task",
        status: .inProgress,
        createdAt: Date().addingTimeInterval(-10 * 86400),
        updatedAt: Date().addingTimeInterval(-1 * 86400) // 1 day ago
    )
    try taskStore.create(task)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.staleTaskCount, 0)
}

// MARK: - Priority Order

func test_urgentOverridesInput() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Overdue task
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Overdue",
        status: .todo,
        dueDate: Date().addingTimeInterval(-86400)
    ))
    
    // Agent needs input (assume agent_sessions table exists)
    try sessionStore.create(AgentSession(
        id: UUID(),
        agentType: .claudeCode,
        projectPath: "/test",
        status: .needsInput,
        startedAt: Date()
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .urgent) // Urgent wins
    XCTAssertEqual(state.badgeCount, 2)  // Both count
}

func test_inputOverridesAttention() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Agent needs input
    try sessionStore.create(AgentSession(
        id: UUID(),
        agentType: .claudeCode,
        projectPath: "/test",
        status: .needsInput,
        startedAt: Date()
    ))
    
    // Stale task
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Stale",
        status: .inProgress,
        updatedAt: Date().addingTimeInterval(-4 * 86400)
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .input) // Input wins over attention
}

func test_attentionOverridesClear() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Only stale task, no urgent/input
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Stale",
        status: .inProgress,
        updatedAt: Date().addingTimeInterval(-4 * 86400)
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .attention)
}

// MARK: - Badge Count

func test_badgeCount_sumsOverdueAndNeedsInput() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // 2 overdue
    try taskStore.create(Task(id: UUID(), spaceId: spaceId, title: "O1", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
    try taskStore.create(Task(id: UUID(), spaceId: spaceId, title: "O2", status: .todo, dueDate: Date().addingTimeInterval(-86400)))
    
    // 1 agent needs input
    try sessionStore.create(AgentSession(id: UUID(), agentType: .claudeCode, projectPath: "/a", status: .needsInput, startedAt: Date()))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.badgeCount, 3)
}

func test_badgeCount_excludesStaleAndIdle() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // 1 stale task
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Stale",
        status: .inProgress,
        updatedAt: Date().addingTimeInterval(-4 * 86400)
    ))
    
    // 1 idle agent
    try sessionStore.create(AgentSession(
        id: UUID(),
        agentType: .claudeCode,
        projectPath: "/a",
        status: .idle,
        startedAt: Date()
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.badgeCount, 0) // Neither counts
    XCTAssertEqual(state.color, .attention)
}

// MARK: - Configuration

func test_staleThreshold_isConfigurable() throws {
    let calculator = MenuBarStateCalculator(database: db, staleThresholdDays: 7)
    
    // 5 days old - not stale with 7-day threshold
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Recent-ish",
        status: .inProgress,
        updatedAt: Date().addingTimeInterval(-5 * 86400)
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.staleTaskCount, 0)
}

func test_staleThreshold_defaultsTo3Days() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // 2 days old - not stale
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "2 days",
        status: .inProgress,
        updatedAt: Date().addingTimeInterval(-2 * 86400)
    ))
    
    // 4 days old - stale
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "4 days",
        status: .inProgress,
        updatedAt: Date().addingTimeInterval(-4 * 86400)
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.staleTaskCount, 1)
}
```

### 2.2 Linear Integration Tests

```swift
// Tests: MenuBarStateLinearTests.swift

func test_linearDoneCount_countsLast24Hours() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // Issue marked done 12 hours ago
    try linearStore.create(LinearLink(
        id: UUID(),
        taskId: taskId,
        linearIssueId: "issue-1",
        linearIssueKey: "MAE-1",
        linearTeamId: "team-1",
        linearState: "Done",
        updatedAt: Date().addingTimeInterval(-12 * 3600)
    ))
    
    // Issue marked done 36 hours ago - shouldn't count
    try linearStore.create(LinearLink(
        id: UUID(),
        taskId: taskId2,
        linearIssueId: "issue-2",
        linearIssueKey: "MAE-2",
        linearTeamId: "team-1",
        linearState: "Done",
        updatedAt: Date().addingTimeInterval(-36 * 3600)
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.linearDoneCount, 1)
}

func test_linearDoneCount_onlyCountsDoneState() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    // In Progress - shouldn't count
    try linearStore.create(LinearLink(
        id: UUID(),
        taskId: taskId,
        linearIssueId: "issue-1",
        linearIssueKey: "MAE-1",
        linearTeamId: "team-1",
        linearState: "In Progress",
        updatedAt: Date().addingTimeInterval(-1 * 3600)
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.linearDoneCount, 0)
}
```

### 2.3 Agent State Tests (Assumes agent_sessions exists)

```swift
// Tests: MenuBarStateAgentTests.swift

func test_inputState_whenAgentNeedsInput() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    try sessionStore.create(AgentSession(
        id: UUID(),
        agentType: .claudeCode,
        projectPath: "/test",
        status: .needsInput,
        startedAt: Date()
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .input)
    XCTAssertEqual(state.summary.agentsNeedingInputCount, 1)
    XCTAssertEqual(state.badgeCount, 1)
}

func test_activeAgentCount_excludesEnded() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    try sessionStore.create(AgentSession(id: UUID(), agentType: .claudeCode, projectPath: "/a", status: .active, startedAt: Date()))
    try sessionStore.create(AgentSession(id: UUID(), agentType: .codexCLI, projectPath: "/b", status: .idle, startedAt: Date()))
    try sessionStore.create(AgentSession(id: UUID(), agentType: .claudeCode, projectPath: "/c", status: .ended, startedAt: Date(), endedAt: Date()))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.summary.activeAgentCount, 2) // active + idle, not ended
}

func test_attentionState_whenAgentIdle() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    try sessionStore.create(AgentSession(
        id: UUID(),
        agentType: .claudeCode,
        projectPath: "/test",
        status: .idle,
        startedAt: Date()
    ))
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .attention) // Idle = attention, not input
}
```

---

## 3. MCP Tool

### 3.1 Status Tool Tests

```swift
// Tests: MCPStatusToolTests.swift

func test_getStatus_returnsFullSummary() async throws {
    let server = try MaestroMCPServer(databasePath: ":memory:")
    
    // Setup: 1 overdue task
    try taskStore.create(Task(
        id: UUID(),
        spaceId: spaceId,
        title: "Overdue",
        status: .todo,
        dueDate: Date().addingTimeInterval(-86400)
    ))
    
    let result = try await server.callTool(
        "maestro_get_status",
        arguments: [:]
    )
    
    XCTAssertEqual(result["color"] as? String, "urgent")
    XCTAssertEqual(result["badge_count"] as? Int, 1)
    XCTAssertEqual(result["overdue_task_count"] as? Int, 1)
    XCTAssertEqual(result["stale_task_count"] as? Int, 0)
    XCTAssertEqual(result["agents_needing_input_count"] as? Int, 0)
    XCTAssertEqual(result["active_agent_count"] as? Int, 0)
}

func test_getStatus_includesTimestamp() async throws {
    let server = try MaestroMCPServer(databasePath: ":memory:")
    
    let result = try await server.callTool(
        "maestro_get_status",
        arguments: [:]
    )
    
    XCTAssertNotNil(result["updated_at"])
}

func test_getStatus_includesLinearCounts() async throws {
    let server = try MaestroMCPServer(databasePath: ":memory:")
    
    // Setup Linear done issue
    try linearStore.create(LinearLink(
        id: UUID(),
        taskId: taskId,
        linearIssueId: "issue-1",
        linearIssueKey: "MAE-1",
        linearTeamId: "team-1",
        linearState: "Done",
        updatedAt: Date().addingTimeInterval(-1 * 3600)
    ))
    
    let result = try await server.callTool(
        "maestro_get_status",
        arguments: [:]
    )
    
    XCTAssertEqual(result["linear_done_count"] as? Int, 1)
}

func test_getStatus_toolIsRegistered() throws {
    let server = try MaestroMCPServer(databasePath: ":memory:")
    
    let tools = server.listTools()
    let toolNames = tools.map { $0.name }
    
    XCTAssertTrue(toolNames.contains("maestro_get_status"))
}
```

### 3.2 Tool Definition

```swift
// Tool definition for MCP server

Tool(
    name: "maestro_get_status",
    description: """
        Get current status summary for menu bar.
        Returns: color (clear/attention/input/urgent), badge_count, 
        and counts for overdue tasks, stale tasks, agents needing input,
        active agents, and recent Linear activity.
        """,
    parameters: [:] // No parameters needed
)
```

---

## 4. Implementation

### 4.1 MenuBarStateCalculator

```swift
// MenuBarStateCalculator.swift

public class MenuBarStateCalculator {
    private let db: Database
    private let staleThresholdDays: Int
    
    public init(database: Database, staleThresholdDays: Int = 3) {
        self.db = database
        self.staleThresholdDays = staleThresholdDays
    }
    
    public func calculate() throws -> MenuBarState {
        let summary = try calculateSummary()
        let color = determineColor(from: summary)
        let badge = calculateBadge(from: summary)
        
        return MenuBarState(
            color: color,
            badgeCount: badge,
            summary: summary,
            updatedAt: Date()
        )
    }
    
    private func calculateSummary() throws -> StatusSummary {
        // Query each metric
        let overdueCount = try countOverdueTasks()
        let staleCount = try countStaleTasks()
        let needsInputCount = try countAgentsNeedingInput()
        let activeCount = try countActiveAgents()
        let linearDone = try countLinearDone()
        let linearAssigned = try countLinearAssigned()
        
        return StatusSummary(
            overdueTaskCount: overdueCount,
            staleTaskCount: staleCount,
            agentsNeedingInputCount: needsInputCount,
            activeAgentCount: activeCount,
            linearDoneCount: linearDone,
            linearAssignedCount: linearAssigned
        )
    }
    
    private func determineColor(from summary: StatusSummary) -> MenuBarColor {
        if summary.overdueTaskCount > 0 {
            return .urgent
        }
        if summary.agentsNeedingInputCount > 0 {
            return .input
        }
        if summary.staleTaskCount > 0 {
            return .attention
        }
        return .clear
    }
    
    private func calculateBadge(from summary: StatusSummary) -> Int {
        // Only overdue + needs_input count for badge
        return summary.overdueTaskCount + summary.agentsNeedingInputCount
    }
}
```

### 4.2 SQL Queries

```sql
-- Overdue tasks
SELECT COUNT(*) FROM tasks 
WHERE due_date < datetime('now') 
  AND status NOT IN ('done', 'archived');

-- Stale tasks (inProgress, not updated in N days)
SELECT COUNT(*) FROM tasks
WHERE status = 'inProgress'
  AND updated_at < datetime('now', '-3 days');

-- Agents needing input
SELECT COUNT(*) FROM agent_sessions
WHERE status = 'needs_input';

-- Active agents (not ended)
SELECT COUNT(*) FROM agent_sessions
WHERE status != 'ended';

-- Linear done in last 24h
SELECT COUNT(*) FROM linear_sync
WHERE linear_state = 'Done'
  AND updated_at > datetime('now', '-1 day');
```

---

## 5. Performance Tests

```swift
// Tests: MenuBarStatePerformanceTests.swift

func test_calculate_performsUnder10ms() throws {
    let db = Database(path: ":memory:")
    try db.connect()
    
    // Setup: 500 tasks, 20 agents, 100 Linear links
    let space = Space(id: UUID(), name: "Test", color: "#000")
    try spaceStore.create(space)
    
    for i in 0..<500 {
        try taskStore.create(Task(
            id: UUID(),
            spaceId: space.id,
            title: "Task \(i)",
            status: i % 5 == 0 ? .inProgress : .todo,
            dueDate: i % 10 == 0 ? Date().addingTimeInterval(-86400) : nil
        ))
    }
    
    for i in 0..<20 {
        try sessionStore.create(AgentSession(
            id: UUID(),
            agentType: .claudeCode,
            projectPath: "/project-\(i)",
            status: i % 5 == 0 ? .needsInput : .active,
            startedAt: Date()
        ))
    }
    
    let calculator = MenuBarStateCalculator(database: db)
    
    measure {
        for _ in 0..<100 {
            _ = try? calculator.calculate()
        }
    }
    // Target: < 10ms average per calculation
}

func test_calculate_handlesEmptyDatabase() throws {
    let calculator = MenuBarStateCalculator(database: db)
    
    let state = try calculator.calculate()
    
    XCTAssertEqual(state.color, .clear)
    XCTAssertEqual(state.badgeCount, 0)
}
```

---

## 6. Test Summary

| Category | Tests |
|----------|-------|
| Color logic | 8 |
| Priority order | 3 |
| Badge count | 2 |
| Configuration | 2 |
| Linear integration | 2 |
| Agent state | 3 |
| MCP tool | 4 |
| Performance | 2 |
| **Total** | **26** |

---

## 7. Implementation Order

1. [ ] MenuBarState model
2. [ ] StatusSummary model  
3. [ ] MenuBarStateCalculator
4. [ ] SQL queries for each metric
5. [ ] MCP tool `maestro_get_status`
6. [ ] Wire to menu bar UI (color + badge)
7. [ ] Popover displays summary

---

## 8. Usage Flow

**Ambient:**
1. Daemon runs calculator on interval (30s) or on data change
2. Menu bar icon updates color
3. Badge shows count

**On click:**
1. Popover shows structured summary
2. "2 overdue • 1 agent waiting • Linear: 3 done"

**Claude query:**
```
User: "What's my status?"
Claude: calls maestro_get_status
Claude: "You have 2 overdue tasks and Claude Code is waiting for permission on the maestro project."
```
