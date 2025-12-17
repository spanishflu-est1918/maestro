# MCP Server Configuration Guide

This guide covers setting up the Maestro MCP server for use with Claude Desktop and other MCP-compatible clients.

## Prerequisites

- Maestro daemon built and installed at `/usr/local/bin/maestrod`
- MCP-compatible client (e.g., Claude Desktop)
- macOS 13.0 or later

## Claude Desktop Setup

### 1. Locate Configuration File

Claude Desktop stores its MCP configuration in:

```
~/.config/claude/config.json
```

If this file doesn't exist, create it:

```bash
mkdir -p ~/.config/claude
touch ~/.config/claude/config.json
```

### 2. Add Maestro Server

Edit `~/.config/claude/config.json`:

```json
{
  "mcpServers": {
    "maestro": {
      "command": "/usr/local/bin/maestrod",
      "args": [],
      "env": {
        "MAESTRO_CONFIG": "~/.maestro/config.json"
      }
    }
  }
}
```

### 3. Create Maestro Configuration

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

**Configuration Options:**

- `logLevel`: One of `"debug"`, `"info"`, `"warning"`, `"error"`
- `logPath`: Where to write log files (supports `~` expansion)
- `logRotationSizeMB`: Max log file size before rotation
- `databasePath`: SQLite database location (supports `~` expansion)
- `refreshInterval`: Seconds between sync operations (future use)

### 4. Restart Claude Desktop

Close and reopen Claude Desktop to load the new MCP server configuration.

### 5. Verify Connection

In Claude Desktop, you should see Maestro tools available:

```
Tools available:
- maestro_list_spaces
- maestro_create_space
- maestro_list_tasks
- maestro_create_task
... (23 total tools)
```

## Troubleshooting

### Server Not Starting

**Check daemon installation:**

```bash
which maestrod
# Should output: /usr/local/bin/maestrod

maestrod --version
# Should output version information
```

**Check logs:**

```bash
tail -f ~/.maestro/logs/maestrod.log
```

**Common issues:**

1. **Permission denied** - Ensure maestrod is executable:
   ```bash
   chmod +x /usr/local/bin/maestrod
   ```

2. **Config file not found** - Verify `~/.maestro/config.json` exists and is valid JSON

3. **Database connection failed** - Check database path is writable:
   ```bash
   mkdir -p "~/Library/Application Support/Maestro"
   ```

### Tools Not Appearing

**Verify MCP configuration:**

```bash
cat ~/.config/claude/config.json
```

Ensure JSON is valid and maestro server is defined.

**Check Claude Desktop logs:**

On macOS, Claude Desktop logs are in:
```
~/Library/Logs/Claude/
```

Look for MCP connection errors.

### Tools Returning Errors

**Check database state:**

```bash
sqlite3 ~/Library/Application\ Support/Maestro/maestro.db ".tables"
```

Should show:
- documents
- linear_sync
- reminder_space_links
- spaces
- tasks

If tables are missing, delete the database and restart maestrod to run migrations:

```bash
rm ~/Library/Application\ Support/Maestro/maestro.db
# Restart Claude Desktop
```

## Advanced Configuration

### Custom Database Path

To use a different database location:

```json
{
  "databasePath": "/path/to/custom/maestro.db"
}
```

### Debug Logging

For troubleshooting, enable debug logging:

```json
{
  "logLevel": "debug"
}
```

This provides detailed logs of:
- MCP tool calls
- Database operations
- Sync operations
- Error details

### Multiple Workspaces

Currently, Maestro uses a single database. For multiple workspaces:

1. Create separate config files:
   ```
   ~/.maestro/work-config.json
   ~/.maestro/personal-config.json
   ```

2. Configure different MCP servers in Claude:
   ```json
   {
     "mcpServers": {
       "maestro-work": {
         "command": "/usr/local/bin/maestrod",
         "env": {
           "MAESTRO_CONFIG": "~/.maestro/work-config.json"
         }
       },
       "maestro-personal": {
         "command": "/usr/local/bin/maestrod",
         "env": {
           "MAESTRO_CONFIG": "~/.maestro/personal-config.json"
         }
       }
     }
   }
   ```

3. Use different database paths in each config

## Tool Reference

### Space Tools

#### maestro_list_spaces
Lists all spaces with optional filters.

**Parameters:**
- `includeArchived` (boolean, optional) - Include archived spaces
- `parentId` (string, optional) - Filter by parent space ID

**Returns:** Array of space objects

#### maestro_create_space
Creates a new space.

**Parameters:**
- `name` (string, required) - Space name
- `color` (string, required) - Hex color code (e.g., "#FF0000")
- `path` (string, optional) - Filesystem path
- `parentId` (string, optional) - Parent space ID
- `tags` (array, optional) - Array of tag strings

**Returns:** Created space object with UUID

### Task Tools

#### maestro_list_tasks
Lists tasks with optional filters.

**Parameters:**
- `spaceId` (string, optional) - Filter by space
- `status` (string, optional) - Filter by status: inbox, todo, inProgress, done, archived
- `includeArchived` (boolean, optional) - Include archived tasks

**Returns:** Array of task objects

#### maestro_create_task
Creates a new task.

**Parameters:**
- `spaceId` (string, required) - Space UUID
- `title` (string, required) - Task title
- `description` (string, optional) - Task description
- `status` (string, optional) - Initial status (default: inbox)
- `priority` (string, optional) - Priority: none, low, medium, high, urgent

**Returns:** Created task object with UUID

#### maestro_get_surfaced_tasks
Gets prioritized tasks using surfacing algorithm.

**Parameters:**
- `spaceId` (string, optional) - Filter by space
- `limit` (integer, optional) - Max tasks to return (default: 10)

**Returns:** Array of task objects ordered by priority

### Document Tools

#### maestro_create_document
Creates a new document.

**Parameters:**
- `spaceId` (string, required) - Space UUID
- `title` (string, required) - Document title
- `content` (string, optional) - Markdown content
- `path` (string, optional) - Virtual path within space

**Returns:** Created document object with UUID

#### maestro_update_document
Updates document content.

**Parameters:**
- `id` (string, required) - Document UUID
- `title` (string, optional) - New title
- `content` (string, optional) - New content

**Returns:** Updated document object

## Integration Examples

### Creating a Project Workflow

```javascript
// 1. Create a project space
const space = await maestro_create_space({
  name: "New Feature Development",
  color: "#4CAF50",
  path: "/Users/you/projects/new-feature",
  tags: ["active", "dev"]
});

// 2. Create tasks
const tasks = [
  {
    title: "Design database schema",
    priority: "high",
    status: "todo"
  },
  {
    title: "Implement API endpoints",
    priority: "high",
    status: "inbox"
  },
  {
    title: "Write unit tests",
    priority: "medium",
    status: "inbox"
  }
];

for (const taskData of tasks) {
  await maestro_create_task({
    spaceId: space.id,
    ...taskData
  });
}

// 3. Create project documentation
await maestro_create_document({
  spaceId: space.id,
  title: "Project Overview",
  content: `# New Feature Development\n\n## Goals\n- Design schema\n- Implement API\n- Test coverage\n`
});

// 4. Set as default document
await maestro_set_default_document({ id: document.id });
```

### Task Management

```javascript
// Get high-priority tasks
const surfaced = await maestro_get_surfaced_tasks({
  limit: 5
});

// Update task as you work
await maestro_update_task({
  id: surfaced[0].id,
  status: "inProgress"
});

// Complete task
await maestro_complete_task({
  id: surfaced[0].id
});
```

## Security Considerations

### Database Access

The SQLite database is stored in your user directory and is only accessible to your user account. No network access is required for basic operation.

### API Keys

When configuring Linear sync or other integrations, store API keys in environment variables rather than config files:

```json
{
  "mcpServers": {
    "maestro": {
      "command": "/usr/local/bin/maestrod",
      "env": {
        "LINEAR_API_KEY": "${LINEAR_API_KEY}"
      }
    }
  }
}
```

Then set in your shell profile:
```bash
export LINEAR_API_KEY="your-api-key-here"
```

### Log Files

Log files may contain sensitive information. Ensure log directory has appropriate permissions:

```bash
chmod 700 ~/.maestro/logs
```

## Support

For issues or questions:

1. Check logs: `~/.maestro/logs/maestrod.log`
2. Verify configuration: `~/.maestro/config.json`
3. Open an issue: https://github.com/yourusername/maestro/issues
