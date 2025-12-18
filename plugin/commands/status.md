---
description: Check Maestro status and get top surfaced tasks
---

# Maestro Status

Get current Maestro menu bar state and top prioritized tasks.

Use maestro_get_status to show:
- Menu bar color state (clear/attention/input/urgent)
- Badge count (actionable items)
- Overdue task count
- Stale task count (3+ days inactive)
- Agents needing input
- Active agent count
- Linear activity (done in last 24h, currently assigned)

Then use maestro_get_surfaced_tasks with limit: 10 to show top priorities.

Present the information clearly to help the user understand what needs attention.
