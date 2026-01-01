# Task Management Guide

Complete patterns and best practices for managing tasks in Maestro.

## Task Lifecycle

### 1. Capture Phase (Inbox)

**Purpose**: Quick capture without interrupting flow

**When to use inbox**:
- Rapid idea capture during meetings
- User feedback that needs triage
- Tasks that need more context before planning
- Ideas that might not become tasks

**Inbox workflow**:
```
1. Create task with status="inbox", minimal title
2. Don't worry about priority/due dates yet
3. Review inbox daily (morning planning)
4. Either:
   - Move to "todo" with full context
   - Archive if no longer relevant
   - Convert to document if it's not actionable
```

**Example**:
```json
{
  "spaceId": "personal-space-uuid",
  "title": "Explore GraphQL subscriptions",
  "status": "inbox"
}
```

### 2. Planning Phase (Todo)

**Purpose**: Ready to work, properly contextualized

**Required for todo status**:
- Clear, actionable title
- Detailed description with requirements
- Assigned priority (based on impact/urgency matrix)
- Due date (if time-sensitive)
- Proper space assignment

**Priority matrix**:
```
         High Impact    Low Impact
Urgent   → urgent       → high
Not      → medium       → low/none
Urgent
```

**Planning workflow**:
```
1. Move from inbox to todo
2. Add full description with:
   - What needs to be done
   - Why it matters
   - Acceptance criteria
   - Links to related issues/docs
3. Set priority using matrix above
4. Set due date if externally driven
5. Verify space assignment is correct
```

**Example**:
```json
{
  "id": "task-uuid",
  "title": "Implement GraphQL subscriptions for real-time updates",
  "description": "Add WebSocket-based GraphQL subscriptions to support real-time dashboard updates.\n\n**Requirements:**\n- Support subscription queries\n- Handle reconnection logic\n- Add error handling\n- Update client library\n\n**Acceptance:**\n- Dashboard updates in real-time\n- Reconnects automatically\n- No memory leaks",
  "status": "todo",
  "priority": "high",
  "dueDate": "2025-12-30"
}
```

### 3. Execution Phase (InProgress)

**Purpose**: Active work in progress

**When to move to inProgress**:
- You're actively working on it right now
- You have time blocked for it
- It's your current focus

**InProgress workflow**:
```
1. Move to inProgress when starting work (not before)
2. Update task every 1-3 days with progress notes
3. If blocked, note blocker in description
4. If pausing work, move back to todo
5. Complete when acceptance criteria met
```

**Progress update pattern**:
```
Add to description:
---
**Update 2025-12-18:**
- Completed WebSocket setup
- Added subscription resolver
- Next: Client-side integration
```

**Stale detection**: Tasks inactive for 3+ days while inProgress trigger "attention" state.

**Preventing staleness**:
- Update description with progress notes
- If blocked, document blocker and move to todo
- If waiting on others, note dependency
- If paused, move back to todo

**Example update**:
```json
{
  "id": "task-uuid",
  "description": "...(original description)...\n\n---\n**Update 2025-12-18:**\n- Implemented subscription server\n- Added reconnection logic\n- Testing error handling\n- Next: Client library updates"
}
```

### 4. Completion Phase (Done)

**Purpose**: Work completed, ready for review/deployment

**Use `maestro_complete_task`**:
```json
{
  "id": "task-uuid"
}
```

This automatically sets status to "done" and records completion time.

**Before marking complete**:
- ✅ All acceptance criteria met
- ✅ Tests passing
- ✅ Code reviewed (if applicable)
- ✅ Documentation updated

**After completion**:
- Review outcomes (what worked, what didn't)
- Update related tasks if needed
- Archive after 1-2 weeks (keeps recent history)

### 5. Archival Phase

**Purpose**: Historical record, removed from active views

**When to archive**:
- Completed tasks after review period (1-2 weeks)
- Cancelled/obsolete tasks
- Tasks superseded by other work

**Use `maestro_archive_task`**:
```json
{
  "id": "task-uuid"
}
```

**Note**: Archived tasks are excluded from:
- Surfaced tasks algorithm
- Default list views
- Stale detection
- Menu bar counts

But included in:
- Historical searches (with includeArchived=true)
- Metrics/analytics
- Audit logs

### 6. Parked Tasks Pattern

**Purpose**: Tasks that need to wait for external factors

**When to park a task**:
- Waiting for external input/approval
- Blocked by another task or dependency
- Missing required information
- Seasonal/time-gated work (not ready yet)
- Needs resources not currently available

**How to park**:
1. Keep status as `todo` or move back from `inProgress`
2. Add context to description about why it's parked:
   ```markdown
   **PARKED**: Waiting for [X]
   - Reason: [why it's waiting]
   - Needed: [what unblocks it]
   - When: [expected timeframe, if known]
   ```
3. Optionally set a due date for when to revisit
4. Task will surface when user returns to that world

**Example**:
```json
{
  "id": "task-uuid",
  "title": "Implement OAuth provider",
  "description": "Add Google OAuth integration.\n\n**PARKED**: Waiting for Google OAuth API credentials\n- Reason: IT team processing API access request\n- Needed: Client ID and Secret from Google Console\n- When: Should have by end of week\n- Next: Once credentials arrive, update .env and test flow",
  "status": "todo",
  "priority": "medium"
}
```

**When to un-park**:
- Blocker is resolved
- Information arrives
- Resources become available
- Time-gate passes

**Pattern**: Parked tasks stay visible in the space (not archived), so when user switches to that world, Claude can surface: "You have parked task X waiting for Y — has that arrived?"

**Anti-pattern**: Don't archive parked tasks — they're still relevant, just waiting.

---

## Priority Management

### Priority Levels

**Urgent** (priority=1):
- Overdue or production issues
- Blocking other work
- External hard deadlines (tomorrow)
- Security vulnerabilities
- Data loss risks

**High** (priority=2):
- Important with approaching deadlines (this week)
- High impact features
- Customer commitments
- Performance issues affecting users

**Medium** (priority=3):
- Standard feature work
- Important but not time-sensitive
- Technical debt with visible impact
- Documentation gaps

**Low** (priority=4):
- Nice-to-have improvements
- Minor UI tweaks
- Code cleanup
- Future considerations

**None** (priority=0):
- Default for inbox items
- Ideas/research tasks
- Backlog items
- Needs more definition

### Priority Anti-Patterns

❌ **Everything is urgent**:
- Dilutes meaning of priority
- Causes burnout
- Reduces focus

✅ **Use priority sparingly**:
- Max 20% of tasks should be urgent/high
- Most work is medium priority
- Low/none for backlog

❌ **Never updating priority**:
- Priorities change as context changes
- Review weekly

✅ **Adjust as needed**:
- Promote tasks as deadlines approach
- Demote tasks if dependencies emerge

## Due Date Management

### When to Set Due Dates

**Do set due dates for**:
- External commitments (demos, launches)
- Compliance deadlines
- Event-driven work (conference talks)
- Time-sensitive opportunities

**Don't set due dates for**:
- Internal feature work (use priority instead)
- Research/exploration tasks
- Backlog items
- Ongoing maintenance

### Due Date Patterns

**Hard deadline**:
```json
{
  "dueDate": "2025-12-25",
  "priority": "urgent",
  "description": "Must ship before holiday shutdown"
}
```

**Soft deadline** (target):
```json
{
  "dueDate": "2025-12-30",
  "priority": "medium",
  "description": "Target end of year, flexible if needed"
}
```

**No deadline**:
```json
{
  "priority": "high",
  "description": "Important but no external deadline"
}
```

### Overdue Handling

When task becomes overdue:
- Menu bar shows 🔴 urgent state
- Task appears first in surfaced list
- Badge counter increments

**Response pattern**:
1. Review why overdue (missed deadline vs wrong date)
2. Either:
   - Complete if nearly done
   - Extend due date with new commitment
   - Deprioritize if circumstances changed
   - Archive if no longer relevant
3. Update stakeholders if external commitment

## Task Surfacing Algorithm

### How Surfacing Works

The `maestro_get_surfaced_tasks` algorithm ranks tasks by:

1. **Overdue status** (highest priority)
   - Past due date
   - Not done/archived

2. **Due date proximity** (approaching deadlines)
   - Within 7 days: high weight
   - Within 14 days: medium weight
   - Beyond 14 days: low weight

3. **Explicit priority** (urgent → high → medium → low)
   - Urgent multiplier: 4x
   - High multiplier: 2x
   - Medium multiplier: 1x
   - Low multiplier: 0.5x

4. **Update recency** (active work prioritized)
   - Recently updated: higher rank
   - Stale (3+ days): lower rank

5. **Not archived** (archived tasks excluded)

### Using Surfaced Tasks

**Daily planning**:
```
Morning: Get top 10 surfaced tasks
Review and select 3-5 for today
Move to inProgress as you work on them
```

**Example call**:
```json
{
  "limit": 10,
  "spaceId": "current-project-uuid"
}
```

**Response interpretation**:
- First task: Most important to work on
- Top 3: Should complete today
- Top 10: Current focus area
- Beyond 10: Review weekly

**Filtering by space**:
```json
{
  "limit": 5,
  "spaceId": "frontend-space-uuid"
}
```

Returns top 5 tasks for specific team/project.

## Batch Operations

### Creating Multiple Tasks

**Use case**: Breaking down a large feature

```
1. Create parent task (overview)
2. Create child tasks (detailed steps)
3. Link via description references
4. Set dependencies in descriptions
```

**Example**: Implementing authentication

```json
// Parent task
{
  "title": "Implement user authentication",
  "description": "Complete auth system.\n\nSub-tasks:\n- JWT setup (TASK-001)\n- Login UI (TASK-002)\n- Password reset (TASK-003)",
  "status": "todo",
  "priority": "high"
}

// Child tasks
{
  "title": "TASK-001: JWT authentication setup",
  "description": "Server-side JWT implementation",
  "status": "todo",
  "priority": "high"
}
```

### Updating Multiple Tasks

**Use case**: Status transitions (sprint planning)

```
1. List tasks in current sprint space
2. Update each to inProgress
3. Set due dates for sprint end
```

### Bulk Archival

**Use case**: Cleaning up completed work

```
1. List tasks with status=done
2. Filter by updated_at > 2 weeks ago
3. Archive each task
```

## Task Organization Patterns

### By Feature

Group related tasks in same space:
```
Space: "User Authentication Feature"
Tasks:
- Backend API endpoints
- Frontend login UI
- Password reset flow
- Email verification
- Testing suite
```

### By Sprint/Iteration

Create space per sprint:
```
Space: "Sprint 24 - Dec 18-Jan 1"
Tasks: All work planned for sprint
Archive space after sprint complete
```

### By Status (Kanban)

Use status field, organize spaces by team:
```
Space: "Frontend Team"
Filter tasks by status:
- inbox (new ideas)
- todo (planned)
- inProgress (active)
- done (completed)
```

### By Priority (Eisenhower)

Organize by urgency/importance:
```
Space: "Q4 Priorities"
Tags:
- urgent-important (do first)
- important-not-urgent (schedule)
- urgent-not-important (delegate)
- neither (eliminate)
```

## Templates and Patterns

### Bug Report Template

```json
{
  "title": "[BUG] Brief description of issue",
  "description": "**Reproduction Steps:**\n1. Go to page X\n2. Click button Y\n3. Observe error Z\n\n**Expected Behavior:**\nShould do A\n\n**Actual Behavior:**\nDoes B instead\n\n**Environment:**\n- Browser: Chrome 120\n- OS: macOS 14\n- Version: 1.2.3\n\n**Fix Plan:**\nTBD after investigation",
  "priority": "high",
  "status": "todo"
}
```

### Feature Request Template

```json
{
  "title": "[FEATURE] User-facing description",
  "description": "**User Story:**\nAs a [user type], I want [goal] so that [benefit]\n\n**Requirements:**\n- Must have: Core functionality\n- Should have: Nice additions\n- Could have: Future enhancements\n\n**Acceptance Criteria:**\n- [ ] Criterion 1\n- [ ] Criterion 2\n- [ ] Criterion 3\n\n**Technical Approach:**\nTBD\n\n**Testing Plan:**\nTBD",
  "priority": "medium",
  "status": "inbox"
}
```

### Research Task Template

```json
{
  "title": "[RESEARCH] Topic to investigate",
  "description": "**Question:**\nWhat problem are we trying to solve?\n\n**Goals:**\n- Find solutions for X\n- Evaluate options A vs B\n- Recommend approach\n\n**Deliverable:**\nDocument with findings and recommendation\n\n**Time Box:**\n4 hours",
  "priority": "medium",
  "status": "todo"
}
```

### Refactoring Template

```json
{
  "title": "[REFACTOR] Component/module to improve",
  "description": "**Current Problems:**\n- Hard to test\n- Tight coupling\n- Performance issues\n\n**Goals:**\n- Extract interfaces\n- Add unit tests\n- Improve performance by 50%\n\n**Approach:**\n1. Add tests for current behavior\n2. Extract X\n3. Refactor Y\n4. Verify tests still pass\n\n**Success Metrics:**\n- Test coverage >80%\n- Load time <100ms",
  "priority": "low",
  "status": "todo"
}
```

## Best Practices Summary

**Capture**:
- ✅ Use inbox for quick capture
- ✅ Review inbox daily
- ✅ Keep inbox under 10 items

**Planning**:
- ✅ Add detailed descriptions
- ✅ Set realistic due dates
- ✅ Use priority matrix
- ✅ Break down large tasks

**Execution**:
- ✅ Update every 1-3 days
- ✅ Document blockers
- ✅ Move to todo if pausing
- ✅ Focus on acceptance criteria

**Completion**:
- ✅ Verify all criteria met
- ✅ Update linked issues
- ✅ Review outcomes
- ✅ Archive after review period

**Surfacing**:
- ✅ Check daily for priorities
- ✅ Work top 3 tasks first
- ✅ Filter by space when needed
- ✅ Trust the algorithm

**Organization**:
- ✅ Assign to proper spaces
- ✅ Use consistent naming
- ✅ Link related tasks
- ✅ Tag appropriately
