"""Writes the examples of Book 2, chapter "Modules, Tooling and Build Systems", in English and Arabic.
Run: python3 make.py   (needs the internet once: it creates a real Vite project in a temporary folder,
runs every command the chapter shows, and saves what the tools really printed)

The module examples (modules/*.mjs) are run by the book's build. The terminal sessions (*.sh) are
recorded here, once, because they install packages; run this script again to refresh them.
"""
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).parent

T = {
    "en": dict(
        c_create="Create a project from the vanilla TypeScript template", c_install="Download the packages it needs",
        c_tree="What the template created", c_peer="Add a linter and a formatter", c_fix="Choose a TypeScript that typescript-eslint supports",
        c_ls="The direct dependencies, and their exact versions", c_lint="Check the code", c_check="Is the code formatted?",
        c_write="Format every file", c_scripts="Name the commands the team will run",
        c_check1="Run every check before committing", c_check2="After fixing the problem", c_env="Two settings files",
        c_grep="Which address went into the built file?", api="API:",
        cfg="All settings are read and checked in one place", missing="VITE_API_URL is not set: add it to a .env file", c_build="Build the site for production", c_split="Build again after adding a lazy import",
        title="Bit's shop", products="Products", report="Show report", total="Total", currency="EGP", loading="Loading the report…",
        p1="Book", p2="Mug", p3="Sticker", unused="Hello",
        m_c1="Named exports: any number per module", m_c2="One default export per module, at most",
        m_c3="This line runs once, however many modules import this file", m_main="Imported:",
        m_cart="Cart total:", m_count="Times the price module was loaded:",
    ),
    "ar": dict(
        c_create="أنشئ مشروعاً من قالب TypeScript البسيط", c_install="نزّل الحزم التي يحتاجها",
        c_tree="ما أنشأه القالب", c_peer="أضف مدققاً للكود ومنسّقاً له", c_fix="اختر نسخة TypeScript يدعمها typescript-eslint",
        c_ls="الاعتماديات المباشرة، ونسخها بالضبط", c_lint="افحص الكود", c_check="هل الكود منسّق؟",
        c_write="نسّق كل الملفات", c_scripts="سمِّ الأوامر التي سيشغّلها الفريق",
        c_check1="شغّل كل الفحوص قبل الـ commit", c_check2="بعد إصلاح المشكلة", c_env="ملفا إعدادات",
        c_grep="أي عنوان دخل الملف المبني؟", api="الواجهة البرمجية:",
        cfg="كل الإعدادات تُقرأ وتُفحص في مكان واحد", missing="VITE_API_URL غير مضبوط: أضفه إلى ملف .env", c_build="ابنِ الموقع للإنتاج", c_split="ابنِ من جديد بعد إضافة استيراد كسول",
        title="متجر بِت", products="المنتجات", report="اعرض التقرير", total="المجموع", currency="جنيهاً", loading="جارٍ تحميل التقرير…",
        p1="كتاب", p2="كوب", p3="ملصق", unused="مرحباً",
        m_c1="تصديرات مسماة: أي عدد في الوحدة", m_c2="تصدير افتراضي واحد في الوحدة على الأكثر",
        m_c3="هذا السطر يعمل مرة واحدة، مهما كان عدد الوحدات التي تستورد هذا الملف", m_main="المستورد:",
        m_cart="مجموع السلة:", m_count="عدد مرات تحميل وحدة الأسعار:",
    ),
}


def fill(text, t):
    return re.sub(r"(?<!\$)\{(\w+)\}", lambda m: t.get(m.group(1), m.group(0)), text)


# ---------------------------------------------------------------- module examples, run by the book
MODULES = {
    "modules/prices.mjs": '''// {m_c3}
globalThis.priceLoads = (globalThis.priceLoads ?? 0) + 1;

// {m_c1}
export const VAT = 0.14;
export function withVat(price) {
  return Math.round(price * (1 + VAT) * 100) / 100;
}

// {m_c2}
export default function formatPrice(value) {
  return `${value.toFixed(2)} {currency}`;
}
''',
    "modules/cart.mjs": '''import formatPrice, { withVat } from "./prices.mjs";

export function cartTotal(prices) {
  return formatPrice(withVat(prices.reduce((sum, p) => sum + p, 0)));
}
''',
    "modules/index.mjs": '''// {barrel}
export { cartTotal } from "./cart.mjs";
export { default as formatPrice, VAT } from "./prices.mjs";
''',
    "modules/main.mjs": '''import { cartTotal, formatPrice, VAT } from "./index.mjs";
import * as prices from "./prices.mjs";

console.log("{m_main}", typeof cartTotal, typeof formatPrice, VAT);
console.log("{m_cart}", cartTotal([25, 8, 3]));
console.log(prices.withVat(100), prices.default(9));
console.log("{m_count}", globalThis.priceLoads);
''',
}
T["en"]["barrel"] = "A \"barrel\": one entry point that re-exports the public parts"
T["ar"]["barrel"] = "«برميل»: مدخل واحد يعيد تصدير الأجزاء العامة"

# ---------------------------------------------------------------- the app inside the Vite project
APP = {
    "index.html": '''<!doctype html>
<html lang="{lang}"{dir}>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{title}</title>
  </head>
  <body>
    <main id="app"></main>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
''',
    "src/products.ts": '''export type Product = { id: number; name: string; price: number };

export const products: Product[] = [
  { id: 1, name: "{p1}", price: 25 },
  { id: 2, name: "{p2}", price: 8 },
  { id: 3, name: "{p3}", price: 3 },
];
''',
    "src/format.ts": '''export function formatPrice(value: number): string {
  return `${value.toFixed(2)} {currency}`;
}
''',
    "src/main.ts": '''import "./style.css";
import { products } from "./products.ts";
import { formatPrice } from "./format.ts";

const app = document.querySelector<HTMLElement>("#app")!;

const heading = document.createElement("h1");
heading.textContent = "{title}";
const list = document.createElement("ul");
for (const product of products) {
  const item = document.createElement("li");
  item.textContent = `${product.name}: ${formatPrice(product.price)}`;
  list.append(item);
}
app.append(heading, list);
''',
    "src/style.css": '''body { font-family: system-ui, sans-serif; margin: 2rem; }
h1 { color: #4338ca; }
''',
}

SPLIT_MAIN = APP["src/main.ts"] + '''
const button = document.createElement("button");
button.textContent = "{report}";
button.addEventListener("click", async () => {
  button.textContent = "{loading}";
  const { buildReport } = await import("./report.ts");
  app.append(buildReport(products));
  button.remove();
});
app.append(button);
'''

REPORT = '''import type { Product } from "./products.ts";
import { formatPrice } from "./format.ts";

// {big}
export function buildReport(items: Product[]): HTMLElement {
  const table = document.createElement("table");
  for (const item of items) {
    const row = table.insertRow();
    row.insertCell().textContent = item.name;
    row.insertCell().textContent = formatPrice(item.price);
  }
  const total = items.reduce((sum, item) => sum + item.price, 0);
  const foot = table.createTFoot().insertRow();
  foot.insertCell().textContent = "{total}";
  foot.insertCell().textContent = formatPrice(total);
  return table;
}
'''
T["en"]["big"] = "Imagine a big charting library here: only people who press the button download it"
T["ar"]["big"] = "تخيّل هنا مكتبة رسوم بيانية كبيرة: لا ينزّلها إلا من يضغط الزر"

CONFIG = '''// {cfg}
const apiUrl = import.meta.env.VITE_API_URL;
if (!apiUrl) throw new Error("{missing}");

export const config = {
  apiUrl,
  isProduction: import.meta.env.PROD,
} as const;
'''

BAD = '''const greeting = "{unused}";

export function total(prices: any[]) {
  let sum = 0;
  for (const price of prices) {
    if (price == null) continue;
    sum += price;
  }
  return sum;
}
'''

ESLINT_CONFIG = '''import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist"] },
  js.configs.recommended,
  tseslint.configs.recommended,
  {
    rules: {
      eqeqeq: "error",
      "no-console": "warn",
    },
  },
);
'''

PRETTIER = '''{
  "printWidth": 100
}
'''


class Session:
    def __init__(self, cwd, home):
        self.cwd, self.home, self.lines = cwd, home, []

    def note(self, text):
        self.lines.append(f"# {text}")

    def run(self, cmd, comment=None, keep=None, check=True):
        if comment:
            self.note(comment)
        self.lines.append(f"$ {cmd}")
        if cmd.startswith("cd "):
            self.cwd = self.cwd / cmd[3:]
            return
        env = dict(os.environ, NO_COLOR="1", FORCE_COLOR="0", npm_config_fund="false", npm_config_update_notifier="false")
        r = subprocess.run(cmd, shell=True, cwd=self.cwd, capture_output=True, text=True, env=env, timeout=600)
        if check and r.returncode not in (0, 1):
            raise SystemExit(f"{cmd} failed:\n{r.stdout}\n{r.stderr}")
        out = re.sub(r"\x1b\[[0-9;]*m", "", r.stdout + r.stderr)
        lines = [l.rstrip() for l in out.splitlines()]
        lines = [l for l in lines if l.strip() and l.strip() not in ("|", "│", "◇", "—", ">")]
        lines = [l for l in lines if not l.startswith("> ")]
        if keep:
            lines = keep(lines)
        self.lines.extend(lines)

    def text(self):
        return "\n".join(self.lines).replace(str(self.home), "~/code") + "\n"


def write_tree(root, files, t):
    for name, text in files.items():
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(fill(text, t))


def record(lang):
    t = dict(T[lang], lang=lang, dir=' dir="rtl"' if lang == "ar" else "")
    out = HERE / lang
    home = Path(tempfile.mkdtemp())
    try:
        s = Session(home, home)
        s.run("npm create vite@latest my-shop -- --template vanilla-ts --no-interactive", t["c_create"],
              keep=lambda ls: [l.lstrip("o◇│ ") for l in ls if "Scaffolding" in l or "create-vite" in l])
        s.run("cd my-shop")
        s.run("npm install", t["c_install"], keep=lambda ls: [l for l in ls if l.startswith("added")])
        shop = home / "my-shop"
        for f in ("src/counter.ts", "src/typescript.svg", "public/vite.svg", "src/assets/hero.png", "src/assets/vite.svg",
                  "src/assets/typescript.svg", "public/icons.svg", "public/favicon.svg"):
            (shop / f).unlink(missing_ok=True)
        write_tree(shop, APP, t)
        s.run("find . -path ./node_modules -prune -o -type f -print | sort", t["c_tree"])
        (out / "create.sh").write_text(s.text())
        (out / "package.json").write_text((shop / "package.json").read_text())
        (out / "tsconfig.json").write_text((shop / "tsconfig.json").read_text())

        s = Session(shop, home)
        s.run("npm install -D eslint @eslint/js typescript-eslint prettier", t["c_peer"],
              keep=lambda ls: [l for l in ls if l.startswith(("npm error code", "npm error ERESOLVE", "npm error Found", "npm error Could not", "npm error peer"))], check=False)
        s.run("npm install -D typescript@~6.0.0 eslint @eslint/js typescript-eslint prettier", t["c_fix"],
              keep=lambda ls: [l for l in ls if l.startswith(("added", "changed", "removed"))])
        s.run("npm ls --depth=0", t["c_ls"], keep=lambda ls: ls[1:])
        s.run('npm pkg set scripts.lint="eslint src" scripts.format="prettier --write src" '
              'scripts.check="tsc && eslint src && prettier --check src"', t["c_scripts"])
        (out / "install.sh").write_text(s.text())
        (out / "package.final.json").write_text((shop / "package.json").read_text())

        (shop / "eslint.config.js").write_text(ESLINT_CONFIG)
        (shop / ".prettierrc.json").write_text(PRETTIER)
        (shop / "src/total.ts").write_text(fill(BAD, t))
        s = Session(shop, home)
        s.run("npx eslint src", t["c_lint"], check=False)
        (out / "lint.sh").write_text(s.text())
        (out / "eslint.config.js").write_text(ESLINT_CONFIG)
        (out / "total.ts").write_text(fill(BAD, t))
        (shop / "src/total.ts").unlink()

        (shop / "src/format.ts").write_text('export function formatPrice(value:number):string{return `${value.toFixed(2)} '
                                           + t["currency"] + '`}\n')
        s = Session(shop, home)
        s.run("npx prettier --check src", t["c_check"], check=False)
        s.run("npx prettier --write src", t["c_write"])
        s.run("cat src/format.ts")
        (out / "format.sh").write_text(s.text())

        s = Session(shop, home)
        s.run("npm run build", t["c_build"], keep=lambda ls: [l for l in ls if l.startswith(("dist", "✓"))])
        (out / "build.sh").write_text(s.text())

        (shop / "src/main.ts").write_text(fill(SPLIT_MAIN, t))
        (shop / "src/report.ts").write_text(fill(REPORT, t))
        s = Session(shop, home)
        s.run("npm run build", t["c_split"], keep=lambda ls: [l for l in ls if l.startswith(("dist", "✓"))])
        (out / "split.sh").write_text(s.text())
        (out / "main.ts").write_text(fill(SPLIT_MAIN, t))
        (out / "report.ts").write_text(fill(REPORT, t))

        # Project: one command that runs every check, failing and then passing.
        (shop / "src/discount.ts").write_text("export function discount(price: number, percent: number) {\n"
                                             "  var result = price - (price * percent) / 100;\n  return result;\n}\n")
        s = Session(shop, home)
        s.run("npm run check", t["c_check1"], check=False,
              keep=lambda ls: [l for l in ls if not l.startswith(("npm error", "Checking formatting"))])
        (shop / "src/discount.ts").write_text("export function discount(price: number, percent: number) {\n"
                                             "  return price - (price * percent) / 100;\n}\n")
        s.run("npm run check", t["c_check2"], keep=lambda ls: [l for l in ls if not l.startswith("Checking formatting")])
        (out / "projects").mkdir(exist_ok=True)
        (out / "projects/check.sh").write_text(s.text())

        # Project: settings that differ between development and production.
        (shop / ".env.development").write_text("VITE_API_URL=http://localhost:8000\n")
        (shop / ".env.production").write_text("VITE_API_URL=https://api.bits-shop.example\n")
        (shop / "src/config.ts").write_text(fill(CONFIG, t))
        (shop / "src/main.ts").write_text(fill(SPLIT_MAIN, t).replace('import { formatPrice } from "./format.ts";',
                                          'import { formatPrice } from "./format.ts";\nimport { config } from "./config.ts";') +
                                          'console.info("{api}", config.apiUrl);\n'.replace("{api}", t["api"]))
        s = Session(shop, home)
        s.run("cat .env.development .env.production", t["c_env"])
        s.run("npm run build", t["c_build"], keep=lambda ls: [l for l in ls if l.startswith("✓ built")])
        s.run("grep -o 'https://[a-z.-]*example' dist/assets/index-*.js", t["c_grep"])
        (out / "projects/env.sh").write_text(s.text())
        (out / "projects/config.ts").write_text(fill(CONFIG, t))

        # The finished project, for the screenshot and for readers.
        site = out / "my-shop"
        shutil.rmtree(site, ignore_errors=True)
        shutil.copytree(shop / "dist", site)
    finally:
        shutil.rmtree(home, ignore_errors=True)


for lang in ("en", "ar"):
    write_tree(HERE / lang, MODULES, dict(T[lang], currency=T[lang]["currency"]))
    record(lang)
    print("recorded", lang)
