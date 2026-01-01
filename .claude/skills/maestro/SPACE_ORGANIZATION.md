# Space Organization Guide

Best practices for organizing spaces in Maestro.

## Core Principles

### Spaces Are Earned

**Don't create spaces prematurely.** A space should be a world you operate in, not a placeholder for an idea.

Things graduate to spaces when:
- **Active work is happening** — Not just planning, but doing
- **Decisions need to be made** — There's substance to track
- **You switch into it** — It's a context you actually inhabit

**Before creating a space, ask:**
- Is there work happening now?
- Do I have enough context to act?
- Will I actually switch into this world?

**Anti-pattern:** Creating spaces for every idea mentioned
- "Future marketing site" → Don't create space yet
- "Client mentioned wanting analytics" → Don't create space yet
- "Maybe we should refactor auth" → Don't create space yet

**Pattern:** Capture mentioned items in parent's State of the World doc under "Mentioned / Undefined" until they earn promotion.

### State of the World Document

**Every space should have a default document** that answers:
- What's happening here right now?
- What are the active workstreams?
- What problems exist?
- What's been tried?
- What's mentioned but undefined?

**Structure:**
```markdown
# State of the World: [Space Name]

## Current Context
[What's happening, why this space exists]

## Active Projects
### Project A
- Status: In progress
- Problem: [what we're solving]
- Tried: [what we've attempted]
- Space: Yes (uuid: xxx)

### Project B
- Status: Blocked
- Blocker: [what we need]
- Next: [what happens when unblocked]

## Mentioned / Undefined
*Agent has no details. Ask before acting.*
- Thing X — mentioned, no context yet
- Idea Y — future consideration
```

**Pattern:** When entering a world, read this doc first. It provides context before querying tasks.

### Brain Dump Graduation Flow

**When user dumps information:**
1. **Capture loosely** — Don't over-structure immediately
2. **Identify defined** — Active work with context → create space
3. **Identify mentioned** — Vague references → add to parent doc
4. **Ask about gaps** — Surface undefined items when appropriate

**Example flow:**
```
User: "I'm working on the auth refactor, it's breaking mobile sessions.
       Also there's that analytics thing and maybe a marketing site later."

You:
1. Create "Auth Refactor" space (defined: active work, has problem)
2. Add to parent State of World under "Mentioned / Undefined":
   - Analytics thing — mentioned, no details
   - Marketing site — future idea
3. Ask later: "You mentioned analytics — want to flesh that out or keep it parked?"
```

---

## Space Hierarchies

### Pattern 1: Project-Based (Recommended for Teams)

```
Company (root)
├── Product Development
│   ├── Feature A
│   │   ├── Backend
│   │   ├── Frontend
│   │   └── Testing
│   └── Feature B
├── Operations
│   ├── Infrastructure
│   ├── Support
│   └── Monitoring
└── Planning
    ├── Q1 2025
    └── Q2 2025
```

**Advantages**:
- Clear project ownership
- Easy to find related work
- Scales with team size
- Natural archive points (complete projects)

**Use when**:
- Team of 3+ people
- Multiple concurrent projects
- Need clear project boundaries

### Pattern 2: Status-Based (Recommended for Personal)

```
Work (root)
├── Planning (ideas, research)
├── Active (current work)
├── Review (completed, not deployed)
└── Done (deployed, archived monthly)
```

**Advantages**:
- Visual workflow
- Easy to see current load
- Simple to maintain
- Natural cleanup cycle

**Use when**:
- Solo developer
- Kanban-style workflow
- Want minimal structure

### Pattern 3: Team-Based (Recommended for Large Orgs)

```
Engineering (root)
├── Backend Team
│   ├── Team Projects
│   └── Individual Work
├── Frontend Team
│   ├── Team Projects
│   └── Individual Work
└── Shared
    ├── Infrastructure
    └── Cross-Team
```

**Advantages**:
- Clear team ownership
- Supports team autonomy
- Shared spaces for collaboration
- Scales to 10+ teams

**Use when**:
- Multiple specialized teams
- Clear team boundaries
- Need ownership clarity

## Color Coding Strategies

### By Status

- 🟢 Green (#22C55E): Active/healthy
- 🟡 Yellow (#EAB308): Planning/in-review
- 🔵 Blue (#3B82F6): Standard work
- 🟣 Purple (#A855F7): Research/exploration
- ⚪ Gray (#6B7280): Paused/archived

**Example**:
```json
{
  "name": "Feature Development",
  "color": "#22C55E",  // Green = active work
  "status": "active"
}
```

### By Team

- 🔴 Red (#EF4444): Backend
- 🟠 Orange (#F97316): Frontend
- 🟡 Yellow (#EAB308): Design
- 🟢 Green (#22C55E): QA
- 🔵 Blue (#3B82F6): DevOps

**Example**:
```json
{
  "name": "Authentication Work",
  "color": "#EF4444",  // Red = backend team
  "tags": ["backend", "security"]
}
```

### By Priority

- 🔴 Red (#EF4444): Critical/P0
- 🟠 Orange (#F97316): High priority/P1
- 🟡 Yellow (#EAB308): Medium/P2
- 🟢 Green (#22C55E): Low/P3
- ⚪ Gray (#6B7280): Backlog

**Example**:
```json
{
  "name": "Security Fixes",
  "color": "#EF4444",  // Red = critical
  "priority": "urgent"
}
```

## Tagging Strategies

### By Discipline

```json
{
  "tags": ["backend", "frontend", "design", "qa", "devops", "security"]
}
```

### By Technology

```json
{
  "tags": ["swift", "typescript", "python", "react", "grdb"]
}
```

### By Category

```json
{
  "tags": ["feature", "bug", "refactor", "docs", "test"]
}
```

### By Status

```json
{
  "tags": ["active", "paused", "blocked", "archived"]
}
```

### Combination Tagging

```json
{
  "name": "Auth Refactor",
  "tags": ["backend", "swift", "refactor", "security", "active"]
}
```

## Space Lifecycle

### 1. Creation

```json
{
  "name": "Clear, descriptive name",
  "color": "#3B82F6",
  "parentId": "parent-uuid",  // Optional
  "tags": ["relevant", "tags"],
  "path": "/optional/filesystem/path"
}
```

**Naming conventions**:
- Use title case: "Feature Name"
- Be specific: "User Authentication" not "Auth"
- Include phase if relevant: "Q1 Planning"
- Avoid abbreviations

### 2. Active Use

- Create tasks within space
- Add documents for context
- Monitor via menu bar

### 3. Completion

When project complete:
1. Mark all tasks done
2. Archive completed tasks
3. Update space tags: add "completed"
4. Set color to gray
5. Keep for reference (don't delete yet)

### 4. Archival

After 1-3 months:
1. Verify no active references
2. Use `maestro_archive_space`
3. Space excluded from default views
4. Still searchable with includeArchived=true

### 5. Deletion

Only delete if:
- Created by mistake
- Duplicate space
- No historical value

**Warning**: Deletion is permanent, archival is preferred.

## Advanced Patterns

### Project Workspaces

Create comprehensive project spaces:

```
Project Alpha
├── 📋 Planning (space for specs/designs)
├── 🚀 Development (space for implementation)
├── 🧪 Testing (space for QA work)
└── 📚 Documentation (space for docs)
```

Each sub-space:
- Has relevant documents pinned
- Contains phase-specific tasks
- Uses color coding for status
- Tags for filtering

### Client/Customer Spaces

```
Clients (root)
├── Customer A
│   ├── Active Projects
│   ├── Support Requests
│   └── Meeting Notes
└── Customer B
    ├── Active Projects
    └── Support Requests
```

**Benefits**:
- Clear customer segmentation
- Easy to find customer work
- Privacy via space isolation
- Track customer activity

### Research & Development

```
R&D
├── Experiments
│   ├── Experiment 1 (in progress)
│   └── Experiment 2 (paused)
├── Prototypes
└── Learning
    ├── Tutorials
    └── Documentation
```

**Use for**:
- Exploratory work
- POCs
- Learning new technologies
- Innovation projects

## Best Practices

### Naming

✅ **Do**:
- "User Authentication Feature"
- "Q1 2025 Planning"
- "Backend Team Projects"
- "Customer A - Support"

❌ **Don't**:
- "stuff"
- "misc"
- "temp"
- "new-space-123"

### Hierarchy Depth

✅ **Do**:
- Keep hierarchies 2-4 levels deep
- Use flat structure when possible
- Group related spaces

❌ **Don't**:
- Create 5+ level hierarchies
- Nest unnecessarily
- Over-categorize

### Space Count

✅ **Do**:
- Keep active spaces under 20
- Archive completed spaces
- Merge similar spaces
- Delete duplicates

❌ **Don't**:
- Create space for every task
- Hoard old spaces
- Duplicate existing spaces

### Color Usage

✅ **Do**:
- Use consistent color scheme
- Document color meanings
- Update colors as status changes
- Use enough contrast

❌ **Don't**:
- Use random colors
- Change color scheme frequently
- Use too many colors
- Ignore accessibility

### Path Integration

✅ **Do**:
- Link to relevant codebases
- Use absolute paths
- Keep paths updated
- Document path purpose

❌ **Don't**:
- Use relative paths
- Link to temp directories
- Leave broken paths
