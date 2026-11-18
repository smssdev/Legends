"""Writes the examples of Book 2, chapter "Accessibility (WCAG) in Practice", in English and Arabic.
Run: python3 make.py   The audits run axe-core in a real Chromium through Playwright.
Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Accessibility", lang="en", dir="ltr", w_shop="Bit's shop", w_search="Search", w_search_ph="Search products…",
        w_hero="New: the Bit mug", w_hero_text="Big enough for long coding nights. Only this week: 20% off.",
        w_more="Click here", w_more_ok="Read about the Bit mug", w_news="Newsletter", w_email="Email",
        w_join="Join", w_cart="Cart", w_menu="Menu", w_mug_alt="A white mug with the purple Bit robot on it",
        w_open="Delete account…", w_dlg_title="Delete your account?",
        w_dlg_text="All your orders and saved lists will be removed. This cannot be undone.",
        w_cancel="Cancel", w_delete="Delete", w_actions="Actions for order #1042", w_track="Track", w_invoice="Download invoice",
        w_return="Return items", w_cancel_order="Cancel order",
        w_c_all="Audit every page, and fail the build if any has a violation", w_total="Total violations",
        w_home="Home", w_orders="Your orders",
        w_before="Before", w_after="After", w_issues="issues", w_none="No violations found.",
    ),
    "ar": dict(
        w_title="سهولة الوصول", lang="ar", dir="rtl", w_shop="متجر بِت", w_search="ابحث", w_search_ph="ابحث في المنتجات…",
        w_hero="جديد: كوب بِت", w_hero_text="كبير بما يكفي لليالي البرمجة الطويلة. هذا الأسبوع فقط: خصم 20%.",
        w_more="اضغط هنا", w_more_ok="اقرأ عن كوب بِت", w_news="النشرة البريدية", w_email="البريد الإلكتروني",
        w_join="اشترك", w_cart="السلة", w_menu="القائمة", w_mug_alt="كوب أبيض عليه الروبوت البنفسجي بِت",
        w_open="احذف الحساب…", w_dlg_title="أتحذف حسابك؟",
        w_dlg_text="ستُحذف كل طلباتك وقوائمك المحفوظة، ولا يمكن التراجع عن ذلك.",
        w_cancel="ألغِ", w_delete="احذف", w_actions="إجراءات الطلب #1042", w_track="تتبّع", w_invoice="نزّل الفاتورة",
        w_return="أرجع منتجات", w_cancel_order="ألغِ الطلب",
        w_c_all="افحص كل صفحة، وأفشل البناء إن كانت في أي منها مخالفة", w_total="مجموع المخالفات",
        w_home="الرئيسية", w_orders="طلباتك",
        w_before="قبل", w_after="بعد", w_issues="مشكلات", w_none="لا مخالفات.",
    ),
}

PLAIN, NODE, BROWSER = {}, {}, {}

MUG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 80"><rect width="120" height="80" fill="#eef2ff"/>
<rect x="34" y="18" width="40" height="48" rx="6" fill="#fff" stroke="#c7d2fe" stroke-width="3"/>
<path d="M74 30 h8 a8 8 0 0 1 0 16 h-8" fill="none" stroke="#c7d2fe" stroke-width="4"/>
<circle cx="54" cy="40" r="9" fill="#6366f1"/></svg>
'''
PLAIN["mug.svg"] = MUG

SEARCH_ICON = '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/></svg>'

STYLE = """    <style>
      body { font-family: system-ui, "Segoe UI", Tahoma, sans-serif; margin: 0; padding: 16px; background: #f5f5fb; color: #1e1b2e; }
      header { display: flex; gap: 8px; align-items: center; background: white; padding: 8px 12px; border-radius: 12px; }
      header .brand { font-weight: 800; color: #4338ca; margin-inline-end: auto; }
      button { font: inherit; border: 0; border-radius: 999px; padding: 6px 12px; background: #4338ca; color: white; cursor: pointer; }
      input { font: inherit; padding: 6px 10px; border: 2px solid #c7d2fe; border-radius: 10px; }
      .card { background: white; border-radius: 12px; padding: 12px 14px; margin-top: 10px; display: flex; gap: 12px; align-items: center; }
      .faint { color: #b4b2c6; }
      .icon { padding: 6px 8px; display: inline-flex; }
      :focus-visible { outline: 3px solid #db2777; outline-offset: 2px; }
    </style>
"""

PLAIN["before.html"] = f'''<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>{{w_shop}}</title>
{STYLE}  </head>
  <body>
    <header>
      <div class="brand">{{w_shop}}</div>
      <input placeholder="{{w_search_ph}}">
      <button class="icon">{SEARCH_ICON}</button>
    </header>
    <div class="card">
      <img src="mug.svg" width="120" height="80">
      <div>
        <h4>{{w_hero}}</h4>
        <p class="faint">{{w_hero_text}}</p>
        <a href="#mug">{{w_more}}</a>
      </div>
    </div>
    <div class="card">
      <h4>{{w_news}}</h4>
      <input type="email">
      <div onclick="alert('ok')"><button tabindex="-1">{{w_join}}</button></div>
    </div>
  </body>
</html>
'''

PLAIN["after.html"] = f'''<!doctype html>
<html lang="{{lang}}" dir="{{dir}}">
  <head>
    <meta charset="utf-8">
    <title>{{w_shop}}</title>
{STYLE.replace(".faint { color: #b4b2c6; }", ".faint { color: #5b5873; }")}  </head>
  <body>
    <header>
      <p class="brand">{{w_shop}}</p>
      <form role="search" style="display: flex; gap: 8px; align-items: center">
        <label for="q" class="sr-only">{{w_search}}</label>
        <input id="q" type="search" placeholder="{{w_search_ph}}">
        <button class="icon" aria-label="{{w_search}}">{SEARCH_ICON.replace("<svg ", '<svg aria-hidden="true" ')}</button>
      </form>
    </header>
    <main>
      <h1 class="sr-only">{{w_shop}}</h1>
      <section class="card">
        <img src="mug.svg" width="120" height="80" alt="{{w_mug_alt}}">
        <div>
          <h2>{{w_hero}}</h2>
          <p class="faint">{{w_hero_text}}</p>
          <a href="#mug">{{w_more_ok}}</a>
        </div>
      </section>
      <section class="card">
        <h2>{{w_news}}</h2>
        <form style="display: flex; gap: 8px; align-items: center">
          <label for="email">{{w_email}}</label>
          <input id="email" type="email" autocomplete="email" dir="ltr">
          <button type="submit">{{w_join}}</button>
        </form>
      </section>
    </main>
  </body>
</html>
'''.replace("</style>", ".sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }\n    </style>")

PLAIN["audit-lib.ts"] = '''import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);
// Only the few Playwright functions this script uses
type Page = {
  goto(url: string): Promise<unknown>;
  addScriptTag(options: { path: string }): Promise<unknown>;
  evaluate<T>(fn: () => T | Promise<T>): Promise<T>;
};
type Browser = { newPage(): Promise<Page>; close(): Promise<void> };
const { chromium } = require("playwright") as { chromium: { launch(): Promise<Browser> } };
const axePath = require.resolve("axe-core/axe.min.js");

type Violation = { id: string; impact: string; help: string; nodes: unknown[] };

// Opens a page (a path from the current folder) in a real browser, runs axe-core, and prints what fails
export async function audit(page: string): Promise<number> {
  const browser = await chromium.launch();
  const tab = await browser.newPage();
  await tab.goto(pathToFileURL(resolve(page)).href);
  await tab.addScriptTag({ path: axePath });
  const violations = (await tab.evaluate(() =>
    // @ts-expect-error axe is added to the page by the script tag above
    axe.run({ runOnly: ["wcag2a", "wcag2aa", "wcag21aa", "wcag22aa", "best-practice"] }).then((r) => r.violations),
  )) as Violation[];
  await browser.close();

  for (const v of violations) {
    console.log(`[${v.impact}] ${v.id}: ${v.help} (${v.nodes.length})`);
  }
  return violations.length;
}
'''

NODE["audit-before.ts"] = '''import { audit } from "./audit-lib";

const count = await audit("./before.html");
console.log(`{w_before}: ${count} {w_issues}`);
'''

NODE["audit-after.ts"] = '''import { audit } from "./audit-lib";

const count = await audit("./after.html");
console.log(count === 0 ? "{w_none}" : `{w_after}: ${count} {w_issues}`);
'''

CSS = """.card { background: white; border-radius: 12px; padding: 12px 14px; }
dialog { border: 0; border-radius: 16px; padding: 18px 20px; max-width: 380px; box-shadow: 0 10px 40px rgb(0 0 0 / 0.3); }
dialog::backdrop { background: rgb(30 27 46 / 0.55); }
dialog h2 { margin-top: 0; }
.row { display: flex; gap: 8px; justify-content: flex-end; }
.danger { background: #b91c1c; }
.menu-wrap { position: relative; display: inline-block; }
[role="menu"] { position: absolute; inset-inline-start: 0; top: calc(100% + 6px); min-width: 220px; background: white; border-radius: 12px; padding: 6px; margin: 0; list-style: none; box-shadow: 0 8px 24px rgb(30 27 46 / 0.2); }
[role="menuitem"] { display: block; width: 100%; text-align: start; background: none; color: #1e1b2e; border-radius: 8px; padding: 8px 10px; }
[role="menuitem"]:focus { background: #eef2ff; outline: none; }
[role="menuitem"].danger-text { color: #b91c1c; }
body { min-height: 330px; }
"""

PLAIN["react/ConfirmDialog.tsx"] = '''import { useEffect, useRef, type ReactNode } from "react";

type Props = {
  open: boolean;
  title: string;
  children: ReactNode;
  confirmLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onClose: () => void;
};

export function ConfirmDialog({ open, title, children, confirmLabel, cancelLabel, onConfirm, onClose }: Props) {
  const dialog = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const el = dialog.current;
    if (!el) return;
    if (open && !el.open) el.showModal(); // modal: traps focus, Esc closes, the page behind is inert
    if (!open && el.open) el.close(); // the browser returns the focus to the button that opened it
  }, [open]);

  return (
    <dialog ref={dialog} aria-labelledby="dlg-title" aria-describedby="dlg-text" onClose={onClose}>
      <h2 id="dlg-title">{title}</h2>
      <p id="dlg-text">{children}</p>
      <div className="row">
        <button className="secondary" autoFocus onClick={onClose}>
          {cancelLabel}
        </button>
        <button className="danger" onClick={onConfirm}>
          {confirmLabel}
        </button>
      </div>
    </dialog>
  );
}
'''

BROWSER["react/dialog.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { ConfirmDialog } from "./ConfirmDialog";

function Settings() {
  const [open, setOpen] = useState(false);
  return (
    <div className="card">
      <button className="danger" onClick={() => setOpen(true)}>
        {w_open}
      </button>
      <ConfirmDialog
        open={open}
        title="{w_dlg_title}"
        confirmLabel="{w_delete}"
        cancelLabel="{w_cancel}"
        onConfirm={() => setOpen(false)}
        onClose={() => setOpen(false)}
      >
        {w_dlg_text}
      </ConfirmDialog>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Settings />);
''', CSS)

PLAIN["react/projects/MenuButton.tsx"] = '''import { useEffect, useId, useRef, useState } from "react";
import type { KeyboardEvent } from "react";

type Item = { label: string; danger?: boolean; onSelect: () => void };

export function MenuButton({ label, items }: { label: string; items: Item[] }) {
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(0);
  const id = useId();
  const button = useRef<HTMLButtonElement>(null);
  const itemRefs = useRef<(HTMLButtonElement | null)[]>([]);

  // Move the real focus to the active item whenever it changes
  useEffect(() => {
    if (open) itemRefs.current[active]?.focus();
  }, [open, active]);

  function openAt(index: number) {
    setActive(index);
    setOpen(true);
  }

  function close() {
    setOpen(false);
    button.current?.focus(); // focus goes back where it came from
  }

  function onButtonKey(event: KeyboardEvent) {
    if (event.key === "ArrowDown") (event.preventDefault(), openAt(0));
    if (event.key === "ArrowUp") (event.preventDefault(), openAt(items.length - 1));
  }

  function onMenuKey(event: KeyboardEvent) {
    const last = items.length - 1;
    if (event.key === "ArrowDown") setActive((i) => (i === last ? 0 : i + 1));
    else if (event.key === "ArrowUp") setActive((i) => (i === 0 ? last : i - 1));
    else if (event.key === "Home") setActive(0);
    else if (event.key === "End") setActive(last);
    else if (event.key === "Escape" || event.key === "Tab") close();
    else return;
    event.preventDefault();
  }

  return (
    <div className="menu-wrap">
      <button
        ref={button}
        id={`${id}-button`}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-controls={`${id}-menu`}
        onClick={() => (open ? close() : openAt(0))}
        onKeyDown={onButtonKey}
      >
        {label} ▾
      </button>
      {open && (
        <ul role="menu" id={`${id}-menu`} aria-labelledby={`${id}-button`} onKeyDown={onMenuKey}>
          {items.map((item, i) => (
            <li role="none" key={item.label}>
              <button
                ref={(el) => {
                  itemRefs.current[i] = el;
                }}
                role="menuitem"
                tabIndex={-1}
                className={item.danger ? "danger-text" : undefined}
                onClick={() => {
                  item.onSelect();
                  close();
                }}
              >
                {item.label}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
'''

BROWSER["react/projects/menu.tsx"] = ('''import { createRoot } from "react-dom/client";
import { MenuButton } from "./MenuButton";

const noop = () => {};

createRoot(document.getElementById("root")!).render(
  <div className="card">
    <MenuButton
      label="{w_actions}"
      items={[
        { label: "{w_track}", onSelect: noop },
        { label: "{w_invoice}", onSelect: noop },
        { label: "{w_return}", onSelect: noop },
        { label: "{w_cancel_order}", danger: true, onSelect: noop },
      ]}
    />
  </div>,
);
''', CSS)

NODE["projects/audit-all.ts"] = '''import { audit } from "../audit-lib";

// {w_c_all}
const pages = ["../before.html", "../after.html"];
let total = 0;
for (const page of pages) {
  console.log(`— ${page}`);
  const count = await audit(page);
  if (count === 0) console.log("  {w_none}");
  total += count;
}
console.log(`{w_total}: ${total}`);
process.exitCode = total === 0 ? 0 : 1;
'''

PLAIN["react/projects/RouteFocus.tsx"] = '''import { useEffect, useRef, useState } from "react";
import { useLocation } from "react-router";

// After every navigation: update the title, move the focus to the new h1, and announce the page
export function RouteFocus({ appName }: { appName: string }) {
  const location = useLocation();
  const first = useRef(true);
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (first.current) {
      first.current = false; // the first page load is announced by the browser itself
      return;
    }
    const heading = document.querySelector<HTMLElement>("main h1");
    if (!heading) return;
    document.title = `${heading.textContent} · ${appName}`;
    heading.tabIndex = -1;
    heading.focus();
    setMessage(heading.textContent ?? "");
  }, [location.pathname, appName]);

  return (
    <p role="status" className="sr-only">
      {message}
    </p>
  );
}
'''

BROWSER["react/projects/route-focus.tsx"] = ('''import { createRoot } from "react-dom/client";
import { createMemoryRouter, Link, Outlet, RouterProvider } from "react-router";
import { RouteFocus } from "./RouteFocus";

function Layout() {
  return (
    <>
      <nav className="card" style={{ display: "flex", gap: 12 }}>
        <Link to="/">{w_home}</Link>
        <Link to="/orders">{w_orders}</Link>
      </nav>
      <main>
        <Outlet />
      </main>
      <RouteFocus appName="{w_shop}" />
    </>
  );
}

const router = createMemoryRouter([
  {
    path: "/",
    element: <Layout />,
    children: [
      { index: true, element: <h1>{w_home}</h1> },
      { path: "orders", element: <h1>{w_orders}</h1> },
    ],
  },
]);

createRoot(document.getElementById("root")!).render(<RouterProvider router={router} />);
''', CSS + ".sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); white-space: nowrap; }\nh1:focus { outline: 3px solid #db2777; outline-offset: 4px; }\n")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER, title_key="w_title")
