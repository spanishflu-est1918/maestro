# Linear Integration Workflow

Guide for integrating Maestro with Linear for issue tracking and team coordination.

## Integration Philosophy

**Maestro** = Detailed execution tracking, personal workflows, AI agent coordination
**Linear** = Team visibility, milestone tracking, sprint planning, PR linking

Use both together for comprehensive project management.

## Bidirectional Linking

### Linear → Maestro

When you have a Linear issue that needs detailed execution:

1. **Create the Linear issue** (use Linear MCP or web UI)
2. **Create Maestro task** referencing the issue:

```json
{
  "spaceId": "project-space-uuid",
  "title": "[ENG-123] Implement real-time notifications",
  "description": "**Linear Issue:** ENG-123\nhttps://linear.app/team/issue/ENG-123\n\n**Requirements:**\n- WebSocket connection\n- Notification UI\n- User preferences",
  "status": "todo",
  "priority": "high"
}
```

3. **Work in Maestro** for detailed tracking:
   - Break down into subtasks
   - Track agent sessions
   - Log detailed progress
   - Use surfacing for prioritization

4. **Update Linear** when status changes:
   - Maestro "inProgress" → Linear "In Progress"
   - Maestro "done" → Linear "Done"

### Maestro → Linear

When Maestro task needs team visibility:

1. **Create Maestro task first** (for personal/team work)
2. **Escalate to Linear** if:
   - Needs stakeholder visibility
   - Requires sprint planning
   - Needs PR linking
   - Involves multiple teams

3. **Create Linear issue** and link back:
   - Copy Maestro task details to Linear
   - Add Linear issue ID to Maestro task
   - Keep both in sync

## Status Synchronization

### Manual Sync Pattern

**When Maestro task changes**:
```
1. Update Maestro task status
2. Update corresponding Linear issue status
3. Add progress notes to both
```

**When Linear issue changes**:
```
1. Check for linked Maestro task
2. Update Maestro task to match
3. Sync any new requirements
```

### Automated Sync (Future)

The Linear integration tracks:
- **linearDoneCount**: Issues marked "Done" in last 24h
- **linearAssignedCount**: Currently assigned issues

These appear in menu bar status summary automatically.

## Workflow Patterns

### Pattern 1: Sprint Planning

**Use Linear for**:
- Sprint milestone creation
- Story point estimation
- Team capacity planning
- Sprint retrospectives

**Use Maestro for**:
- Daily task prioritization (surfacing)
- Individual execution tracking
- Agent activity monitoring
- Detailed progress updates

**Process**:
```
1. Plan sprint in Linear (assign issues, set estimates)
2. Create Maestro space for sprint
3. Create Maestro tasks linked to Linear issues
4. Use Maestro surfacing for daily priorities
5. Update both systems as work progresses
6. Review in Linear during retro
```

### Pattern 2: Bug Tracking

**Use Linear for**:
- Customer-reported bugs
- Bug triaging
- Priority assignment
- Customer communication

**Use Maestro for**:
- Investigation tasks
- Reproduction steps
- Fix implementation
- Testing verification

**Process**:
```
1. Customer reports bug → Create Linear issue
2. Triage in Linear, assign to team member
3. Create Maestro task: "[BUG-123] Fix login timeout"
4. Track investigation in Maestro
5. Log agent activity if using AI for debugging
6. Complete Maestro task when fixed
7. Update Linear issue with fix details
8. Close Linear issue when deployed
```

### Pattern 3: Feature Development

**Use Linear for**:
- Feature specs
- Design reviews
- Milestone tracking
- Stakeholder updates

**Use Maestro for**:
- Implementation breakdown
- Technical subtasks
- Code review tasks
- Testing tasks

**Process**:
```
1. Plan feature in Linear
2. Create feature space in Maestro
3. Break down into implementation tasks
4. Link Maestro tasks to Linear feature
5. Use Maestro for daily execution
6. Update Linear at milestones
7. Mark both complete when shipped
```

### Pattern 4: Research Tasks

**Use Linear for**:
- Research objectives
- Decision records
- Time boxing
- Team awareness

**Use Maestro for**:
- Detailed investigation steps
- Document creation
- Link collection
- Finding documentation

**Process**:
```
1. Create Linear issue: "Research GraphQL vs REST"
2. Create Maestro task with detailed steps
3. Create Maestro documents for findings
4. Log research sessions
5. Summarize in Linear issue
6. Use findings to plan next steps
```

## Naming Conventions

### Consistent Prefixing

**Pattern**: `[ISSUE-KEY] Task description`

**Examples**:
- `[ENG-123] Implement WebSocket server`
- `[BUG-456] Fix login timeout issue`
- `[FEAT-789] Add dark mode support`

**Benefits**:
- Easy to identify linked tasks
- Searchable by issue key
- Clear cross-reference

### Status Indicators

Add emoji/markers for quick scanning:

- 🔴 `[ENG-123] BLOCKED: Waiting for API access`
- 🟡 `[ENG-123] IN REVIEW: WebSocket implementation`
- 🟢 `[ENG-123] DONE: WebSocket server deployed`

## Team Coordination

### Communication Flow

**Maestro** (individual):
- Detailed progress notes
- Technical implementation details
- Blockers and dependencies
- Time tracking

**Linear** (team):
- Status updates
- Milestone progress
- Blockers requiring help
- Sprint summaries

### Handoff Pattern

When transferring work between team members:

1. **In Linear**:
   - Reassign issue to new owner
   - Add comment with context
   - Update status

2. **In Maestro**:
   - Archive your task (mark completed)
   - New owner creates their own Maestro task
   - Link to same Linear issue
   - Reference previous work in description

## Metrics and Reporting

### Linear Metrics (via Maestro)

Use `maestro_get_status` to see:

```json
{
  "linearDoneCount": 5,      // Issues completed today
  "linearAssignedCount": 12  // Currently assigned issues
}
```

**Use for**:
- Daily standups (done count)
- Workload monitoring (assigned count)
- Velocity tracking (done per day)

### Maestro-Specific Metrics

Track in Maestro (not in Linear):
- Task surfacing patterns
- Agent activity per feature
- Time in each status
- Stale task detection

## Best Practices

### Do

✅ **Use both systems for their strengths**
- Linear for team coordination
- Maestro for execution detail

✅ **Keep consistent naming**
- Always prefix with Linear issue key
- Use same title in both systems

✅ **Update both regularly**
- Sync status changes daily
- Add progress notes to both

✅ **Link bidirectionally**
- Maestro task → Linear issue in description
- Linear issue → Maestro in comments

✅ **Use Linear for visibility**
- Stakeholder updates
- Sprint planning
- Team metrics

✅ **Use Maestro for execution**
- Daily priorities (surfacing)
- Detailed progress
- Agent coordination

### Don't

❌ **Don't duplicate everything**
- Not all Maestro tasks need Linear issues
- Not all Linear issues need Maestro tasks

❌ **Don't let systems drift**
- Keep status in sync
- Update both when complete

❌ **Don't over-communicate**
- Technical details in Maestro
- High-level updates in Linear

❌ **Don't create orphan references**
- Verify links are correct
- Update if issue moved/renamed

## Migration Patterns

### From Linear-Only

**Current state**: All work in Linear
**Target state**: Linear + Maestro hybrid

**Process**:
```
1. Keep existing Linear workflow
2. For complex features, create Maestro space
3. Link Maestro tasks to Linear issues
4. Use Maestro for detailed execution
5. Keep Linear as source of truth for team
```

**Gradual adoption**:
- Week 1: Try Maestro for 1 feature
- Week 2: Use surfacing for daily planning
- Week 3: Add agent monitoring
- Week 4: Full hybrid workflow

### From Maestro-Only

**Current state**: All work in Maestro
**Target state**: Linear + Maestro hybrid

**Process**:
```
1. Keep Maestro for personal work
2. Create Linear issues for team-visible work
3. Link existing Maestro tasks to new Linear issues
4. Use Linear for sprint planning
5. Keep Maestro for execution detail
```

## Integration Checklist

- [ ] Linear MCP server configured
- [ ] Team space created in Maestro
- [ ] Naming convention documented
- [ ] Status sync process defined
- [ ] Team trained on both systems
- [ ] Metrics tracking setup
- [ ] Review cadence established (daily sync, weekly review)
