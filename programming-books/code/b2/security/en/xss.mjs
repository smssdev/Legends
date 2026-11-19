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

// en/xss.ts
var comment = `<img src="x" onerror="window.hacked = true"> Nice book!`;
await withLab({}, async (page, base) => {
  for (const way of ["innerHTML", "textContent"]) {
    await page.goto(base + "comments.html");
    const result = await page.evaluate(
      async ({ way: way2, comment: comment2 }) => {
        const li = document.createElement("li");
        if (way2 === "innerHTML") li.innerHTML = comment2;
        else li.textContent = comment2;
        document.querySelector("#list").append(li);
        await new Promise((r) => setTimeout(r, 100));
        return { ran: window.hacked === true, html: li.innerHTML };
      },
      { way, comment }
    );
    console.log(`${way.padEnd(12)} script ran? ${result.ran ? "YES" : "no"}`);
  }
});
