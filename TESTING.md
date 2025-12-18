# Maestro Local Testing Guide

Complete step-by-step guide to test Maestro before distribution.

## Prerequisites

- macOS 13.0+
- Xcode 15.2+
- Claude Code installed
- Clean test environment (no existing Maestro installation)

## Phase 1: Build the macOS App

### Step 1: Build in Xcode

```bash
# Open project in Xcode
open Package.swift
```

**In Xcode:**
1. Select the Maestro scheme
2. Build: Product → Build (⌘B)
3. Check for warnings/errors - **must be zero**

**Or build via command line:**

```bash
# Build release version
xcodebuild -scheme Maestro \
           -configuration Release \
           -derivedDataPath build/DerivedData \
           build
```

### Step 2: Add Skill Copy Build Phase

**Critical**: The Skill files must be bundled in the app.

**In Xcode:**
1. Select Maestro target
2. Build Phases tab
3. Click + → New Run Script Phase
4. Drag it to run BEFORE "Copy Files"
5. Add script:
   ```bash
   ${SRCROOT}/Scripts/copy-skill-to-bundle.sh
   ```
6. Rebuild (⌘B)

### Step 3: Verify Skill Files Bundled

```bash
# Check built app contains skills
ls -la build/DerivedData/Build/Products/Release/Maestro.app/Contents/Resources/skills/maestro/

# Should see:
# SKILL.md
# TASK_MANAGEMENT.md
# SPACE_ORGANIZATION.md
# LINEAR_WORKFLOW.md
# AGENT_MONITORING.md
# templates/
```

If files are missing, the build phase didn't run. Go back to Step 2.

### Step 4: Copy App to Applications

```bash
# Copy to test location
cp -R build/DerivedData/Build/Products/Release/Maestro.app /Applications/

# Verify
ls -la /Applications/Maestro.app
```

## Phase 2: Test the macOS App

### Step 1: First Launch (Right-Click → Open)

**For unsigned apps:**
```bash
# Remove quarantine attribute
xattr -d com.apple.quarantine /Applications/Maestro.app

# Then open
open /Applications/Maestro.app
```

**Or**: Right-click → Open → Click "Open"

### Step 2: Test First-Run Wizard

**Expected behavior:**

1. **Welcome Dialog Appears**:
   ```
   ┌─────────────────────────────────────┐
   │   Welcome to Maestro!               │
   │                                     │
   │   Setup will:                       │
   │   • Configure Claude Code (MCP)     │
   │   • Install Maestro Skill           │
   │   • Set up menu bar                 │
   │                                     │
   │   Takes ~30 seconds.                │
   │                                     │
   │        [Continue]  [Skip Setup]     │
   └─────────────────────────────────────┘
   ```

2. **Click "Continue"**

3. **Setup Happens** (watch Console.app for logs):
   - ✅ MCP server configured
   - ✅ Skill installed
   - ✅ Database created

4. **Success Dialog**:
   ```
   ┌─────────────────────────────────────┐
   │   Setup Complete!                   │
   │                                     │
   │   ✅ MCP server configured           │
   │   ✅ Maestro Skill installed         │
   │   ✅ Menu bar active                 │
   │                                     │
   │   Next steps:                       │
   │   1. Restart Claude Code            │
   │   2. Try: "How do I use Maestro?"   │
   │                                     │
   │        [Get Started]                │
   └─────────────────────────────────────┘
   ```

### Step 3: Verify Auto-Configuration

**Check MCP server config:**
```bash
cat ~/.mcp.json

# Should contain:
# {
#   "mcpServers": {
#     "maestro": {
#       "command": "/Applications/Maestro.app/Contents/MacOS/Maestro",
#       "args": ["--mcp"],
#       "env": {}
#     }
#   }
# }
```

**Check Skill installation:**
```bash
ls -la ~/.claude/skills/maestro/

# Should contain:
# SKILL.md
# TASK_MANAGEMENT.md
# SPACE_ORGANIZATION.md
# LINEAR_WORKFLOW.md
# AGENT_MONITORING.md
# templates/
```

**Check database creation:**
```bash
ls -la ~/Library/Application\ Support/Maestro/

# Should contain:
# maestro.db
```

### Step 4: Test Menu Bar

**Expected behavior:**

1. **Icon appears in menu bar** (green checklist)
2. **Click icon** → Popover shows
3. **Popover displays**:
   - "Status" section
   - Status summary (e.g., "All clear ✓" or task counts)
   - Color matches state

**Test state changes:**
```bash
# Open Console.app and filter for "Maestro"
# Should see logs every 30 seconds:
# "Menu bar state updated: clear, badge: 0"
```

### Step 5: Test Reset First-Run

```bash
# Reset first-run flag
defaults delete com.maestro.app HasLaunchedBefore

# Kill and relaunch
killall Maestro
open /Applications/Maestro.app

# Welcome wizard should appear again
```

## Phase 3: Test Claude Code Integration

### Step 1: Restart Claude Code

```bash
# Quit Claude Code completely
# Then relaunch
```

### Step 2: Verify MCP Server Loads

**In Claude Code**, check for Maestro tools:

```
"List all available tools"
```

Should see 23 maestro_* tools:
- maestro_list_spaces
- maestro_create_task
- maestro_get_surfaced_tasks
- etc.

### Step 3: Test Basic Tool Usage

**Create a space:**
```
"Create a Maestro space called 'Test Project' with color #3B82F6"
```

Expected: Uses `maestro_create_space` tool successfully.

**Create a task:**
```
"Create a task in Test Project called 'Test task' with high priority"
```

Expected: Uses `maestro_create_task` tool successfully.

**Get surfaced tasks:**
```
"Show me my top 10 surfaced tasks in Maestro"
```

Expected: Uses `maestro_get_surfaced_tasks` and shows the test task.

### Step 4: Test Skill Activation

**Ask workflow questions:**
```
"How should I organize tasks in Maestro?"
```

Expected: Claude uses the Maestro Skill to provide detailed guidance from SKILL.md.

```
"Show me Maestro task management patterns"
```

Expected: Claude references TASK_MANAGEMENT.md.

```
"What are the Linear integration workflows?"
```

Expected: Claude references LINEAR_WORKFLOW.md.

### Step 5: Test Menu Bar Updates

**Create overdue task:**
```
"Create a task with due date yesterday"
```

**Wait 30 seconds**, then:
- Menu bar icon should turn red (urgent)
- Badge should show "1"
- Popover should show "1 overdue"

**Complete the task:**
```
"Complete that overdue task"
```

**Wait 30 seconds**, then:
- Menu bar should turn green (clear)
- Badge should disappear
- Popover should show "All clear ✓"

## Phase 4: Test Plugin Installation (Optional for Now)

### Step 1: Test Local Plugin

```bash
# In Claude Code
/plugin marketplace add /Users/gorkolas/Documents/www/maestro/plugin
/plugin install maestro@.
```

### Step 2: Test Slash Commands

```
/status
```

Expected: Shows menu bar state + top 10 surfaced tasks.

```
/create-task
```

Expected: Guides you through task creation.

```
/setup-space
```

Expected: Helps set up a project structure.

### Step 3: Uninstall Plugin

```
/plugin uninstall maestro@.
```

This tests that manual MCP config still works even without plugin.

## Phase 5: Test All 23 MCP Tools

### Spaces (6 tools)

```bash
# Create
"Create space 'Backend' with color #EF4444"

# List
"List all my Maestro spaces"

# Get
"Get details of the Backend space"

# Update
"Update Backend space color to #22C55E"

# Archive
"Archive the Backend space"

# Delete (test on non-important space)
"Delete the Backend space"
```

### Tasks (8 tools)

```bash
# Create
"Create task 'Implement auth' in Test Project"

# List
"List all tasks in Test Project"

# Get
"Get details of the auth task"

# Update
"Update auth task priority to urgent"

# Complete
"Mark auth task as complete"

# Get surfaced
"Get top 5 surfaced tasks"

# Archive
"Archive the completed task"

# Delete
"Delete the archived task"
```

### Documents (9 tools)

```bash
# Create
"Create document 'README' in Test Project with content 'Hello'"

# List
"List all documents in Test Project"

# Get
"Get README document"

# Update
"Update README content to 'Hello World'"

# Pin
"Pin the README document"

# Unpin
"Unpin the README document"

# Set default
"Set README as default document for Test Project"

# Get default
"Get default document for Test Project"

# Delete
"Delete README document"
```

### Agent Monitoring (7 tools)

```bash
# Start session
"Start a Maestro agent session for claude-code"

# Log activity
"Log a tool_call activity for that session: Created test task"

# List sessions
"List all agent sessions"

# Get session
"Get details of the claude-code session"

# List activities
"List activities for that session"

# Get metrics
"Get agent metrics"

# End session
"End the agent session with outcome completed"
```

### Status (1 tool)

```bash
"Get Maestro status"
```

Expected: Returns JSON with menu bar state, counts, Linear metrics.

## Phase 6: Performance Testing

### Test Surfacing Speed

```bash
# Create many tasks
"Create 100 tasks with various priorities and due dates"

# Then measure
"Get surfaced tasks"
```

Check Console.app logs for calculation time. Should be < 10ms (target is ~0.16ms).

### Test Menu Bar Refresh

Watch Console.app:
- Should see "Menu bar state updated" every 30 seconds
- No memory leaks (check Activity Monitor)
- CPU usage < 1% when idle

## Phase 7: Run Automated Tests

```bash
# Run all 186 tests
swift test

# Expected output:
# Test Suite 'All tests' passed
# Executed 186 tests, with 0 failures
```

If any tests fail, fix before releasing.

## Common Issues & Fixes

### Issue: Welcome wizard doesn't appear

**Fix:**
```bash
defaults delete com.maestro.app HasLaunchedBefore
killall Maestro
open /Applications/Maestro.app
```

### Issue: MCP server not found in Claude Code

**Check:**
```bash
# Verify server is running
ps aux | grep Maestro

# Check .mcp.json
cat ~/.mcp.json

# Check app location
ls /Applications/Maestro.app/Contents/MacOS/Maestro
```

**Fix:**
```bash
# Rerun first-time setup
defaults delete com.maestro.app HasLaunchedBefore
open /Applications/Maestro.app
```

### Issue: Skill not loading

**Check:**
```bash
# Verify skill files exist
ls ~/.claude/skills/maestro/SKILL.md

# Check YAML frontmatter
head -5 ~/.claude/skills/maestro/SKILL.md
```

**Fix:**
```bash
# Manually copy skills
cp -r .claude/skills/maestro ~/.claude/skills/

# Restart Claude Code
```

### Issue: Menu bar icon not appearing

**Check Console.app** for errors:
```
# Filter by "Maestro"
# Look for errors in:
# - Database connection
# - Menu bar initialization
```

**Fix:**
```bash
# Reset database
rm -rf ~/Library/Application\ Support/Maestro/
open /Applications/Maestro.app
```

### Issue: Tests failing

**Fix:**
```bash
# Clean build
swift package clean
swift package resolve
swift test
```

## Success Criteria

Before releasing, ALL of these must pass:

**Build:**
- [ ] Zero compiler warnings
- [ ] Zero compiler errors
- [ ] Skill files bundled in app
- [ ] All 186 tests pass

**App:**
- [ ] First-run wizard appears
- [ ] MCP auto-config works (creates ~/.mcp.json)
- [ ] Skill auto-install works (creates ~/.claude/skills/maestro/)
- [ ] Database creates (~/Library/Application Support/Maestro/maestro.db)
- [ ] Menu bar icon appears
- [ ] Menu bar updates every 30 seconds
- [ ] Popover shows status

**Claude Code:**
- [ ] All 23 maestro_* tools available
- [ ] Tools work correctly (test each one)
- [ ] Skill activates on relevant questions
- [ ] Skill provides accurate guidance
- [ ] Menu bar responds to task changes (< 30s)

**Plugin (optional):**
- [ ] Local installation works
- [ ] Slash commands work
- [ ] MCP server connects

**Performance:**
- [ ] Surfacing < 10ms (target ~0.16ms)
- [ ] Menu bar refresh every 30s
- [ ] Memory < 50MB
- [ ] CPU < 1% idle

## Next Steps After Testing

Once all tests pass:

1. **Tag release**: `git tag v1.0.0`
2. **Build final version**: Follow BUILD.md
3. **Create distributable ZIP**
4. **Upload to GitHub Releases**
5. **Announce on social media**

See BUILD.md and RELEASE_PLAN.md for distribution steps.
