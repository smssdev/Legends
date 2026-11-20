// ar/lab.ts
import { createReadStream } from "node:fs";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { extname, join } from "node:path";
var require2 = createRequire(import.meta.url);
var { chromium } = require2("playwright");
var TYPES = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript" };
async function withLab(headers, run) {
  const server = createServer((req, res) => {
    const path = join(process.cwd(), new URL(req.url ?? "/", "http://x").pathname);
    res.setHeader("Content-Type", TYPES[extname(path)] ?? "application/octet-stream");
    for (const [k, v] of Object.entries(headers)) res.setHeader(k, v);
    createReadStream(path).on("error", () => res.writeHead(404).end()).pipe(res);
  });
  await new Promise((ready) => server.listen(0, ready));
  const base = `http://localhost:${server.address().port}/`;
  const browser = await chromium.launch();
  try {
    await run(await browser.newPage(), base);
  } finally {
    await browser.close();
    server.close();
  }
}

// ar/projects/sanitize.ts
var inputs = [
  "<b>\u0639\u0631\u064A\u0636</b> <i>\u0645\u0627\u0626\u0644</i>",
  '<img src=x onerror="window.hacked=true">',
  '<a href="javascript:alert(1)">\u0647\u062F\u064A\u0629 \u0645\u062C\u0627\u0646\u064A\u0629</a>',
  "<script>window.hacked=true</script><p>\u0628\u0639\u0636 \u0627\u0644\u0646\u0635</p>"
];
await withLab({}, async (page, base) => {
  await page.goto(base + "sanitize.html");
  await page.evaluate(async (src) => {
    const s = document.createElement("script");
    s.src = src;
    document.head.append(s);
    await new Promise((r) => s.onload = r);
  }, base + "purify.js");
  for (const input of inputs) {
    const clean = await page.evaluate(
      (html) => (
        // تبقى الوسوم المسموحة فقط، وتُحذف السكربتات ومعالجات الأحداث
        window.DOMPurify.sanitize(html, {
          ALLOWED_TAGS: ["b", "i", "em", "strong", "a", "p"],
          ALLOWED_ATTR: ["href"]
        })
      ),
      input
    );
    console.log(`${input}
  \u2192 ${clean}`);
  }
});
