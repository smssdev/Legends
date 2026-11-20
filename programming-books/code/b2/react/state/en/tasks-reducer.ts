export type Task = { id: number; text: string; done: boolean };

export type Action =
  | { type: "added"; id: number; text: string }
  | { type: "toggled"; id: number }
  | { type: "cleared" };

// The reducer is a pure function: it can run anywhere, even without React
export function tasksReducer(tasks: Task[], action: Action): Task[] {
  switch (action.type) {
    case "added":
      return [...tasks, { id: action.id, text: action.text, done: false }];
    case "toggled":
      return tasks.map((t) => (t.id === action.id ? { ...t, done: !t.done } : t));
    case "cleared":
      return tasks.filter((t) => !t.done);
  }
}
