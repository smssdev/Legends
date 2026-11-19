// ar/measure-lib.ts
import { createReadStream } from "node:fs";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { extname, join } from "node:path";
var require2 = createRequire(import.meta.url);
var { chromium } = require2("playwright");
function serve() {
  const types = { ".html": "text/html", ".js": "text/javascript", ".png": "image/png" };
  const server = createServer((req, res) => {
    const path = join(process.cwd(), new URL(req.url ?? "/", "http://x").pathname);
    res.setHeader("Content-Type", types[extname(path)] ?? "application/octet-stream");
    createReadStream(path).on("error", () => res.writeHead(404).end()).pipe(res);
  });
  return new Promise(
    (ready) => server.listen(0, () => ready({ url: `http://localhost:${server.address().port}/`, close: () => server.close() }))
  );
}
async function measure(page) {
  const site = await serve();
  const browser = await chromium.launch();
  const tab = await browser.newPage();
  const cdp = await tab.context().newCDPSession(tab);
  await cdp.send("Network.enable");
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false,
    latency: 150,
    downloadThroughput: 1.6 * 1024 * 1024 / 8,
    uploadThroughput: 750 * 1024 / 8
  });
  await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });
  await tab.goto(site.url + page);
  await tab.waitForTimeout(1e3);
  const vitals = await tab.evaluate(
    () => new Promise((done) => {
      let lcp = 0;
      let cls = 0;
      new PerformanceObserver((list) => {
        for (const e of list.getEntries()) lcp = e.startTime;
      }).observe({ type: "largest-contentful-paint", buffered: true });
      new PerformanceObserver((list) => {
        for (const e of list.getEntries()) {
          if (!e.hadRecentInput) cls += e.value;
        }
      }).observe({ type: "layout-shift", buffered: true });
      setTimeout(() => done({ lcp, cls }), 100);
    })
  );
  await browser.close();
  site.close();
  return vitals;
}
function rate(value, good, poor) {
  return value <= good ? "\u062C\u064A\u062F" : value <= poor ? "\u064A\u062D\u062A\u0627\u062C \u062A\u062D\u0633\u064A\u0646\u0627\u064B" : "\u0636\u0639\u064A\u0641";
}

// ar/measure.ts
for (const page of ["slow.html", "fast.html"]) {
  const { lcp, cls } = await measure(page);
  const seconds = (Math.round(lcp / 100) / 10).toFixed(1);
  console.log(`${page.padEnd(10)} LCP ${seconds} s (${rate(lcp, 2500, 4e3)})   CLS ${cls.toFixed(2)} (${rate(cls, 0.1, 0.25)})`);
}
