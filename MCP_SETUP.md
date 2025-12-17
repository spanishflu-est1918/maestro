# Maestro MCP Server Setup

## What is This?

Maestro provides an MCP (Model Context Protocol) server that exposes 23 tools for managing spaces, tasks, and documents. AI assistants like Claude can connect to this server to organize your work.

## Building the Server

```bash
# Build release version
swift build -c release

# The executable is at:
# .build/release/maestrod
```

## Testing the Server

### 1. Manual Test (Verify it starts)

```bash
# Start the server (it will wait for MCP protocol input on stdin)
.build/release/maestrod

# You should see:
# Maestro daemon starting...
# MCP server initialized

# Press Ctrl+C to stop
```

### 2. Configure for Claude Code

The server needs to be registered in Claude Code's MCP server configuration. There are a few ways to do this:

#### Option A: Project-level MCP Config (Recommended for testing)

Create `.claude/mcp_servers.json` in this project:

```json
{
  "mcpServers": {
    "maestro": {
      "command": "/Users/gorkolas/Documents/www/maestro/.build/release/maestrod",
      "env": {
        "MAESTRO_DB_PATH": "/Users/gorkolas/Documents/www/maestro/maestro.db"
      }
    }
  }
}
```

#### Option B: Global MCP Config

Add to `~/.config/claude/mcp_servers.json` (create if doesn't exist):

```json
{
  "mcpServers": {
    "maestro": {
      "command": "/Users/gorkolas/Documents/www/maestro/.build/release/maestrod",
      "env": {
        "MAESTRO_DB_PATH": "/Users/gorkolas/.maestro/maestro.db"
      }
    }
  }
}
```

### 3. Restart Claude Code

After adding the configuration, restart your Claude Code session for it to pick up the new MCP server.

### 4. Verify Tools Are Available

In a new Claude Code session, you should see maestro tools available:

- `maestro_list_spaces`
- `maestro_create_space`
- `maestro_get_space`
- `maestro_update_space`
- `maestro_archive_space`
- `maestro_delete_space`
- `maestro_list_tasks`
- `maestro_create_task`
- `maestro_get_task`
- `maestro_update_task`
- `maestro_complete_task`
- `maestro_archive_task`
- `maestro_delete_task`
- `maestro_get_surfaced_tasks`
- `maestro_list_documents`
- `maestro_create_document`
- `maestro_get_document`
- `maestro_update_document`
- `maestro_pin_document`
- `maestro_unpin_document`
- `maestro_delete_document`
- `maestro_get_default_document`
- `maestro_set_default_document`

## Testing the Tools

Once configured, you can test by asking Claude to use the tools:

```
"Create a space called 'My Project' with color #FF0000"
"List all spaces"
"Create a task in that space called 'Test task'"
"Get surfaced tasks"
```

## Database Location

The server uses SQLite and will create a database at:
- Custom path via `MAESTRO_DB_PATH` env var
- Default: `~/.maestro/maestro.db` (if we implement defaults)
- Test: `:memory:` for tests

## Troubleshooting

### Server doesn't start
- Check that the executable has been built: `ls -la .build/release/maestrod`
- Try running directly: `.build/release/maestrod` and check for errors

### Tools not appearing in Claude Code
- Verify the MCP config file exists and has correct JSON syntax
- Check the executable path in config is absolute and correct
- Restart Claude Code completely
- Check Claude Code logs for MCP connection errors

### Tools return errors
- Check that the database path is writable
- Run tests to verify functionality: `swift test`
- Check server stderr output for error messages

## Architecture

```
Claude Code
    ↓ (MCP protocol via stdio)
MCP Server (maestrod)
    ↓ (Swift SDK)
Tool Handlers (MCPTools+*.swift)
    ↓
Data Stores (SpaceStore, TaskStore, DocumentStore)
    ↓ (GRDB)
SQLite Database
```

## Development

To work on the MCP server:

1. Make changes to `Sources/Maestro/MCP*.swift` files
2. Write tests in `Tests/MaestroTests/MCPServerTests.swift`
3. Run tests: `swift test`
4. Rebuild: `swift build -c release`
5. Restart Claude Code to pick up changes

## Next Steps

- [ ] Add daemon mode (long-running background process)
- [ ] Add database path configuration
- [ ] Add logging configuration
- [ ] Test with Claude Code in practice
- [ ] Create install script
- [ ] Package as macOS app bundle
