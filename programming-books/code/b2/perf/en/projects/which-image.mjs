// en/projects/which-image.ts
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
  console.log(`${name.padEnd(9)} hero image: ${result.hero}   picture far below loaded? ${result.lowerLoaded ? "yes" : "no (lazy)"}`);
}
await browser.close();
