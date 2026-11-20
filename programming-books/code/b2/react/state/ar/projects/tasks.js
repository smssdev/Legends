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

// ar/projects/tasks.tsx
import { useEffect, useReducer, useRef, useState } from "react";
import { createRoot } from "react-dom/client";
import { jsx, jsxs } from "react/jsx-runtime";
var require_tasks = __commonJS({
  "ar/projects/tasks.tsx"() {
    init_tasks_reducer();
    var KEY = "tasks";
    function load() {
      try {
        const saved = localStorage.getItem(KEY);
        return saved ? JSON.parse(saved) : [];
      } catch {
        return [];
      }
    }
    function Tasks() {
      const [tasks, dispatch] = useReducer(tasksReducer, [], load);
      const [text, setText] = useState("");
      const input = useRef(null);
      const left = tasks.filter((t) => !t.done).length;
      useEffect(() => {
        localStorage.setItem(KEY, JSON.stringify(tasks));
      }, [tasks]);
      function submit(event) {
        event.preventDefault();
        if (!text.trim()) return;
        dispatch({ type: "added", id: Date.now(), text: text.trim() });
        setText("");
        input.current?.focus();
      }
      return /* @__PURE__ */ jsxs("div", { className: "card", children: [
        /* @__PURE__ */ jsx("h2", { children: "\u0627\u0644\u0645\u0647\u0627\u0645" }),
        /* @__PURE__ */ jsxs("form", { className: "row", onSubmit: submit, children: [
          /* @__PURE__ */ jsx("input", { ref: input, "aria-label": "\u0645\u0647\u0645\u0629 \u062C\u062F\u064A\u062F\u0629", placeholder: "\u0645\u0647\u0645\u0629 \u062C\u062F\u064A\u062F\u0629", value: text, onChange: (e) => setText(e.target.value), style: { flex: 1, width: "auto" } }),
          /* @__PURE__ */ jsx("button", { type: "submit", children: "\u0623\u0636\u0641" })
        ] }),
        /* @__PURE__ */ jsx("ul", { children: tasks.map((task) => /* @__PURE__ */ jsxs("li", { children: [
          /* @__PURE__ */ jsx("input", { type: "checkbox", id: `t${task.id}`, checked: task.done, onChange: () => dispatch({ type: "toggled", id: task.id }), style: { width: "auto" } }),
          /* @__PURE__ */ jsx("span", { children: /* @__PURE__ */ jsx("label", { htmlFor: `t${task.id}`, style: { display: "inline", fontWeight: 400, textDecoration: task.done ? "line-through" : "none" }, children: task.text }) })
        ] }, task.id)) }),
        /* @__PURE__ */ jsxs("div", { className: "row", children: [
          /* @__PURE__ */ jsxs("span", { className: "muted", style: { flex: 1 }, children: [
            left,
            " \u0645\u062A\u0628\u0642\u064A\u0629"
          ] }),
          /* @__PURE__ */ jsx("button", { className: "secondary", onClick: () => dispatch({ type: "cleared" }), children: "\u0627\u062D\u0630\u0641 \u0627\u0644\u0645\u0646\u062C\u0632\u0629" })
        ] })
      ] });
    }
    createRoot(document.getElementById("root")).render(/* @__PURE__ */ jsx(Tasks, {}));
  }
});
export default require_tasks();
