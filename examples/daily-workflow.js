/**
 * Example: Daily Workflow
 *
 * This script demonstrates a typical daily workflow:
 * 1. Get surfaced tasks (priority work)
 * 2. Start working on a task
 * 3. Update task progress
 * 4. Complete tasks
 * 5. Review completed work
 *
 * Prerequisites:
 * - Maestro daemon running
 * - Existing spaces and tasks
 */

async function dailyWorkflow() {
  console.log("🌅 Starting daily workflow...\n");

  // 1. Get surfaced tasks (highest priority work)
  console.log("📋 Getting your top priorities...");
  const surfaced = await maestro_get_surfaced_tasks({
    limit: 5
  });

  console.log(`\nYou have ${surfaced.length} priority tasks:\n`);
  surfaced.forEach((task, i) => {
    const emoji = task.priority === "urgent" ? "🔥" :
                  task.priority === "high" ? "⚡" :
                  task.priority === "medium" ? "📌" : "📝";
    console.log(`${i + 1}. ${emoji} ${task.title}`);
    console.log(`   Status: ${task.status} | Priority: ${task.priority}`);
    if (task.description) {
      console.log(`   ${task.description.substring(0, 60)}...`);
    }
    console.log();
  });

  // 2. Start working on the top task
  if (surfaced.length === 0) {
    console.log("✨ No pending tasks! Great job!");
    return;
  }

  const currentTask = surfaced[0];
  console.log(`\n🎯 Starting: ${currentTask.title}`);

  // Update to in-progress
  await maestro_update_task({
    id: currentTask.id,
    status: "inProgress"
  });

  console.log("   ✓ Status updated to 'inProgress'");

  // Simulate work...
  console.log("\n⏳ Working on task...");
  console.log("   (This is where you'd actually do the work)");

  // 3. Add progress notes (update description)
  await maestro_update_task({
    id: currentTask.id,
    description: `${currentTask.description || ''}\n\nProgress Update:\n- Completed initial research\n- Created wireframe drafts\n- Next: Get feedback from design team`
  });

  console.log("   ✓ Added progress notes");

  // 4. Complete the task
  console.log("\n✅ Completing task...");
  await maestro_complete_task({
    id: currentTask.id
  });

  console.log("   ✓ Task marked as done!");

  // 5. Check remaining work
  const remaining = await maestro_list_tasks({
    status: "inProgress"
  });

  console.log(`\n📊 Daily Summary:`);
  console.log(`   ✓ Completed: ${currentTask.title}`);
  console.log(`   📝 In Progress: ${remaining.length} tasks`);
  console.log(`   🎯 Next Priority: ${surfaced[1]?.title || "None - all caught up!"}`);

  // 6. Get all tasks for today
  const today = new Date().toISOString().split('T')[0];
  const allTasks = await maestro_list_tasks({
    includeArchived: false
  });

  const dueTasks = allTasks.filter(task => {
    if (!task.dueDate) return false;
    return task.dueDate.startsWith(today);
  });

  if (dueTasks.length > 0) {
    console.log(`\n⏰ Tasks due today: ${dueTasks.length}`);
    dueTasks.forEach(task => {
      console.log(`   - ${task.title}`);
    });
  }

  console.log("\n✨ Workflow complete! Keep up the great work!");
}

/**
 * Alternative: Weekly Review
 */
async function weeklyReview() {
  console.log("📊 Weekly Review\n");

  // Get all spaces
  const spaces = await maestro_list_spaces({
    includeArchived: false
  });

  console.log(`Active spaces: ${spaces.length}\n`);

  for (const space of spaces) {
    console.log(`📁 ${space.name}`);

    // Get tasks for this space
    const tasks = await maestro_list_tasks({
      spaceId: space.id,
      includeArchived: false
    });

    const completed = tasks.filter(t => t.status === "done").length;
    const inProgress = tasks.filter(t => t.status === "inProgress").length;
    const todo = tasks.filter(t => t.status === "todo").length;
    const inbox = tasks.filter(t => t.status === "inbox").length;

    console.log(`   ✓ Completed: ${completed}`);
    console.log(`   🔄 In Progress: ${inProgress}`);
    console.log(`   📝 To Do: ${todo}`);
    console.log(`   📥 Inbox: ${inbox}`);
    console.log();

    // Archive completed tasks older than 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldCompleted = tasks.filter(t =>
      t.status === "done" &&
      new Date(t.completedAt) < thirtyDaysAgo
    );

    if (oldCompleted.length > 0) {
      console.log(`   🗄️  Archiving ${oldCompleted.length} old completed tasks...`);
      for (const task of oldCompleted) {
        await maestro_archive_task({ id: task.id });
      }
    }
  }

  console.log("✅ Weekly review complete!");
}

// Usage
if (process.argv.includes('--weekly')) {
  weeklyReview().catch(console.error);
} else {
  dailyWorkflow().catch(console.error);
}
