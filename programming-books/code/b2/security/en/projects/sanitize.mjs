// en/lab.ts
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

// en/projects/sanitize.ts
var inputs = [
  "<b>Bold</b> <i>italic</i>",
  '<img src=x onerror="window.hacked=true">',
  '<a href="javascript:alert(1)">Free gift</a>',
  "<script>window.hacked=true</script><p>Some text</p>"
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
        // Only the allowed tags survive; scripts and event handlers are removed
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
