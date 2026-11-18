const form = document.querySelector("#join");
const summary = document.querySelector("#summary");
const done = document.querySelector("#done");

const rules = [
  { id: "name", message: "Enter your full name.", ok: (value) => value.trim().length >= 2 },
  { id: "email", message: "Enter an email like name@example.com.", ok: (value) => /^\S+@\S+\.\S+$/.test(value) },
];

function showError(field, message) {
  const input = document.querySelector("#" + field);
  const error = document.querySelector("#" + field + "-error");
  error.textContent = message;
  input.setAttribute("aria-invalid", message ? "true" : "false");
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  const problems = [];

  for (const rule of rules) {
    const value = document.querySelector("#" + rule.id).value;
    if (rule.ok(value)) {
      showError(rule.id, "");
    } else {
      showError(rule.id, rule.message);
      problems.push(rule);
    }
  }

  if (problems.length === 0) {
    summary.hidden = true;
    done.textContent = "Welcome to the club!";
    return;
  }

  const title = document.createElement("p");
  title.textContent = problems.length === 1 ? problems[0].message : "Please fix 2 problems:";
  const list = document.createElement("ul");
  for (const problem of problems) {
    const link = document.createElement("a");
    link.href = "#" + problem.id;
    link.textContent = problem.message;
    const item = document.createElement("li");
    item.append(link);
    list.append(item);
  }
  summary.replaceChildren(title);
  if (problems.length > 1) summary.append(list);
  summary.hidden = false;
  summary.focus();
});
