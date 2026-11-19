import { useState, type FormEvent } from "react";

type Task = { id: number; text: string; done: boolean };

export function Tasks({ initial = [] }: { initial?: Task[] }) {
  const [tasks, setTasks] = useState(initial);
  const [text, setText] = useState("");
  const left = tasks.filter((t) => !t.done).length;

  function add(event: FormEvent) {
    event.preventDefault();
    if (!text.trim()) return;
    setTasks((all) => [...all, { id: all.length + 1, text: text.trim(), done: false }]);
    setText("");
  }

  return (
    <section aria-labelledby="tasks-title">
      <h2 id="tasks-title">Tasks</h2>
      <form onSubmit={add}>
        <input aria-label="New task" value={text} onChange={(e) => setText(e.target.value)} />
        <button type="submit">Add</button>
      </form>
      <ul>
        {tasks.map((t) => (
          <li key={t.id}>
            <label>
              <input
                type="checkbox"
                checked={t.done}
                onChange={() => setTasks((all) => all.map((x) => (x.id === t.id ? { ...x, done: !x.done } : x)))}
              />
              {t.text}
            </label>
          </li>
        ))}
      </ul>
      <p role="status">
        {left} left
      </p>
    </section>
  );
}
