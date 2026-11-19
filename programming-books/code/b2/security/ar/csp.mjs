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

// ar/csp.ts
var policy = "default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'";
await withLab({ "Content-Security-Policy": policy }, async (page, base) => {
  const blocked = [];
  page.on("console", (m) => {
    if (m.text().includes("Content Security Policy")) blocked.push(m.text().slice(0, 70) + "\u2026");
  });
  await page.goto(base + "csp.html");
  await page.waitForTimeout(200);
  const state = await page.evaluate(
    () => ({ hacked: window.hacked === true, title: document.querySelector("#title").textContent }),
    null
  );
  for (const line of blocked) console.log("\u0645\u0646\u0639\u062A\u0647 CSP:", line);
  console.log("\u0639\u0645\u0644 \u0627\u0644\u0633\u0643\u0631\u0628\u062A\u061F", state.hacked ? "\u0646\u0639\u0645" : "\u0644\u0627");
  console.log("\u0627\u0644\u062A\u0637\u0628\u064A\u0642 \u0645\u0627 \u0632\u0627\u0644 \u064A\u0639\u0645\u0644:", state.title);
});
