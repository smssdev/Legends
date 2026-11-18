"""Writes chapter 17's practice projects: three upgrades of the tasks app, in English and Arabic.
Each project is a copy of the finished app in its own folder, with the upgrade applied.
Run: python3 projects.py   (after make.py; the folders go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(
        of="of", done_word="done", edit="Edit", edit_label="Edit task",
        p_css_note="Progress", lang_button="العربية",
    ),
    "ar": dict(
        of="من", done_word="منجزة", edit="عدّل", edit_label="عدّل المهمة",
        p_css_note="التقدّم", lang_button="English",
    ),
}


def must(text, old, new):
    assert old in text, old
    return text.replace(old, new, 1)


def progress(lang, t, html, css, js):
    html = must(html, '      <ul id="tasks"></ul>', '''      <div class="progress">
        <progress id="progress" max="1" value="0" aria-labelledby="progress-text"></progress>
        <span id="progress-text"></span>
      </div>

      <ul id="tasks"></ul>''')
    css += '''
.progress {
  display: flex;
  align-items: center;
  gap: 10px;
  margin: 8px 0 4px;
  color: var(--muted);
  font-size: 0.9rem;
}

.progress progress {
  flex: 1;
  height: 10px;
  accent-color: var(--brand);
}
'''
    js = must(js, '''  document.querySelector("#count").textContent = leftText(count);
''', f'''  document.querySelector("#count").textContent = leftText(count);

  const done = tasks.length - count;
  const bar = document.querySelector("#progress");
  bar.max = tasks.length || 1;
  bar.value = done;
  document.querySelector("#progress-text").textContent = `${{done}} {t["of"]} ${{tasks.length}} {t["done_word"]}`;
''')
    return html, css, js


def editing(lang, t, html, css, js):
    css += '''
.edit {
  padding: 4px 12px;
  color: var(--brand);
  background: var(--soft);
}

li input.edit-text {
  flex: 1;
  width: auto;
  height: auto;
  padding: 6px 10px;
  font: inherit;
  border: 2px solid var(--brand);
  border-radius: 10px;
}
'''
    js = must(js, '''function deleteTask(id) {''', '''function renameTask(id, text) {
  const task = tasks.find((t) => t.id === id);
  task.text = text;
  update();
}

function deleteTask(id) {''')
    js = must(js, '''  li.append(box, label, remove);''', f'''  const edit = document.createElement("button");
  edit.type = "button";
  edit.className = "edit";
  edit.textContent = "{t["edit"]}";
  edit.setAttribute("aria-label", `{t["edit"]}: ${{task.text}}`);
  edit.addEventListener("click", () => startEditing(li, task));

  li.append(box, label, edit, remove);''')
    js = must(js, '''function leftText(count) {''', f'''function startEditing(li, task) {{
  const input = document.createElement("input");
  input.className = "edit-text";
  input.value = task.text;
  input.setAttribute("aria-label", "{t["edit_label"]}");

  input.addEventListener("keydown", (event) => {{
    if (event.key === "Enter") {{
      const text = input.value.trim();
      if (text) renameTask(task.id, text);
      else render();
    }}
    if (event.key === "Escape") render();
  }});
  input.addEventListener("blur", () => render());

  li.querySelector("label").replaceWith(input);
  input.focus();
  input.select();
}}

function leftText(count) {{''')
    return html, css, js


I18N_TEXTS = '''const TEXTS = {
  en: {
    title: "My Tasks",
    subtitle: "Small steps, every day.",
    newTask: "New task",
    placeholder: "e.g. Read chapter 17",
    add: "Add",
    show: "Show",
    all: "All",
    active: "To do",
    done: "Done",
    empty: "Nothing here yet. Add your first task above!",
    clear: "Clear done",
    delete: "Delete",
    switchTo: "العربية",
    left: (count) => {
      if (count === 0) return "All done!";
      if (count === 1) return "1 task left";
      return `${count} tasks left`;
    },
  },
  ar: {
    title: "مهامي",
    subtitle: "خطوات صغيرة، كل يوم.",
    newTask: "مهمة جديدة",
    placeholder: "مثلاً: اقرأ الفصل 17",
    add: "أضف",
    show: "اعرض",
    all: "الكل",
    active: "المتبقية",
    done: "المنجزة",
    empty: "لا شيء هنا بعد. أضف أول مهمة لك في الأعلى!",
    clear: "احذف المنجزة",
    delete: "احذف",
    switchTo: "English",
    left: (count) => {
      if (count === 0) return "أنجزت كل مهامك!";
      if (count === 1) return "بقيت مهمة واحدة";
      if (count === 2) return "بقيت مهمتان";
      if (count <= 10) return `بقيت ${count} مهام`;
      return `بقيت ${count} مهمة`;
    },
  },
};

const LANG_KEY = "my-tasks-language";
let language = localStorage.getItem(LANG_KEY) || "__DEFAULT__";

function t(key) {
  return TEXTS[language][key];
}

function applyLanguage() {
  document.documentElement.lang = language;
  document.documentElement.dir = language === "ar" ? "rtl" : "ltr";
  document.title = t("title");

  for (const element of document.querySelectorAll("[data-text]")) {
    element.textContent = t(element.dataset.text);
  }
  document.querySelector("#task-text").placeholder = t("placeholder");
  document.querySelector(".filters").setAttribute("aria-label", t("show"));
  const button = document.querySelector("#language");
  button.textContent = t("switchTo");
  button.lang = language === "en" ? "ar" : "en";
  render();
}

function switchLanguage() {
  language = language === "en" ? "ar" : "en";
  localStorage.setItem(LANG_KEY, language);
  applyLanguage();
}

'''


def languages(lang, t, html, css, js):
    en_html = (HERE / "en" / "index.html").read_text()
    html = en_html.replace('<html lang="en">', '<html lang="en" dir="ltr">')
    pairs = [
        ('<h1>My Tasks</h1>', '<h1 data-text="title">My Tasks</h1>'),
        ('<p class="subtitle">Small steps', '<p class="subtitle" data-text="subtitle">Small steps'),
        ('class="visually-hidden">New task', 'class="visually-hidden" data-text="newTask">New task'),
        ('type="submit">Add', 'type="submit" data-text="add">Add'),
        ('aria-pressed="true">All', 'aria-pressed="true" data-text="all">All'),
        ('aria-pressed="false">To do', 'aria-pressed="false" data-text="active">To do'),
        ('aria-pressed="false">Done', 'aria-pressed="false" data-text="done">Done'),
        ('id="empty">Nothing', 'id="empty" data-text="empty">Nothing'),
        ('id="clear">Clear done', 'id="clear" data-text="clear">Clear done'),
        ('      <h1 data-text="title">My Tasks</h1>', '''      <header class="top">
        <h1 data-text="title">My Tasks</h1>
        <button type="button" id="language" lang="ar">العربية</button>
      </header>'''),
    ]
    for old, new in pairs:
        html = must(html, old, new)
    css = (HERE / "en" / "style.css").read_text() + '''
.top {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

#language {
  padding: 6px 14px;
  color: var(--brand);
  background: var(--soft);
}
'''
    js = (HERE / "en" / "app.js").read_text()
    js = must(js, "// ---------- Data ----------\n",
              "// ---------- Texts ----------\n" + I18N_TEXTS.replace("__DEFAULT__", lang) + "// ---------- Data ----------\n")
    js = must(js, '''  remove.textContent = "Delete";
  remove.setAttribute("aria-label", `Delete: ${task.text}`);''', '''  remove.textContent = t("delete");
  remove.setAttribute("aria-label", `${t("delete")}: ${task.text}`);''')
    js = must(js, '''function leftText(count) {
  if (count === 0) return "All done!";
  if (count === 1) return "1 task left";
  return `${count} tasks left`;
}

''', "")
    js = must(js, "leftText(count)", 't("left")(count)')
    js = must(js, '''document.querySelector("#clear").addEventListener("click", clearDone);

render();''', '''document.querySelector("#clear").addEventListener("click", clearDone);
document.querySelector("#language").addEventListener("click", switchLanguage);

applyLanguage();''')
    return html, css, js


for lang, t in T.items():
    base = HERE / lang
    for name, upgrade in [("progress", progress), ("edit", editing), ("languages", languages)]:
        html, css, js = upgrade(lang, t, (base / "index.html").read_text(), (base / "style.css").read_text(), (base / "app.js").read_text())
        d = base / "projects" / name
        d.mkdir(parents=True, exist_ok=True)
        (d / "index.html").write_text(html)
        (d / "style.css").write_text(css)
        (d / "app.js").write_text(js)
print("ok")
