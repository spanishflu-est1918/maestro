/**
 * Example: Create a New Project
 *
 * This script demonstrates how to:
 * 1. Create a project space
 * 2. Add initial tasks
 * 3. Create project documentation
 * 4. Set up the default document
 *
 * Prerequisites:
 * - Maestro daemon running
 * - MCP client connected
 */

// Example MCP tool calls (pseudo-code for illustration)
// In practice, these would be called via your MCP client

async function createProject() {
  console.log("Creating new project...");

  // 1. Create project space
  const space = await maestro_create_space({
    name: "Website Redesign",
    color: "#3498db",
    path: "/Users/you/projects/website-redesign",
    tags: ["active", "design", "frontend"]
  });

  console.log(`✓ Created space: ${space.name} (${space.id})`);

  // 2. Create initial tasks
  const tasks = [
    {
      title: "Research competitor websites",
      description: "Analyze 5 competitor sites for design patterns",
      priority: "high",
      status: "todo"
    },
    {
      title: "Create wireframes",
      description: "Design wireframes for key pages (home, about, contact)",
      priority: "high",
      status: "inbox"
    },
    {
      title: "Develop component library",
      description: "Build reusable React components",
      priority: "medium",
      status: "inbox"
    },
    {
      title: "Implement responsive design",
      description: "Ensure mobile-first responsive layout",
      priority: "medium",
      status: "inbox"
    },
    {
      title: "Performance optimization",
      description: "Optimize images, lazy loading, code splitting",
      priority: "low",
      status: "inbox"
    }
  ];

  for (const taskData of tasks) {
    const task = await maestro_create_task({
      spaceId: space.id,
      ...taskData
    });
    console.log(`  ✓ Created task: ${task.title}`);
  }

  // 3. Create project documentation
  const doc = await maestro_create_document({
    spaceId: space.id,
    title: "Project Overview",
    content: `# Website Redesign Project

## Objective
Modernize company website with improved UX and performance.

## Goals
- [ ] Reduce page load time by 50%
- [ ] Increase mobile conversion rate by 20%
- [ ] Improve accessibility score to AA standard
- [ ] Launch by Q1 2025

## Tech Stack
- React 18
- Next.js 14
- Tailwind CSS
- Vercel deployment

## Team
- Designer: Jane Doe
- Frontend Dev: John Smith
- Project Manager: You

## Timeline
- Week 1-2: Research and wireframes
- Week 3-4: Component development
- Week 5-6: Page implementation
- Week 7: Testing and optimization
- Week 8: Launch

## Resources
- [Design System](https://figma.com/...)
- [Brand Guidelines](https://...)
- [Performance Budget](https://...)
`,
    path: "/docs"
  });

  console.log(`  ✓ Created document: ${doc.title}`);

  // 4. Set as default document
  await maestro_set_default_document({
    id: doc.id
  });

  console.log(`  ✓ Set as default document`);

  // 5. Create additional documents
  const meetingNotes = await maestro_create_document({
    spaceId: space.id,
    title: "Meeting Notes",
    content: "# Meeting Notes\n\n## Kickoff Meeting - 2025-12-17\n\n...",
    path: "/meetings"
  });

  const decisions = await maestro_create_document({
    spaceId: space.id,
    title: "Design Decisions",
    content: "# Design Decisions\n\n## Color Scheme\n\n...",
    path: "/decisions"
  });

  console.log(`  ✓ Created additional documents`);

  console.log("\n✅ Project setup complete!");
  console.log(`\nNext steps:`);
  console.log(`1. Open Maestro menu bar app to see your project`);
  console.log(`2. Start working on: ${tasks[0].title}`);
  console.log(`3. Link with Linear: maestro_linear_sync`);

  return space;
}

// Usage
createProject().catch(console.error);
