"""Writes the examples of Book 2, chapter "Performance and Core Web Vitals", in English and Arabic.
Run: python3 make.py   The measurements open real pages in Chromium with a slowed network and CPU.
Text placeholders are {w_…}.
"""
import base64
import sys
import zlib
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Performance", w_item="Bit item", lang="en", dir="ltr", w_shop="Bit's shop", w_hero="The Bit mug is back",
        w_text="Big enough for long coding nights, and now in three colours. Order before Friday for free delivery.",
        w_buy="Order now", w_banner="Free delivery this week!", w_alt="The Bit mug in purple, white and pink",
        w_page="page", w_good="good", w_needs="needs work", w_poor="poor",
        w_search="Filter products", w_showing="Showing", w_of="of", w_pending="Updating…",
        w_budget="Budget", w_over="over budget", w_ok="within budget", w_total="Total",
        w_hero_label="hero image:", w_lower_label="picture far below loaded?", w_yes="yes", w_no="no (lazy)",
        w_c1="Slow down the network and the CPU, like a mid-range phone on a 4G connection",
        w_c2="Keep the typing urgent; the big list update can wait",
        w_c3="Fails the build when the JavaScript or CSS sent to users grows past the budget",
    ),
    "ar": dict(
        w_title="الأداء", w_item="منتج بِت", lang="ar", dir="rtl", w_shop="متجر بِت", w_hero="عاد كوب بِت",
        w_text="كبير بما يكفي لليالي البرمجة الطويلة، والآن بثلاثة ألوان. اطلب قبل الجمعة لتحصل على توصيل مجاني.",
        w_buy="اطلب الآن", w_banner="توصيل مجاني هذا الأسبوع!", w_alt="كوب بِت بالبنفسجي والأبيض والوردي",
        w_page="الصفحة", w_good="جيد", w_needs="يحتاج تحسيناً", w_poor="ضعيف",
        w_search="صفِّ المنتجات", w_showing="يظهر", w_of="من", w_pending="جارٍ التحديث…",
        w_budget="الميزانية", w_over="تجاوز الميزانية", w_ok="ضمن الميزانية", w_total="المجموع",
        w_hero_label="الصورة الرئيسية:", w_lower_label="هل حُمّلت الصورة البعيدة؟", w_yes="نعم", w_no="لا (كسولة)",
        w_c1="أبطئ الشبكة والمعالج، كجوال متوسط على اتصال 4G",
        w_c2="أبقِ الكتابة عاجلة، وتحديث القائمة الكبيرة يستطيع الانتظار",
        w_c3="يُفشل البناء حين تكبر JavaScript أو CSS المرسلة للمستخدمين فوق الميزانية",
    ),
}

PLAIN, NODE, BROWSER = {}, {}, {}

# A big picture (about 900 KB, like an uncompressed photo) and a small one (about 30 KB, like a compressed one).
def picture(name, size):
    # A real PNG whose size comes from random-looking pixels that do not compress
    import random
    import struct
    random.seed(7)
    w, h = (1000, 560) if size == "big" else (640, 360)
    rows = []
    for y in range(h):
        row = bytearray([0])
        for x in range(w):
            if size == "big":
                v = random.randrange(256)
                row += bytes((99 + v % 40, 102 + v % 30, 241 - v % 50))
            else:
                row += bytes((99, 102, 241)) if (x // 40 + y // 40) % 2 else bytes((224, 231, 255))
        rows.append(bytes(row))
    raw = b"".join(rows)

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    return png


STYLE = """      body { font-family: system-ui, "Segoe UI", Tahoma, sans-serif; margin: 0; background: #f5f5fb; color: #1e1b2e; }
      header { background: white; padding: 10px 16px; font-weight: 800; color: #4338ca; }
      main { padding: 16px; max-width: 640px; margin: auto; }
      img { width: 100%; height: auto; border-radius: 12px; display: block; }
      h1 { color: #4338ca; }
      .banner { background: #fef3c7; color: #92400e; padding: 24px 16px; min-height: 140px; font-weight: 700; font-size: 1.2rem; }
      button { font: inherit; border: 0; border-radius: 999px; padding: 8px 18px; background: #4338ca; color: white; }
"""

PLAIN["slow.html"] = f'''<!doctype html>
<html lang="{{lang}}" dir="{{dir}}">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{w_shop}}</title>
    <script src="heavy.js"></script>
    <style>
{STYLE}    </style>
  </head>
  <body>
    <header>{{w_shop}}</header>
    <main>
      <img src="hero-big.png">
      <h1>{{w_hero}}</h1>
      <p>{{w_text}}</p>
      <button>{{w_buy}}</button>
    </main>
    <script>
      // A banner added after load pushes everything down
      setTimeout(() => document.body.insertAdjacentHTML("afterbegin", '<div class="banner">{{w_banner}}</div>'), 600);
    </script>
  </body>
</html>
'''

PLAIN["fast.html"] = f'''<!doctype html>
<html lang="{{lang}}" dir="{{dir}}">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{w_shop}}</title>
    <link rel="preload" as="image" href="hero-small.png" fetchpriority="high">
    <script src="heavy.js" defer></script>
    <style>
{STYLE}    </style>
  </head>
  <body>
    <div class="banner">{{w_banner}}</div>
    <header>{{w_shop}}</header>
    <main>
      <img src="hero-small.png" width="640" height="360" alt="{{w_alt}}" fetchpriority="high">
      <h1>{{w_hero}}</h1>
      <p>{{w_text}}</p>
      <button>{{w_buy}}</button>
    </main>
  </body>
</html>
'''

# A script that keeps the main thread busy for a while, like a big analytics or chat widget
PLAIN["heavy.js"] = '''// Pretend third-party widget: about 300 ms of work on a fast computer
const end = performance.now() + 300;
let n = 0;
while (performance.now() < end) n += Math.sqrt(n + 1);
window.widgetReady = n > 0;
'''

PLAIN["measure-lib.ts"] = '''import { createReadStream } from "node:fs";
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
  // {w_c1}
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
  return value <= good ? "{w_good}" : value <= poor ? "{w_needs}" : "{w_poor}";
}
'''

NODE["measure.ts"] = '''import { measure, rate } from "./measure-lib";

for (const page of ["slow.html", "fast.html"]) {
  const { lcp, cls } = await measure(page);
  // Rounded, because each run differs by a few milliseconds
  const seconds = (Math.round(lcp / 100) / 10).toFixed(1);
  console.log(`${page.padEnd(10)} LCP ${seconds} s (${rate(lcp, 2500, 4000)})   CLS ${cls.toFixed(2)} (${rate(cls, 0.1, 0.25)})`);
}
'''

CSS = """.card { background: white; border-radius: 12px; padding: 12px 14px; max-width: 460px; }
input { font: inherit; padding: 7px 10px; border: 2px solid #c7d2fe; border-radius: 10px; width: 100%; }
ul { list-style: none; padding: 0; margin: 8px 0 0; max-height: 150px; overflow: hidden; }
li { padding: 3px 0; border-bottom: 1px solid #eef2ff; }
.muted { color: #5b5873; }
.stale { opacity: 0.55; }
"""

PLAIN["react/SlowList.tsx"] = '''import { memo } from "react";

// A deliberately slow row: in a real app, a rich card with images, prices and badges
function SlowRow({ name }: { name: string }) {
  const start = performance.now();
  while (performance.now() - start < 0.2) {
    // 0.2 ms of work per row
  }
  return <li>{name}</li>;
}

// memo: re-render the list only when its props change
export const SlowList = memo(function SlowList({ items }: { items: string[] }) {
  return (
    <ul>
      {items.slice(0, 2000).map((name) => (
        <SlowRow key={name} name={name} />
      ))}
    </ul>
  );
});
'''

BROWSER["react/transition.tsx"] = ('''import { useDeferredValue, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import { SlowList } from "./SlowList";

const ALL = Array.from({ length: 5000 }, (_, i) => `{w_item} ${i + 1}`);

function Filter() {
  const [text, setText] = useState("");
  // {w_c2}
  const deferred = useDeferredValue(text);
  const items = useMemo(() => ALL.filter((name) => name.includes(deferred)), [deferred]);
  const stale = text !== deferred;

  return (
    <div className="card">
      <label htmlFor="q">{w_search}</label>
      <input id="q" value={text} onChange={(e) => setText(e.target.value)} />
      <p className="muted" aria-live="polite">
        {stale ? "{w_pending}" : `{w_showing} ${items.length} {w_of} ${ALL.length}`}
      </p>
      <div className={stale ? "stale" : undefined}>
        <SlowList items={items} />
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Filter />);
''', CSS)

# ---------------------------------------------------------------- projects
PLAIN["projects/images.html"] = '''<!doctype html>
<html lang="{lang}" dir="{dir}">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{w_shop}</title>
  </head>
  <body style="margin: 0">
    <img
      src="../hero-small.png"
      srcset="../hero-small.png 640w, ../hero-big.png 1000w"
      sizes="(min-width: 700px) 640px, 100vw"
      width="640" height="360" alt="{w_alt}"
      style="width: 100%; max-width: 640px; height: auto">
    <div style="height: 1500px"></div>
    <img src="../below.png" loading="lazy" width="1000" height="560" alt="" style="width: 100%; height: auto">
  </body>
</html>
'''

NODE["projects/which-image.ts"] = '''import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const require = createRequire(import.meta.url);
type Page = {
  goto(url: string): Promise<unknown>;
  evaluate<T>(fn: () => T): Promise<T>;
};
type Browser = { newPage(o: { viewport: { width: number; height: number }; deviceScaleFactor: number }): Promise<Page>; close(): Promise<void> };
const { chromium } = require("playwright") as { chromium: { launch(): Promise<Browser> } };

const browser = await chromium.launch();
for (const [name, width, dpr] of [["phone", 390, 1], ["phone 2x", 390, 2], ["desktop", 1280, 1]] as const) {
  const tab = await browser.newPage({ viewport: { width, height: 800 }, deviceScaleFactor: dpr });
  await tab.goto(pathToFileURL(resolve("images.html")).href);
  const result = await tab.evaluate(() => {
    const downloaded = performance.getEntriesByType("resource").map((e) => e.name.split("/").pop());
    return { hero: document.images[0]!.currentSrc.split("/").pop(), lowerLoaded: downloaded.includes("below.png") };
  });
  console.log(`${name.padEnd(9)} {w_hero_label} ${result.hero}   {w_lower_label} ${result.lowerLoaded ? "{w_yes}" : "{w_no}"}`);
}
await browser.close();
'''

NODE["projects/budget.ts"] = '''import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { gzipSync } from "node:zlib";

// {w_c3}
const BUDGET = { js: 60 * 1024, css: 15 * 1024 };

function files(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? files(path) : [path];
  });
}

const sizes = { js: 0, css: 0 };
for (const file of files(process.argv[2] ?? "../../../vendor")) {
  const kind = file.endsWith(".js") ? "js" : file.endsWith(".css") ? "css" : null;
  if (kind) sizes[kind] += gzipSync(readFileSync(file)).length;
}

let failed = false;
for (const kind of ["js", "css"] as const) {
  const over = sizes[kind] > BUDGET[kind];
  failed ||= over;
  const kb = (n: number) => `${(n / 1024).toFixed(1)} KB`;
  console.log(`${kind.toUpperCase().padEnd(4)} ${kb(sizes[kind]).padStart(9)}  {w_budget} ${kb(BUDGET[kind]).padStart(8)}  ${over ? "✗ {w_over}" : "✓ {w_ok}"}`);
}
process.exitCode = failed ? 1 : 0;
'''


for lang, words in T.items():
    out = HERE / lang
    out.mkdir(parents=True, exist_ok=True)
    (out / "hero-big.png").write_bytes(picture("hero-big.png", "big"))
    (out / "hero-small.png").write_bytes(picture("hero-small.png", "small"))
    (out / "below.png").write_bytes(picture("below.png", "small"))

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER, title_key="w_title")
