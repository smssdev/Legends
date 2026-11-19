// ar/projects/which-image.ts
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
var require2 = createRequire(import.meta.url);
var { chromium } = require2("playwright");
var browser = await chromium.launch();
for (const [name, width, dpr] of [["phone", 390, 1], ["phone 2x", 390, 2], ["desktop", 1280, 1]]) {
  const tab = await browser.newPage({ viewport: { width, height: 800 }, deviceScaleFactor: dpr });
  await tab.goto(pathToFileURL(resolve("images.html")).href);
  const result = await tab.evaluate(() => {
    const downloaded = performance.getEntriesByType("resource").map((e) => e.name.split("/").pop());
    return { hero: document.images[0].currentSrc.split("/").pop(), lowerLoaded: downloaded.includes("below.png") };
  });
  console.log(`${name.padEnd(9)} \u0627\u0644\u0635\u0648\u0631\u0629 \u0627\u0644\u0631\u0626\u064A\u0633\u064A\u0629: ${result.hero}   \u0647\u0644 \u062D\u064F\u0645\u0651\u0644\u062A \u0627\u0644\u0635\u0648\u0631\u0629 \u0627\u0644\u0628\u0639\u064A\u062F\u0629\u061F ${result.lowerLoaded ? "\u0646\u0639\u0645" : "\u0644\u0627 (\u0643\u0633\u0648\u0644\u0629)"}`);
}
await browser.close();
