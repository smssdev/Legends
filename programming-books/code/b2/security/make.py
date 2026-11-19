"""Writes the examples of Book 2, chapter "Frontend Security", in English and Arabic.
Run: python3 make.py   The attacks run for real, in Chromium, against pages served on this computer.
Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Security", lang="en", w_comments="Comments", w_hacked="HACKED: the attacker's script ran",
        w_safe="safe: the text was shown, nothing ran", w_way="way", w_ran="script ran?", w_yes="YES", w_no="no",
        w_shown="shown as", w_blocked="Blocked by CSP:", w_app_ok="The app still works:",
        w_header="header", w_missing="missing", w_present="present", w_score="Score",
        w_great="Great comment! **Bold** works too.", w_c1="Served with a strict Content Security Policy",
        w_c2="Only the allowed tags survive; scripts and event handlers are removed",
        w_c3="Checks the security headers a server sends, like the tools security teams use",
    ),
    "ar": dict(
        w_title="الأمان", lang="ar", w_comments="التعليقات", w_hacked="اختُرق: عمل سكربت المهاجم",
        w_safe="آمن: ظهر النص ولم يعمل شيء", w_way="الطريقة", w_ran="عمل السكربت؟", w_yes="نعم", w_no="لا",
        w_shown="عُرض هكذا", w_blocked="منعته CSP:", w_app_ok="التطبيق ما زال يعمل:",
        w_header="الترويسة", w_missing="غائبة", w_present="موجودة", w_score="النتيجة",
        w_great="تعليق رائع! والخط **العريض** يعمل أيضاً.", w_c1="تُقدَّم بسياسة أمان محتوى صارمة",
        w_c2="تبقى الوسوم المسموحة فقط، وتُحذف السكربتات ومعالجات الأحداث",
        w_c3="يفحص ترويسات الأمان التي يرسلها الخادم، كالأدوات التي تستخدمها فرق الأمان",
    ),
}

PLAIN, NODE = {}, {}

PLAIN["lab.ts"] = '''// A small lab: serves pages from this folder with chosen headers, and opens them in Chromium.
import { createReadStream } from "node:fs";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import type { AddressInfo } from "node:net";
import { createRequire } from "node:module";
import { extname, join } from "node:path";

const require = createRequire(import.meta.url);
export type Page = {
  goto(url: string): Promise<unknown>;
  on(event: "console", fn: (m: { text(): string }) => void): void;
  evaluate<T, A>(fn: (arg: A) => T | Promise<T>, arg: A): Promise<T>;
  waitForTimeout(ms: number): Promise<void>;
};
type Browser = { newPage(): Promise<Page>; close(): Promise<void> };
const { chromium } = require("playwright") as { chromium: { launch(): Promise<Browser> } };

const TYPES: Record<string, string> = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript" };

export async function withLab(headers: Record<string, string>, run: (page: Page, base: string) => Promise<void>) {
  const server = createServer((req: IncomingMessage, res: ServerResponse) => {
    const path = join(process.cwd(), new URL(req.url ?? "/", "http://x").pathname);
    res.setHeader("Content-Type", TYPES[extname(path)] ?? "application/octet-stream");
    for (const [k, v] of Object.entries(headers)) res.setHeader(k, v);
    createReadStream(path).on("error", () => res.writeHead(404).end()).pipe(res);
  });
  await new Promise<void>((ready) => server.listen(0, ready));
  const base = `http://localhost:${(server.address() as AddressInfo).port}/`;
  const browser = await chromium.launch();
  try {
    await run(await browser.newPage(), base);
  } finally {
    await browser.close();
    server.close();
  }
}
'''

PLAIN["comments.html"] = '''<!doctype html>
<html lang="{lang}">
  <head><meta charset="utf-8"><title>{w_comments}</title></head>
  <body>
    <h1>{w_comments}</h1>
    <ul id="list"></ul>
  </body>
</html>
'''

NODE["xss.ts"] = '''import { withLab } from "./lab";

// What an attacker types into the comment box
const comment = `<img src="x" onerror="window.hacked = true">{w_nice}`;

await withLab({}, async (page, base) => {
  for (const way of ["innerHTML", "textContent"] as const) {
    await page.goto(base + "comments.html");
    const result = await page.evaluate(
      async ({ way, comment }) => {
        const li = document.createElement("li");
        if (way === "innerHTML") li.innerHTML = comment; // dangerous
        else li.textContent = comment; // safe
        document.querySelector("#list")!.append(li);
        await new Promise((r) => setTimeout(r, 100)); // give the broken image time to fire onerror
        return { ran: (window as { hacked?: boolean }).hacked === true, html: li.innerHTML };
      },
      { way, comment },
    );
    console.log(`${way.padEnd(12)} {w_ran} ${result.ran ? "{w_yes}" : "{w_no}"}`);
  }
});
'''

PLAIN["csp.html"] = '''<!doctype html>
<html lang="{lang}">
  <head><meta charset="utf-8"><title>CSP</title></head>
  <body>
    <h1 id="title">…</h1>
    <!-- An inline script, as an attacker might manage to inject -->
    <script>document.title = "pwned"; window.hacked = true;</script>
    <!-- The app's own script, from a file on the same site -->
    <script src="app.js"></script>
  </body>
</html>
'''
PLAIN["app.js"] = '''document.getElementById("title").textContent = "OK";
'''

NODE["csp.ts"] = '''import { withLab } from "./lab";

// {w_c1}
const policy = "default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'";

await withLab({ "Content-Security-Policy": policy }, async (page, base) => {
  const blocked: string[] = [];
  page.on("console", (m) => {
    if (m.text().includes("Content Security Policy")) blocked.push(m.text().slice(0, 70) + "…");
  });
  await page.goto(base + "csp.html");
  await page.waitForTimeout(200);
  const state = await page.evaluate(
    () => ({ hacked: (window as { hacked?: boolean }).hacked === true, title: document.querySelector("#title")!.textContent }),
    null,
  );
  for (const line of blocked) console.log("{w_blocked}", line);
  console.log("{w_ran}", state.hacked ? "{w_yes}" : "{w_no}");
  console.log("{w_app_ok}", state.title);
});
'''

# ---------------------------------------------------------------- projects
PLAIN["projects/sanitize.html"] = '''<!doctype html>
<html lang="{lang}">
  <head><meta charset="utf-8"><title>Sanitize</title></head>
  <body><div id="out"></div></body>
</html>
'''

NODE["projects/sanitize.ts"] = '''import { withLab } from "../lab";

const inputs = [
  "<b>{w_bold}</b> <i>{w_italic}</i>",
  '<img src=x onerror="window.hacked=true">',
  '<a href="javascript:alert(1)">{w_link}</a>',
  "<script>window.hacked=true</script><p>{w_text}</p>",
];

await withLab({}, async (page, base) => {
  await page.goto(base + "sanitize.html");
  await page.evaluate(async (src) => {
    const s = document.createElement("script");
    s.src = src;
    document.head.append(s);
    await new Promise((r) => (s.onload = r));
  }, base + "purify.js");
  for (const input of inputs) {
    const clean = await page.evaluate(
      (html) =>
        // {w_c2}
        (window as unknown as { DOMPurify: { sanitize(h: string, o: object): string } }).DOMPurify.sanitize(html, {
          ALLOWED_TAGS: ["b", "i", "em", "strong", "a", "p"],
          ALLOWED_ATTR: ["href"],
        }),
      input,
    );
    console.log(`${input}\\n  → ${clean}`);
  }
});
'''

NODE["projects/headers.ts"] = '''import { createServer } from "node:http";
import type { AddressInfo } from "node:net";

// {w_c3}
const RECOMMENDED: Record<string, string> = {
  "content-security-policy": "{w_why_csp}",
  "strict-transport-security": "{w_why_hsts}",
  "x-content-type-options": "{w_why_nosniff}",
  "referrer-policy": "{w_why_ref}",
  "permissions-policy": "{w_why_perm}",
};

export async function check(url: string): Promise<number> {
  const response = await fetch(url);
  let score = 0;
  for (const [name, why] of Object.entries(RECOMMENDED)) {
    const value = response.headers.get(name);
    if (value) score++;
    console.log(`${value ? "✓" : "✗"} ${name.padEnd(26)} ${value ? "{w_present}" : `{w_missing} (${why})`}`);
  }
  console.log(`{w_score}: ${score}/${Object.keys(RECOMMENDED).length}`);
  return score;
}

// A local server that sends only some of the headers, to check against
const server = createServer((_req, res) => {
  res.setHeader("Content-Security-Policy", "default-src 'self'");
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.end("ok");
});
await new Promise<void>((ready) => server.listen(0, ready));
await check(`http://localhost:${(server.address() as AddressInfo).port}/`);
server.close();
'''

NODE["react/escape.tsx"] = '''import { renderToStaticMarkup } from "react-dom/server";

const comment = `<img src="x" onerror="alert('hacked')">`;

// Text in braces is escaped: it is shown, never run
console.log(renderToStaticMarkup(<p>{comment}</p>));

// The name is a warning: this puts raw HTML into the page
console.log(renderToStaticMarkup(<p dangerouslySetInnerHTML={{ __html: comment }} />));

// URLs from users can run code too: React warns, but checking the scheme is your job
const link = "javascript:alert('hacked')";
const safe = /^https?:\\/\\//.test(link) ? link : "#";
console.log(renderToStaticMarkup(<a href={safe}>{w_profile}</a>));
'''

T["en"].update(w_profile="Profile", w_why_csp="stops injected scripts", w_why_hsts="forces HTTPS", w_why_nosniff="stops MIME sniffing",
               w_why_ref="limits what leaks in links", w_why_perm="turns off unused powerful features")
T["ar"].update(w_profile="الملف الشخصي", w_why_csp="توقف السكربتات المحقونة", w_why_hsts="تفرض HTTPS", w_why_nosniff="توقف تخمين نوع الملف",
               w_why_ref="تحدّ مما يتسرب في الروابط", w_why_perm="تطفئ المزايا القوية غير المستخدمة")
T["en"].update(w_nice=" Nice book!", w_bold="Bold", w_italic="italic", w_link="Free gift", w_text="Some text")
T["ar"].update(w_nice=" كتاب جميل!", w_bold="عريض", w_italic="مائل", w_link="هدية مجانية", w_text="بعض النص")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, title_key="w_title")

# DOMPurify, served to the sanitize page as a plain browser script
purify = (HERE.parent / "node_modules" / "dompurify" / "dist" / "purify.js").read_text()
for lang in T:
    (HERE / lang / "projects" / "purify.js").write_text(purify)
