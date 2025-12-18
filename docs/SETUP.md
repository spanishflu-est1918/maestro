# Maestro Setup Guide: MCP Server & Skill

Complete setup guide for Maestro across all Claude platforms.

**What Maestro provides:**
- **MCP Server** - 23 tools for task/space/document management
- **Maestro Skill** - Workflow guidance and best practices (Claude Code only)

## Prerequisites

- Maestro installed (menu bar app + daemon)
- Claude Code or Claude Desktop
- macOS 13.0 or later

---

## Choose Your Platform

Select the Claude platform you're using:

- **[Claude Code (CLI)](#claude-code-setup)** - Command-line tool with MCP + Skills support
- **[Claude Desktop](#claude-desktop-setup)** - Desktop app with local MCP support

---

## Claude Code Setup

### Automatic Setup (Recommended)

If you installed Maestro via the app, setup is **automatic**:

1. Launch Maestro.app (first time)
2. Click "Continue" in the setup wizard
3. Wait 30 seconds for configuration
4. Restart Claude Code

Setup automatically:
- ✅ Adds MCP server to `~/.mcp.json`
- ✅ Installs Maestro Skill to `~/.claude/skills/maestro/`
- ✅ Creates database and config files

**Skip to [Verification](#verification)** if you used automatic setup.

### Manual Setup

For advanced users or troubleshooting.

#### 1. Configure MCP Server

Edit `~/.mcp.json`:

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

#### 2. Install Maestro Skill

```bash
# Create skills directory
mkdir -p ~/.claude/skills

# Copy Maestro skill from app bundle
cp -R /Applications/Maestro.app/Contents/Resources/skills/maestro ~/.claude/skills/
```

#### 3. Restart Claude Code

Restart Claude Code to load the new configuration.

---

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

**Note:** Claude Desktop does not support Skills - only the MCP server tools will be available.

---

## Maestro Skill Installation

The Maestro Skill teaches Claude Code how to use Maestro effectively with workflow patterns and best practices.

### 1. Manual Installation

If automatic setup didn't work, install manually:

```bash
# Create skills directory
mkdir -p ~/.claude/skills

# Copy Maestro skill (from app bundle or repo)
cp -R /Applications/Maestro.app/Contents/Resources/skills/maestro ~/.claude/skills/

# Or from repository
cp -R plugin/skills/maestro ~/.claude/skills/
```

### 2. Verify Installation

Check that skill files are present:

```bash
ls -la ~/.claude/skills/maestro/
# Should show:
# - SKILL.md (main skill file)
# - REFERENCE.md (detailed docs)
# - LICENSE.txt
# - templates/ (task and space templates)
```

### 3. Skill Structure

The Maestro Skill provides:

- **SKILL.md** - Overview and when to use Maestro
- **REFERENCE.md** - Complete API reference, patterns, examples
- **templates/** - Pre-built templates for:
  - Task types (bug fix, feature, research, documentation, refactoring, testing, deployment)
  - Space patterns (project, area, team, sprint, client, research)

### 4. Using the Skill

Once installed, invoke with:

```
"How should I organize my tasks in Maestro?"
"What's the best way to track a bug fix?"
"Show me Maestro templates"
"Help me set up a new project space"
```

Claude Code will automatically reference the skill for Maestro-related questions.

## Verification

After setup (automatic or manual), verify both components are working:

### 1. Check MCP Server

In Claude Code, the MCP server should be connected:

```
"List my Maestro spaces"
"What MCP tools do you have for Maestro?"
```

You should see 23 available tools:
- `maestro_list_spaces`, `maestro_create_space`, ...
- `maestro_list_tasks`, `maestro_create_task`, ...
- `maestro_list_documents`, `maestro_create_document`, ...

### 2. Check Maestro Skill

Test skill knowledge:

```
"How do I use Maestro?"
"What are the Maestro task templates?"
"Explain the Maestro workflow"
```

Claude should provide detailed answers from the skill documentation.

### 3. Full Integration Test

Create a complete workflow:

```
"Create a Maestro space called 'Test Project' with color #22C55E"
"Create a task in Test Project: 'Sample task' with high priority"
"Show my top 10 surfaced tasks"
"What's the recommended workflow for feature development?"
```

All commands should work, combining MCP tools with skill guidance.

### 4. Menu Bar App

Check that the menu bar app is running:
- Look for Maestro icon in menu bar
- Click icon to see QuickView panel
- Status should show "All Clear" (green dot)

## Troubleshooting

### MCP Server Issues

#### Server Not Starting

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
- agent_activities
- agent_sessions
- documents
- linear_sync
- reminder_space_links
- spaces
- tasks

If tables are missing, delete the database and restart maestrod to run migrations:

```bash
rm ~/Library/Application\ Support/Maestro/maestro.db
# Restart Claude Code
```

### Maestro Skill Issues

#### Skill Not Loading

**Check installation:**

```bash
ls ~/.claude/skills/maestro/SKILL.md
# Should exist
```

If missing, reinstall:

```bash
# Launch Maestro.app and go through setup wizard again
# OR manually copy:
cp -R /Applications/Maestro.app/Contents/Resources/skills/maestro ~/.claude/skills/
```

**Restart Claude Code** after installation.

#### Claude Not Using Skill

If Claude doesn't seem to reference Maestro patterns:

1. **Explicitly invoke the skill:**
   ```
   "Use the Maestro skill to help me organize tasks"
   "According to Maestro documentation, how should I..."
   ```

2. **Check skill file format:**
   ```bash
   # SKILL.md should start with frontmatter:
   head -5 ~/.claude/skills/maestro/SKILL.md
   # Should show:
   # ---
   # name: maestro
   # description: ...
   # ---
   ```

3. **Verify Claude Code version:**
   - Skills require Claude Code with skills support
   - Update to latest version if needed

#### Skill Content Outdated

If skill documentation is outdated:

```bash
# Remove old version
rm -rf ~/.claude/skills/maestro

# Copy latest from Maestro.app
cp -R /Applications/Maestro.app/Contents/Resources/skills/maestro ~/.claude/skills/

# Restart Claude Code
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

---

## ChatGPT Setup (Experimental)

**Note:** ChatGPT support is experimental and requires manual skill recreation. The MCP server works, but workflow guidance requires custom setup.

### What Works

✅ **MCP Server** - ChatGPT has full MCP support (as of September 2025)
❌ **Maestro Skill** - No skills system; must recreate manually as Custom Instructions

### Setup Steps

#### 1. Configure MCP Server

ChatGPT uses the same MCP configuration as Claude Desktop:

Edit `~/.config/claude/config.json` (or ChatGPT's equivalent):

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

Restart ChatGPT to load the MCP server.

#### 2. Recreate Skills as Custom GPT (Manual)

Since ChatGPT doesn't have a skills system, you need to manually recreate Maestro's workflow guidance:

**Option A: Custom Instructions** (Global)

1. Open ChatGPT Settings → Personalization → Custom Instructions
2. In "What would you like ChatGPT to know about you?":
   ```
   I use Maestro for task and project management. It has a fractal space
   organization system (spaces can contain child spaces via parentId).
   Tasks have statuses (inbox, todo, inProgress, done) and priorities
   (urgent, high, medium, low, none). Tasks become stale after 3 days inactive.
   ```
3. In "How would you like ChatGPT to respond?":
   - Copy key concepts from `~/.claude/skills/maestro/REFERENCE.md`
   - Include workflow patterns from `SKILL.md`
   - Add common query patterns (see below)

**Option B: Custom GPT** (Recommended)

1. Create a new Custom GPT
2. Name it "Maestro Assistant"
3. Upload knowledge files:
   ```bash
   # Copy skill files to share with ChatGPT
   cp ~/.claude/skills/maestro/REFERENCE.md ~/Desktop/
   cp ~/.claude/skills/maestro/SKILL.md ~/Desktop/
   ```
4. Upload `REFERENCE.md` and `SKILL.md` as knowledge files
5. In Configuration → Instructions, add:
   ```
   You are a Maestro workflow assistant. Use the uploaded REFERENCE.md
   and SKILL.md to guide users on:
   - Organizing tasks across project spaces
   - Using the surfacing algorithm for priority
   - Understanding the fractal space system
   - Best practices for task management

   When users ask about Maestro tools, reference the uploaded documentation
   to explain concepts, patterns, and workflows.
   ```
6. Enable the Maestro MCP connector in the Custom GPT

#### 3. Map Skill Concepts to Custom Instructions

**Key mappings from Maestro Skill to ChatGPT:**

| Maestro Skill Concept | ChatGPT Implementation |
|----------------------|------------------------|
| SKILL.md frontmatter | Custom GPT name/description |
| REFERENCE.md content | Upload as knowledge file |
| Template files | Paste into Custom Instructions |
| Context-aware synthesis | Explain in Instructions: "Synthesize task state across spaces" |
| Surfacing patterns | Include surfacing algorithm explanation |
| Fractal organization | Define in Instructions: "Spaces nest infinitely via parentId" |

**Example Custom Instructions snippet:**

```
When asked "What should I work on?":
1. Query surfaced tasks with maestro_get_surfaced_tasks
2. Check menu bar state with maestro_get_status
3. Synthesize by priority: overdue (urgent) > high priority > stale items
4. Present context-aware recommendations

When organizing work:
- Use fractal spaces: Areas → Projects → Features → Tasks
- Create parent space first, then children with parentId
- Filter tasks by spaceId to stay context-aware
- Check staleness: tasks >3 days in "inProgress" need attention
```

### Limitations

**No automatic skill loading:**
- You must manually maintain Custom Instructions
- Updates to skill files require re-uploading to Custom GPT
- No version sync with Maestro app

**Custom GPT vs Global:**
- Custom GPT: Isolated, can upload files, project-specific
- Custom Instructions: Global, shorter, no file uploads

**Workflow guidance:**
- Less sophisticated than Claude Code skills
- Requires explicit prompting ("Use Maestro patterns to...")
- May not automatically apply context-aware synthesis

### Verification

Test the setup:

```
"List my Maestro spaces"
→ Should use maestro_list_spaces tool

"According to Maestro documentation, how should I organize a project?"
→ Should reference uploaded skill files

"What should I work on?"
→ Should query surfaced tasks and synthesize with workflow patterns
```

### Maintenance

When Maestro skill files are updated:

1. Copy updated files from `~/.claude/skills/maestro/`
2. Re-upload to Custom GPT knowledge base
3. Update Custom Instructions if patterns changed

---

## Support

For issues or questions:

1. Check logs: `~/.maestro/logs/maestrod.log`
2. Verify configuration: `~/.maestro/config.json`
3. Open an issue: https://github.com/yourusername/maestro/issues
