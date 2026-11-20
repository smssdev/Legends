import { tasksReducer, type Action, type Task } from "./tasks-reducer";

const actions: Action[] = [
  { type: "added", id: 1, text: "اقرأ الفصل 5" },
  { type: "added", id: 2, text: "اكتب دالة اختزال" },
  { type: "toggled", id: 1 },
  { type: "cleared" },
];

let state: Task[] = [];
for (const action of actions) {
  state = tasksReducer(state, action);
  console.log(action.type.padEnd(8), JSON.stringify(state.map((t) => `${t.done ? "✓" : "·"} ${t.text}`)));
}
