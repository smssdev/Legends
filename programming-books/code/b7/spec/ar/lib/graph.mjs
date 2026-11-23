// Checks a task list: unknown dependencies, cycles, and an order to do
// them in.
export function checkTasks(tasks) {
  const ids = new Set(tasks.map((t) => t.id));
  const problems = [];
  for (const task of tasks) {
    for (const dep of task.dependsOn) {
      if (!ids.has(dep)) {
        problems.push(`${task.id} depends on ${dep}, which does not exist`);
      }
      if (dep === task.id) {
        problems.push(`${task.id} depends on itself`);
      }
    }
  }
  const order = [];
  const state = new Map();
  const visit = (id, path) => {
    if (state.get(id) === "done" || !ids.has(id)) {
      return;
    }
    if (state.get(id) === "visiting") {
      problems.push(`cycle: ${[...path, id].join(" -> ")}`);
      return;
    }
    state.set(id, "visiting");
    for (const dep of tasks.find((t) => t.id === id).dependsOn) {
      visit(dep, [...path, id]);
    }
    state.set(id, "done");
    order.push(id);
  };
  tasks.forEach((t) => visit(t.id, []));
  return {problems, order};
}
