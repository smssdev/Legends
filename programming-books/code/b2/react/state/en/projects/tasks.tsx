import { useEffect, useReducer, useRef, useState } from "react";
import type { FormEvent } from "react";
import { createRoot } from "react-dom/client";
import { tasksReducer, type Task } from "../tasks-reducer";

const KEY = "tasks";

function load(): Task[] {
  try {
    const saved = localStorage.getItem(KEY);
    return saved ? (JSON.parse(saved) as Task[]) : [];
  } catch {
    return [];
  }
}

function Tasks() {
  const [tasks, dispatch] = useReducer(tasksReducer, [], load);
  const [text, setText] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const left = tasks.filter((t) => !t.done).length;

  useEffect(() => {
    localStorage.setItem(KEY, JSON.stringify(tasks));
  }, [tasks]);

  function submit(event: FormEvent) {
    event.preventDefault();
    if (!text.trim()) return;
    dispatch({ type: "added", id: Date.now(), text: text.trim() });
    setText("");
    input.current?.focus();
  }

  return (
    <div className="card">
      <h2>Tasks</h2>
      <form className="row" onSubmit={submit}>
        <input ref={input} aria-label="New task" placeholder="New task" value={text} onChange={(e) => setText(e.target.value)} style={{ flex: 1, width: "auto" }} />
        <button type="submit">Add</button>
      </form>
      <ul>
        {tasks.map((task) => (
          <li key={task.id}>
            <input type="checkbox" id={`t${task.id}`} checked={task.done} onChange={() => dispatch({ type: "toggled", id: task.id })} style={{ width: "auto" }} />
            <span>
              <label htmlFor={`t${task.id}`} style={{ display: "inline", fontWeight: 400, textDecoration: task.done ? "line-through" : "none" }}>
                {task.text}
              </label>
            </span>
          </li>
        ))}
      </ul>
      <div className="row">
        <span className="muted" style={{ flex: 1 }}>
          {left} left
        </span>
        <button className="secondary" onClick={() => dispatch({ type: "cleared" })}>
          Clear done
        </button>
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Tasks />);
