# Project Structure Guide

Templates for organizing Maestro spaces and tasks for different project types.

## Software Project Structure

### Standard Feature Development

```
Project Name (Space)
├── 📋 Planning
│   ├── TASK: Feature specification document
│   ├── TASK: Design mockups
│   └── DOC: Technical architecture
├── 🚀 Development
│   ├── TASK: Backend API implementation
│   ├── TASK: Frontend UI components
│   ├── TASK: Database migrations
│   └── TASK: Integration work
├── 🧪 Testing
│   ├── TASK: Unit tests
│   ├── TASK: Integration tests
│   ├── TASK: E2E tests
│   └── TASK: Performance testing
└── 📚 Documentation
    ├── TASK: API documentation
    ├── TASK: User guides
    └── DOC: Release notes
```

### Bug Fix Project

```
Bug Fix: [BUG-123] Description (Space)
├── TASK: Reproduce bug
├── TASK: Root cause analysis
├── TASK: Implement fix
├── TASK: Add regression tests
├── TASK: Deploy to staging
└── DOC: Post-mortem
```

### Refactoring Project

```
Refactor: [Component Name] (Space)
├── 📝 Analysis
│   ├── TASK: Code audit
│   ├── TASK: Identify problem areas
│   └── DOC: Refactoring plan
├── 🛡️ Safety
│   ├── TASK: Add comprehensive tests
│   ├── TASK: Set up monitoring
│   └── TASK: Create rollback plan
├── 🔧 Implementation
│   ├── TASK: Extract interfaces
│   ├── TASK: Refactor module A
│   ├── TASK: Refactor module B
│   └── TASK: Update dependencies
└── ✅ Validation
    ├── TASK: Verify tests pass
    ├── TASK: Performance benchmarks
    └── DOC: Before/after metrics
```

## Team Organization Structure

### Multi-Team Company

```
Company (Root)
├── Backend Team
│   ├── Current Sprint
│   ├── Backlog
│   └── Technical Debt
├── Frontend Team
│   ├── Current Sprint
│   ├── Backlog
│   └── Technical Debt
├── DevOps Team
│   ├── Infrastructure
│   ├── CI/CD
│   └── Monitoring
└── Shared
    ├── Cross-Team Projects
    ├── Company Goals
    └── All-Hands Action Items
```

### Startup Structure

```
Startup Name (Root)
├── Product
│   ├── Feature A
│   ├── Feature B
│   └── User Research
├── Engineering
│   ├── Backend
│   ├── Frontend
│   └── Infrastructure
├── Growth
│   ├── Marketing Campaigns
│   ├── SEO Tasks
│   └── Analytics
└── Operations
    ├── Customer Support
    ├── Sales
    └── Admin
```

## Sprint Organization

### Two-Week Sprint

```
Sprint 24: Dec 18 - Jan 1 (Space)
├── 🎯 Sprint Goals
│   └── DOC: Sprint objectives and success criteria
├── 📋 Planning
│   ├── TASK: Sprint planning meeting
│   └── DOC: Sprint backlog
├── 🚀 In Progress
│   ├── TASK: Story 1 [High Priority]
│   ├── TASK: Story 2 [High Priority]
│   ├── TASK: Story 3 [Medium Priority]
│   └── TASK: Bug fixes
├── 👀 Review
│   ├── TASK: Code review for Story 1
│   └── TASK: QA testing
├── ✅ Done
│   └── [Completed tasks move here]
└── 🔄 Retrospective
    ├── TASK: Prepare retro agenda
    ├── DOC: What went well
    ├── DOC: What could improve
    └── TASK: Action items for next sprint
```

## Client Project Structure

### Agency Client Work

```
Client Name (Space)
├── 🎯 Active Projects
│   ├── Project A
│   │   ├── TASK: Deliverable 1
│   │   ├── TASK: Deliverable 2
│   │   └── DOC: Project brief
│   └── Project B
├── 🆘 Support Queue
│   ├── TASK: Support ticket #001
│   ├── TASK: Support ticket #002
│   └── TASK: Bug report #003
├── 💬 Communication
│   ├── DOC: Weekly status updates
│   ├── DOC: Meeting notes (dated)
│   └── TASK: Upcoming client call
└── 💰 Billing
    ├── TASK: Time tracking review
    ├── TASK: Invoice preparation
    └── DOC: Scope changes
```

## Personal Productivity Structure

### GTD-Style Organization

```
Personal (Root)
├── 📥 Inbox
│   └── [Quick capture, review daily]
├── 🔥 This Week
│   ├── Work tasks
│   └── Personal tasks
├── 📅 This Month
│   └── Monthly goals
├── 🎯 Projects
│   ├── Active Project 1
│   ├── Active Project 2
│   └── Active Project 3
├── 📚 Someday/Maybe
│   └── Future ideas
└── 🗂️ Reference
    └── Documents and notes
```

### Time-Based Organization

```
Personal (Root)
├── Today
│   └── [Max 5 tasks, moved from weekly]
├── This Week
│   └── [Weekly priorities]
├── This Month
│   └── [Monthly goals]
├── This Quarter
│   └── [Quarterly objectives]
└── This Year
    └── [Annual goals]
```

## Research Project Structure

### Technical Investigation

```
Research: [Topic] (Space)
├── 🎯 Objectives
│   └── DOC: Research questions and goals
├── 📚 Literature Review
│   ├── TASK: Review solution A
│   ├── TASK: Review solution B
│   └── DOC: Findings summary
├── 🧪 Experiments
│   ├── TASK: Prototype A
│   ├── TASK: Prototype B
│   └── TASK: Benchmark tests
├── 📊 Analysis
│   ├── TASK: Compare results
│   ├── DOC: Trade-off analysis
│   └── DOC: Metrics and data
└── 📝 Deliverables
    ├── DOC: Final recommendation
    ├── DOC: Implementation plan
    └── TASK: Present findings
```

## Color Coding Examples

### By Project Phase

- 🟡 Yellow (#EAB308): Planning/Design
- 🔵 Blue (#3B82F6): Development
- 🟠 Orange (#F97316): Testing/QA
- 🟣 Purple (#8B5CF6): Documentation
- 🟢 Green (#22C55E): Deployed/Done

### By Priority

- 🔴 Red (#EF4444): Critical/P0
- 🟠 Orange (#F97316): High/P1
- 🟡 Yellow (#EAB308): Medium/P2
- 🟢 Green (#22C55E): Low/P3
- ⚪ Gray (#6B7280): Backlog

### By Team

- 🔴 Red (#EF4444): Backend
- 🔵 Blue (#3B82F6): Frontend
- 🟢 Green (#22C55E): Mobile
- 🟡 Yellow (#EAB308): Design
- 🟣 Purple (#8B5CF6): DevOps

## Tagging Conventions

### Standard Tags

```
Status: active, paused, blocked, completed
Type: feature, bug, refactor, docs, test
Priority: critical, high, medium, low
Team: backend, frontend, design, qa, devops
Technology: swift, typescript, python, react
Phase: planning, development, testing, deployed
```

### Example Multi-Tag Usage

```
Task: Implement OAuth Login
Tags: ["feature", "backend", "security", "swift", "high", "active"]
```

## Document Organization

### Documentation Hierarchy

```
Space: Project Name
├── /specs/
│   ├── feature-a.md
│   └── feature-b.md
├── /designs/
│   ├── architecture.md
│   └── database-schema.md
├── /meetings/
│   ├── 2025-12-18-standup.md
│   └── 2025-12-18-planning.md
├── /decisions/
│   ├── 001-use-graphql.md
│   └── 002-database-choice.md
└── README.md (pinned, default)
```

## Migration Paths

### From Flat Structure to Hierarchical

**Before**:
```
All Tasks (Space)
├── Task 1
├── Task 2
├── Task 3
└── ... (100+ tasks)
```

**After**:
```
Projects (Root)
├── Project A
│   ├── Feature 1 tasks
│   └── Feature 2 tasks
├── Project B
│   └── Feature tasks
└── Operations
    └── Ongoing tasks
```

### From Tool-Specific to Maestro

**Before** (Linear/Jira/Trello):
- All tasks in external tool
- No local tracking
- Limited customization

**After** (Maestro):
- Core tasks in Maestro
- Link to external tools for team visibility
- Custom workflows and surfacing
- Agent activity tracking

## Best Practices

### Naming Conventions

✅ Clear, descriptive names
- "Authentication Feature" not "Auth"
- "Q1 2025 Planning" not "Q1"
- "Client A - Website Redesign" not "Redesign"

### Hierarchy Depth

✅ 2-4 levels maximum
- Root → Project → Phase → Task
- Deeper hierarchies become hard to navigate

### Regular Maintenance

✅ Weekly cleanup:
- Archive completed spaces
- Update stale tasks
- Review and update priorities
- Clean up unused tags

### Consistent Structure

✅ Use templates:
- Same structure for similar projects
- Predictable organization
- Easy onboarding
