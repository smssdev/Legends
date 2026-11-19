import { createReadStream } from "node:fs";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { createRequire } from "node:module";
import { extname, join } from "node:path";

const require = createRequire(import.meta.url);
type CDP = { send(method: string, params?: object): Promise<unknown> };
type Page = {
  context(): { newCDPSession(page: Page): Promise<CDP> };
  goto(url: string): Promise<unknown>;
  waitForTimeout(ms: number): Promise<void>;
  evaluate<T>(fn: () => T | Promise<T>): Promise<T>;
};
type Browser = { newPage(): Promise<Page>; close(): Promise<void> };
const { chromium } = require("playwright") as { chromium: { launch(): Promise<Browser> } };

export type Vitals = { lcp: number; cls: number };

// Throttling only works over HTTP, so the pages are served like a real site
function serve(): Promise<{ url: string; close: () => void }> {
  const types: Record<string, string> = { ".html": "text/html", ".js": "text/javascript", ".png": "image/png" };
  const server = createServer((req, res) => {
    const path = join(process.cwd(), new URL(req.url ?? "/", "http://x").pathname);
    res.setHeader("Content-Type", types[extname(path)] ?? "application/octet-stream");
    createReadStream(path).on("error", () => res.writeHead(404).end()).pipe(res);
  });
  return new Promise((ready) =>
    server.listen(0, () => ready({ url: `http://localhost:${(server.address() as AddressInfo).port}/`, close: () => server.close() })),
  );
}

export async function measure(page: string): Promise<Vitals> {
  const site = await serve();
  const browser = await chromium.launch();
  const tab = await browser.newPage();
  // Slow down the network and the CPU, like a mid-range phone on a 4G connection
  const cdp = await tab.context().newCDPSession(tab);
  await cdp.send("Network.enable");
  await cdp.send("Network.emulateNetworkConditions", {
    offline: false, latency: 150, downloadThroughput: (1.6 * 1024 * 1024) / 8, uploadThroughput: (750 * 1024) / 8,
  });
  await cdp.send("Emulation.setCPUThrottlingRate", { rate: 4 });

  await tab.goto(site.url + page); // waits for the load event, pictures included
  await tab.waitForTimeout(1000);
  const vitals = await tab.evaluate(
    () =>
      new Promise<{ lcp: number; cls: number }>((done) => {
        let lcp = 0;
        let cls = 0;
        new PerformanceObserver((list) => {
          for (const e of list.getEntries()) lcp = e.startTime;
        }).observe({ type: "largest-contentful-paint", buffered: true });
        new PerformanceObserver((list) => {
          for (const e of list.getEntries() as (PerformanceEntry & { value: number; hadRecentInput: boolean })[]) {
            if (!e.hadRecentInput) cls += e.value;
          }
        }).observe({ type: "layout-shift", buffered: true });
        setTimeout(() => done({ lcp, cls }), 100);
      }),
  );
  await browser.close();
  site.close();
  return vitals;
}

export function rate(value: number, good: number, poor: number): string {
  return value <= good ? "good" : value <= poor ? "needs work" : "poor";
}
