# Maestro Cloud API Reference

## Connection Details

**Base URL:** `https://maestro.1918.gripe`
**Auth:** Bearer token in Authorization header

```bash
# API Key (stored securely)
MAESTRO_API_KEY="msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

## How to Call the API

Use `curl` via Bash for all API operations:

```bash
curl -s "https://maestro.1918.gripe/api/ENDPOINT" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

---

## Endpoints

### Spaces

**List all spaces:**
```bash
curl -s "https://maestro.1918.gripe/api/spaces" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

Query params:
- `includeArchived=true` - Include archived spaces
- `parentId=<uuid>` - Filter by parent
- `parentId=null` - Only root spaces

**Get a space:**
```bash
curl -s "https://maestro.1918.gripe/api/spaces/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

**Create a space:**
```bash
curl -s "https://maestro.1918.gripe/api/spaces" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"name": "Space Name", "color": "#1ABC9C", "parentId": null, "tags": []}'
```

**Update a space:**
```bash
curl -s -X PUT "https://maestro.1918.gripe/api/spaces/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"name": "New Name"}'
```

**Delete a space:**
```bash
curl -s -X DELETE "https://maestro.1918.gripe/api/spaces/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

---

### Tasks

**List tasks:**
```bash
curl -s "https://maestro.1918.gripe/api/tasks" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

Query params:
- `spaceId=<uuid>` - Filter by space
- `status=inbox|todo|inProgress|done|archived`
- `priority=none|low|medium|high|urgent`
- `excludeArchived=false` - Include archived (default: true)

**Get a task:**
```bash
curl -s "https://maestro.1918.gripe/api/tasks/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

**Create a task:**
```bash
curl -s "https://maestro.1918.gripe/api/tasks" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"spaceId": "<uuid>", "title": "Task title", "status": "todo", "priority": "medium"}'
```

Fields:
- `spaceId` (required)
- `title` (required)
- `description`
- `status`: inbox, todo, inProgress, done, archived
- `priority`: none, low, medium, high, urgent
- `dueDate`: ISO date string

**Update a task:**
```bash
curl -s -X PUT "https://maestro.1918.gripe/api/tasks/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"status": "done"}'
```

**Delete a task:**
```bash
curl -s -X DELETE "https://maestro.1918.gripe/api/tasks/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

---

### Documents

**List documents:**
```bash
curl -s "https://maestro.1918.gripe/api/documents" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

Query params:
- `spaceId=<uuid>` - Filter by space
- `path=/folder/` - Filter by path prefix
- `pinnedOnly=true` - Only pinned docs

**Get a document:**
```bash
curl -s "https://maestro.1918.gripe/api/documents/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

**Create a document:**
```bash
curl -s "https://maestro.1918.gripe/api/documents" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"spaceId": "<uuid>", "title": "Doc Title", "content": "Content here"}'
```

Fields:
- `spaceId` (required)
- `title` (required if no content)
- `content`
- `path`: defaults to "/"
- `isDefault`: boolean
- `isPinned`: boolean

**Update a document:**
```bash
curl -s -X PUT "https://maestro.1918.gripe/api/documents/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"content": "Updated content"}'
```

**Delete a document:**
```bash
curl -s -X DELETE "https://maestro.1918.gripe/api/documents/<id>" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

---

## MCP Tool Mapping

Old MCP tool → New API call:

| MCP Tool | API Call |
|----------|----------|
| `maestro_list_spaces()` | GET /api/spaces |
| `maestro_get_space(id)` | GET /api/spaces/:id |
| `maestro_create_space(...)` | POST /api/spaces |
| `maestro_list_tasks(spaceId)` | GET /api/tasks?spaceId=X |
| `maestro_get_task(id)` | GET /api/tasks/:id |
| `maestro_create_task(...)` | POST /api/tasks |
| `maestro_complete_task(id)` | PUT /api/tasks/:id `{"status":"done"}` |
| `maestro_archive_task(id)` | PUT /api/tasks/:id `{"status":"archived"}` |
| `maestro_list_documents(spaceId)` | GET /api/documents?spaceId=X |
| `maestro_get_document(id)` | GET /api/documents/:id |
| `maestro_create_document(...)` | POST /api/documents |
| `maestro_set_default_document(id)` | PUT /api/documents/:id `{"isDefault":true}` |
| `maestro_get_default_document(spaceId)` | GET /api/documents?spaceId=X then filter isDefault |

---

## Status/Surfacing

The old `maestro_get_status()` and `maestro_get_surfaced_tasks()` need to be computed client-side:

**Get status:**
1. Fetch all tasks: `GET /api/tasks`
2. Calculate:
   - Overdue: tasks with `dueDate < now` and status not done/archived
   - Stale: tasks with `inProgress` status and `updatedAt` > 3 days ago
   - Menu state: urgent (overdue) > attention (stale) > clear

**Get surfaced tasks:**
1. Fetch tasks for space: `GET /api/tasks?spaceId=X`
2. Sort by: overdue first, then priority, then recent activity
3. Return top N

---

---

### Agent Orchestration

**Run Claude Code in a sandbox:**

Triggers an autonomous Claude Code agent to work on a GitHub repository. The agent runs in an isolated E2B sandbox with full Claude Code capabilities.

```bash
curl -s -X POST "https://maestro.1918.gripe/api/agent/run" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{
    "repo": "owner/repo-name",
    "instruction": "Your task instruction here"
  }'
```

**Request fields:**
- `repo` (required): GitHub repository in `owner/repo` format
- `instruction` (required): Natural language instruction for Claude Code
- `taskId` (optional): Maestro task ID to associate with this run

**Response:**
```json
{
  "success": true,
  "output": "Claude Code's response and work summary",
  "sessionId": "e2b-session-id"
}
```

**Error response:**
```json
{
  "success": false,
  "error": "Error description"
}
```

**Notes:**
- Supports both public and private repositories (uses configured GitHub token)
- Agent has full Claude Code capabilities including file editing, bash, etc.
- Timeout: 8 minutes for Claude Code execution
- Uses `--dangerously-skip-permissions` for non-interactive execution

**Example: Fix a bug**
```bash
curl -s -X POST "https://maestro.1918.gripe/api/agent/run" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{
    "repo": "spanishflu-est1918/my-project",
    "instruction": "Fix the TypeScript error in src/utils.ts"
  }'
```

---

## Example: Full Status Check

```bash
# Get all active tasks
curl -s "https://maestro.1918.gripe/api/tasks" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" | jq '
  . as $tasks |
  {
    total: ($tasks | length),
    by_status: ($tasks | group_by(.status) | map({(.[0].status): length}) | add),
    overdue: [$tasks[] | select(.dueDate != null and .dueDate < now and .status != "done" and .status != "archived")],
    in_progress: [$tasks[] | select(.status == "inProgress")]
  }
'
```
