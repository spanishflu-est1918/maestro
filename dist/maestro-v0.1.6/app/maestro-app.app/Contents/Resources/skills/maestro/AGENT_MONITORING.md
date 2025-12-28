# Agent Monitoring Guide

Complete guide for tracking AI agent activity in Maestro.

## Overview

Agent monitoring helps you:
- Track Claude Code and Codex sessions
- Understand tool usage patterns
- Identify errors and blockers
- Measure productivity metrics
- Optimize agent workflows

## Core Concepts

### Sessions

A **session** represents one complete agent interaction:
- Start time (when agent begins work)
- End time (when agent completes or stops)
- Duration (total time active)
- Outcome (completed, failed, needs_input)
- Agent name (claude-code, codex, custom)

### Activities

**Activities** are events within a session:
- Tool calls (which tools were used)
- User messages (when you provided input)
- Errors (when something went wrong)
- Timestamps (when activity occurred)

### Metrics

**Metrics** aggregate session data:
- Total sessions count
- Active sessions (currently running)
- Average session duration
- Tool usage frequency
- Error rates
- Most used tools

## Session Management

### Starting a Session

**When to start**:
- Beginning AI-assisted coding work
- Starting automated task execution
- Running agent-driven workflows

**How to start**:
```json
{
  "agentName": "claude-code",
  "startedAt": "2025-12-18T10:00:00Z"
}
```

**Agent names**:
- `claude-code`: Claude Code CLI
- `codex`: OpenAI Codex
- `cursor`: Cursor AI
- `copilot`: GitHub Copilot
- Custom names for your own agents

**Returns**: Session ID for tracking activities

### During a Session

Track significant events with `maestro_log_agent_activity`:

**Tool call activity**:
```json
{
  "sessionId": "session-uuid",
  "activityType": "tool_call",
  "description": "Called maestro_create_task to create feature task",
  "timestamp": "2025-12-18T10:05:00Z"
}
```

**User message activity**:
```json
{
  "sessionId": "session-uuid",
  "activityType": "user_message",
  "description": "Provided additional context on requirements",
  "timestamp": "2025-12-18T10:10:00Z"
}
```

**Error activity**:
```json
{
  "sessionId": "session-uuid",
  "activityType": "error",
  "description": "Failed to compile: missing import statement",
  "timestamp": "2025-12-18T10:15:00Z"
}
```

### Ending a Session

**How to end**:
```json
{
  "sessionId": "session-uuid",
  "endedAt": "2025-12-18T11:00:00Z",
  "outcome": "completed"
}
```

**Outcomes**:

**completed**: Successfully finished work
- All tasks completed
- No blocking errors
- Expected result achieved

**failed**: Encountered unrecoverable error
- Build/compile errors
- Logic errors
- System failures

**needs_input**: Waiting for user input
- Ambiguous requirements
- Decision needed
- Clarification required

## Activity Logging Patterns

### Tool Call Pattern

Log when agent uses tools:

```json
{
  "activityType": "tool_call",
  "description": "maestro_create_task: Created 'Implement auth' task",
  "metadata": {
    "tool": "maestro_create_task",
    "result": "success",
    "taskId": "abc-123"
  }
}
```

**Track**:
- Which tools used most frequently
- Success/failure rates
- Time spent per tool

### User Interaction Pattern

Log when you provide input:

```json
{
  "activityType": "user_message",
  "description": "Clarified that auth should use JWT, not sessions",
  "metadata": {
    "category": "clarification",
    "impact": "changed_approach"
  }
}
```

**Track**:
- How often agent needs input
- Types of questions asked
- Workflow interruptions

### Error Pattern

Log errors for debugging:

```json
{
  "activityType": "error",
  "description": "TypeError: Cannot read property 'id' of undefined",
  "metadata": {
    "severity": "high",
    "file": "src/auth.ts",
    "line": 42,
    "recoverable": false
  }
}
```

**Track**:
- Common error types
- Error frequency
- Recovery patterns

### Decision Point Pattern

Log significant decisions:

```json
{
  "activityType": "decision",
  "description": "Chose GraphQL over REST for API",
  "metadata": {
    "alternatives": ["REST", "gRPC"],
    "reason": "Better for real-time updates",
    "reversible": true
  }
}
```

**Track**:
- Decision quality
- Reversal frequency
- Decision patterns

## Metrics Analysis

### Getting Metrics

Use `maestro_get_agent_metrics`:

```json
{
  "totalSessions": 45,
  "activeSessions": 2,
  "averageDuration": "00:42:15",
  "toolUsage": {
    "maestro_create_task": 67,
    "maestro_update_task": 34,
    "maestro_get_surfaced_tasks": 23
  },
  "errorRate": 0.12,
  "mostUsedTools": [
    "maestro_create_task",
    "maestro_list_tasks",
    "maestro_get_status"
  ]
}
```

### Interpreting Metrics

**Session Count**:
- High count: Frequent agent usage
- Low count: Manual work or infrequent AI use
- Growing: Increasing automation

**Average Duration**:
- <30 min: Quick tasks, good scoping
- 30-60 min: Standard sessions
- >60 min: Complex work or inefficiency

**Tool Usage**:
- Top tools: Core workflow patterns
- Unused tools: Features to explore or remove
- Unbalanced: Potential workflow issues

**Error Rate**:
- <10%: Healthy, expected failures
- 10-20%: Moderate issues, investigate
- >20%: Significant problems, needs attention

### Menu Bar Integration

Agent state affects menu bar:

🟠 **Orange (input)**: Agent needs input
- At least one session with outcome="needs_input"
- Badge shows count of waiting agents

🟡 **Yellow (attention)**: Idle agents
- Sessions active >1 hour without activity
- May need intervention

**Menu bar shows**:
- `agentsNeedingInputCount`: Agents waiting
- `activeAgentCount`: Currently running

## Workflow Patterns

### Pattern 1: Feature Development

```
1. Start session: "Implementing authentication feature"
2. Log: "tool_call: Created feature space"
3. Log: "tool_call: Created 5 implementation tasks"
4. Log: "user_message: Clarified JWT requirements"
5. Log: "tool_call: Generated auth middleware"
6. Log: "tool_call: Created tests"
7. End session: outcome="completed"
```

**Analysis**:
- Duration: 45 minutes
- Tools used: 4 different tools
- User input: 1 clarification
- Result: Complete feature implementation

### Pattern 2: Bug Investigation

```
1. Start session: "Investigating login timeout bug"
2. Log: "tool_call: Listed recent error logs"
3. Log: "error: Timeout after 30s waiting for DB"
4. Log: "user_message: Confirmed DB credentials correct"
5. Log: "tool_call: Checked DB connection pool settings"
6. Log: "decision: Increase pool size from 10 to 50"
7. End session: outcome="completed"
```

**Analysis**:
- Duration: 20 minutes
- Error found: Database connection pool
- User input: Verification
- Result: Root cause identified

### Pattern 3: Blocked Workflow

```
1. Start session: "Adding payment integration"
2. Log: "tool_call: Created payment task"
3. Log: "user_message: Which payment provider?"
4. Log: "user_message: What's the API key?"
5. Log: "user_message: Should we use test or live mode?"
6. End session: outcome="needs_input"
```

**Analysis**:
- Duration: 10 minutes
- User input: 3 questions (blocked)
- Result: Needs clarification before continuing

### Pattern 4: Error Recovery

```
1. Start session: "Deploying to production"
2. Log: "tool_call: Built application"
3. Log: "error: Build failed - missing dependency"
4. Log: "tool_call: Installed missing dependency"
5. Log: "tool_call: Rebuilt application"
6. Log: "tool_call: Deployed successfully"
7. End session: outcome="completed"
```

**Analysis**:
- Duration: 15 minutes
- Error encountered: Missing dependency
- Recovery: Automatic fix
- Result: Successful deployment

## Best Practices

### Session Management

✅ **Do**:
- Start session when beginning agent work
- End session when work complete or blocked
- Use descriptive agent names
- Record actual start/end times

❌ **Don't**:
- Leave sessions open indefinitely
- Reuse session IDs
- Use generic names ("agent1")
- Forget to end sessions

### Activity Logging

✅ **Do**:
- Log significant events only
- Include context in descriptions
- Use correct activity types
- Add metadata for analysis

❌ **Don't**:
- Log every tiny action
- Use vague descriptions
- Mix activity types
- Over-log (creates noise)

### Metrics Review

✅ **Do**:
- Review metrics weekly
- Look for patterns
- Identify improvement areas
- Track trends over time

❌ **Don't**:
- Obsess over metrics
- Compare different agent types
- Ignore error patterns
- Only look at totals

### Outcome Selection

✅ **Do**:
- Use "completed" for successful work
- Use "failed" for unrecoverable errors
- Use "needs_input" when blocked on user
- Be honest about outcomes

❌ **Don't**:
- Mark failed as completed
- Use "needs_input" for agent limitations
- Blame agent for unclear requirements

## Integration with Task Management

### Linking Sessions to Tasks

**Pattern**: Reference task in session activities

```json
{
  "activityType": "tool_call",
  "description": "Created task [abc-123] for authentication",
  "metadata": {
    "taskId": "abc-123",
    "operation": "create"
  }
}
```

**Benefits**:
- Track which agent worked on which tasks
- Measure agent effectiveness per task
- Understand task complexity

### Agent-Created Tasks

Track tasks created by agents:

```json
{
  "activityType": "tool_call",
  "description": "Agent created 5 subtasks for feature breakdown",
  "metadata": {
    "taskIds": ["t1", "t2", "t3", "t4", "t5"],
    "parentTask": "feature-uuid"
  }
}
```

### Progress Tracking

Log task status changes:

```json
{
  "activityType": "tool_call",
  "description": "Moved task [abc-123] to inProgress",
  "metadata": {
    "taskId": "abc-123",
    "oldStatus": "todo",
    "newStatus": "inProgress"
  }
}
```

## Advanced Patterns

### Multi-Agent Coordination

Track multiple agents working together:

**Agent 1** (code generation):
```
Session: "Generate auth middleware"
Tools: maestro_create_task, code_generation
Outcome: completed
```

**Agent 2** (testing):
```
Session: "Test auth middleware"
Tools: maestro_get_task, test_runner
Outcome: completed
```

**Agent 3** (deployment):
```
Session: "Deploy auth to staging"
Tools: maestro_update_task, deployment
Outcome: completed
```

### Performance Optimization

Track optimization work:

```
Before: Average session 60 minutes
Action: Improved tool descriptions
After: Average session 45 minutes
Result: 25% efficiency gain
```

### Error Pattern Analysis

Identify recurring errors:

```
Week 1: 12 "missing dependency" errors
Action: Created setup checklist
Week 2: 2 "missing dependency" errors
Result: 83% reduction
```

## Troubleshooting

### High Error Rate

**Problem**: >20% of sessions fail

**Solutions**:
1. Review error logs for patterns
2. Improve tool descriptions
3. Add validation to inputs
4. Provide better context upfront

### Frequent Needs Input

**Problem**: Many sessions end with "needs_input"

**Solutions**:
1. Provide more context in initial prompt
2. Add decision-making guidelines
3. Document common edge cases
4. Pre-answer likely questions

### Long Session Duration

**Problem**: Sessions consistently >60 minutes

**Solutions**:
1. Break work into smaller tasks
2. Provide clearer requirements
3. Pre-load necessary context
4. Optimize tool performance

### Low Tool Usage

**Problem**: Agents not using Maestro tools

**Solutions**:
1. Improve tool descriptions
2. Add examples to documentation
3. Train on typical workflows
4. Simplify tool interfaces
