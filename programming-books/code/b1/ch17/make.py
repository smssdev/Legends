"""Writes the chapter 17 project, a daily tasks app, in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(lang='lang="en"', title="My Tasks", h1="My Tasks", sub="Small steps, every day.",
               label="New task", placeholder="e.g. Read chapter 17", add="Add",
               all="All", active="To do", done="Done", clear="Clear done",
               empty="Nothing here yet. Add your first task above!",
               left_fn='''function leftText(count) {
  if (count === 0) return "All done!";
  if (count === 1) return "1 task left";
  return `${count} tasks left`;
}''', delete="Delete",
               filters="Show"),
    "ar": dict(lang='lang="ar" dir="rtl"', title="مهامي", h1="مهامي", sub="خطوات صغيرة، كل يوم.",
               label="مهمة جديدة", placeholder="مثلاً: اقرأ الفصل 17", add="أضف",
               all="الكل", active="المتبقية", done="المنجزة", clear="احذف المنجزة",
               empty="لا شيء هنا بعد. أضف أول مهمة لك في الأعلى!",
               left_fn='''// العربية تغيّر صيغة الكلمة مع العدد
function leftText(count) {
  if (count === 0) return "أنجزت كل مهامك!";
  if (count === 1) return "بقيت مهمة واحدة";
  if (count === 2) return "بقيت مهمتان";
  if (count <= 10) return `بقيت ${count} مهام`;
  return `بقيت ${count} مهمة`;
}''', delete="احذف",
               filters="اعرض"),
}

CSS = '''*,
*::before,
*::after {
  box-sizing: border-box;
}

:root {
  --brand: #4338ca;
  --accent: #db2777;
  --ink: #1e1b2e;
  --muted: #5b5873;
  --soft: #eef2ff;
}

body {
  margin: 0;
  font-family: system-ui, "Segoe UI", Tahoma, sans-serif;
  color: var(--ink);
  background: var(--soft);
}

.app {
  max-width: 560px;
  margin: 32px auto;
  padding: 24px;
  background: white;
  border-radius: 20px;
  box-shadow: 0 4px 20px rgba(30, 27, 46, 0.1);
}

h1 {
  margin: 0;
  color: var(--brand);
}

.subtitle {
  margin: 4px 0 20px;
  color: var(--muted);
}

form {
  display: flex;
  gap: 8px;
}

form input {
  flex: 1;
  padding: 10px 14px;
  font: inherit;
  border: 2px solid #c7c5dd;
  border-radius: 12px;
}

button {
  font: inherit;
  cursor: pointer;
  border: 0;
  border-radius: 999px;
}

.primary {
  padding: 10px 20px;
  color: white;
  background: var(--brand);
}

.filters {
  display: flex;
  gap: 6px;
  margin: 18px 0 8px;
}

.filters button {
  padding: 6px 14px;
  color: var(--brand);
  background: var(--soft);
}

.filters button[aria-pressed="true"] {
  color: white;
  background: var(--brand);
}

ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

li {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 4px;
  border-bottom: 1px solid var(--soft);
}

li label {
  flex: 1;
}

li.done label {
  color: var(--muted);
  text-decoration: line-through;
}

li input {
  width: 20px;
  height: 20px;
  accent-color: var(--brand);
}

.delete {
  padding: 4px 12px;
  color: var(--accent);
  background: #fdf0f6;
}

.empty {
  color: var(--muted);
  text-align: center;
  padding: 24px 0;
}

footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 14px;
  color: var(--muted);
}

footer button {
  padding: 4px 10px;
  color: var(--muted);
  background: none;
  text-decoration: underline;
}

:focus-visible {
  outline: 3px solid var(--accent);
  outline-offset: 2px;
}
'''


def files(t, lang):
    en = lang == "en"
    c = (lambda e, a: e if en else a)
    html = f'''<!doctype html>
<html {t["lang"]}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{t["title"]}</title>
    <link rel="stylesheet" href="style.css">
  </head>
  <body>
    <main class="app">
      <h1>{t["h1"]}</h1>
      <p class="subtitle">{t["sub"]}</p>

      <form id="new-task">
        <label for="task-text" class="visually-hidden">{t["label"]}</label>
        <input id="task-text" type="text" placeholder="{t["placeholder"]}" required>
        <button class="primary" type="submit">{t["add"]}</button>
      </form>

      <div class="filters" role="group" aria-label="{t["filters"]}">
        <button type="button" data-filter="all" aria-pressed="true">{t["all"]}</button>
        <button type="button" data-filter="active" aria-pressed="false">{t["active"]}</button>
        <button type="button" data-filter="done" aria-pressed="false">{t["done"]}</button>
      </div>

      <ul id="tasks"></ul>
      <p class="empty" id="empty">{t["empty"]}</p>

      <footer>
        <span id="count" aria-live="polite"></span>
        <button type="button" id="clear">{t["clear"]}</button>
      </footer>
    </main>
    <script src="app.js"></script>
  </body>
</html>
'''
    js = f'''// ---------- {c("Data", "البيانات")} ----------
const STORAGE_KEY = "my-tasks";
let tasks = load();
let filter = "all";

function load() {{
  const saved = localStorage.getItem(STORAGE_KEY);
  return saved ? JSON.parse(saved) : [];
}}

function save() {{
  localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
}}

// ---------- {c("Changes", "التغييرات")} ----------
function addTask(text) {{
  tasks.push({{ id: Date.now(), text, done: false }});
  update();
}}

function toggleTask(id) {{
  const task = tasks.find((t) => t.id === id);
  task.done = !task.done;
  update();
}}

function deleteTask(id) {{
  tasks = tasks.filter((t) => t.id !== id);
  update();
}}

function clearDone() {{
  tasks = tasks.filter((t) => !t.done);
  update();
}}

function update() {{
  save();
  render();
}}

// ---------- {c("Display", "العرض")} ----------
function visibleTasks() {{
  if (filter === "active") return tasks.filter((t) => !t.done);
  if (filter === "done") return tasks.filter((t) => t.done);
  return tasks;
}}

function taskItem(task) {{
  const li = document.createElement("li");
  li.classList.toggle("done", task.done);

  const box = document.createElement("input");
  box.type = "checkbox";
  box.id = `task-${{task.id}}`;
  box.checked = task.done;
  box.addEventListener("change", () => toggleTask(task.id));

  const label = document.createElement("label");
  label.htmlFor = box.id;
  label.textContent = task.text;

  const remove = document.createElement("button");
  remove.type = "button";
  remove.className = "delete";
  remove.textContent = "{t["delete"]}";
  remove.setAttribute("aria-label", `{t["delete"]}: ${{task.text}}`);
  remove.addEventListener("click", () => deleteTask(task.id));

  li.append(box, label, remove);
  return li;
}}

{t["left_fn"]}

function render() {{
  const list = document.querySelector("#tasks");
  list.replaceChildren(...visibleTasks().map(taskItem));

  document.querySelector("#empty").hidden = tasks.length > 0;

  const count = tasks.filter((t) => !t.done).length;
  document.querySelector("#count").textContent = leftText(count);

  for (const button of document.querySelectorAll("[data-filter]")) {{
    button.setAttribute("aria-pressed", String(button.dataset.filter === filter));
  }}
}}

// ---------- {c("Events", "الأحداث")} ----------
document.querySelector("#new-task").addEventListener("submit", (event) => {{
  event.preventDefault();
  const input = document.querySelector("#task-text");
  const text = input.value.trim();
  if (text) {{
    addTask(text);
    input.value = "";
  }}
  input.focus();
}});

for (const button of document.querySelectorAll("[data-filter]")) {{
  button.addEventListener("click", () => {{
    filter = button.dataset.filter;
    render();
  }});
}}

document.querySelector("#clear").addEventListener("click", clearDone);

render();
'''
    css = CSS + '''
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
'''
    return {"index.html": html, "style.css": css, "app.js": js}


for lang, t in T.items():
    d = HERE / lang
    d.mkdir(exist_ok=True)
    for name, text in files(t, lang).items():
        (d / name).write_text(text)
print("ok")
