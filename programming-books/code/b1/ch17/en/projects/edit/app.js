// ---------- Data ----------
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

// ---------- Changes ----------
function addTask(text) {
  tasks.push({ id: Date.now(), text, done: false });
  update();
}

function toggleTask(id) {
  const task = tasks.find((t) => t.id === id);
  task.done = !task.done;
  update();
}

function renameTask(id, text) {
  const task = tasks.find((t) => t.id === id);
  task.text = text;
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

// ---------- Display ----------
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
  remove.textContent = "Delete";
  remove.setAttribute("aria-label", `Delete: ${task.text}`);
  remove.addEventListener("click", () => deleteTask(task.id));

  const edit = document.createElement("button");
  edit.type = "button";
  edit.className = "edit";
  edit.textContent = "Edit";
  edit.setAttribute("aria-label", `Edit: ${task.text}`);
  edit.addEventListener("click", () => startEditing(li, task));

  li.append(box, label, edit, remove);
  return li;
}

function startEditing(li, task) {
  const input = document.createElement("input");
  input.className = "edit-text";
  input.value = task.text;
  input.setAttribute("aria-label", "Edit task");

  input.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      const text = input.value.trim();
      if (text) renameTask(task.id, text);
      else render();
    }
    if (event.key === "Escape") render();
  });
  input.addEventListener("blur", () => render());

  li.querySelector("label").replaceWith(input);
  input.focus();
  input.select();
}

function leftText(count) {
  if (count === 0) return "All done!";
  if (count === 1) return "1 task left";
  return `${count} tasks left`;
}

function render() {
  const list = document.querySelector("#tasks");
  list.replaceChildren(...visibleTasks().map(taskItem));

  document.querySelector("#empty").hidden = tasks.length > 0;

  const count = tasks.filter((t) => !t.done).length;
  document.querySelector("#count").textContent = leftText(count);

  for (const button of document.querySelectorAll("[data-filter]")) {
    button.setAttribute("aria-pressed", String(button.dataset.filter === filter));
  }
}

// ---------- Events ----------
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
