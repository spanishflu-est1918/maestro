---
name: maestro
description: Query when user asks about work status, active projects, or what to focus on. Provides context-aware synthesis of tasks across project spaces, surfacing priorities. Use when user wants to understand current work state or needs help prioritizing across contexts.
license: Complete terms in LICENSE.txt
---

# Maestro: Awareness Without Attention

## Overview

Maestro is a native macOS headless daemon with MCP server integration. It provides ambient awareness of work state through a menu bar interface and exposes all functionality via MCP tools for Claude to query and manipulate.

**The paradigm**: Maestro is the backend. You (Claude) are the frontend. The user juggles multiple worlds simultaneously. You understand which world they're in and synthesize what matters right now.

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

### Understanding Worlds
- `maestro_list_spaces()` — See all spaces
- `maestro_get_space(id)` — Space details
- `maestro_list_spaces(parentId)` — Get children of a space

### Synthesizing State
- `maestro_get_status()` — Health across all worlds (menu bar state)
- `maestro_get_surfaced_tasks(spaceId, limit)` — Most important items
- `maestro_list_tasks(spaceId, status)` — All tasks in a space
- `maestro_get_default_document(spaceId)` — Read State of the World

### Managing Work
- `maestro_create_space(name, color, parentId?, tags?)` — Create a world
- `maestro_create_task(spaceId, title, description?, priority?, status?)` — Create work item
- `maestro_create_document(spaceId, title, content)` — Create knowledge
- `maestro_set_default_document(id)` — Set State of the World doc
- `maestro_complete_task(id)` — Mark done
- `maestro_archive_task(id)` — Archive completed work

### Agent Activity
- `maestro_start_agent_session(agentName)` — Begin tracking
- `maestro_log_agent_activity(sessionId, activityType, resourceType, ...)` — Log events
- `maestro_end_agent_session(sessionId)` — End tracking

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

## Troubleshooting

**"Server not available" error**: If Maestro MCP tools return this error, Claude Code needs to be restarted. The daemon may have been updated or crashed. Tell the user: "Maestro server isn't responding — try restarting Claude Code (`/exit` then relaunch)."

---

## Related Documentation

- [REFERENCE.md](./REFERENCE.md) — Technical details and query patterns
- [TASK_MANAGEMENT.md](./TASK_MANAGEMENT.md) — Task lifecycle and best practices
- [SPACE_ORGANIZATION.md](./SPACE_ORGANIZATION.md) — Space hierarchy patterns
- [LINEAR_WORKFLOW.md](./LINEAR_WORKFLOW.md) — Linear integration
- [AGENT_MONITORING.md](./AGENT_MONITORING.md) — Agent session tracking
