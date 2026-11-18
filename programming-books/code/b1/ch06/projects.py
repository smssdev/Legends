"""Writes the solutions of chapter 6's practice projects: chapter 5's project pages, styled.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
import shutil
from pathlib import Path

HERE = Path(__file__).parent
CH5 = HERE.parent / "ch05"

RECIPE = '''body {
  margin: 0;
  padding: 24px;
  font-family: Georgia, "Times New Roman", serif;
  line-height: 1.6;
  color: #3b2f2f;
  background-color: #fdf6ec;
}

h1 {
  font-size: 2rem;
  color: #b45309;
  margin-bottom: 8px;
}

img {
  background-color: white;
  border-radius: 16px;
  padding: 8px;
}

h2 {
  font-family: system-ui, sans-serif;
  font-size: 1.1rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: #92400e;
  border-bottom: 2px solid #fcd34d;
  padding-bottom: 4px;
}

li {
  margin-bottom: 6px;
}

strong {
  color: #b45309;
}
'''

CAFE = ''':root {
  --brown: #6b4423;
  --cream: #fff8ee;
  --gold: #d97706;
}

body {
  margin: 0;
  font-family: system-ui, "Segoe UI", Tahoma, sans-serif;
  color: #2b2118;
  background-color: var(--cream);
  line-height: 1.6;
}

header {
  text-align: center;
  padding: 32px 16px;
  color: white;
  background-color: var(--brown);
}

header h1 {
  margin: 0;
}

nav a {
  display: inline-block;
  margin: 4px;
  padding: 6px 14px;
  border-radius: 999px;
  color: var(--brown);
  background-color: var(--cream);
  text-decoration: none;
  font-weight: 700;
}

main {
  max-width: 560px;
  margin: 24px auto;
  padding: 0 16px;
}

section {
  background-color: white;
  border-radius: 14px;
  padding: 4px 20px 12px;
  margin-bottom: 16px;
  border-top: 4px solid var(--gold);
}

h2 {
  color: var(--brown);
}

a {
  color: var(--gold);
}

footer {
  text-align: center;
  font-size: 0.9rem;
  padding: 16px;
  color: var(--brown);
}
'''

SIGNUP = '''*,
*::before,
*::after {
  box-sizing: border-box;
}

body {
  margin: 0;
  padding: 24px;
  font-family: system-ui, "Segoe UI", Tahoma, sans-serif;
  background-color: #eef2ff;
  color: #1e1b2e;
}

form {
  max-width: 420px;
  padding: 8px 24px 24px;
  background-color: white;
  border-radius: 16px;
  box-shadow: 0 4px 16px rgba(30, 27, 46, 0.1);
}

h1 {
  color: #4338ca;
}

label {
  font-weight: 700;
}

input,
select,
textarea {
  width: 100%;
  margin-top: 4px;
  padding: 8px 12px;
  font: inherit;
  border: 2px solid #c7c5dd;
  border-radius: 10px;
}

input[type="checkbox"] {
  width: auto;
}

input:focus,
select:focus,
textarea:focus {
  outline: none;
  border-color: #4338ca;
  box-shadow: 0 0 0 3px #c7d2fe;
}

button {
  padding: 10px 24px;
  font: inherit;
  font-weight: 700;
  color: white;
  background-color: #4338ca;
  border: 0;
  border-radius: 999px;
}
'''

for lang in ("en", "ar"):
    src = CH5 / lang / "projects"
    d = HERE / lang / "projects"
    d.mkdir(parents=True, exist_ok=True)
    for name, css_name, css in (("recipe.html", "recipe.css", RECIPE), ("cafe.html", "cafe.css", CAFE), ("signup.html", "signup.css", SIGNUP)):
        page = (src / name).read_text().replace("    <title>", f'    <link rel="stylesheet" href="{css_name}">\n    <title>', 1)
        if name == "signup.html":
            page = page.replace("    <h1>", "    <form>\n      <h1>", 1).replace("    <form>\n      <p>", "      <p>", 1)
        (d / name).write_text(page)
        (d / css_name).write_text(css)
    shutil.copy(src / "soup.svg", d / "soup.svg")
print("ok")
