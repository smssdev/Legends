// ---------- البيانات ----------
const STORAGE_KEY = "my-tasks";
let tasks = load();
let filter = "all";

function load() {
  const saved = localStorage.getItem(STORAGE_KEY);
  return saved ? JSON.parse(saved) : [];
}

function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
}

// ---------- التغييرات ----------
function addTask(text) {
  tasks.push({ id: Date.now(), text, done: false });
  update();
}

function toggleTask(id) {
  const task = tasks.find((t) => t.id === id);
  task.done = !task.done;
  update();
}

function deleteTask(id) {
  tasks = tasks.filter((t) => t.id !== id);
  update();
}

function clearDone() {
  tasks = tasks.filter((t) => !t.done);
  update();
}

function update() {
  save();
  render();
}

// ---------- العرض ----------
function visibleTasks() {
  if (filter === "active") return tasks.filter((t) => !t.done);
  if (filter === "done") return tasks.filter((t) => t.done);
  return tasks;
}

function taskItem(task) {
  const li = document.createElement("li");
  li.classList.toggle("done", task.done);

  const box = document.createElement("input");
  box.type = "checkbox";
  box.id = `task-${task.id}`;
  box.checked = task.done;
  box.addEventListener("change", () => toggleTask(task.id));

  const label = document.createElement("label");
  label.htmlFor = box.id;
  label.textContent = task.text;

  const remove = document.createElement("button");
  remove.type = "button";
  remove.className = "delete";
  remove.textContent = "احذف";
  remove.setAttribute("aria-label", `احذف: ${task.text}`);
  remove.addEventListener("click", () => deleteTask(task.id));

  li.append(box, label, remove);
  return li;
}

// العربية تغيّر صيغة الكلمة مع العدد
function leftText(count) {
  if (count === 0) return "أنجزت كل مهامك!";
  if (count === 1) return "بقيت مهمة واحدة";
  if (count === 2) return "بقيت مهمتان";
  if (count <= 10) return `بقيت ${count} مهام`;
  return `بقيت ${count} مهمة`;
}

function render() {
  const list = document.querySelector("#tasks");
  list.replaceChildren(...visibleTasks().map(taskItem));

  document.querySelector("#empty").hidden = tasks.length > 0;

  const count = tasks.filter((t) => !t.done).length;
  document.querySelector("#count").textContent = leftText(count);

  const done = tasks.length - count;
  const bar = document.querySelector("#progress");
  bar.max = tasks.length || 1;
  bar.value = done;
  document.querySelector("#progress-text").textContent = `${done} من ${tasks.length} منجزة`;

  for (const button of document.querySelectorAll("[data-filter]")) {
    button.setAttribute("aria-pressed", String(button.dataset.filter === filter));
  }
}

// ---------- الأحداث ----------
document.querySelector("#new-task").addEventListener("submit", (event) => {
  event.preventDefault();
  const input = document.querySelector("#task-text");
  const text = input.value.trim();
  if (text) {
    addTask(text);
    input.value = "";
  }
  input.focus();
});

for (const button of document.querySelectorAll("[data-filter]")) {
  button.addEventListener("click", () => {
    filter = button.dataset.filter;
    render();
  });
}

document.querySelector("#clear").addEventListener("click", clearDone);

render();
