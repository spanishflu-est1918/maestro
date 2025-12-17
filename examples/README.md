# Maestro Usage Examples

This directory contains example scripts demonstrating common Maestro workflows.

## Examples

### 1. Create Project (`create-project.js`)

Demonstrates how to set up a new project with:
- Project space creation
- Initial task breakdown
- Documentation setup
- Default document configuration

**Use case:** Starting a new project or feature

```javascript
node examples/create-project.js
```

### 2. Daily Workflow (`daily-workflow.js`)

Shows a typical daily routine:
- Getting surfaced priority tasks
- Starting work on tasks
- Updating progress
- Completing tasks
- Reviewing daily summary

**Use case:** Daily task management

```javascript
# Daily workflow
node examples/daily-workflow.js

# Weekly review
node examples/daily-workflow.js --weekly
```

## How to Use

These examples are written in JavaScript pseudo-code to illustrate the MCP tool calls. To use them:

### Option 1: Via Claude Desktop (Recommended)

Simply ask Claude to execute these workflows:

```
@maestro Create a new project for "Mobile App Redesign"
```

```
@maestro Show me my top priority tasks and help me get started
```

### Option 2: Direct MCP Client

If you're building your own MCP client:

```javascript
import { MCPClient } from '@anthropic/mcp-sdk';

const client = new MCPClient({
  server: {
    command: '/usr/local/bin/maestrod',
    args: []
  }
});

await client.connect();

// Now you can call the tools
const space = await client.callTool('maestro_create_space', {
  name: "My Project",
  color: "#FF5733"
});
```

## Common Patterns

### Creating a Space

```javascript
const space = await maestro_create_space({
  name: "Project Name",
  color: "#HEXCODE",
  path: "/path/to/project", // optional
  parentId: "parent-uuid",   // optional
  tags: ["tag1", "tag2"]     // optional
});
```

### Creating a Task

```javascript
const task = await maestro_create_task({
  spaceId: space.id,
  title: "Task Title",
  description: "Detailed description", // optional
  status: "todo",                      // inbox, todo, inProgress, done
  priority: "high"                     // none, low, medium, high, urgent
});
```

### Creating a Document

```javascript
const doc = await maestro_create_document({
  spaceId: space.id,
  title: "Document Title",
  content: "# Markdown Content\n\n...",
  path: "/docs"  // virtual path within space
});
```

### Getting Priority Tasks

```javascript
// Get top 10 tasks using surfacing algorithm
const tasks = await maestro_get_surfaced_tasks({
  limit: 10,
  spaceId: space.id  // optional: filter by space
});
```

### Updating Task Status

```javascript
// Method 1: Update status directly
await maestro_update_task({
  id: task.id,
  status: "inProgress"
});

// Method 2: Use complete helper
await maestro_complete_task({
  id: task.id
});
```

## Integration Examples

### Linear Sync

```javascript
// Link a Maestro task to a Linear issue
await maestro_linear_link_issue({
  taskId: task.id,
  linearIssueId: "linear-issue-id",
  linearIssueKey: "PROJ-123",
  linearTeamId: "team-id",
  linearState: "In Progress"
});

// Get linked issue
const link = await maestro_get_linear_link({
  taskId: task.id
});
```

### EventKit Reminders

```javascript
// Link a space to a Reminders.app reminder
await maestro_link_reminder({
  spaceId: space.id,
  reminderId: "reminder-id",
  reminderTitle: "Reminder Title",
  reminderListId: "list-id",
  reminderListName: "My List"
});

// Get linked reminders
const reminders = await maestro_get_linked_reminders({
  spaceId: space.id
});
```

## Best Practices

### 1. Space Organization

- Use spaces to represent projects, areas, or clients
- Use `path` to link spaces to filesystem locations
- Use hierarchical spaces for sub-projects (set `parentId`)
- Use tags for cross-cutting concerns

### 2. Task Management

- Start tasks in `inbox`, move to `todo` when ready
- Use `inProgress` for active work (keep only 1-3 active)
- Use priority levels: `urgent` for today, `high` for this week
- Archive completed tasks periodically to reduce clutter

### 3. Document Organization

- Set one document as default (primary project doc)
- Use virtual paths to organize documents logically
- Pin frequently accessed documents
- Use Markdown for rich formatting

### 4. Workflow Integration

- Use surfaced tasks to focus on highest-impact work
- Review and process inbox regularly (GTD style)
- Link with Linear for engineering tasks
- Link with Reminders for personal tasks

## Tips

- **Batch operations**: Create multiple tasks/docs in one session
- **Use tags**: Tag spaces with "active", "paused", "archived"
- **Set due dates**: For time-sensitive tasks
- **Update descriptions**: Add progress notes as you work
- **Regular reviews**: Weekly cleanup of completed tasks

## Troubleshooting

### "Database not found"

Ensure Maestro daemon is running:
```bash
maestrod
```

### "Space/Task not found"

Verify IDs are correct:
```javascript
const spaces = await maestro_list_spaces();
console.log(spaces.map(s => ({ id: s.id, name: s.name })));
```

### "Permission denied"

For EventKit integration, grant Reminders permission:
1. System Preferences → Privacy → Reminders
2. Enable for Maestro

## More Examples

For more examples, see:
- [MCP Setup Guide](../docs/MCP_SETUP.md)
- [README](../README.md)
- [Integration documentation](../docs/)

## Contributing

Have a useful workflow? Submit a PR with your example!
