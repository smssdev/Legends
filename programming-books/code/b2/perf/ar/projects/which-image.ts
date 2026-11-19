import { createRequire } from "node:module";
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
  console.log(`${name.padEnd(9)} الصورة الرئيسية: ${result.hero}   هل حُمّلت الصورة البعيدة؟ ${result.lowerLoaded ? "نعم" : "لا (كسولة)"}`);
}
await browser.close();
