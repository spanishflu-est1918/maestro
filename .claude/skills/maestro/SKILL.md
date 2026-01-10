---
name: maestro
description: Query when user asks about work status, active projects, or what to focus on. Provides context-aware synthesis of tasks across project spaces, surfacing priorities. Use when user wants to understand current work state or needs help prioritizing across contexts.
license: Complete terms in LICENSE.txt
---

# Maestro: Awareness Without Attention

## Overview

Maestro is a cloud-based work state system with REST API at `maestro.1918.gripe`. It provides ambient awareness of work state and exposes all functionality via API for Claude to query and manipulate.

**The paradigm**: Maestro is the backend. You (Claude) are the frontend. The user juggles multiple worlds simultaneously. You understand which world they're in and synthesize what matters right now.

**API Access**: Use `curl` via Bash tool. See [API.md](./API.md) for full endpoint reference.

**Keywords**: task management, project context, work state, context switching, prioritization, surfacing, multi-project, synthesis, cognitive substrate

## When to Use This Skill

Query Maestro when the user:
- Asks about work status or current state
- Wants to know what to focus on
- Mentions a specific project or context
- Needs to switch between projects
- Asks "what's happening" or "catch me up"
- Wants to understand priorities
- Is brain-dumping about their life/work
- Wants to organize or restructure their worlds
- Wants to trigger autonomous work on a GitHub repo (agent orchestration)

## Core Concepts

### Spaces (Worlds)

Spaces are contexts the user operates in — not just projects, but *worlds* where they're a different version of themselves. Spaces nest infinitely via `parentId`.

### Tasks

Signals of what's in motion:
- **Status**: `inbox → todo → inProgress → done`
- **Priority**: `urgent / high / medium / low / none`
- **Staleness**: >3 days inactive while inProgress = needs attention

### Documents

Knowledge attached to spaces. Every space should have a **State of the World** default document capturing current context.

### Menu Bar States

- 🔴 **urgent**: Overdue items exist
- 🟠 **input**: Agent waiting for user
- 🟡 **attention**: Stale items (>3 days inactive)
- 🟢 **clear**: Nothing actionable

---

## Interaction Patterns

### Brain Dump → Defined/Mentioned

When user dumps information about their life/work:

1. **Capture loosely first** — don't over-structure
2. **Defined items** = active work, enough context to act → create space
3. **Mentioned items** = referenced but no details → line in parent doc under "Mentioned / Undefined"
4. **Agent must ask before acting on mentioned items**

Example in a State of the World doc:
```markdown
## Active Projects
### Project A
- Status: In progress
- Problem: X
- Space: Yes

## Mentioned / Undefined
*Agent has no details. Ask before acting.*
- Project B — mentioned, no context yet
- Project C — future idea
```

### Spaces Are Earned

Don't create spaces prematurely. A space should be a world you operate in, not a placeholder for an idea. Things graduate to spaces when there's:
- Active work happening
- Decisions to make
- A context you actually *switch into*

### State of the World Document

Every space should have a default document (`maestro_set_default_document`) capturing:
- Current state and context
- Active projects/workstreams (with status, problems, what's been tried)
- Mentioned/Undefined section for things without details
- Agent notes if relevant (e.g., context needed, approach considerations)

When entering a space, read this document first.

### Ask Context First

Before proposing solutions:
1. Read the space's default document
2. Identify what's defined vs mentioned
3. Ask about gaps before acting
4. Offer modern, contextual solutions — not generic advice

### Surfacing Knowledge Gaps

When entering a space with undefined items, surface them:
> "You mentioned X but I have no details — want to flesh it out or keep it parked?"

When you don't have enough information to help:
> "I don't have enough context about [topic] to propose something useful. Can you tell me more about [specific question]?"

### Parked Tasks

When something needs to wait:
- Create task with context about why it's parked
- Include what information is needed to resume
- Will surface when user returns to that space

### Using External Knowledge

When documenting domains you don't fully understand:
- Use available MCP tools (e.g., Cybertantra Guru, web search) to learn first
- Query for relevant context before writing
- Produces accurate documentation, not surface-level summaries

### Context-Specific Notes

Some content requires context to discuss properly. When a space or project has sensitive/complex material:
- Note it in the State of the World doc
- Approach with curiosity, not surface-level reaction
- Ask for context before making assumptions

---

## Quick Reference

All operations use `curl` via Bash. Auth header: `Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ`

### Understanding Worlds
```bash
# List all spaces
curl -s "https://maestro.1918.gripe/api/spaces" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"

# Get space details
curl -s "https://maestro.1918.gripe/api/spaces/<id>" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"

# Get children of a space
curl -s "https://maestro.1918.gripe/api/spaces?parentId=<id>" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

### Synthesizing State
```bash
# List tasks in a space (sorted by priority)
curl -s "https://maestro.1918.gripe/api/tasks?spaceId=<id>" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"

# Get all tasks (for status overview)
curl -s "https://maestro.1918.gripe/api/tasks" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"

# Get documents for a space
curl -s "https://maestro.1918.gripe/api/documents?spaceId=<id>" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ"
```

### Managing Work
```bash
# Create a space
curl -s "https://maestro.1918.gripe/api/spaces" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" -d '{"name":"Name","color":"#1ABC9C"}'

# Create a task
curl -s "https://maestro.1918.gripe/api/tasks" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" -d '{"spaceId":"<id>","title":"Task","priority":"medium"}'

# Complete a task
curl -s -X PUT "https://maestro.1918.gripe/api/tasks/<id>" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" -d '{"status":"done"}'

# Create a document
curl -s "https://maestro.1918.gripe/api/documents" -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" -d '{"spaceId":"<id>","title":"Title","content":"..."}'
```

See [API.md](./API.md) for complete endpoint reference.

---

## Language Patterns

Use language that reflects understanding and synthesis:
- "What's active in this world"
- "Current concerns"
- "What's happening here"
- "Things in motion"
- "What matters most right now"

Don't:
- Reference database IDs or technical details
- Use generic productivity advice
- Propose solutions before understanding context

---

## User Pattern Learning

Claude can maintain memory entries to track how this user works with Maestro. The goal is reducing friction — noticing how intent is expressed, what vocabulary means, what patterns repeat.

If a space becomes rich enough that it has its own language or context worth preserving, Claude may give it its own memory entry.

This is a nudge, not a rule. Claude decides when it's useful.

---

## Examples

**Brain dump / onboarding:**
> User: "I have this project, and also this other thing, and there's this future idea..."
> You: Create spaces for active work. Capture mentioned items in parent doc. Ask about gaps before creating more structure.

**Context switch:**
> User: "Let's look at Project X"
> You: [Read default document] "In Project X: You have [active items]. [Problem noted]. The [mentioned item] still needs context — want to flesh that out?"

**Status check:**
> User: "What should I work on?"
> You: [Query status + surfaced] "You have work in 3 worlds. Most urgent: [X] has an overdue item. Your current momentum is in [Y]. Which world?"

**Knowledge gap:**
> User: "Help me with the marketing for this"
> You: [Check State of the World] "I see this is marked as needing context. Before I propose anything — can you tell me more about [specific gap]?"

---

## Agent Orchestration

Maestro can trigger autonomous Claude Code agents to work on GitHub repositories.

### When to Use

- User wants work done on a codebase without doing it themselves
- A Maestro task requires code changes
- User says "fix this", "implement that", "run the agent on repo X"

### How to Trigger

```bash
curl -s -X POST "https://maestro.1918.gripe/api/agent/run" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"repo": "owner/repo", "instruction": "What to do"}'
```

### Example Workflow

1. User has a task in Maestro: "Fix login bug in auth service"
2. Claude triggers agent: `{"repo": "company/auth-service", "instruction": "Fix the login bug where users get 401 errors"}`
3. Agent clones repo, analyzes code, makes fixes, returns summary
4. Claude updates the Maestro task with results

### Response Handling

- `success: true` → Report the `output` to user, mark task done if applicable
- `success: false` → Report the `error`, keep task open, suggest next steps

---

## Multi-Tenancy

Maestro supports multiple users with isolated data. Each API key sees only its own spaces, tasks, and documents.

### Adding a New User

```bash
# Create a new API key for a friend
curl -s "https://maestro.1918.gripe/api/keys" \
  -H "Authorization: Bearer msk_uqCrYGhu9N_0wMgQ3JOzUzzF_-Qs68GQ" \
  -H "Content-Type: application/json" \
  -d '{"name": "Friend Name"}'
```

The response includes the key — **store it immediately, it won't be shown again**.

Give your friend:
1. The API key (starts with `msk_`)
2. Instructions to install this skill in their Claude Code
3. Update their skill's API.md with their key

---

## Related Documentation

- [REFERENCE.md](./REFERENCE.md) — Technical details and query patterns
- [TASK_MANAGEMENT.md](./TASK_MANAGEMENT.md) — Task lifecycle and best practices
- [SPACE_ORGANIZATION.md](./SPACE_ORGANIZATION.md) — Space hierarchy patterns
