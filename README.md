# Maestro

A Claude Code skill for organizing work into spaces.

## What it does

Spaces are contexts/worlds you operate in. Tasks and documents live inside spaces. Claude reads your state and synthesizes what matters right now.

## Installation

Copy `.claude/skills/maestro/` to your Claude Code skills directory:

```bash
cp -r .claude/skills/maestro ~/.claude/skills/
```

## Usage

Ask Claude:
- "What should I work on?"
- "Catch me up on Project X"
- "Create a space for this new project"

The skill teaches Claude how to manage your work contexts.

## Structure

- **Spaces** - Contexts/worlds (nest via parentId)
- **Tasks** - Work items with status and priority
- **Documents** - Knowledge per space, including "State of the World" docs
