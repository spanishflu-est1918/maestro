# Maestro Technical Reference

This document provides comprehensive technical details, query patterns, and best practices for using Maestro effectively.

## Table of Contents

- [Understanding Worlds](#understanding-worlds)
- [Data Model](#data-model)
- [Synthesis Patterns](#synthesis-patterns)
- [Technical Reference](#technical-reference)
- [Conversation Examples](#conversation-examples)
- [Best Practices](#best-practices)

---

## Understanding Worlds

### The Relationship

```
User defines worlds (contexts they operate in)
    ↓
Maestro stores state (what's happening in each)
    ↓
You query and synthesize (interpret for the user)
    ↓
User asks questions → You answer using Maestro as your knowledge base
```

### World Details

Each world has:
- **Active concerns** (tasks currently in motion)
- **Stale items** (things that haven't been touched in 3+ days)
- **Documents** (notes, specs, knowledge)
- **State of the World doc** (default document with current context)
- **Priority signals** (due dates, urgency markers)
- **Team coordination** (Linear integration if used)

### World Switching Rules

When the user says:
- "I'm working on X now"
- "Let's switch to Y"
- "What's happening with Z?"

**You filter to that world.** Query only that space. Synthesize only what's relevant there.

World-aware synthesis provides signal. Focus on the active world.

### World-Aware Response Flow

1. **If user mentions a project name** → Automatically filter to that space
2. **If ambiguous** → Ask "Which world?"
3. **If talking about work generally** → Synthesize across all worlds
4. **Keep worlds separate** → Only combine when explicitly asked to compare

---

## Data Model

### Spaces (Fractal Organization)

**Core Concept:** Spaces nest infinitely via `parentId`. Each space can contain child spaces, creating fractal organization - the same patterns repeat at every scale.

**Why Fractal?**
- Areas contain Projects
- Projects contain Features
- Features contain Tasks
- Same organizational structure at every level

**Common Patterns:**

```
Company
├── Engineering (Team)
│   ├── Backend Platform (Project)
│   │   ├── Auth Service (Feature)
│   │   └── API Gateway (Feature)
│   └── Frontend (Project)
│       ├── Dashboard (Feature)
│       └── Mobile App (Feature)
└── Product (Team)
    └── User Research (Project)
```

Or:

```
Life
├── Work
│   ├── Client A
│   │   └── Project X
│   └── Client B
└── Personal
    ├── Health
    └── Learning
```

**How to Use:**
- Create parent: `maestro_create_space(name, color)`
- Create child: `maestro_create_space(name, color, parentId)`
- Query hierarchy: `maestro_list_spaces(parentId)` to get children
- Filter tasks: `maestro_list_tasks(spaceId)` works at any level

**Additional Features:**
- **Color-coded**: Visual organization (#hex colors)
- **Tag-based**: Cross-cutting categorization
- **Path-based**: Filesystem integration for auto-inference

### Tasks

Active concerns in a context - think of them as **signals of what's in motion**:

**Status Flow:**
- `inbox`: Captured but not yet planned
- `todo`: Planned, ready to work on
- `inProgress`: Actively being worked on (becomes stale if >3 days inactive)
- `done`: Completed

**Priority Levels:**
- `urgent`: Blocking work, immediate attention
- `high`: Important, should do soon
- `medium`: Normal priority
- `low`: Nice to have
- `none`: No explicit priority

**Staleness:**
- Tasks >3 days inactive while `inProgress` need attention

**Due Dates:**
- Time-sensitive work

### Documents

Knowledge and notes for a world:
- Project specs, meeting notes, design docs
- Organized by path (folder-like hierarchy)
- Pin important docs for quick access

**State of the World Document:**
Every space should have a default document (`maestro_set_default_document`) that captures:
- **Current state and context** — What's happening now
- **Active projects/workstreams** — Status, problems, what's been tried
- **Mentioned / Undefined** — Items referenced but lacking detail
  - Agent must ask before acting on these
  - Graduate to spaces when there's real work
- **Agent notes** — Context needed, approach considerations

**Pattern:** When entering a world, read the State of the World doc first. This provides context before querying tasks or suggesting actions.

### Surfacing

Intelligent prioritization within context considering:
- Overdue items
- Due dates
- Priority levels
- Staleness (>3 days inactive)
- Recent activity

Query this to answer "What matters most in this context?"

### Linear Integration

Team coordination layer (if used):
- Links to Linear issues for team visibility
- Track completion metrics (last 24h)
- Separate concern from Maestro's execution tracking

### Menu Bar States

The status you query with `maestro_get_status()`:
- 🔴 **urgent**: Overdue items exist → Address immediately
- 🟠 **input**: Agent waiting for user → Provide input
- 🟡 **attention**: Stale items (>3 days) → Review and update
- 🟢 **clear**: Nothing actionable → All on track

---

## Synthesis Patterns

### Brain Dump / Defined vs Mentioned

When user dumps information about their life/work:

**Process:**
1. **Capture loosely first** — Don't over-structure immediately
2. **Identify defined items** — Active work with enough context to act
   - Create space for these
   - Add tasks with what you know
3. **Identify mentioned items** — Referenced but no details
   - Add to parent's State of the World doc under "Mentioned / Undefined"
   - Mark as "Agent has no details. Ask before acting."
4. **Ask about gaps** — Surface what's undefined before proposing solutions

**Pattern:**
- **Defined** = "I'm working on Project X, trying to solve Y problem, I've tried Z"
  → Create space, document context, create tasks
- **Mentioned** = "Also there's Project B" (no details)
  → Line in parent doc, don't create space yet

**Example State of the World:**
```markdown
## Active Projects
### Project A
- Status: In progress
- Problem: Auth flow breaking on mobile
- Tried: Updated tokens, checked session storage
- Space: Yes (uuid: xxx)

## Mentioned / Undefined
*Agent has no details. Ask before acting.*
- Project B — mentioned, no context yet
- Future marketing site — vague idea
```

**Graduate mentioned → defined when:**
- User provides enough context to act
- There's actual work happening
- It becomes a world they switch into

### "What should I work on?"

**Process:**
1. Check if they've indicated a world
2. If yes: Query surfaced tasks in that space
3. If no: Query surfaced tasks globally + check status
4. Synthesize with reasoning:
   - "X is overdue in World A"
   - "Y is highest priority in current world"
   - "Z was just updated and active"
5. Ask: "Which world do you want to work in?"

**Example:**
```
maestro_get_surfaced_tasks(spaceId: "maestro-uuid", limit: 10)
→ Returns prioritized items
→ Synthesize: "In Maestro: icon integration (in progress, updated 10min ago),
   skill rewrite (high priority, due tomorrow), database optimization (medium priority)"
```

### "What's happening in [Project]?"

**Process:**
1. Query tasks in that space (list_tasks with spaceId filter)
2. Check status distribution (how many in each state)
3. Identify stale items (>3 days inactive)
4. Surface most important (get_surfaced_tasks for that space)
5. Summarize the context's state

**Example:**
```
maestro_list_tasks(spaceId: "project-x-uuid", status: "inProgress")
→ 5 items in progress, 2 are stale
→ Synthesize: "Project X has 5 active items. Two haven't been touched in 4 days:
   [item 1] and [item 2]. Most urgent is [item 3]—it's due tomorrow."
```

### "Catch me up" / "What's my status?"

**Process:**
1. Query global status (maestro_get_status)
2. Break down by world if multiple spaces
3. Highlight attention items (overdue, stale, urgent)
4. Provide world health summary

**Example:**
```
maestro_get_status()
→ Returns: 1 overdue, 2 stale, 3 worlds with active work
→ Synthesize: "You have 1 overdue item in Project X. Two tasks are stale
   (inactive 3+ days) in Project Y. Your current world (Maestro) has 3 active
   items, all moving. Menu bar shows attention state because of the stale items."
```

### World-Aware Recommendations

When user asks for guidance, consider:
- **Current world** (if indicated)
- **Overdue items** (urgent, cross-world)
- **Stale items** (need attention)
- **Recent activity** (momentum)
- **Due dates approaching** (time-sensitive)

Frame recommendations as world choices:
- "Project X needs attention (overdue item)"
- "Continue in Maestro? (active momentum)"
- "Or switch to Project Y? (stale items need refresh)"

---

## Technical Reference

### Core Query Tools

**Understanding Worlds:**
- `maestro_list_spaces()` - See all worlds (spaces)
- `maestro_get_space(id)` - Details of specific world

**Synthesizing Within World:**
- `maestro_get_surfaced_tasks(spaceId, limit)` - Most important items in world
- `maestro_list_tasks(spaceId, status)` - All concerns in world
- `maestro_get_task(id)` - Details of specific concern

**Global Status:**
- `maestro_get_status()` - Health across all worlds (menu bar state)

**Documents:**
- `maestro_list_documents(spaceId)` - Knowledge in world
- `maestro_get_document(id)` - Specific doc content
- `maestro_get_default_document(spaceId)` - Read State of the World

**Agent Activity:**
- `maestro_list_agent_sessions()` - AI work sessions
- `maestro_get_agent_metrics()` - Usage patterns

---

## Conversation Examples

### Context Switch

**User:** "I'm switching to Maestro"
**You:**
```
[Query: maestro_get_surfaced_tasks for maestro space]
"In Maestro context: You have the icon integration in progress (updated 10 minutes ago),
the skill documentation rewrite as high priority, and database optimization as medium
priority. The icon is actively moving—want to continue there?"
```

### Ambiguous Query

**User:** "What should I work on?"
**You:**
```
[Query: maestro_get_status]
"You have work in 3 contexts. Most urgent: Project X has an overdue item.
Your current momentum is in Maestro (3 active items). Which context do you
want to work in?"
```

### Status Check

**User:** "How's everything looking?"
**You:**
```
[Query: maestro_get_status + surfaced tasks]
"Across contexts: Project X needs attention (1 overdue, 2 stale items).
Maestro has healthy momentum (3 active, nothing stale). Project Y is quiet
(nothing urgent). Your menu bar shows attention state because of Project X.
Want to address those stale items?"
```

### Deep Context Query

**User:** "What's happening with Project X?"
**You:**
```
[Query: maestro_list_tasks for Project X space + get_surfaced_tasks]
"Project X has 7 items total: 2 in progress (1 is stale—4 days since update),
3 in todo, 2 done recently. Most urgent is 'Fix authentication bug'—it's overdue
by 2 days. The stale item is 'Refactor API layer'—hasn't been touched since Monday.
Want to focus on the overdue bug first?"
```

---

## Best Practices

### Always Context-Aware

- If user mentions project name → filter to that space
- If working in a context → focus only on that project
- If status check → synthesize across contexts clearly

### Synthesize State

Provide meaningful summaries with context and reasoning:

"3 contexts active. Project X needs attention (overdue). Maestro has momentum. Project Y is quiet."

### Ask Good Questions

- "Which context are you in?"
- "Want to continue here or switch contexts?"
- "This context has stale items—want to review?"
- "What's your current state?" (energy, time, focus)

### Respect Context Boundaries

- Treat each project as a distinct context
- Keep synthesis focused on current context
- Go cross-context only for status/prioritization questions

### Use Natural Language

Reference things naturally: "The icon integration in Maestro" rather than technical IDs or database references.

---

## Core Principles

Maestro is a cognitive substrate you query to understand their work. It's a multi-context state machine you interpret—a way to know what's happening across their projects. Think of it as your knowledge base about their current concerns, the backend to your frontend synthesis.

**Remember:** You **understand** their work. They **ask you** about it. You query, synthesize, and guide through conversation.

The user is the director. Maestro is the stage. You are the narrator who knows what's happening in every scene.
