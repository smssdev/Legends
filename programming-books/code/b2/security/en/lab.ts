// A small lab: serves pages from this folder with chosen headers, and opens them in Chromium.
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
