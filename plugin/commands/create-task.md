---
description: Create a new task in Maestro with proper structure
---

# Create Task

Help the user create a well-structured task in Maestro.

Ask the user for:
1. Which space the task belongs to (use maestro_list_spaces if needed)
2. Task title (clear, actionable)
3. Description (detailed context)
4. Status (inbox for quick capture, todo if ready to work)
5. Priority (only if truly urgent/high, default to medium)
6. Due date (only if externally driven deadline)

Then use maestro_create_task with all the information.

Suggest using templates from the Maestro skill for common task types:
- Feature (user story, requirements, acceptance criteria)
- Bug (reproduction steps, environment, fix plan)
- Refactor (problems, goals, approach)
- Research (question, goals, time box)
