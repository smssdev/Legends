var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// ar/tasks-reducer.ts
function tasksReducer(tasks, action) {
  switch (action.type) {
    case "added":
      return [...tasks, { id: action.id, text: action.text, done: false }];
    case "toggled":
      return tasks.map((t) => t.id === action.id ? { ...t, done: !t.done } : t);
    case "cleared":
      return tasks.filter((t) => !t.done);
  }
}
var init_tasks_reducer = __esm({
  "ar/tasks-reducer.ts"() {
  }
});

// ar/reducer-test.ts
var require_reducer_test = __commonJS({
  "ar/reducer-test.ts"() {
    init_tasks_reducer();
    var actions = [
      { type: "added", id: 1, text: "\u0627\u0642\u0631\u0623 \u0627\u0644\u0641\u0635\u0644 5" },
      { type: "added", id: 2, text: "\u0627\u0643\u062A\u0628 \u062F\u0627\u0644\u0629 \u0627\u062E\u062A\u0632\u0627\u0644" },
      { type: "toggled", id: 1 },
      { type: "cleared" }
    ];
    var state = [];
    for (const action of actions) {
      state = tasksReducer(state, action);
      console.log(action.type.padEnd(8), JSON.stringify(state.map((t) => `${t.done ? "\u2713" : "\xB7"} ${t.text}`)));
    }
  }
});
export default require_reducer_test();
