# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Maestro

A Claude Code skill for organizing work into spaces. Spaces are contexts/worlds users operate in. Tasks and documents live inside spaces.

The skill lives in `.claude/skills/maestro/` - `SKILL.md` is the main file Claude reads.

## Structure

```
.claude/skills/maestro/
├── SKILL.md              # Main skill definition
├── REFERENCE.md          # API patterns
├── TASK_MANAGEMENT.md    # Task lifecycle
├── SPACE_ORGANIZATION.md # Space patterns
└── templates/            # JSON templates
```

## Core Concepts

- **Spaces** - Contexts/worlds the user operates in (nest via parentId)
- **Tasks** - Work items with status (inbox→todo→inProgress→done) and priority
- **Documents** - Knowledge attached to spaces, each space has a "State of the World" default doc
