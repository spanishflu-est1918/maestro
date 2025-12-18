---
description: Set up a new project or team space in Maestro with recommended structure
---

# Setup Space

Help the user create a well-organized space structure in Maestro.

Ask the user what type of project they're setting up:
1. **Software Project** - Feature development with planning/dev/testing/docs phases
2. **Team Space** - Team organization with projects/ops/individual work
3. **Sprint** - Time-boxed sprint with goals/in-progress/review/retro
4. **Client Work** - Client projects with active work/support/meetings
5. **Personal** - Personal organization with inbox/this-week/this-month/someday

Then use the appropriate template from the Maestro skill templates and create:
- Root space with descriptive name and color
- Child spaces for phases/categories
- Suggest color coding scheme
- Recommend tags for filtering

Use maestro_create_space for each space in the hierarchy.

Reference the space-template.json in the Maestro skill for pre-built patterns.
